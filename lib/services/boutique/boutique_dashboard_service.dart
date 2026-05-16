import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/boutique/shop_activity.dart';
import '../../models/boutique/shop_dashboard_summary.dart';
import '../../models/boutique/shop_order.dart';
import '../../models/boutique/shop_product.dart';
import '../preferences/currency_service.dart';

class BoutiqueDashboardService {
  BoutiqueDashboardService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<ShopDashboardSummary> watchSummary(String boutiqueId) {
    if (boutiqueId.isEmpty) {
      return Stream.value(_emptySummary);
    }
    return _firestore.collection('users').doc(boutiqueId).snapshots().asyncMap((
      userDoc,
    ) async {
      final userData = userDoc.data() ?? {};
      final productDocs = await _loadBySellerFields(
        collection: 'products',
        boutiqueId: boutiqueId,
        limit: 80,
      );
      final orderDocs = await _loadBySellerFields(
        collection: 'orders',
        boutiqueId: boutiqueId,
        limit: 80,
      );
      final appointmentDocs = await _loadAppointments(
        boutiqueId: boutiqueId,
        limit: 40,
      );
      final notificationsSnapshot = await _getSafely(
        _firestore
            .collection('conversations')
            .where('participants', arrayContains: boutiqueId)
            .limit(80),
      );

      final products = productDocs.map(ShopProduct.fromDoc).toList();
      final orders = orderDocs.map(ShopOrder.fromDoc).toList();
      final followers = (userData['followers'] as List? ?? const []).length;
      final productViews = products.fold<int>(
        0,
        (total, product) => total + product.viewsCount,
      );
      final profileViews =
          (userData['profileViewsCount'] as num?)?.toInt() ??
          (userData['viewsCount'] as num?)?.toInt() ??
          (userData['stats'] is Map
              ? ((Map<String, dynamic>.from(
                        userData['stats'] as Map,
                      )['profileViews']
                      as num?)
                  ?.toInt())
              : null) ??
          0;
      final today = DateTime.now();
      final todayAppointments =
          appointmentDocs.where((doc) {
            final data = doc.data();
            final raw = data['date'] ?? data['startAt'] ?? data['scheduledAt'];
            final date =
                raw is Timestamp
                    ? raw.toDate()
                    : raw is DateTime
                    ? raw
                    : raw is String
                    ? DateTime.tryParse(raw)
                    : null;
            return date != null &&
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
          }).length;
      final pendingOrders =
          orders
              .where((order) => order.isPending || order.needsPaymentReview)
              .toList();
      final revenue = orders
          .where((order) => !order.isCancelled)
          .fold<double>(0, (total, order) => total + order.total);
      final activities = <ShopActivity>[
        if (pendingOrders.isNotEmpty)
          ShopActivity(
            title: '${pendingOrders.length} commandes à traiter',
            subtitle: 'Confirmez les paiements et lancez la préparation',
            icon: Icons.shopping_bag_rounded,
            color: const Color(0xFFB45309),
          ),
        if (products.where((product) => product.isOutOfStock).isNotEmpty)
          ShopActivity(
            title: 'Produits en rupture',
            subtitle: 'Mettez à jour le stock ou masquez les articles',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFFDC2626),
          ),
        if (todayAppointments > 0)
          ShopActivity(
            title: '$todayAppointments rendez-vous aujourd’hui',
            subtitle: 'Préparez les essayages ou retraits',
            icon: Icons.event_available_rounded,
            color: const Color(0xFF7C3AED),
          ),
      ];

      return ShopDashboardSummary(
        boutiqueName:
            userData['boutiqueName']?.toString() ??
            userData['shopProfile']?['name']?.toString() ??
            'Ma boutique',
        productsCount: products.length,
        publishedCount: products.where((product) => product.isPublished).length,
        lowStockCount: products.where((product) => product.isLowStock).length,
        outOfStockCount:
            products.where((product) => product.isOutOfStock).length,
        hiddenCount: products.where((product) => product.isHidden).length,
        missingImageCount:
            products.where((product) => product.coverImage.isEmpty).length,
        pendingOrdersCount: pendingOrders.length,
        paymentProofCount:
            orders.where((order) => order.needsPaymentReview).length,
        todayAppointmentsCount: todayAppointments,
        unreadMessagesCount:
            notificationsSnapshot?.docs.fold<int>(0, (total, doc) {
              final data = doc.data();
              final counters =
                  data['compteurNonLu'] is Map
                      ? Map<String, dynamic>.from(data['compteurNonLu'] as Map)
                      : const <String, dynamic>{};
              final raw = counters[boutiqueId];
              final count =
                  raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
              return total + count;
            }) ??
            0,
        followersCount: followers,
        productViewsCount: productViews,
        profileViewsCount: profileViews,
        estimatedRevenue: revenue,
        currency: CurrencyService.currencyFromUserData(userData),
        topProducts:
            (products..sort((a, b) => b.viewsCount.compareTo(a.viewsCount)))
                .take(5)
                .toList(),
        urgentOrders: pendingOrders.take(5).toList(),
        activities: activities,
      );
    });
  }

  static const _emptySummary = ShopDashboardSummary(
    boutiqueName: 'Ma boutique',
    productsCount: 0,
    publishedCount: 0,
    lowStockCount: 0,
    outOfStockCount: 0,
    hiddenCount: 0,
    missingImageCount: 0,
    pendingOrdersCount: 0,
    paymentProofCount: 0,
    todayAppointmentsCount: 0,
    unreadMessagesCount: 0,
    followersCount: 0,
    productViewsCount: 0,
    profileViewsCount: 0,
    estimatedRevenue: 0,
    topProducts: [],
    urgentOrders: [],
    activities: [],
  );

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadAppointments({
    required String boutiqueId,
    required int limit,
  }) async {
    final docs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final field in const ['boutiqueId', 'creatorId', 'createurId']) {
      final snapshot = await _getSafely(
        _firestore
            .collection('appointments')
            .where(field, isEqualTo: boutiqueId)
            .limit(limit),
      );
      for (final doc
          in snapshot?.docs ??
              const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
        docs[doc.id] = doc;
      }
    }
    return docs.values.toList();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadBySellerFields({
    required String collection,
    required String boutiqueId,
    required int limit,
  }) async {
    final byBoutique = await _getSafely(
      _firestore
          .collection(collection)
          .where('boutiqueId', isEqualTo: boutiqueId)
          .limit(limit),
    );
    final bySeller = await _getSafely(
      _firestore
          .collection(collection)
          .where('sellerId', isEqualTo: boutiqueId)
          .limit(limit),
    );
    final docs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc
        in byBoutique?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
      docs[doc.id] = doc;
    }
    for (final doc
        in bySeller?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
      docs[doc.id] = doc;
    }
    return docs.values.toList();
  }

  Future<QuerySnapshot<Map<String, dynamic>>?> _getSafely(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return await query.get();
    } catch (_) {
      return null;
    }
  }
}
