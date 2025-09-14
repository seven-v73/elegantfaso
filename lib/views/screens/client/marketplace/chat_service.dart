import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<DocumentSnapshot> getUserStatusStream(String userId) {
    return _firestore.collection('user_status').doc(userId).snapshots();
  }

  Future<void> updateUserPresence({required bool isOnline}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('user_status').doc(userId).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> ensureConversationExists(String conversationId, List<String> userIds) async {
    final docRef = _firestore.collection('conversations').doc(conversationId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      final unreadCountMap = {for (var uid in userIds) uid: 0};
      await docRef.set({
        'participants': userIds,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': unreadCountMap,
      });
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String message,
    required String senderName,
    String? senderImage,
    String messageType = 'text',
  }) async {
    try {
      final senderId = _auth.currentUser?.uid;
      if (senderId == null) throw "Utilisateur non authentifié";

      // Ensure conversation exists
      await ensureConversationExists(
          conversationId,
          [senderId, receiverId]
      );

      final timestamp = Timestamp.now();
      final messageRef = _firestore.collection('messages').doc();

      await _firestore.runTransaction((transaction) async {
        transaction.set(messageRef, {
          'id': messageRef.id,
          'conversationId': conversationId,
          'senderId': senderId,
          'receiverId': receiverId,
          'message': message,
          'type': messageType,
          'timestamp': timestamp,
          'senderName': senderName,
          'senderImage': senderImage,
          'status': 'sent',
          'readBy': [],
        });

        final convRef = _firestore.collection('conversations').doc(conversationId);
        transaction.update(convRef, {
          'lastMessage': message,
          'lastMessageTime': timestamp,
          'lastSenderId': senderId,
          'updatedAt': FieldValue.serverTimestamp(),
          'unreadCount.$receiverId': FieldValue.increment(1),
        });
      });

      Future.delayed(const Duration(seconds: 1), () {
        _updateMessageStatus(messageRef.id, 'delivered');
      });
    } catch (e) {
      debugPrint("Erreur d'envoi de message: $e");
      rethrow;
    }
  }

  Future<void> sendTypingIndicator(String conversationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final docRef = _firestore.collection('conversations').doc(conversationId);
    await docRef.set({
      'typing.$userId': true,
      'typingTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearTypingIndicator(String conversationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final docRef = _firestore.collection('conversations').doc(conversationId);
    await docRef.set({
      'typing.$userId': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<void> markMessagesAsRead(String conversationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Handle nullable otherUserId
    final otherUserId = _getOtherUserId(conversationId, userId);
    if (otherUserId == null) {
      debugPrint("Could not determine other user in conversation $conversationId");
      return;
    }

    // Ensure conversation exists with non-nullable IDs
    await ensureConversationExists(conversationId, [userId, otherUserId]);

    final unreadMessages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('receiverId', isEqualTo: userId)
        .get()
        .then((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final readBy = List<String>.from(data['readBy'] ?? []);
        return !readBy.contains(userId);
      }).toList();
    });

    if (unreadMessages.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in unreadMessages) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
          'status': 'read',
        });
      }
      await batch.commit();
    }

    final convRef = _firestore.collection('conversations').doc(conversationId);
    await convRef.set({
      'unreadCount.$userId': 0,
    }, SetOptions(merge: true));
  }

  String? _getOtherUserId(String conversationId, String currentUserId) {
    final parts = conversationId.split('_');
    if (parts.length < 3) return null;

    final id1 = parts[1];
    final id2 = parts[2];
    return id1 == currentUserId ? id2 : id1;
  }

  Stream<QuerySnapshot> getMessages(String conversationId, {int limit = 50}) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<void> _updateMessageStatus(String messageId, String status) async {
    await _firestore.collection('messages').doc(messageId).update({
      'status': status,
    });
  }

  String generateConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'conv_${ids[0]}_${ids[1]}';
  }
}