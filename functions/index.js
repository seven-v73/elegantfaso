"use strict";

const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {logger} = require("firebase-functions");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();
const auth = getAuth();

const INVALID_TOKEN_CODES = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
  "messaging/invalid-argument",
]);

exports.sendQueuedNotification = onDocumentCreated(
  {
    document: "notification_outbox/{outboxId}",
    region: "europe-west1",
    retry: false,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const outboxId = event.params.outboxId;
    const outboxRef = snap.ref;
    const payload = snap.data() || {};

    if (payload.status && payload.status !== "queued") {
      logger.info("Notification outbox ignored: not queued", {outboxId});
      return;
    }

    const recipientId = stringValue(payload.recipientId);
    const title = stringValue(payload.title);
    const body = stringValue(payload.body);

    if (!recipientId || !title || !body) {
      await outboxRef.set(
        {
          status: "failed",
          error: "recipientId, title and body are required",
          processedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      return;
    }

    try {
      const tokens = await loadRecipientTokens(recipientId);
      if (tokens.length === 0) {
        await outboxRef.set(
          {
            status: "failed",
            error: "No active FCM token for recipient",
            processedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          {merge: true},
        );
        return;
      }

      const data = stringifyData({
        ...(payload.data || {}),
        type: payload.type || "system",
        priority: payload.priority || "normal",
        actionLabel: payload.actionLabel || "",
        route: payload.route || "",
        notificationId: payload.notificationId || "",
        outboxId,
      });
      const priority = stringValue(payload.priority);

      const response = await messaging.sendEachForMulticast({
        tokens,
        notification: {title, body},
        data,
        android: {
          priority: priority === "low" ? "normal" : "high",
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });

      const invalidTokens = collectInvalidTokens(tokens, response.responses);
      if (invalidTokens.length > 0) {
        await removeInvalidTokens(recipientId, invalidTokens);
      }

      await outboxRef.set(
        {
          status: response.failureCount === tokens.length ? "failed" : "sent",
          sentCount: response.successCount,
          failedCount: response.failureCount,
          invalidTokens,
          processedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    } catch (error) {
      logger.error("Failed to send queued notification", {outboxId, error});
      await outboxRef.set(
        {
          status: "failed",
          error: error.message || String(error),
          attempts: FieldValue.increment(1),
          processedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }
  },
);

exports.processAccountClosureDecision = onDocumentUpdated(
  {
    document: "account_closure_requests/{requestId}",
    region: "europe-west1",
    retry: false,
  },
  async (event) => {
    const before = event.data && event.data.before.data();
    const after = event.data && event.data.after.data();
    if (!after) return;

    if (before && before.status === after.status) return;
    if (after.status !== "permanent_delete") return;

    const userId = stringValue(after.userId);
    const target = stringValue(after.target);
    if (!userId || target !== "account") {
      logger.info("Permanent deletion ignored for non-account target", {
        requestId: event.params.requestId,
        userId,
        target,
      });
      return;
    }

    try {
      await auth.deleteUser(userId);
      await db.collection("users").doc(userId).delete();
      await event.data.after.ref.set(
        {
          authDeleted: true,
          userDocumentDeleted: true,
          processedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      logger.info("Account permanently deleted", {
        requestId: event.params.requestId,
        userId,
      });
    } catch (error) {
      logger.error("Failed to permanently delete account", {
        requestId: event.params.requestId,
        userId,
        error,
      });
      await event.data.after.ref.set(
        {
          status: "delete_failed",
          error: error.message || String(error),
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }
  },
);

async function loadRecipientTokens(userId) {
  const userRef = db.collection("users").doc(userId);
  const userSnap = await userRef.get();
  const tokens = new Set();

  if (userSnap.exists) {
    const user = userSnap.data() || {};
    if (typeof user.fcmToken === "string" && user.fcmToken.trim()) {
      tokens.add(user.fcmToken.trim());
    }
    if (Array.isArray(user.fcmTokens)) {
      user.fcmTokens
        .filter((token) => typeof token === "string" && token.trim())
        .forEach((token) => tokens.add(token.trim()));
    }
  }

  const devicesSnap = await userRef
    .collection("devices")
    .where("active", "==", true)
    .limit(50)
    .get();
  devicesSnap.docs.forEach((doc) => {
    const token = stringValue((doc.data() || {}).token);
    if (token) tokens.add(token);
  });

  return Array.from(tokens);
}

function collectInvalidTokens(tokens, responses) {
  const invalidTokens = [];
  responses.forEach((response, index) => {
    const code = response.error && response.error.code;
    if (code && INVALID_TOKEN_CODES.has(code)) {
      invalidTokens.push(tokens[index]);
    }
  });
  return invalidTokens;
}

async function removeInvalidTokens(userId, invalidTokens) {
  const userRef = db.collection("users").doc(userId);
  const batch = db.batch();
  batch.set(
    userRef,
    {
      fcmTokens: FieldValue.arrayRemove(...invalidTokens),
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  invalidTokens.forEach((token) => {
    const safeTokenId = token.replaceAll("/", "_");
    batch.set(
      userRef.collection("devices").doc(safeTokenId),
      {
        active: false,
        disabledAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  });

  await batch.commit();
}

function stringifyData(data) {
  return Object.fromEntries(
    Object.entries(data || {}).map(([key, value]) => [
      key,
      value === undefined || value === null ? "" : String(value),
    ]),
  );
}

function stringValue(value) {
  return typeof value === "string" ? value.trim() : "";
}
