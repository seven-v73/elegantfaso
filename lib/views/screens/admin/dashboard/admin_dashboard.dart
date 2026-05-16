import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../../../../core/account_roles.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/admin/admin_workflow_decision.dart';
import '../../../../models/commerce/checkout_promotion.dart';
import '../../../../models/commerce/managed_payment.dart';
import '../../../../models/commerce/platform_revenue.dart';
import '../../../../models/community/community_access_policy.dart';
import '../../../../models/community/community_group.dart';
import '../../../../services/admin/admin_commerce_config_service.dart';
import '../../../../services/commerce/commerce_revenue_service.dart';
import '../../../../services/commerce/pro_growth_service.dart';
import '../../../../services/commerce/stock_inventory_service.dart';
import '../../../../services/notifications/app_notification_service.dart';
import '../../../../services/preferences/currency_service.dart';
import '../../auth/login_screen.dart';
import '../../../widgets/forms/app_form_section.dart';
import '../../../widgets/forms/app_money_field.dart';
import '../../../widgets/forms/app_select_field.dart';
import '../../../widgets/forms/app_sticky_form_bar.dart';
import '../../../widgets/forms/app_text_field.dart';
import '../../../widgets/forms/payment_methods_editor.dart';
import 'user_model.dart';

part 'admin_constants.dart';
part 'admin_data_source.dart';
part 'user_management.dart';
part 'stat_card.dart';
part 'custom_app_bar.dart';
part 'responsive_builder.dart';
part 'admin_navigation.dart';
part 'admin_quick_widgets.dart';
part 'admin_shell_widgets.dart';
part 'admin_commerce_widgets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminFinanceNotice extends StatelessWidget {
  const _AdminFinanceNotice({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ModernColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.warning.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ModernColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppNotificationService _notificationService = AppNotificationService();
  final StockInventoryService _stockInventoryService = StockInventoryService();
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );
  final ScrollController _adminUsersScrollController = ScrollController(
    keepScrollOffset: false,
  );
  final TextEditingController _adminUserSearchController =
      TextEditingController();
  final GlobalKey _plansSectionKey = GlobalKey();
  final GlobalKey _boostsSectionKey = GlobalKey();
  final GlobalKey _withdrawalsSectionKey = GlobalKey();

  int _currentIndex = 0;
  int _nbClients = 0;
  int _nbBoutiques = 0;
  int _nbCreators = 0;
  int _nbCommandes = 0;
  double _totalRevenus = 0.0;
  List<SalesData> _salesData = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _recentActivities = [];
  Future<_AdminAttentionSnapshot>? _attentionFuture;
  _AdminAttentionSnapshot _attentionSnapshot = _AdminAttentionSnapshot.empty;
  Future<List<_AdminWorkQueueItem>>? _workQueueFuture;
  String _workQueueFilter = 'all';
  String _auditFilter = 'all';
  String _withdrawalFilter = 'pending';
  String _adminUserQuery = '';
  String _adminUserRoleFilter = 'all';
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _attentionFuture = _createAttentionFuture();
    _workQueueFuture = _loadWorkQueueItems();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _adminUsersScrollController.dispose();
    _adminUserSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      _attentionFuture = _createAttentionFuture();
      _workQueueFuture = _loadWorkQueueItems();
      await Future.wait([
        _fetchUsersData(),
        _fetchOrdersData(),
        _fetchRecentActivities(),
      ]);
    } catch (e) {
      setState(() => _errorMessage = "Erreur de chargement: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUsersData() async {
    final users = await _fetchAllAccountRecords();

    setState(() {
      _users = users;
      _nbClients = users.where((u) => u.hasRole('client')).length;
      _nbBoutiques = users.where((u) => u.hasRole('boutique')).length;
      _nbCreators = users.where((u) => u.hasRole('createur')).length;
    });
  }

  Future<List<UserModel>> _fetchAllAccountRecords() async {
    final merged = <String, UserModel>{};

    Future<void> collect(
      String collection, {
      String fallbackRole = 'client',
      String? idField,
      List<String> idFields = const [],
      bool separateVitrine = false,
    }) async {
      try {
        final snapshot = await _fetchRecentCollection(collection, limit: 200);
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final candidateFields = [if (idField != null) idField, ...idFields];
          final id = candidateFields
              .map((field) => data[field]?.toString().trim() ?? '')
              .firstWhere((value) => value.isNotEmpty, orElse: () => doc.id);
          final model = UserModel.fromSnapshot(
            doc,
            source:
                separateVitrine
                    ? '$collection • ${_roleLabel(fallbackRole)}'
                    : collection,
            fallbackRole: fallbackRole,
            roleOverride: separateVitrine ? fallbackRole : null,
            nameOverride:
                separateVitrine
                    ? UserModel.displayNameForRole(data, fallbackRole)
                    : null,
          ).copyWith(id: id);
          if (separateVitrine) {
            merged['$collection:${doc.id}:$fallbackRole'] = model;
          } else {
            merged.update(
              id,
              (existing) => existing.mergeWith(model),
              ifAbsent: () => model,
            );
          }
        }
      } catch (_) {
        // Certaines installations n'ont pas toutes les collections métier.
        // L'Admin doit continuer à afficher ce qui est accessible.
      }
    }

    Future<void> collectUserQuery(
      Query<Map<String, dynamic>> query, {
      required String fallbackRole,
      bool separateVitrine = false,
    }) async {
      try {
        final snapshot = await query.get();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final model = UserModel.fromSnapshot(
            doc,
            source:
                separateVitrine
                    ? 'users • ${_roleLabel(fallbackRole)}'
                    : 'users',
            fallbackRole: fallbackRole,
            roleOverride: separateVitrine ? fallbackRole : null,
            nameOverride:
                separateVitrine
                    ? UserModel.displayNameForRole(data, fallbackRole)
                    : null,
          );
          if (separateVitrine) {
            merged['users:${doc.id}:$fallbackRole'] = model;
          } else {
            merged.update(
              doc.id,
              (existing) => existing.mergeWith(model),
              ifAbsent: () => model,
            );
          }
        }
      } catch (_) {
        // Certaines requêtes peuvent nécessiter un index ou manquer selon le projet.
      }
    }

    await collect('users');
    await collectUserQuery(
      _firestore
          .collection('users')
          .where('roleFlags.isCreator', isEqualTo: true)
          .limit(300),
      fallbackRole: 'createur',
      separateVitrine: true,
    );
    await collectUserQuery(
      _firestore
          .collection('users')
          .where('roles', arrayContains: 'createur')
          .limit(300),
      fallbackRole: 'createur',
      separateVitrine: true,
    );
    await collectUserQuery(
      _firestore
          .collection('users')
          .where('roles', arrayContains: 'creator')
          .limit(300),
      fallbackRole: 'createur',
      separateVitrine: true,
    );
    await collectUserQuery(
      _firestore
          .collection('users')
          .where('publicRole', isEqualTo: 'createur')
          .limit(200),
      fallbackRole: 'createur',
      separateVitrine: true,
    );
    await collectUserQuery(
      _firestore
          .collection('users')
          .where('publicRole', isEqualTo: 'creator')
          .limit(200),
      fallbackRole: 'createur',
      separateVitrine: true,
    );
    await collectUserQuery(
      _firestore
          .collection('users')
          .where('roleFlags.isShop', isEqualTo: true)
          .limit(300),
      fallbackRole: 'boutique',
      separateVitrine: true,
    );
    await collect('clients', fallbackRole: 'client', idField: 'userId');
    await collect(
      'boutiques',
      fallbackRole: 'boutique',
      idField: 'userId',
      separateVitrine: true,
    );
    await collect(
      'shops',
      fallbackRole: 'boutique',
      idField: 'ownerId',
      separateVitrine: true,
    );
    await collect(
      'createurs',
      fallbackRole: 'createur',
      idField: 'userId',
      idFields: const ['ownerId', 'creatorId', 'createurId'],
      separateVitrine: true,
    );
    await collect(
      'creators',
      fallbackRole: 'createur',
      idField: 'userId',
      idFields: const ['ownerId', 'creatorId', 'createurId'],
      separateVitrine: true,
    );
    await collect(
      'salon_places',
      fallbackRole: 'createur',
      idField: 'ownerId',
      separateVitrine: true,
    );

    final users = merged.values.toList();
    users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return users;
  }

  Future<void> _fetchOrdersData() async {
    final commandes = await _fetchRecentCollection('orders', limit: 240);
    double revenus = 0;
    final monthlyTotals = <String, double>{};

    for (var doc in commandes.docs) {
      final data = doc.data();
      final totals = data['totals'];
      final amount =
          (data['platformCommission'] as num?)?.toDouble() ??
          (totals is Map
              ? (totals['platformCommission'] as num?)?.toDouble()
              : null) ??
          ((data['total'] as num?)?.toDouble() ?? 0) * 0.08;
      revenus += amount;

      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final monthKey = DateFormat('MMM yyyy').format(createdAt);
        monthlyTotals.update(
          monthKey,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
    }

    setState(() {
      _nbCommandes = commandes.size;
      _totalRevenus = revenus;
      _salesData = _processSalesData(monthlyTotals);
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchRecentCollection(
    String collection, {
    int limit = 80,
  }) async {
    final ref = _firestore.collection(collection);
    try {
      return await ref
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
    } catch (_) {
      return ref.limit(limit).get();
    }
  }

  List<SalesData> _processSalesData(Map<String, double> rawData) {
    return rawData.entries.map((e) => SalesData(e.key, e.value)).toList()
      ..sort((a, b) {
        final dateFormat = DateFormat('MMM yyyy');
        return dateFormat.parse(a.month).compareTo(dateFormat.parse(b.month));
      });
  }

  Future<_AdminAttentionSnapshot> _loadAttentionSnapshot() async {
    final results = await Future.wait<int>([
      _countPendingOrderPayments(),
      _countPendingWithdrawals(),
      _countPendingBusinessRequests('pro_upgrade_requests'),
      _countPendingBusinessRequests('boost_campaigns'),
      _countPendingReports(),
    ]);
    return _AdminAttentionSnapshot(
      orderPayments: results[0],
      withdrawals: results[1],
      proPlans: results[2],
      boosts: results[3],
      reports: results[4],
    );
  }

  Future<_AdminAttentionSnapshot> _createAttentionFuture() {
    final future = _loadAttentionSnapshot();
    future.then((snapshot) {
      if (!mounted) return;
      setState(() => _attentionSnapshot = snapshot);
    });
    return future;
  }

  Future<List<_AdminWorkQueueItem>> _loadWorkQueueItems() async {
    final items = <_AdminWorkQueueItem>[];

    try {
      final orders = await _firestore.collection('orders').limit(80).get();
      for (final doc in orders.docs) {
        final data = doc.data();
        final status = _string(
          data,
          'orderStatus',
          fallback: _string(data, 'status', fallback: 'pending'),
        );
        final paymentStatus = _string(data, 'paymentStatus');
        final total =
            _number(data, 'total') ??
            _number(data, 'grandTotal') ??
            _number(data, 'sellerPayout') ??
            0;
        final currency = _string(data, 'currency', fallback: 'XOF');
        final isDispute =
            status.contains('dispute') ||
            status.contains('disputed') ||
            paymentStatus.contains('dispute');
        if (_canReviewOrderPayment(status, paymentStatus)) {
          items.add(
            _AdminWorkQueueItem(
              type: 'payment',
              priority: 1,
              priorityLabel: 'Urgent',
              icon: Icons.receipt_long_rounded,
              color: ModernColors.warning,
              title:
                  _string(data, 'orderNumber').isNotEmpty
                      ? _string(data, 'orderNumber')
                      : 'Paiement commande ${_shortId(doc.id)}',
              subtitle:
                  '${_string(data, 'customerName', fallback: 'Client')} • ${_formatMoney(total, currency)}',
              amountLabel: _formatMoney(total, currency),
              userLabel: _string(
                data,
                'sellerName',
                fallback: _string(data, 'sellerId', fallback: 'Vendeur'),
              ),
              statusLabel: ManagedPaymentCopy.paymentStatusLabel(paymentStatus),
              createdAt:
                  _dateFrom(data['createdAt']) ?? _dateFrom(data['updatedAt']),
              primaryLabel: 'Vérifier',
              onPrimary: () => _showOrderTransactionDetail(doc),
              onDetail: () => _showOrderTransactionDetail(doc),
            ),
          );
        } else if (isDispute) {
          items.add(
            _AdminWorkQueueItem(
              type: 'dispute',
              priority: 0,
              priorityLabel: 'Critique',
              icon: Icons.report_problem_rounded,
              color: ModernColors.danger,
              title: 'Litige ${_shortId(doc.id)}',
              subtitle:
                  '${_string(data, 'customerName', fallback: 'Client')} • ${_formatMoney(total, currency)}',
              amountLabel: _formatMoney(total, currency),
              userLabel: _string(data, 'sellerName', fallback: 'Vendeur'),
              statusLabel: ManagedPaymentCopy.orderStatusLabel(status),
              createdAt:
                  _dateFrom(data['updatedAt']) ?? _dateFrom(data['createdAt']),
              primaryLabel: 'Ouvrir fiche',
              onPrimary: () => _showOrderTransactionDetail(doc),
              onDetail: () => _showOrderTransactionDetail(doc),
            ),
          );
        }
      }
    } catch (_) {}

    try {
      final withdrawals =
          await _firestore
              .collection('seller_withdrawal_requests')
              .limit(80)
              .get();
      for (final doc in withdrawals.docs) {
        final data = doc.data();
        final status = _string(
          data,
          'status',
          fallback: 'pending_admin_transfer',
        );
        if (status != 'pending_admin_transfer') continue;
        final amount = _number(data, 'amount') ?? 0;
        final currency = _string(data, 'currency', fallback: 'XOF');
        final kind = _withdrawalKind(data);
        items.add(
          _AdminWorkQueueItem(
            type: 'withdrawal',
            priority: 2,
            priorityLabel: 'Finance',
            icon: _withdrawalKindIcon(kind),
            color: _withdrawalKindColor(kind),
            title: _withdrawalKindLabel(kind),
            subtitle:
                '${_string(data, 'preferredPayoutMethod', fallback: 'Retrait')} • ${_string(data, 'paymentReference', fallback: doc.id)}',
            amountLabel: _formatMoney(amount, currency),
            userLabel: _string(data, 'sellerId', fallback: 'Vendeur'),
            statusLabel: _financeStatusLabel(status),
            createdAt:
                _dateFrom(data['createdAt']) ?? _dateFrom(data['requestedAt']),
            primaryLabel: 'Contrôler',
            onPrimary: () => _showWithdrawalTransactionDetail(doc),
            onDetail: () => _showWithdrawalTransactionDetail(doc),
          ),
        );
      }
    } catch (_) {}

    await _collectBusinessQueueItems(
      items: items,
      collection: 'pro_upgrade_requests',
      type: 'pro',
      icon: Icons.workspace_premium_rounded,
      color: ModernColors.creator,
      priorityLabel: 'Pro',
      primaryLabel: 'Activer',
      onApprove: _approvePlanRequest,
    );
    await _collectBusinessQueueItems(
      items: items,
      collection: 'boost_campaigns',
      type: 'boost',
      icon: Icons.trending_up_rounded,
      color: ModernColors.client,
      priorityLabel: 'Salon',
      primaryLabel: 'Lancer',
      onApprove: _activateBoost,
    );

    try {
      final reports = await _firestore.collection('reports').limit(60).get();
      for (final doc in reports.docs) {
        final data = doc.data();
        final status = _string(data, 'status', fallback: 'pending');
        final active =
            status == 'pending' ||
            status == 'open' ||
            status == 'new' ||
            status == 'investigating';
        if (!active) continue;
        items.add(
          _AdminWorkQueueItem(
            type: 'moderation',
            priority: status == 'investigating' ? 2 : 1,
            priorityLabel: status == 'investigating' ? 'Enquête' : 'Modération',
            icon: Icons.shield_rounded,
            color: ModernColors.danger,
            title: _string(
              data,
              'title',
              fallback: 'Signalement ${_shortId(doc.id)}',
            ),
            subtitle: _string(
              data,
              'reason',
              fallback: _string(data, 'description', fallback: 'À analyser'),
            ),
            amountLabel: '',
            userLabel: _string(
              data,
              'reportedUserId',
              fallback: _string(data, 'userId', fallback: 'Utilisateur'),
            ),
            statusLabel: status,
            createdAt: _dateFrom(data['createdAt']),
            primaryLabel: 'Traiter',
            onPrimary:
                () => _moderateDocument(
                  collection: 'reports',
                  id: doc.id,
                  action: 'reviewed',
                  targetType: 'report',
                  fields: {'status': 'reviewed'},
                ),
            onDetail: () => setState(() => _currentIndex = 6),
          ),
        );
      }
    } catch (_) {}

    items.sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      if (priority != 0) return priority;
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return items;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadDisputeOrderDocs() async {
    try {
      final snapshot = await _firestore.collection('orders').limit(120).get();
      return snapshot.docs.where((doc) => _isDisputeData(doc.data())).toList()
        ..sort((a, b) {
          final aDate =
              _dateFrom(a.data()['updatedAt']) ??
              _dateFrom(a.data()['createdAt']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              _dateFrom(b.data()['updatedAt']) ??
              _dateFrom(b.data()['createdAt']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
    } catch (_) {
      return const [];
    }
  }

  Future<List<_AdminSearchResult>> _searchAdmin(String rawQuery) async {
    final query = rawQuery.trim().toLowerCase();
    if (query.length < 2) return const [];
    final results = <_AdminSearchResult>[];
    final seen = <String>{};

    Future<void> collect({
      required String collection,
      required IconData icon,
      required Color color,
      required String typeLabel,
      required List<String> fields,
      required String Function(QueryDocumentSnapshot<Map<String, dynamic>> doc)
      titleBuilder,
      required String Function(QueryDocumentSnapshot<Map<String, dynamic>> doc)
      subtitleBuilder,
      required VoidCallback Function(
        QueryDocumentSnapshot<Map<String, dynamic>> doc,
      )
      onOpenBuilder,
    }) async {
      try {
        final snapshot =
            await _firestore.collection(collection).limit(100).get();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final haystack =
              [
                doc.id,
                for (final field in fields) _string(data, field),
                for (final entry in data.entries)
                  if (entry.value is String || entry.value is num) entry.value,
              ].join(' ').toLowerCase();
          if (!haystack.contains(query)) continue;
          final key = '$collection/${doc.id}';
          if (!seen.add(key)) continue;
          results.add(
            _AdminSearchResult(
              icon: icon,
              color: color,
              typeLabel: typeLabel,
              title: titleBuilder(doc),
              subtitle: subtitleBuilder(doc),
              targetId: doc.id,
              collection: collection,
              onOpen: onOpenBuilder(doc),
            ),
          );
        }
      } catch (_) {}
    }

    await Future.wait([
      collect(
        collection: 'orders',
        icon: Icons.shopping_bag_rounded,
        color: ModernColors.warning,
        typeLabel: 'Commande',
        fields: [
          'orderNumber',
          'paymentReference',
          'customerName',
          'customerPhone',
          'userId',
          'clientId',
          'sellerId',
          'sellerName',
          'paymentAccount',
        ],
        titleBuilder:
            (doc) =>
                _string(doc.data(), 'orderNumber').isNotEmpty
                    ? _string(doc.data(), 'orderNumber')
                    : 'Commande ${_shortId(doc.id)}',
        subtitleBuilder:
            (doc) =>
                '${_string(doc.data(), 'customerName', fallback: 'Client')} • ${_string(doc.data(), 'paymentReference', fallback: doc.id)}',
        onOpenBuilder: (doc) => () => _showOrderTransactionDetail(doc),
      ),
      collect(
        collection: 'seller_withdrawal_requests',
        icon: Icons.account_balance_wallet_rounded,
        color: ModernColors.success,
        typeLabel: 'Retrait',
        fields: [
          'paymentReference',
          'sellerId',
          'orderId',
          'listingId',
          'preferredPayoutAccount',
          'preferredPayoutMethod',
        ],
        titleBuilder:
            (doc) =>
                '${_withdrawalKindLabel(_withdrawalKind(doc.data()))} • ${_string(doc.data(), 'paymentReference', fallback: doc.id)}',
        subtitleBuilder:
            (doc) =>
                '${_string(doc.data(), 'sellerId', fallback: 'Vendeur')} • ${_formatMoney(_number(doc.data(), 'amount') ?? 0, _string(doc.data(), 'currency', fallback: 'XOF'))}',
        onOpenBuilder: (doc) => () => _showWithdrawalTransactionDetail(doc),
      ),
      collect(
        collection: 'users',
        icon: Icons.person_rounded,
        color: ModernColors.primary,
        typeLabel: 'Utilisateur',
        fields: [
          'displayName',
          'email',
          'phone',
          'telephone',
          'boutiqueName',
          'creatorName',
          'activeRole',
        ],
        titleBuilder:
            (doc) => _string(
              doc.data(),
              'displayName',
              fallback: _string(doc.data(), 'email', fallback: doc.id),
            ),
        subtitleBuilder:
            (doc) =>
                '${_string(doc.data(), 'email', fallback: 'email non renseigné')} • ${_string(doc.data(), 'activeRole', fallback: 'compte')}',
        onOpenBuilder:
            (doc) =>
                () => _showAdminDocumentDetail(
                  title: _string(
                    doc.data(),
                    'displayName',
                    fallback: _string(doc.data(), 'email', fallback: doc.id),
                  ),
                  subtitle: 'Fiche utilisateur',
                  icon: Icons.person_rounded,
                  data: doc.data(),
                  targetId: doc.id,
                ),
      ),
      collect(
        collection: 'products',
        icon: Icons.inventory_2_rounded,
        color: ModernColors.shop,
        typeLabel: 'Produit',
        fields: ['name', 'title', 'sellerId', 'sellerName', 'category'],
        titleBuilder:
            (doc) => _string(
              doc.data(),
              'name',
              fallback: _string(doc.data(), 'title', fallback: doc.id),
            ),
        subtitleBuilder:
            (doc) =>
                '${_string(doc.data(), 'sellerName', fallback: _string(doc.data(), 'sellerId', fallback: 'Vendeur'))} • ${_string(doc.data(), 'category', fallback: 'Produit')}',
        onOpenBuilder:
            (doc) =>
                () => _showAdminDocumentDetail(
                  title: _string(
                    doc.data(),
                    'name',
                    fallback: _string(doc.data(), 'title', fallback: doc.id),
                  ),
                  subtitle: 'Fiche produit',
                  icon: Icons.inventory_2_rounded,
                  data: doc.data(),
                  targetId: doc.id,
                ),
      ),
      collect(
        collection: 'creations',
        icon: Icons.brush_rounded,
        color: ModernColors.creator,
        typeLabel: 'Création',
        fields: ['name', 'title', 'creatorId', 'creatorName', 'category'],
        titleBuilder:
            (doc) => _string(
              doc.data(),
              'title',
              fallback: _string(doc.data(), 'name', fallback: doc.id),
            ),
        subtitleBuilder:
            (doc) =>
                '${_string(doc.data(), 'creatorName', fallback: _string(doc.data(), 'creatorId', fallback: 'Créateur'))} • ${_string(doc.data(), 'category', fallback: 'Création')}',
        onOpenBuilder:
            (doc) =>
                () => _showAdminDocumentDetail(
                  title: _string(
                    doc.data(),
                    'title',
                    fallback: _string(doc.data(), 'name', fallback: doc.id),
                  ),
                  subtitle: 'Fiche création',
                  icon: Icons.brush_rounded,
                  data: doc.data(),
                  targetId: doc.id,
                ),
      ),
      collect(
        collection: 'secondhand_listings',
        icon: Icons.recycling_rounded,
        color: ModernColors.client,
        typeLabel: 'Vide-dressing',
        fields: ['title', 'sellerId', 'ownerId', 'city', 'category'],
        titleBuilder: (doc) => _string(doc.data(), 'title', fallback: doc.id),
        subtitleBuilder:
            (doc) =>
                '${_string(doc.data(), 'sellerId', fallback: _string(doc.data(), 'ownerId', fallback: 'Client'))} • ${_string(doc.data(), 'category', fallback: 'Annonce')}',
        onOpenBuilder:
            (doc) =>
                () => _showAdminDocumentDetail(
                  title: _string(doc.data(), 'title', fallback: doc.id),
                  subtitle: 'Annonce seconde main',
                  icon: Icons.recycling_rounded,
                  data: doc.data(),
                  targetId: doc.id,
                ),
      ),
      collect(
        collection: 'pro_upgrade_requests',
        icon: Icons.workspace_premium_rounded,
        color: ModernColors.creator,
        typeLabel: 'Plan Pro',
        fields: [
          'paymentReference',
          'userId',
          'accountId',
          'plan',
          'requestLabel',
        ],
        titleBuilder:
            (doc) => _string(
              doc.data(),
              'requestLabel',
              fallback:
                  'Plan ${ProGrowthService.planDisplayLabel(_string(doc.data(), 'plan', fallback: 'pro'))}',
            ),
        subtitleBuilder:
            (doc) =>
                '${_string(doc.data(), 'paymentReference', fallback: doc.id)} • ${_string(doc.data(), 'userId', fallback: 'Compte')}',
        onOpenBuilder:
            (doc) =>
                () => _showBusinessRequestDetail(
                  doc,
                  title: 'Demande Pro / Signature',
                  icon: Icons.workspace_premium_rounded,
                ),
      ),
      collect(
        collection: 'boost_campaigns',
        icon: Icons.trending_up_rounded,
        color: ModernColors.client,
        typeLabel: 'Boost',
        fields: ['paymentReference', 'ownerId', 'accountId', 'requestLabel'],
        titleBuilder:
            (doc) =>
                _string(doc.data(), 'requestLabel', fallback: 'Boost Salon'),
        subtitleBuilder:
            (doc) =>
                '${_string(doc.data(), 'paymentReference', fallback: doc.id)} • ${_string(doc.data(), 'ownerId', fallback: 'Compte')}',
        onOpenBuilder:
            (doc) =>
                () => _showBusinessRequestDetail(
                  doc,
                  title: 'Demande boost',
                  icon: Icons.trending_up_rounded,
                ),
      ),
      collect(
        collection: 'reports',
        icon: Icons.shield_rounded,
        color: ModernColors.danger,
        typeLabel: 'Signalement',
        fields: ['title', 'reason', 'reportedUserId', 'userId', 'targetId'],
        titleBuilder:
            (doc) => _string(
              doc.data(),
              'title',
              fallback: 'Signalement ${_shortId(doc.id)}',
            ),
        subtitleBuilder:
            (doc) => _string(
              doc.data(),
              'reason',
              fallback: _string(doc.data(), 'status', fallback: 'À traiter'),
            ),
        onOpenBuilder:
            (doc) =>
                () => _showAdminDocumentDetail(
                  title: _string(
                    doc.data(),
                    'title',
                    fallback: 'Signalement ${_shortId(doc.id)}',
                  ),
                  subtitle: 'Fiche signalement',
                  icon: Icons.shield_rounded,
                  data: doc.data(),
                  targetId: doc.id,
                ),
      ),
    ]);

    results.sort((a, b) => a.typeLabel.compareTo(b.typeLabel));
    return results.take(60).toList();
  }

  Future<void> _collectBusinessQueueItems({
    required List<_AdminWorkQueueItem> items,
    required String collection,
    required String type,
    required IconData icon,
    required Color color,
    required String priorityLabel,
    required String primaryLabel,
    required ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>>
    onApprove,
  }) async {
    try {
      final snapshot = await _firestore.collection(collection).limit(60).get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!_isBusinessPaymentPending(data)) continue;
        final amount = _number(data, 'amount') ?? 0;
        final currency = _string(data, 'currency', fallback: 'XOF');
        final plan = _string(data, 'plan');
        items.add(
          _AdminWorkQueueItem(
            type: type,
            priority: 3,
            priorityLabel: priorityLabel,
            icon: icon,
            color: color,
            title: _string(
              data,
              'requestLabel',
              fallback:
                  type == 'pro'
                      ? 'Plan ${ProGrowthService.planDisplayLabel(plan)}'
                      : 'Boost Salon',
            ),
            subtitle:
                '${_string(data, 'paymentReference', fallback: doc.id)} • ${_formatMoney(amount, currency)}',
            amountLabel: _formatMoney(amount, currency),
            userLabel: _string(
              data,
              type == 'pro' ? 'userId' : 'ownerId',
              fallback: 'Compte pro',
            ),
            statusLabel: _businessPaymentStatusLabel(
              _string(data, 'paymentStatus', fallback: 'pending'),
            ),
            createdAt:
                _dateFrom(data['createdAt']) ?? _dateFrom(data['requestedAt']),
            primaryLabel: primaryLabel,
            onPrimary: () => onApprove(doc),
            onDetail:
                () => _showAdminProof(
                  _string(
                    data,
                    'proofImageUrl',
                    fallback: _string(data, 'paymentProofUrl'),
                  ),
                  _string(data, 'requestLabel', fallback: primaryLabel),
                ),
          ),
        );
      }
    } catch (_) {}
  }

  Future<int> _countPendingOrderPayments() async {
    try {
      final snapshot =
          await _firestore
              .collection('orders')
              .where(
                'paymentStatus',
                whereIn: [
                  'client_marked_paid',
                  'proof_submitted',
                  'pending_review',
                  'pending_payment',
                ],
              )
              .limit(80)
              .get();
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return _canReviewOrderPayment(
          _string(data, 'status'),
          _string(data, 'paymentStatus'),
        );
      }).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countPendingWithdrawals() async {
    try {
      final snapshot =
          await _firestore
              .collection('seller_withdrawal_requests')
              .limit(100)
              .get();
      return snapshot.docs.where((doc) {
        final status =
            _string(
              doc.data(),
              'status',
              fallback: 'pending_admin_transfer',
            ).toLowerCase();
        return status == 'pending' ||
            status == 'requested' ||
            status == 'pending_admin_transfer' ||
            status == 'admin_review';
      }).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countPendingBusinessRequests(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).limit(80).get();
      return snapshot.docs
          .where((doc) => _isBusinessPaymentPending(doc.data()))
          .length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countPendingReports() async {
    try {
      final snapshot = await _firestore.collection('reports').limit(80).get();
      return snapshot.docs.where((doc) {
        final status = _string(doc.data(), 'status', fallback: 'pending');
        return status == 'pending' ||
            status == 'open' ||
            status == 'new' ||
            status == 'investigating';
      }).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _fetchRecentActivities() async {
    final activities =
        await _firestore
            .collection('activities')
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();

    setState(() {
      _recentActivities =
          activities.docs.map((doc) {
            final data = doc.data();
            return {
              'type': data['type'],
              'title': data['title'],
              'description': data['description'] ?? '',
              'subtitle': DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(data['timestamp'].toDate()),
              'icon': _getActivityIcon(data['type']),
              'color': _getActivityColor(data['type']),
            };
          }).toList();
    });
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'user':
        return Icons.person_add;
      case 'order':
        return Icons.shopping_cart;
      case 'shop':
        return Icons.store;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'user':
        return AppColors.primary;
      case 'order':
        return Colors.green;
      case 'shop':
        return AppColors.secondary;
      case 'payment':
        return Colors.teal;
      default:
        return Colors.amber;
    }
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.all(24),
            child: UserDetailsSheet(user: user),
          ),
    );
  }

  void _editUser(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: EditUserDialog(
              user: user,
              onSave: (updatedUser) => _updateUser(updatedUser),
            ),
          ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    final decision = await showDialog<_AdminUserDecision>(
      context: context,
      builder:
          (context) => _AdminSensitiveActionDialog(
            title: 'Suspendre ou archiver',
            message:
                'Choisissez une action claire pour ${user.name}. L’historique reste conservé pour l’audit.',
            primaryLabel: 'Suspendre',
            dangerLabel: 'Archiver',
          ),
    );

    if (decision == null) return;

    try {
      if (decision.deletePermanently) {
        await _firestore.collection('users').doc(user.id).set({
          'isActive': false,
          'accountStatus': 'archived',
          'archived': true,
          'archive': {
            'status': 'archived',
            'reason': decision.note,
            'by': _auth.currentUser?.uid,
            'at': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _logAdminAction(
          action: 'archive_user',
          targetId: user.id,
          targetType: 'user',
          note: decision.note,
        );
      } else {
        await _firestore.collection('users').doc(user.id).set({
          'isActive': false,
          'accountStatus': 'suspended',
          'suspension': {
            'status': 'suspended',
            'reason': decision.note,
            'by': _auth.currentUser?.uid,
            'at': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _logAdminAction(
          action: 'suspend_user',
          targetId: user.id,
          targetType: 'user',
          note: decision.note,
        );
      }
      await _fetchUsersData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision.deletePermanently
                ? 'Utilisateur archivé'
                : 'Utilisateur suspendu',
          ),
          backgroundColor: ModernColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action impossible: $e'),
          backgroundColor: ModernColors.danger,
        ),
      );
    }
  }

  Future<void> _updateUser(UserModel updatedUser) async {
    try {
      final roles = <String>{AccountRoles.client, updatedUser.role}.toList();
      await _firestore.collection('users').doc(updatedUser.id).set({
        ...updatedUser.toMap(),
        'activeRole': updatedUser.role,
        'roles': roles,
        'roleFlags': AccountRoleService.roleFlags(roles),
        'accountStatus': updatedUser.isActive ? 'active' : 'suspended',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _logAdminAction(
        action: 'update_user',
        targetId: updatedUser.id,
        targetType: 'user',
        note: 'Rôle ${updatedUser.role}, actif ${updatedUser.isActive}',
      );
      await _fetchUsersData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur mis à jour avec succès'),
          backgroundColor: ModernColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Erreur admin mise à jour utilisateur: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mise à jour impossible pour le moment.'),
          backgroundColor: ModernColors.danger,
        ),
      );
    }
  }

  Future<void> _createNewUser() async {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: CreateUserDialog(
              onCreate: (newUser) => _saveNewUser(newUser),
            ),
          ),
    );
  }

  Future<void> _saveNewUser(UserModel newUser) async {
    try {
      final roles = <String>{AccountRoles.client, newUser.role}.toList();
      final doc = await _firestore.collection('users').add({
        ...newUser.toMap(),
        'activeRole': newUser.role,
        'roles': roles,
        'roleFlags': AccountRoleService.roleFlags(roles),
        'accountStatus': newUser.isActive ? 'active' : 'suspended',
        'createdBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _logAdminAction(
        action: 'create_user_profile',
        targetId: doc.id,
        targetType: 'user',
        note: 'Profil créé depuis admin. Auth Firebase à créer séparément.',
      );
      await _fetchUsersData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nouvel utilisateur créé avec succès'),
          backgroundColor: ModernColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Erreur admin création utilisateur: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Création impossible pour le moment.'),
          backgroundColor: ModernColors.danger,
        ),
      );
    }
  }

  Future<void> _logAdminAction({
    required String action,
    required String targetId,
    required String targetType,
    String note = '',
    Map<String, dynamic> details = const {},
  }) async {
    final payload = {
      'action': action,
      'targetId': targetId,
      'targetType': targetType,
      'note': note,
      'adminId': _auth.currentUser?.uid,
      'adminEmail': _auth.currentUser?.email,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await Future.wait([
      _firestore.collection('admin_activity_logs').add(payload),
      _firestore.collection('admin_audit_logs').add({
        ...payload,
        'immutable': true,
        'auditVersion': 1,
      }),
    ]);
  }

  Map<String, dynamic> _auditDiffDetails({
    required Map<String, dynamic> before,
    required Map<String, dynamic> patch,
  }) {
    final changed = patch.keys.where((key) => key != 'updatedAt').toList();
    return {
      'changedKeys': changed,
      'before': {
        for (final key in changed)
          if (before.containsKey(key)) key: _auditValue(before[key]),
      },
      'after': {for (final key in changed) key: _auditValue(patch[key])},
    };
  }

  dynamic _auditValue(dynamic value) {
    if (value is FieldValue) return '<server-field-value>';
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), _auditValue(val)),
      );
    }
    if (value is Iterable) return value.map(_auditValue).toList();
    return value;
  }

  Future<void> _notifyAdminDecision({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    String priority = 'high',
    String actionLabel = '',
    String route = '/notifications',
    Map<String, dynamic> data = const {},
  }) async {
    if (recipientId.trim().isEmpty) return;
    try {
      await _notificationService.createNotification(
        recipientId: recipientId,
        title: title,
        body: body,
        type: type,
        priority: priority,
        actionLabel: actionLabel,
        route: route,
        data: data,
      );
    } catch (_) {
      // La décision admin ne doit pas échouer si la notification est indisponible.
    }
  }

  static String _recipientFromData(Map<String, dynamic> data) {
    for (final key in [
      'ownerId',
      'userId',
      'sellerId',
      'creatorId',
      'createurId',
      'boutiqueId',
      'organizerId',
      'reportedUserId',
    ]) {
      final value = _string(data, key);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Voulez-vous quitter l’espace Admin ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Se déconnecter'),
                style: FilledButton.styleFrom(
                  backgroundColor: ModernColors.danger,
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) await _signOut();
  }

  Widget _buildMainContent() {
    final width = MediaQuery.sizeOf(context).width;
    final page = _buildCurrentPage();
    final badgeCounts = _adminNavigationBadges();

    if (width < 600) {
      return page;
    }

    final extended = width >= 1000;
    return Row(
      children: [
        _AdminSideNavigation(
          selectedIndex: _currentIndex,
          extended: extended,
          badgeCounts: badgeCounts,
          onSelect: (index) => setState(() => _currentIndex = index),
          onSignOut: _confirmSignOut,
        ),
        const VerticalDivider(thickness: 1, width: 1, color: ModernColors.line),
        Expanded(child: page),
      ],
    );
  }

  Map<int, int> _adminNavigationBadges() {
    return {
      8: _attentionSnapshot.total,
      3: _attentionSnapshot.orderPayments,
      4:
          _attentionSnapshot.orderPayments +
          _attentionSnapshot.withdrawals +
          _attentionSnapshot.proPlans +
          _attentionSnapshot.boosts,
      6: _attentionSnapshot.reports,
    };
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 1:
        return _buildUsersView();
      case 2:
        return _buildSalonView();
      case 3:
        return _buildOrdersView();
      case 4:
        return _buildRevenueView();
      case 5:
        return _buildCouponsView();
      case 6:
        return _buildModerationView();
      case 7:
        return _buildSettingsView();
      case 8:
        return _buildWorkQueueView();
      case 0:
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildAdminHero()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildDashboardDecisionQueue()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildAdminAttentionCenter()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildAdminTodayPanel()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildStatsSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildChartsSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            sliver: SliverToBoxAdapter(child: _buildActivitySection()),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminAttentionCenter() {
    return FutureBuilder<_AdminAttentionSnapshot>(
      future: _attentionFuture,
      builder: (context, snapshot) {
        return _AdminAttentionCenter(
          loading: snapshot.connectionState == ConnectionState.waiting,
          data: snapshot.data ?? _AdminAttentionSnapshot.empty,
          onRefresh: () {
            setState(() => _attentionFuture = _createAttentionFuture());
          },
          onOrders: () => setState(() => _currentIndex = 3),
          onWithdrawals:
              () => setState(() {
                _withdrawalFilter = 'pending';
                _currentIndex = 4;
              }),
          onProPlans: () => setState(() => _currentIndex = 4),
          onBoosts: () => setState(() => _currentIndex = 4),
          onReports: () => setState(() => _currentIndex = 6),
        );
      },
    );
  }

  Widget _buildDashboardDecisionQueue() {
    return _AdminCard(
      title: 'Décisions du jour',
      subtitle:
          'Paiements, retraits, forfaits, boosts, litiges et signalements',
      child: FutureBuilder<List<_AdminWorkQueueItem>>(
        future: _workQueueFuture,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <_AdminWorkQueueItem>[];
          return _AdminWorkQueuePanel(
            loading: snapshot.connectionState == ConnectionState.waiting,
            error: snapshot.error,
            items: items,
            selectedFilter: _workQueueFilter,
            onFilterChanged:
                (filter) => setState(() => _workQueueFilter = filter),
            onRefresh: _refreshWorkQueue,
          );
        },
      ),
    );
  }

  Widget _buildWorkQueueView() {
    return _AdminPageScaffold(
      title: 'À traiter',
      subtitle:
          'File unique des paiements, retraits, plans, boosts, litiges et signalements.',
      icon: Icons.inbox_rounded,
      onRefresh: _refreshWorkQueue,
      trailing: _AdminTinyButton(
        icon: Icons.refresh_rounded,
        label: 'Actualiser',
        onTap: _refreshWorkQueue,
      ),
      children: [
        FutureBuilder<List<_AdminWorkQueueItem>>(
          future: _workQueueFuture,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <_AdminWorkQueueItem>[];
            return _AdminWorkQueuePanel(
              loading: snapshot.connectionState == ConnectionState.waiting,
              error: snapshot.error,
              items: items,
              selectedFilter: _workQueueFilter,
              onFilterChanged:
                  (filter) => setState(() => _workQueueFilter = filter),
              onRefresh: _refreshWorkQueue,
            );
          },
        ),
      ],
    );
  }

  Future<void> _refreshWorkQueue() async {
    setState(() {
      _attentionFuture = _createAttentionFuture();
      _workQueueFuture = _loadWorkQueueItems();
    });
    await _workQueueFuture;
  }

  Widget _buildUsersView() {
    final compactHeader = MediaQuery.sizeOf(context).width < 390;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final filteredUsers = _filteredAdminUsers();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comptes utilisateurs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: ModernColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${filteredUsers.length} compte(s) affiché(s)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ModernColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: compactHeader ? 46 : 124,
                height: 44,
                child: FilledButton(
                  onPressed: _createNewUser,
                  style: FilledButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    backgroundColor: ModernColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      compactHeader
                          ? const Icon(Icons.person_add_alt_rounded, size: 20)
                          : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Ajouter',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildAdminUserFilters(),
          const SizedBox(height: 18),
          _buildClosureRequestsPanel(),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ModernColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ModernColors.line),
                boxShadow: ModernShadows.card,
              ),
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : isMobile
                      ? _buildAdminUsersMobileList(filteredUsers)
                      : SfDataGridTheme(
                        data: SfDataGridThemeData(
                          headerColor: ModernColors.surfaceRaised,
                          rowHoverColor: ModernColors.primary.withValues(
                            alpha: 0.05,
                          ),
                        ),
                        child: SfDataGrid(
                          source: UserDataSource(
                            filteredUsers,
                            _showUserDetails,
                            _editUser,
                            _deleteUser,
                          ),
                          columns: [
                            GridColumn(
                              columnName: 'name',
                              width: 180,
                              label: Container(
                                padding: EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Nom',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            GridColumn(
                              columnName: 'email',
                              width: 220,
                              label: Container(
                                padding: EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Email',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            GridColumn(
                              columnName: 'role',
                              width: 120,
                              label: Container(
                                padding: EdgeInsets.all(16),
                                alignment: Alignment.center,
                                child: Text(
                                  'Rôle',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            GridColumn(
                              columnName: 'source',
                              width: 140,
                              label: Container(
                                padding: EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Source',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            GridColumn(
                              columnName: 'status',
                              width: 100,
                              label: Container(
                                padding: EdgeInsets.all(16),
                                alignment: Alignment.center,
                                child: Text(
                                  'Statut',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            GridColumn(
                              columnName: 'actions',
                              width: 120,
                              label: Container(
                                padding: EdgeInsets.all(16),
                                alignment: Alignment.center,
                                child: Text(
                                  'Actions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          gridLinesVisibility: GridLinesVisibility.horizontal,
                          headerGridLinesVisibility: GridLinesVisibility.both,
                          allowSorting: true,
                          selectionMode: SelectionMode.single,
                          rowHeight: 60,
                          headerRowHeight: 56,
                          columnWidthMode: ColumnWidthMode.fill,
                          onCellTap: (details) {
                            if (details.rowColumnIndex.rowIndex > 0) {
                              final user =
                                  filteredUsers[details
                                          .rowColumnIndex
                                          .rowIndex -
                                      1];
                              _showUserDetails(user);
                            }
                          },
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  List<UserModel> _filteredAdminUsers() {
    final query = _adminUserQuery.trim().toLowerCase();
    return _users.where((user) {
      final roleMatch =
          _adminUserRoleFilter == 'all' || user.hasRole(_adminUserRoleFilter);
      final queryMatch =
          query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.id.toLowerCase().contains(query) ||
          user.source.toLowerCase().contains(query);
      return roleMatch && queryMatch;
    }).toList();
  }

  Widget _buildAdminUserFilters() {
    final roles = const [
      ('all', 'Tous', Icons.people_alt_rounded),
      ('client', 'Clients', Icons.person_rounded),
      ('boutique', 'Boutiques', Icons.storefront_rounded),
      ('createur', 'Créateurs', Icons.brush_rounded),
      ('admin', 'Admins', Icons.admin_panel_settings_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _adminUserSearchController,
          label: 'Rechercher',
          hint: 'Nom, email, identifiant',
          icon: Icons.search_rounded,
          onChanged: (value) => setState(() => _adminUserQuery = value.trim()),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                roles.map((role) {
                  final selected = _adminUserRoleFilter == role.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: selected,
                      avatar: Icon(
                        role.$3,
                        size: 17,
                        color: selected ? Colors.white : ModernColors.primary,
                      ),
                      label: Text(role.$2),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : ModernColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                      selectedColor: ModernColors.primary,
                      backgroundColor: ModernColors.surfaceRaised,
                      side: BorderSide(
                        color:
                            selected ? ModernColors.primary : ModernColors.line,
                      ),
                      onSelected:
                          (_) => setState(() => _adminUserRoleFilter = role.$1),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminUsersMobileList(List<UserModel> users) {
    if (users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun compte pour ce filtre.',
            style: TextStyle(
              color: ModernColors.inkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _adminUsersScrollController,
      primary: false,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(12),
      itemCount: users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = users[index];
        final role = user.role.toLowerCase();
        return _AdminActionCard(
          icon: _adminRoleIcon(role),
          title: user.name.isEmpty ? 'Compte ${_shortId(user.id)}' : user.name,
          subtitle:
              user.email.isEmpty
                  ? 'Source ${user.source}'
                  : '${user.email} • ${user.source}',
          meta: [
            _AdminStatusChip(
              icon: _adminRoleIcon(role),
              label: _adminUserRolesLabel(user),
              color: _roleColor(role),
            ),
            _AdminStatusChip(
              icon:
                  user.isActive
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_rounded,
              label: user.isActive ? 'Actif' : 'Suspendu',
              color:
                  user.isActive ? ModernColors.success : ModernColors.warning,
            ),
            _AdminStatusChip(
              icon: Icons.calendar_month_rounded,
              label: DateFormat('dd/MM/yy').format(user.createdAt),
              color: ModernColors.inkSoft,
            ),
          ],
          actions: [
            _AdminCardAction(
              label: 'Voir',
              icon: Icons.visibility_rounded,
              onTap: () => _showUserDetails(user),
            ),
            _AdminCardAction(
              label: 'Modifier',
              icon: Icons.edit_rounded,
              onTap: () => _editUser(user),
            ),
            _AdminCardAction(
              label: user.isActive ? 'Suspendre' : 'Archiver',
              icon: Icons.block_rounded,
              danger: true,
              onTap: () => _deleteUser(user),
            ),
          ],
        );
      },
    );
  }

  static IconData _adminRoleIcon(String role) {
    if (role == 'boutique') return Icons.storefront_rounded;
    if (role == 'createur') return Icons.brush_rounded;
    if (role == 'admin') return Icons.admin_panel_settings_rounded;
    return Icons.person_rounded;
  }

  static Color _roleColor(String role) {
    if (role == 'boutique') return ModernColors.shop;
    if (role == 'createur') return ModernColors.creator;
    if (role == 'admin') return ModernColors.danger;
    return ModernColors.client;
  }

  static String _roleLabel(String role) {
    if (role == 'boutique') return 'Boutique';
    if (role == 'createur') return 'Créateur';
    if (role == 'admin') return 'Admin';
    return 'Client';
  }

  static String _adminUserRolesLabel(UserModel user) {
    final ordered = [
      if (user.hasRole('admin')) 'Admin',
      if (user.hasRole('boutique')) 'Boutique',
      if (user.hasRole('createur')) 'Créateur',
      if (user.hasRole('client')) 'Client',
    ];
    return ordered.isEmpty
        ? _roleLabel(user.role.toLowerCase())
        : ordered.join(' + ');
  }

  Widget _buildClosureRequestsPanel() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          _firestore
              .collection('account_closure_requests')
              .where('status', isEqualTo: 'pending')
              .limit(8)
              .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                padding: EdgeInsets.zero,
                title: 'Demandes de fermeture',
                subtitle:
                    'Comptes et espaces professionnels à traiter avec attention',
              ),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                final data = doc.data();
                final userId = _string(data, 'userId');
                final target = _string(data, 'target');
                return _AdminActionCard(
                  icon: Icons.pause_circle_outline_rounded,
                  title: _string(
                    data,
                    'displayName',
                    fallback: _string(data, 'email', fallback: 'Utilisateur'),
                  ),
                  subtitle:
                      '${_string(data, 'targetLabel', fallback: target)} • ${_string(data, 'reasonLabel', fallback: 'Raison non précisée')}',
                  meta: [
                    _AdminStatusChip(
                      icon: Icons.pending_actions_rounded,
                      label: 'En attente',
                      color: ModernColors.warning,
                    ),
                  ],
                  actions: [
                    _AdminCardAction(
                      label: 'Fermer',
                      icon: Icons.lock_rounded,
                      onTap:
                          () => _resolveClosureRequest(
                            requestId: doc.id,
                            userId: userId,
                            target: target,
                            decision: 'closed',
                          ),
                    ),
                    _AdminCardAction(
                      label: 'Réactiver',
                      icon: Icons.lock_open_rounded,
                      onTap:
                          () => _resolveClosureRequest(
                            requestId: doc.id,
                            userId: userId,
                            target: target,
                            decision: 'reactivated',
                          ),
                    ),
                    _AdminCardAction(
                      label: 'Supprimer',
                      icon: Icons.delete_forever_rounded,
                      danger: true,
                      onTap:
                          () => _resolveClosureRequest(
                            requestId: doc.id,
                            userId: userId,
                            target: target,
                            decision: 'permanent_delete',
                          ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _resolveClosureRequest({
    required String requestId,
    required String userId,
    required String target,
    required String decision,
  }) async {
    if (userId.isEmpty) {
      _showAdminSnack('Demande sans utilisateur associé', danger: true);
      return;
    }

    final adminNote = await showDialog<String>(
      context: context,
      builder:
          (context) => _AdminNoteDialog(
            title:
                decision == 'permanent_delete'
                    ? 'Confirmer la suppression'
                    : decision == 'reactivated'
                    ? 'Réactiver la demande'
                    : 'Fermer la demande',
            subtitle:
                decision == 'permanent_delete'
                    ? 'Cette décision est sensible. Ajoutez une note claire pour l’historique admin.'
                    : 'Ajoutez une note courte pour garder une trace de la décision.',
            primaryLabel:
                decision == 'permanent_delete'
                    ? 'Supprimer'
                    : decision == 'reactivated'
                    ? 'Réactiver'
                    : 'Fermer',
            danger: decision == 'permanent_delete',
          ),
    );
    if (adminNote == null) return;

    final now = FieldValue.serverTimestamp();
    final requestRef = _firestore
        .collection('account_closure_requests')
        .doc(requestId);
    final userRef = _firestore.collection('users').doc(userId);
    final batch = _firestore.batch();
    batch.set(requestRef, {
      'status': decision,
      'adminDecision': decision,
      'resolvedAt': now,
      'updatedAt': now,
      'resolvedBy': _auth.currentUser?.uid,
      'adminNote': adminNote,
    }, SetOptions(merge: true));

    final userPatch = <String, dynamic>{'updatedAt': now};
    if (target == 'account') {
      userPatch['accountStatus'] =
          decision == 'reactivated'
              ? 'active'
              : decision == 'permanent_delete'
              ? 'deleting'
              : 'closed';
      userPatch['closure.status'] =
          decision == 'reactivated'
              ? 'reactivated'
              : decision == 'permanent_delete'
              ? 'permanent_delete'
              : 'closed';
      userPatch['closure.resolvedAt'] = now;
    } else {
      final roleKey = target.contains('boutique') ? 'boutique' : 'createur';
      userPatch['roleClosures.$roleKey.status'] =
          decision == 'reactivated' ? 'active' : decision;
      userPatch['roleClosures.$roleKey.resolvedAt'] = now;
    }

    batch.set(userRef, userPatch, SetOptions(merge: true));
    await batch.commit();
    await _logAdminAction(
      action: 'resolve_closure_$decision',
      targetId: userId,
      targetType: target,
      note: adminNote,
    );
    await _fetchUsersData();
    if (!mounted) return;
    _showAdminSnack(
      decision == 'permanent_delete'
          ? 'Suppression définitive envoyée au serveur'
          : decision == 'reactivated'
          ? 'Compte ou espace réactivé'
          : 'Compte ou espace fermé',
    );
  }

  Widget _buildOrdersView() {
    return _AdminPageScaffold(
      title: 'Commandes',
      subtitle:
          'Pipeline commercial : paiement, confirmation vendeur, préparation, livraison et litiges.',
      icon: Icons.shopping_bag_rounded,
      onRefresh: _refreshData,
      trailing: _AdminTinyButton(
        icon: Icons.refresh_rounded,
        label: 'Actualiser',
        onTap: _refreshData,
      ),
      children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('orders').limit(40).snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? const [];
            final pending =
                docs.where((doc) {
                  final status = _string(
                    doc.data(),
                    'orderStatus',
                    fallback: _string(doc.data(), 'status'),
                  );
                  final paymentStatus = _string(doc.data(), 'paymentStatus');
                  return _canReviewOrderPayment(status, paymentStatus);
                }).length;
            final delivered =
                docs.where((doc) {
                  final status = _string(
                    doc.data(),
                    'orderStatus',
                    fallback: _string(doc.data(), 'status'),
                  );
                  return status.contains('delivered') ||
                      status.contains('livr');
                }).length;

            return Column(
              children: [
                _AdminMetricGrid(
                  items: [
                    _AdminMetricItem(
                      label: 'Commandes',
                      value: docs.length.toString(),
                      icon: Icons.receipt_long_rounded,
                      color: ModernColors.primary,
                    ),
                    _AdminMetricItem(
                      label: 'À traiter',
                      value: pending.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: ModernColors.warning,
                    ),
                    _AdminMetricItem(
                      label: 'Livrées',
                      value: delivered.toString(),
                      icon: Icons.inventory_2_rounded,
                      color: ModernColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AdminStreamBody(
                  loading: snapshot.connectionState == ConnectionState.waiting,
                  error: snapshot.error,
                  empty: docs.isEmpty,
                  emptyTitle: 'Aucune commande',
                  emptySubtitle:
                      'Les commandes créées depuis le Salon apparaîtront ici.',
                  child: Column(
                    children:
                        docs.map((doc) {
                          final data = doc.data();
                          final status = _string(
                            data,
                            'orderStatus',
                            fallback: _string(
                              data,
                              'status',
                              fallback: 'pending',
                            ),
                          );
                          final paymentStatus = _string(
                            data,
                            'paymentStatus',
                            fallback: 'non défini',
                          );
                          final canReviewPayment = _canReviewOrderPayment(
                            status,
                            paymentStatus,
                          );
                          final timeline = ManagedPaymentTimelineEntry.listFrom(
                            data['paymentTimeline'],
                          );
                          final paymentReference = _string(
                            data,
                            'paymentReference',
                          );
                          final paymentAccount = _string(
                            data,
                            'paymentAccount',
                          );
                          final sellerPaymentMethods = _stringMap(
                            data['sellerPaymentMethods'],
                          );
                          final proofImageUrl = _string(
                            data,
                            'proofImageUrl',
                            fallback: _string(
                              data,
                              'paymentProofUrl',
                              fallback: _string(data, 'proofUrl'),
                            ),
                          );
                          final total =
                              _number(data, 'total') ??
                              _number(data, 'grandTotal') ??
                              _number(data, 'sellerPayout') ??
                              _number(data, 'platformCommission') ??
                              0;
                          return _AdminActionCard(
                            icon: Icons.shopping_bag_rounded,
                            title:
                                _string(data, 'orderNumber').isNotEmpty
                                    ? _string(data, 'orderNumber')
                                    : 'Commande ${_shortId(doc.id)}',
                            subtitle:
                                '${_string(data, 'customerName', fallback: _string(data, 'userId', fallback: 'Client'))} • ${_money(total)}',
                            meta: [
                              _AdminStatusChip(
                                icon: Icons.timeline_rounded,
                                label: ManagedPaymentCopy.orderStatusLabel(
                                  status,
                                ),
                                color: _statusColor(status),
                              ),
                              _AdminStatusChip(
                                icon: Icons.payments_rounded,
                                label: ManagedPaymentCopy.paymentStatusLabel(
                                  paymentStatus,
                                ),
                                color: _statusColor(paymentStatus),
                              ),
                              if (paymentReference.isNotEmpty)
                                _AdminStatusChip(
                                  icon: Icons.tag_rounded,
                                  label: paymentReference,
                                  color: ModernColors.primary,
                                ),
                              if (paymentAccount.isNotEmpty)
                                _AdminStatusChip(
                                  icon: Icons.account_balance_wallet_rounded,
                                  label: paymentAccount,
                                  color: ModernColors.shop,
                                ),
                              if (sellerPaymentMethods.isNotEmpty)
                                _AdminStatusChip(
                                  icon: Icons.storefront_rounded,
                                  label:
                                      '${sellerPaymentMethods.length} moyen(s) vendeur',
                                  color: ModernColors.creator,
                                ),
                              if (proofImageUrl.isNotEmpty)
                                const _AdminStatusChip(
                                  icon: Icons.image_rounded,
                                  label: 'preuve jointe',
                                  color: ModernColors.client,
                                ),
                              if (timeline.isNotEmpty)
                                _AdminStatusChip(
                                  icon: Icons.history_rounded,
                                  label: '${timeline.length} étape(s)',
                                  color: ModernColors.inkSoft,
                                ),
                            ],
                            actions: [
                              _AdminCardAction(
                                label: 'Fiche détail',
                                icon: Icons.open_in_new_rounded,
                                onTap: () => _showOrderTransactionDetail(doc),
                              ),
                              if (proofImageUrl.isNotEmpty)
                                _AdminCardAction(
                                  label: 'Voir preuve',
                                  icon: Icons.receipt_long_rounded,
                                  onTap:
                                      () => _showPaymentProof(
                                        proofImageUrl,
                                        data,
                                      ),
                                ),
                              if (sellerPaymentMethods.isNotEmpty)
                                _AdminCardAction(
                                  label: 'Paiements vendeur',
                                  icon: Icons.account_balance_wallet_rounded,
                                  onTap:
                                      () => _showSellerPaymentMethods(
                                        sellerPaymentMethods,
                                        data,
                                      ),
                                ),
                              if (canReviewPayment) ...[
                                _AdminCardAction(
                                  label: 'Valider paiement',
                                  icon: Icons.verified_user_rounded,
                                  onTap:
                                      () => _reviewOrderPayment(
                                        doc,
                                        decision: 'paid',
                                        orderStatus:
                                            'pending_seller_confirmation',
                                      ),
                                ),
                                _AdminCardAction(
                                  label: 'Refuser',
                                  icon: Icons.cancel_rounded,
                                  danger: true,
                                  onTap:
                                      () => _reviewOrderPayment(
                                        doc,
                                        decision: 'payment_rejected',
                                        orderStatus: 'payment_rejected',
                                        danger: true,
                                      ),
                                ),
                              ],
                              _AdminCardAction(
                                label: 'Litige',
                                icon: Icons.report_problem_rounded,
                                danger: true,
                                onTap:
                                    () => _reviewOrderPayment(
                                      doc,
                                      decision: 'dispute',
                                      orderStatus: 'dispute',
                                      danger: true,
                                    ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSalonView() {
    return _AdminPageScaffold(
      title: 'Salon',
      subtitle:
          'Valide, masque et mets en avant les contenus publics : produits, créations, talents, inspirations et lieux.',
      icon: AppIcons.salon,
      onRefresh: _refreshData,
      children: [
        _AdminCollectionPanel(
          title: 'Contenus Salon',
          subtitle: 'Validation et mise en avant globale',
          collection: 'salon_items',
          icon: Icons.collections_rounded,
          firestore: _firestore,
          primaryAction:
              (doc) => _moderateDocument(
                collection: 'salon_items',
                id: doc.id,
                action: 'approved',
                targetType: 'salon_item',
                fields: {'status': 'approved', 'isPublic': true},
              ),
          primaryLabel: 'Approuver',
          secondaryAction:
              (doc) => _moderateDocument(
                collection: 'salon_items',
                id: doc.id,
                action: 'featured',
                targetType: 'salon_item',
                fields: {'featured': true, 'placement': 'discover'},
              ),
          secondaryLabel: 'Mettre en avant',
          dangerAction:
              (doc) => _moderateDocument(
                collection: 'salon_items',
                id: doc.id,
                action: 'hidden',
                targetType: 'salon_item',
                fields: {'status': 'hidden', 'isPublic': false},
                danger: true,
              ),
          dangerLabel: 'Masquer',
        ),
        const SizedBox(height: 16),
        _buildCommunityGovernancePanel(),
        const SizedBox(height: 16),
        _AdminCollectionPanel(
          title: 'Carte Près de moi',
          subtitle: 'Boutiques, créateurs et événements géolocalisés',
          collection: 'salon_places',
          icon: Icons.location_on_rounded,
          firestore: _firestore,
          primaryAction:
              (doc) => _moderateDocument(
                collection: 'salon_places',
                id: doc.id,
                action: 'approved',
                targetType: 'salon_place',
                fields: {'status': 'approved', 'isPublic': true},
              ),
          primaryLabel: 'Valider',
          secondaryAction:
              (doc) => _moderateDocument(
                collection: 'salon_places',
                id: doc.id,
                action: 'featured',
                targetType: 'salon_place',
                fields: {'featured': true},
              ),
          secondaryLabel: 'Local + monde',
          dangerAction:
              (doc) => _moderateDocument(
                collection: 'salon_places',
                id: doc.id,
                action: 'hidden',
                targetType: 'salon_place',
                fields: {'status': 'hidden', 'isPublic': false},
                danger: true,
              ),
          dangerLabel: 'Masquer',
        ),
      ],
    );
  }

  void _showPaymentProof(String imageUrl, Map<String, dynamic> orderData) {
    final sellerPaymentMethods = _stringMap(orderData['sellerPaymentMethods']);
    final paymentReference = _string(orderData, 'paymentReference');
    final paymentAccount = _string(orderData, 'paymentAccount');
    final timeline = ManagedPaymentTimelineEntry.listFrom(
      orderData['paymentTimeline'],
    );
    showDialog<void>(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: ModernColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: ModernColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Preuve de paiement',
                                style: TextStyle(
                                  color: ModernColors.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${_string(orderData, 'paymentMethod', fallback: 'Méthode non précisée')} • ${_string(orderData, 'customerPhone', fallback: 'numéro inconnu')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ModernColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (paymentReference.isNotEmpty)
                          _AdminStatusChip(
                            icon: Icons.tag_rounded,
                            label: paymentReference,
                            color: ModernColors.primary,
                          ),
                        if (paymentAccount.isNotEmpty)
                          _AdminStatusChip(
                            icon: Icons.account_balance_wallet_rounded,
                            label: paymentAccount,
                            color: ModernColors.shop,
                          ),
                        if (sellerPaymentMethods.isNotEmpty)
                          _AdminStatusChip(
                            icon: Icons.storefront_rounded,
                            label:
                                'Reversement: ${sellerPaymentMethods.keys.join(', ')}',
                            color: ModernColors.creator,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 360,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              height: 220,
                              color: ModernColors.surfaceRaised,
                              alignment: Alignment.center,
                              child: const Text(
                                'Impossible d’afficher cette preuve.',
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (timeline.isNotEmpty) ...[
                      _buildAdminPaymentTimeline(timeline),
                      const SizedBox(height: 14),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            () => Clipboard.setData(
                              ClipboardData(text: imageUrl),
                            ).then((_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lien de preuve copié'),
                                ),
                              );
                            }),
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copier le lien'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildAdminPaymentTimeline(
    List<ManagedPaymentTimelineEntry> timeline,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Journal transaction',
            style: TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in timeline.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.radio_button_checked_rounded,
                    color: ModernColors.primary,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.at == null
                          ? entry.label
                          : '${entry.label} • ${DateFormat('dd/MM HH:mm').format(entry.at!)}',
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showSellerPaymentMethods(
    Map<String, String> methods,
    Map<String, dynamic> orderData,
  ) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Paiements vendeur • ${_string(orderData, 'sellerName', fallback: 'Vendeur')}',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Référence: ${_string(orderData, 'paymentReference', fallback: '-')}',
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...methods.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ModernColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ModernColors.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: ModernColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  entry.value,
                                  style: const TextStyle(
                                    color: ModernColors.inkSoft,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed:
                                () => _copyAdminValue(
                                  entry.value,
                                  '${entry.key} copié',
                                ),
                            icon: const Icon(Icons.copy_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  Future<void> _reviewOrderPayment(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String decision,
    required String orderStatus,
    bool danger = false,
  }) async {
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => _AdminNoteDialog(
            title:
                decision == 'paid'
                    ? 'Valider le paiement'
                    : decision == 'payment_rejected'
                    ? 'Refuser le paiement'
                    : 'Ouvrir un litige',
            subtitle:
                'Vérifiez la preuve, le montant et le vendeur avant de confirmer.',
            primaryLabel:
                decision == 'paid'
                    ? 'Valider'
                    : decision == 'payment_rejected'
                    ? 'Refuser'
                    : 'Ouvrir litige',
            danger: danger,
          ),
    );
    if (note == null) return;

    try {
      final freshSnapshot = await doc.reference.get();
      final currentData = freshSnapshot.data() ?? doc.data();
      final currentStatus = _string(
        currentData,
        'orderStatus',
        fallback: _string(currentData, 'status'),
      );
      final currentPaymentStatus = _string(currentData, 'paymentStatus');
      if (!_canReviewOrderPayment(currentStatus, currentPaymentStatus) &&
          decision != 'dispute') {
        _showAdminSnack(
          'Cette commande est déjà traitée ou a changé de statut.',
          danger: true,
        );
        return;
      }
      final now = FieldValue.serverTimestamp();
      final batch = _firestore.batch();
      batch.set(
        doc.reference,
        AdminWorkflowDecision.orderPaymentPatch(
          decision: decision,
          orderStatus: orderStatus,
          note: note,
          adminId: _auth.currentUser?.uid,
          sellerAmount: _number(currentData, 'sellerPayout') ?? 0,
          currency: _string(currentData, 'currency', fallback: 'XOF'),
          now: now,
        ),
        SetOptions(merge: true),
      );

      final commissionRef = _firestore
          .collection('platform_commissions')
          .doc(doc.id);
      batch.set(
        commissionRef,
        AdminWorkflowDecision.commissionPaymentPatch(
          decision: decision,
          orderStatus: orderStatus,
          note: note,
          now: now,
        ),
        SetOptions(merge: true),
      );

      await batch.commit();
      if (decision == 'paid') {
        await _stockInventoryService.reserveForPaidOrder(doc.id);
      } else if (decision == 'payment_rejected') {
        await _stockInventoryService.releaseReservedOrder(doc.id);
      }
      final orderData = currentData;
      await _logAdminAction(
        action: 'review_payment_$decision',
        targetId: doc.id,
        targetType: 'order',
        note: note,
        details: {
          'previousStatus': _string(orderData, 'status'),
          'previousPaymentStatus': _string(orderData, 'paymentStatus'),
          'newStatus': orderStatus,
          'newPaymentStatus': decision,
          'amount':
              _number(orderData, 'total') ??
              _number(orderData, 'grandTotal') ??
              _number(orderData, 'sellerPayout') ??
              0,
          'currency': _string(orderData, 'currency', fallback: 'XOF'),
          'paymentReference': _string(orderData, 'paymentReference'),
          'proofUrl': _string(
            orderData,
            'proofImageUrl',
            fallback: _string(
              orderData,
              'paymentProofUrl',
              fallback: _string(orderData, 'proofUrl'),
            ),
          ),
        },
      );
      final userId = _string(orderData, 'userId');
      final sellerId = _string(orderData, 'sellerId');
      final orderLabel =
          _string(orderData, 'orderNumber').isNotEmpty
              ? _string(orderData, 'orderNumber')
              : 'Commande ${_shortId(doc.id)}';
      await Future.wait([
        _notifyAdminDecision(
          recipientId: userId,
          title:
              decision == 'paid'
                  ? 'Paiement validé'
                  : decision == 'payment_rejected'
                  ? 'Paiement refusé'
                  : 'Commande en litige',
          body:
              decision == 'paid'
                  ? '$orderLabel est validée. Le vendeur peut confirmer la préparation.'
                  : decision == 'payment_rejected'
                  ? '$orderLabel nécessite une nouvelle vérification de paiement.'
                  : '$orderLabel est passée en litige. L’équipe ElegantStyle suit le dossier.',
          type: 'order_payment_$decision',
          actionLabel: 'Voir la commande',
          data: {
            'targetType': 'order',
            'targetId': doc.id,
            'orderId': doc.id,
            'decision': decision,
          },
        ),
        _notifyAdminDecision(
          recipientId: sellerId,
          title:
              decision == 'paid'
                  ? 'Paiement client validé'
                  : decision == 'payment_rejected'
                  ? 'Paiement client refusé'
                  : 'Commande en litige',
          body:
              decision == 'paid'
                  ? '$orderLabel peut être traitée dans votre espace.'
                  : decision == 'payment_rejected'
                  ? '$orderLabel reste en attente côté client.'
                  : '$orderLabel est en litige. Attendez la résolution admin.',
          type: 'seller_order_payment_$decision',
          actionLabel: 'Voir la commande',
          data: {
            'targetType': 'order',
            'targetId': doc.id,
            'orderId': doc.id,
            'decision': decision,
          },
        ),
      ]);
      if (!mounted) return;
      _showAdminSnack(
        decision == 'paid'
            ? 'Paiement validé'
            : decision == 'payment_rejected'
            ? 'Paiement refusé'
            : 'Litige ouvert',
      );
    } catch (e) {
      if (!mounted) return;
      _showAdminSnack('Revue paiement impossible: $e', danger: true);
    }
  }

  Future<void> _markOrderDisputeInReview(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => const _AdminNoteDialog(
            title: 'Analyser le litige',
            subtitle:
                'Ajoutez ce que vous allez vérifier : preuve, conversation, livraison ou identité vendeur.',
            primaryLabel: 'Passer en analyse',
          ),
    );
    if (note == null) return;

    try {
      await doc.reference.set({
        'status': 'dispute_review',
        'orderStatus': 'dispute_review',
        'paymentStatus': 'dispute',
        'dispute': {
          'status': 'reviewing',
          'reviewNote': note,
          'reviewedBy': _auth.currentUser?.uid,
          'reviewedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _logAdminAction(
        action: 'dispute_review_started',
        targetId: doc.id,
        targetType: 'order',
        note: note,
        details: {
          'paymentReference': _string(doc.data(), 'paymentReference'),
          'amount':
              _number(doc.data(), 'total') ??
              _number(doc.data(), 'grandTotal') ??
              _number(doc.data(), 'sellerPayout') ??
              0,
          'currency': _string(doc.data(), 'currency', fallback: 'XOF'),
        },
      );
      if (!mounted) return;
      _showAdminSnack('Litige passé en analyse');
      setState(() {
        _attentionFuture = _createAttentionFuture();
        _workQueueFuture = _loadWorkQueueItems();
      });
    } catch (e) {
      if (!mounted) return;
      _showAdminSnack(
        'Impossible de passer le litige en analyse: $e',
        danger: true,
      );
    }
  }

  Widget _buildRevenueView() {
    return _AdminPageScaffold(
      title: 'Transactions',
      subtitle:
          'Paiements clients, plans, boosts, commissions et retraits vendeurs.',
      icon: Icons.payments_rounded,
      onRefresh: _refreshData,
      trailing: _AdminTinyButton(
        icon: Icons.tune_rounded,
        label: 'Configurer',
        onTap: () => setState(() => _currentIndex = 7),
      ),
      children: [
        _buildTransactionOverview(),
        const SizedBox(height: 16),
        KeyedSubtree(
          key: _plansSectionKey,
          child: _buildBusinessPaymentsPanel(
            title: 'Plans Pro & Signature',
            subtitle: 'Paiements de passage au plan professionnel',
            collection: 'pro_upgrade_requests',
            icon: Icons.workspace_premium_rounded,
            primaryLabel: 'Valider plan',
            onApprove: _approvePlanRequest,
            rejectType: 'pro_plan',
            recipientKey: 'userId',
          ),
        ),
        const SizedBox(height: 16),
        KeyedSubtree(
          key: _boostsSectionKey,
          child: _buildBusinessPaymentsPanel(
            title: 'Mises en avant',
            subtitle: 'Boosts Salon après paiement validé',
            collection: 'boost_campaigns',
            icon: Icons.trending_up_rounded,
            primaryLabel: 'Valider boost',
            onApprove: _activateBoost,
            rejectType: 'boost',
            recipientKey: 'ownerId',
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              _firestore
                  .collection('platform_commissions')
                  .limit(60)
                  .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? const [];
            final commission = docs.fold<double>(
              0,
              (runningTotal, doc) =>
                  runningTotal +
                  (_number(doc.data(), 'platformCommission') ?? 0),
            );
            final payout = docs.fold<double>(0, (runningTotal, doc) {
              final status = _string(doc.data(), 'status');
              if (status == 'settled' || status == 'blocked') {
                return runningTotal;
              }
              return runningTotal + (_number(doc.data(), 'sellerPayout') ?? 0);
            });
            final pending =
                docs.where((doc) {
                  final status = _string(doc.data(), 'status');
                  return status.isEmpty || status.contains('pending');
                }).length;

            return Column(
              children: [
                _AdminMetricGrid(
                  items: [
                    _AdminMetricItem(
                      label: 'Commission',
                      value: _money(commission),
                      icon: Icons.savings_rounded,
                      color: ModernColors.success,
                    ),
                    _AdminMetricItem(
                      label: 'À reverser',
                      value: _money(payout),
                      icon: Icons.account_balance_wallet_rounded,
                      color: ModernColors.shop,
                    ),
                    _AdminMetricItem(
                      label: 'Payouts attente',
                      value: pending.toString(),
                      icon: Icons.schedule_rounded,
                      color: ModernColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AdminStreamBody(
                  loading: snapshot.connectionState == ConnectionState.waiting,
                  error: snapshot.error,
                  empty: docs.isEmpty,
                  emptyTitle: 'Aucune commission enregistrée',
                  emptySubtitle:
                      'Les commissions seront créées automatiquement au checkout.',
                  child: Column(
                    children:
                        docs.map((doc) {
                          final data = doc.data();
                          final status = _string(
                            data,
                            'status',
                            fallback: 'pending_settlement',
                          );
                          return _AdminActionCard(
                            icon: Icons.receipt_rounded,
                            title: 'Commission ${doc.id}',
                            subtitle:
                                '${_money(_number(data, 'platformCommission') ?? 0)} • vendeur ${_string(data, 'sellerId', fallback: '-')}',
                            meta: [
                              _AdminStatusChip(
                                icon: Icons.account_balance_rounded,
                                label: _money(
                                  _number(data, 'sellerPayout') ?? 0,
                                ),
                                color: ModernColors.shop,
                              ),
                              _AdminStatusChip(
                                icon: Icons.flag_rounded,
                                label: _financeStatusLabel(status),
                                color: _statusColor(status),
                              ),
                            ],
                            actions: [
                              if (status != 'settled' && status != 'blocked')
                                _AdminCardAction(
                                  label: 'Payer vendeur',
                                  icon: Icons.check_circle_rounded,
                                  onTap:
                                      () => _reviewSellerPayout(
                                        doc,
                                        decision: 'settled',
                                      ),
                                ),
                              if (status != 'settled' && status != 'blocked')
                                _AdminCardAction(
                                  label: 'Bloquer',
                                  icon: Icons.block_rounded,
                                  danger: true,
                                  onTap:
                                      () => _reviewSellerPayout(
                                        doc,
                                        decision: 'blocked',
                                        danger: true,
                                      ),
                                ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              _firestore
                  .collection('seller_withdrawal_requests')
                  .limit(60)
                  .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? const [];
            final pendingDocs =
                docs
                    .where(
                      (doc) =>
                          _string(
                            doc.data(),
                            'status',
                            fallback: 'pending_admin_transfer',
                          ) ==
                          'pending_admin_transfer',
                    )
                    .toList();
            final pendingAmount = pendingDocs.fold<double>(
              0,
              (total, doc) => total + (_number(doc.data(), 'amount') ?? 0),
            );
            final settledAmount = docs.fold<double>(0, (total, doc) {
              if (_string(doc.data(), 'status') != 'settled') return total;
              return total + (_number(doc.data(), 'amount') ?? 0);
            });
            final orderedDocs = [...docs]..sort((a, b) {
              final aStatus = _string(a.data(), 'status');
              final bStatus = _string(b.data(), 'status');
              if (aStatus == bStatus) return 0;
              if (aStatus == 'pending_admin_transfer') return -1;
              if (bStatus == 'pending_admin_transfer') return 1;
              return aStatus.compareTo(bStatus);
            });
            final visibleDocs =
                orderedDocs
                    .where((doc) => _matchesWithdrawalFilter(doc.data()))
                    .toList();
            final secondhandPending =
                pendingDocs
                    .where((doc) => _withdrawalKind(doc.data()) == 'secondhand')
                    .length;
            final orderPending = pendingDocs.length - secondhandPending;

            return KeyedSubtree(
              key: _withdrawalsSectionKey,
              child: Column(
                children: [
                  _AdminMetricGrid(
                    items: [
                      _AdminMetricItem(
                        label: 'Retraits attente',
                        value: pendingDocs.length.toString(),
                        icon: Icons.account_balance_wallet_rounded,
                        color: ModernColors.warning,
                      ),
                      _AdminMetricItem(
                        label: 'Commandes pro',
                        value: orderPending.toString(),
                        icon: Icons.storefront_rounded,
                        color: ModernColors.primary,
                      ),
                      _AdminMetricItem(
                        label: 'Vide-dressing',
                        value: secondhandPending.toString(),
                        icon: Icons.recycling_rounded,
                        color: ModernColors.client,
                      ),
                      _AdminMetricItem(
                        label: 'Montant à payer',
                        value: _money(pendingAmount),
                        icon: Icons.payments_rounded,
                        color: ModernColors.shop,
                      ),
                      _AdminMetricItem(
                        label: 'Déjà transféré',
                        value: _money(settledAmount),
                        icon: Icons.verified_rounded,
                        color: ModernColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _AdminFinanceNotice(
                    title: 'Contrôle avant transfert',
                    message:
                        'Ne marquez payé qu’après avoir effectué le transfert réel. Les retraits commandes pro et Vide-dressing sont séparés pour éviter les confusions.',
                    icon: Icons.security_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildWithdrawalFilters(),
                  const SizedBox(height: 12),
                  _AdminStreamBody(
                    loading:
                        snapshot.connectionState == ConnectionState.waiting,
                    error: snapshot.error,
                    empty: visibleDocs.isEmpty,
                    emptyTitle: 'Aucun retrait dans ce filtre',
                    emptySubtitle:
                        'Les demandes apparaissent après réception confirmée ou vente Vide-dressing finalisée.',
                    child: Column(
                      children:
                          visibleDocs.map((doc) {
                            final data = doc.data();
                            final status = _string(
                              data,
                              'status',
                              fallback: 'pending_admin_transfer',
                            );
                            final amount = _number(data, 'amount') ?? 0;
                            final currency = _string(
                              data,
                              'currency',
                              fallback: 'XOF',
                            );
                            final orderId = _string(data, 'orderId');
                            final listingId = _string(data, 'listingId');
                            final reference = _string(
                              data,
                              'paymentReference',
                              fallback: doc.id,
                            );
                            final sellerId = _string(
                              data,
                              'sellerId',
                              fallback: '-',
                            );
                            final sellerPaymentMethods = _stringMap(
                              data['sellerPaymentMethods'],
                            );
                            final kind = _withdrawalKind(data);
                            final kindLabel = _withdrawalKindLabel(kind);
                            final requestType = _string(data, 'requestType');
                            final preferredPayoutMethod = _string(
                              data,
                              'preferredPayoutMethod',
                            );
                            final preferredPayoutAccount = _string(
                              data,
                              'preferredPayoutAccount',
                            );
                            return _AdminActionCard(
                              icon: _withdrawalKindIcon(kind),
                              title: '$kindLabel • $reference',
                              subtitle:
                                  '${_formatMoney(amount, currency)} • ${_withdrawalSellerLabel(kind)} $sellerId',
                              meta: [
                                _AdminStatusChip(
                                  icon: _withdrawalKindIcon(kind),
                                  label: kindLabel,
                                  color: _withdrawalKindColor(kind),
                                ),
                                _AdminStatusChip(
                                  icon: Icons.receipt_long_rounded,
                                  label:
                                      orderId.isNotEmpty
                                          ? 'Commande $orderId'
                                          : listingId.isNotEmpty
                                          ? 'Vide-dressing $listingId'
                                          : 'Origine inconnue',
                                  color: ModernColors.inkSoft,
                                ),
                                _AdminStatusChip(
                                  icon: Icons.tag_rounded,
                                  label: reference,
                                  color: ModernColors.primary,
                                ),
                                _AdminStatusChip(
                                  icon: Icons.flag_rounded,
                                  label: _financeStatusLabel(status),
                                  color: _statusColor(status),
                                ),
                                if (requestType.isNotEmpty)
                                  _AdminStatusChip(
                                    icon: Icons.category_rounded,
                                    label: _withdrawalRequestTypeLabel(
                                      requestType,
                                    ),
                                    color: ModernColors.inkSoft,
                                  ),
                                if (preferredPayoutMethod.isNotEmpty ||
                                    preferredPayoutAccount.isNotEmpty)
                                  _AdminStatusChip(
                                    icon: Icons.account_balance_wallet_rounded,
                                    label:
                                        preferredPayoutMethod.isEmpty
                                            ? preferredPayoutAccount
                                            : '$preferredPayoutMethod • $preferredPayoutAccount',
                                    color: ModernColors.shop,
                                  ),
                              ],
                              actions:
                                  status == 'pending_admin_transfer'
                                      ? [
                                        _AdminCardAction(
                                          label: 'Fiche détail',
                                          icon: Icons.open_in_new_rounded,
                                          onTap:
                                              () =>
                                                  _showWithdrawalTransactionDetail(
                                                    doc,
                                                  ),
                                        ),
                                        if (sellerPaymentMethods.isNotEmpty)
                                          _AdminCardAction(
                                            label: 'Paiements vendeur',
                                            icon:
                                                Icons
                                                    .account_balance_wallet_rounded,
                                            onTap:
                                                () => _showSellerPaymentMethods(
                                                  sellerPaymentMethods,
                                                  data,
                                                ),
                                          ),
                                        if (preferredPayoutAccount.isNotEmpty)
                                          _AdminCardAction(
                                            label: 'Copier paiement',
                                            icon: Icons.copy_all_rounded,
                                            onTap:
                                                () => _copyAdminValue(
                                                  preferredPayoutAccount,
                                                  'Compte vendeur copié',
                                                ),
                                          ),
                                        _AdminCardAction(
                                          label: 'Copier ref',
                                          icon: Icons.copy_rounded,
                                          onTap:
                                              () => _copyAdminValue(
                                                reference,
                                                'Référence copiée',
                                              ),
                                        ),
                                        if (orderId.isNotEmpty)
                                          _AdminCardAction(
                                            label: 'Copier commande',
                                            icon: Icons.receipt_long_rounded,
                                            onTap:
                                                () => _copyAdminValue(
                                                  orderId,
                                                  'ID commande copié',
                                                ),
                                          ),
                                        _AdminCardAction(
                                          label: 'Marquer payé',
                                          icon: Icons.check_circle_rounded,
                                          onTap:
                                              () => _reviewWithdrawalRequest(
                                                doc,
                                                decision: 'settled',
                                              ),
                                        ),
                                        _AdminCardAction(
                                          label: 'Bloquer',
                                          icon: Icons.block_rounded,
                                          danger: true,
                                          onTap:
                                              () => _reviewWithdrawalRequest(
                                                doc,
                                                decision: 'blocked',
                                                danger: true,
                                              ),
                                        ),
                                      ]
                                      : [
                                        _AdminCardAction(
                                          label: 'Fiche détail',
                                          icon: Icons.open_in_new_rounded,
                                          onTap:
                                              () =>
                                                  _showWithdrawalTransactionDetail(
                                                    doc,
                                                  ),
                                        ),
                                      ],
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildAdminAuditPanel(),
      ],
    );
  }

  Widget _buildAdminAuditPanel() {
    const filters = [
      ('all', 'Tout', Icons.history_rounded),
      ('payment', 'Paiements', Icons.receipt_long_rounded),
      ('withdrawal', 'Retraits', Icons.account_balance_wallet_rounded),
      ('pro', 'Pro', Icons.workspace_premium_rounded),
      ('boost', 'Boosts', Icons.trending_up_rounded),
      ('dispute', 'Litiges', Icons.report_problem_rounded),
      ('moderation', 'Modération', Icons.shield_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_edu_rounded, color: ModernColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Journal financier',
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      'Trace des décisions sensibles, conservée pour contrôle.',
                      style: TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children:
                  filters.map((filter) {
                    final selected = _auditFilter == filter.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: selected,
                        showCheckmark: false,
                        avatar: Icon(
                          filter.$3,
                          size: 17,
                          color: selected ? Colors.white : ModernColors.primary,
                        ),
                        label: Text(filter.$2),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : ModernColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                        selectedColor: ModernColors.primary,
                        backgroundColor: ModernColors.surface,
                        side: BorderSide(
                          color:
                              selected
                                  ? ModernColors.primary
                                  : ModernColors.line,
                        ),
                        onSelected:
                            (_) => setState(() => _auditFilter = filter.$1),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                _firestore
                    .collection('admin_audit_logs')
                    .orderBy('createdAt', descending: true)
                    .limit(60)
                    .snapshots(),
            builder: (context, snapshot) {
              final allDocs = snapshot.data?.docs ?? const [];
              final docs =
                  _auditFilter == 'all'
                      ? allDocs.take(20).toList()
                      : allDocs
                          .where(
                            (doc) =>
                                _auditFilterKey(
                                  _string(doc.data(), 'action'),
                                ) ==
                                _auditFilter,
                          )
                          .take(20)
                          .toList();
              return _AdminStreamBody(
                loading: snapshot.connectionState == ConnectionState.waiting,
                error: snapshot.error,
                empty: docs.isEmpty,
                emptyTitle: 'Aucune trace audit',
                emptySubtitle:
                    _auditFilter == 'all'
                        ? 'Les validations, refus, litiges et retraits seront journalisés ici.'
                        : 'Aucune trace dans ce filtre pour le moment.',
                child: Column(
                  children:
                      docs.map((doc) {
                        final data = doc.data();
                        final details = _stringMap(data['details']);
                        final createdAt = data['createdAt'];
                        final date =
                            createdAt is Timestamp
                                ? DateFormat(
                                  'dd/MM HH:mm',
                                ).format(createdAt.toDate())
                                : 'date en attente';
                        final action = _string(data, 'action');
                        return _AdminActionCard(
                          icon: Icons.verified_user_rounded,
                          title: _auditActionLabel(action),
                          subtitle:
                              '${_string(data, 'targetType', fallback: 'cible')} • ${_string(data, 'targetId', fallback: doc.id)}',
                          meta: [
                            _AdminStatusChip(
                              icon: Icons.schedule_rounded,
                              label: date,
                              color: ModernColors.inkSoft,
                            ),
                            if (_string(data, 'adminEmail').isNotEmpty)
                              _AdminStatusChip(
                                icon: Icons.admin_panel_settings_rounded,
                                label: _string(data, 'adminEmail'),
                                color: ModernColors.primary,
                              ),
                            if (details['amount']?.isNotEmpty == true)
                              _AdminStatusChip(
                                icon: Icons.payments_rounded,
                                label:
                                    '${details['amount']} ${details['currency'] ?? ''}',
                                color: ModernColors.success,
                              ),
                            if (details['paymentReference']?.isNotEmpty == true)
                              _AdminStatusChip(
                                icon: Icons.tag_rounded,
                                label: details['paymentReference']!,
                                color: ModernColors.creator,
                              ),
                          ],
                          actions: [
                            _AdminCardAction(
                              label: 'Copier cible',
                              icon: Icons.copy_rounded,
                              onTap:
                                  () => _copyAdminValue(
                                    _string(data, 'targetId', fallback: doc.id),
                                    'Identifiant copié',
                                  ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionOverview() {
    return FutureBuilder<_AdminAttentionSnapshot>(
      future: _attentionFuture,
      builder: (context, snapshot) {
        return _AdminTransactionOverview(
          loading: snapshot.connectionState == ConnectionState.waiting,
          data: snapshot.data ?? _AdminAttentionSnapshot.empty,
          onOrderPayments: () => setState(() => _currentIndex = 3),
          onPlans: () => _scrollToSection(_plansSectionKey),
          onBoosts: () => _scrollToSection(_boostsSectionKey),
          onWithdrawals: () {
            setState(() => _withdrawalFilter = 'pending');
            _scrollToSection(_withdrawalsSectionKey);
          },
          onSettings: () => setState(() => _currentIndex = 7),
        );
      },
    );
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Widget _buildWithdrawalFilters() {
    final filters = const [
      ('pending', 'À traiter', Icons.schedule_rounded),
      ('pro_orders', 'Commandes pro', Icons.storefront_rounded),
      ('secondhand', 'Vide-dressing', Icons.recycling_rounded),
      ('settled', 'Payés', Icons.verified_rounded),
      ('blocked', 'Bloqués', Icons.block_rounded),
      ('all', 'Tout', Icons.all_inbox_rounded),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children:
            filters.map((filter) {
              final selected = _withdrawalFilter == filter.$1;
              final color =
                  filter.$1 == 'secondhand'
                      ? ModernColors.client
                      : filter.$1 == 'blocked'
                      ? ModernColors.danger
                      : filter.$1 == 'settled'
                      ? ModernColors.success
                      : ModernColors.primary;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: selected,
                  avatar: Icon(
                    filter.$3,
                    size: 17,
                    color: selected ? Colors.white : color,
                  ),
                  label: Text(filter.$2),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : color,
                    fontWeight: FontWeight.w900,
                  ),
                  selectedColor: color,
                  backgroundColor: color.withValues(alpha: 0.08),
                  side: BorderSide(color: color.withValues(alpha: 0.16)),
                  showCheckmark: false,
                  onSelected:
                      (_) => setState(() => _withdrawalFilter = filter.$1),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildBusinessPaymentsPanel({
    required String title,
    required String subtitle,
    required String collection,
    required IconData icon,
    required String primaryLabel,
    required ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>>
    onApprove,
    required String rejectType,
    required String recipientKey,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.line),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection(collection).limit(40).snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          final pendingDocs =
              docs
                  .where((doc) => _isBusinessPaymentPending(doc.data()))
                  .toList();
          final activeDocs =
              docs
                  .where((doc) => _isBusinessPaymentApproved(doc.data()))
                  .toList();
          final rejectedDocs =
              docs
                  .where((doc) => _string(doc.data(), 'status') == 'rejected')
                  .toList();
          final pendingAmount = pendingDocs.fold<double>(
            0,
            (total, doc) => total + (_number(doc.data(), 'amount') ?? 0),
          );
          final orderedDocs = [...docs]..sort((a, b) {
            final aRank = _businessRequestRank(a.data());
            final bRank = _businessRequestRank(b.data());
            if (aRank != bRank) return aRank.compareTo(bRank);
            return _string(
              a.data(),
              'requestLabel',
            ).compareTo(_string(b.data(), 'requestLabel'));
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: ModernColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: ModernColors.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _AdminMetricGrid(
                items: [
                  _AdminMetricItem(
                    label: 'En attente',
                    value: pendingDocs.length.toString(),
                    icon: Icons.schedule_rounded,
                    color: ModernColors.warning,
                  ),
                  _AdminMetricItem(
                    label: 'À encaisser',
                    value: _money(pendingAmount),
                    icon: Icons.payments_rounded,
                    color: ModernColors.shop,
                  ),
                  _AdminMetricItem(
                    label: 'Actifs',
                    value: activeDocs.length.toString(),
                    icon: Icons.verified_rounded,
                    color: ModernColors.success,
                  ),
                  _AdminMetricItem(
                    label: 'Refusés',
                    value: rejectedDocs.length.toString(),
                    icon: Icons.block_rounded,
                    color: ModernColors.danger,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _AdminStreamBody(
                loading: snapshot.connectionState == ConnectionState.waiting,
                error: snapshot.error,
                empty: docs.isEmpty,
                emptyTitle: 'Aucune demande',
                emptySubtitle: 'Les paiements $title apparaîtront ici.',
                child: Column(
                  children:
                      orderedDocs.map((doc) {
                        final data = doc.data();
                        final status = _string(
                          data,
                          'status',
                          fallback: 'pending_payment',
                        );
                        final paymentStatus = _string(
                          data,
                          'paymentStatus',
                          fallback: 'pending',
                        );
                        final amount = _number(data, 'amount') ?? 0;
                        final currency = _string(
                          data,
                          'currency',
                          fallback: 'XOF',
                        );
                        final reference = _string(
                          data,
                          'reference',
                          fallback: _string(data, 'paymentReference'),
                        );
                        final ownerId = _string(
                          data,
                          recipientKey,
                          fallback: _string(
                            data,
                            'accountId',
                            fallback: _string(data, 'userId'),
                          ),
                        );
                        final plan = _string(data, 'plan');
                        final proofImageUrl = _string(data, 'proofImageUrl');
                        final label = _string(
                          data,
                          'requestLabel',
                          fallback:
                              plan.isNotEmpty
                                  ? 'Plan ${ProGrowthService.planDisplayLabel(plan)}'
                                  : 'Mise en avant Salon',
                        );

                        return _AdminActionCard(
                          icon: icon,
                          title: label,
                          subtitle:
                              '${_money(amount)} $currency • compte ${ownerId.isEmpty ? '-' : ownerId}',
                          meta: [
                            _AdminStatusChip(
                              icon: Icons.flag_rounded,
                              label: _businessPaymentStatusLabel(status),
                              color: _statusColor(status),
                            ),
                            _AdminStatusChip(
                              icon: Icons.payments_rounded,
                              label: _businessPaymentStatusLabel(paymentStatus),
                              color: _statusColor(paymentStatus),
                            ),
                            if (reference.isNotEmpty)
                              _AdminStatusChip(
                                icon: Icons.tag_rounded,
                                label: reference,
                                color: ModernColors.primary,
                              ),
                            if (plan.isNotEmpty)
                              _AdminStatusChip(
                                icon: Icons.workspace_premium_rounded,
                                label: ProGrowthService.planDisplayLabel(plan),
                                color:
                                    ProGrowthService.normalizePlanForStorage(
                                              plan,
                                            ) ==
                                            'premium'
                                        ? ModernColors.creator
                                        : ModernColors.shop,
                              ),
                          ],
                          actions:
                              _isBusinessPaymentPending(data)
                                  ? [
                                    if (reference.isNotEmpty)
                                      _AdminCardAction(
                                        label: 'Copier ref',
                                        icon: Icons.copy_rounded,
                                        onTap:
                                            () => _copyAdminValue(
                                              reference,
                                              'Référence copiée',
                                            ),
                                      ),
                                    if (proofImageUrl.isNotEmpty)
                                      _AdminCardAction(
                                        label: 'Voir preuve',
                                        icon: Icons.image_rounded,
                                        onTap:
                                            () => _showAdminProof(
                                              proofImageUrl,
                                              label,
                                            ),
                                      ),
                                    _AdminCardAction(
                                      label: primaryLabel,
                                      icon: Icons.check_circle_rounded,
                                      onTap: () => onApprove(doc),
                                    ),
                                    _AdminCardAction(
                                      label: 'Refuser',
                                      icon: Icons.block_rounded,
                                      danger: true,
                                      onTap:
                                          () => _rejectBusinessRequest(
                                            doc,
                                            type: rejectType,
                                            recipientKey: recipientKey,
                                          ),
                                    ),
                                  ]
                                  : const [],
                        );
                      }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAdminTransactionDetail({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<_AdminDetailRow> rows,
    required List<ManagedPaymentTimelineEntry> timeline,
    List<_AdminCardAction> actions = const [],
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _AdminTransactionDetailSheet(
            title: title,
            subtitle: subtitle,
            icon: icon,
            rows: rows,
            timeline: timeline,
            actions: actions,
          ),
    );
  }

  void _showOrderTransactionDetail(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final status = _string(
      data,
      'orderStatus',
      fallback: _string(data, 'status', fallback: 'pending'),
    );
    final paymentStatus = _string(data, 'paymentStatus', fallback: 'pending');
    final proofImageUrl = _string(
      data,
      'proofImageUrl',
      fallback: _string(
        data,
        'paymentProofUrl',
        fallback: _string(data, 'proofUrl'),
      ),
    );
    final sellerPaymentMethods = _stringMap(data['sellerPaymentMethods']);
    final reference = _string(data, 'paymentReference', fallback: doc.id);
    final total =
        _number(data, 'total') ??
        _number(data, 'grandTotal') ??
        _number(data, 'sellerPayout') ??
        0;
    final totals = data['totals'];
    final deliveryFee =
        _number(data, 'deliveryFee') ??
        (totals is Map
            ? _number(Map<String, dynamic>.from(totals), 'deliveryFee')
            : null) ??
        0;
    final currency = _string(data, 'currency', fallback: 'XOF');
    final canReviewPayment = _canReviewOrderPayment(status, paymentStatus);
    _showAdminTransactionDetail(
      title:
          _string(data, 'orderNumber').isNotEmpty
              ? _string(data, 'orderNumber')
              : 'Commande ${_shortId(doc.id)}',
      subtitle: 'Fiche complète avant décision admin',
      icon: Icons.shopping_bag_rounded,
      rows: [
        _AdminDetailRow(
          icon: Icons.tag_rounded,
          label: 'Référence paiement',
          value: reference,
          copyable: true,
        ),
        _AdminDetailRow(
          icon: Icons.person_rounded,
          label: 'Client',
          value: _string(
            data,
            'customerName',
            fallback: _string(data, 'userId'),
          ),
          copyable: _string(data, 'userId').isNotEmpty,
        ),
        _AdminDetailRow(
          icon: Icons.storefront_rounded,
          label: 'Vendeur',
          value: _string(
            data,
            'sellerName',
            fallback: _string(data, 'sellerId'),
          ),
          copyable: _string(data, 'sellerId').isNotEmpty,
        ),
        _AdminDetailRow(
          icon: Icons.payments_rounded,
          label: 'Montant attendu',
          value: _formatMoney(total, currency),
        ),
        _AdminDetailRow(
          icon: Icons.local_shipping_rounded,
          label: 'Frais livraison',
          value:
              deliveryFee > 0
                  ? _formatMoney(deliveryFee, currency)
                  : 'Récupération sur place / aucun frais',
        ),
        _AdminDetailRow(
          icon: Icons.place_rounded,
          label: 'Réception',
          value:
              '${_string(data, 'deliveryMode', fallback: 'Non précisé')} • ${_string(data, 'deliveryAddress', fallback: 'Aucune précision')}',
        ),
        _AdminDetailRow(
          icon: Icons.flag_rounded,
          label: 'Statut commande',
          value: ManagedPaymentCopy.orderStatusLabel(status),
        ),
        _AdminDetailRow(
          icon: Icons.verified_rounded,
          label: 'Statut paiement',
          value: ManagedPaymentCopy.paymentStatusLabel(paymentStatus),
        ),
        _AdminDetailRow(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Compte admin payé',
          value: _string(data, 'paymentAccount', fallback: 'Non renseigné'),
          copyable: _string(data, 'paymentAccount').isNotEmpty,
        ),
        _AdminDetailRow(
          icon: Icons.wallet_rounded,
          label: 'Reversement vendeur',
          value:
              sellerPaymentMethods.isEmpty
                  ? 'Non renseigné'
                  : sellerPaymentMethods.entries
                      .map((entry) => '${entry.key}: ${entry.value}')
                      .join(' • '),
        ),
      ],
      timeline: ManagedPaymentTimelineEntry.listFrom(data['paymentTimeline']),
      actions: [
        if (proofImageUrl.isNotEmpty)
          _AdminCardAction(
            label: 'Voir preuve',
            icon: Icons.image_rounded,
            onTap: () => _showPaymentProof(proofImageUrl, data),
          ),
        _AdminCardAction(
          label: 'Copier ref',
          icon: Icons.copy_rounded,
          onTap: () => _copyAdminValue(reference, 'Référence copiée'),
        ),
        if (canReviewPayment)
          _AdminCardAction(
            label: 'Valider paiement',
            icon: Icons.verified_user_rounded,
            onTap: () {
              Navigator.pop(context);
              _reviewOrderPayment(
                doc,
                decision: 'paid',
                orderStatus: 'pending_seller_confirmation',
              );
            },
          ),
        if (canReviewPayment)
          _AdminCardAction(
            label: 'Refuser',
            icon: Icons.cancel_rounded,
            danger: true,
            onTap: () {
              Navigator.pop(context);
              _reviewOrderPayment(
                doc,
                decision: 'payment_rejected',
                orderStatus: 'payment_rejected',
                danger: true,
              );
            },
          ),
      ],
    );
  }

  void _showWithdrawalTransactionDetail(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final amount = _number(data, 'amount') ?? 0;
    final currency = _string(data, 'currency', fallback: 'XOF');
    final reference = _string(data, 'paymentReference', fallback: doc.id);
    final status = _string(data, 'status', fallback: 'pending_admin_transfer');
    final timeline = ManagedPaymentTimelineEntry.listFrom(
      data['paymentTimeline'],
    );
    final kind = _withdrawalKind(data);
    _showAdminTransactionDetail(
      title: '${_withdrawalKindLabel(kind)} • $reference',
      subtitle: 'Contrôle retrait avant transfert réel',
      icon: _withdrawalKindIcon(kind),
      rows: [
        _AdminDetailRow(
          icon: Icons.tag_rounded,
          label: 'Référence',
          value: reference,
          copyable: true,
        ),
        _AdminDetailRow(
          icon: Icons.person_rounded,
          label: _withdrawalSellerLabel(kind),
          value: _string(data, 'sellerId', fallback: '-'),
          copyable: _string(data, 'sellerId').isNotEmpty,
        ),
        _AdminDetailRow(
          icon: Icons.payments_rounded,
          label: 'Montant à transférer',
          value: _formatMoney(amount, currency),
        ),
        _AdminDetailRow(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Moyen retrait préféré',
          value:
              '${_string(data, 'preferredPayoutMethod', fallback: 'Non précisé')} • ${_string(data, 'preferredPayoutAccount', fallback: 'compte non renseigné')}',
          copyable: _string(data, 'preferredPayoutAccount').isNotEmpty,
        ),
        _AdminDetailRow(
          icon: Icons.receipt_long_rounded,
          label: 'Origine',
          value:
              _string(data, 'orderId').isNotEmpty
                  ? 'Commande ${_string(data, 'orderId')}'
                  : _string(data, 'listingId').isNotEmpty
                  ? 'Vide-dressing ${_string(data, 'listingId')}'
                  : 'Origine non renseignée',
          copyable:
              _string(data, 'orderId').isNotEmpty ||
              _string(data, 'listingId').isNotEmpty,
        ),
        _AdminDetailRow(
          icon: Icons.flag_rounded,
          label: 'Statut',
          value: _financeStatusLabel(status),
        ),
      ],
      timeline: timeline,
      actions:
          status == 'pending_admin_transfer'
              ? [
                _AdminCardAction(
                  label: 'Copier compte',
                  icon: Icons.copy_all_rounded,
                  onTap:
                      () => _copyAdminValue(
                        _string(data, 'preferredPayoutAccount'),
                        'Compte vendeur copié',
                      ),
                ),
                _AdminCardAction(
                  label: 'Marquer payé',
                  icon: Icons.check_circle_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    _reviewWithdrawalRequest(doc, decision: 'settled');
                  },
                ),
                _AdminCardAction(
                  label: 'Bloquer',
                  icon: Icons.block_rounded,
                  danger: true,
                  onTap: () {
                    Navigator.pop(context);
                    _reviewWithdrawalRequest(
                      doc,
                      decision: 'blocked',
                      danger: true,
                    );
                  },
                ),
              ]
              : const [],
    );
  }

  void _showBusinessRequestDetail(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String title,
    required IconData icon,
  }) {
    final data = doc.data();
    final amount = _number(data, 'amount') ?? 0;
    final currency = _string(data, 'currency', fallback: 'XOF');
    final proofImageUrl = _string(
      data,
      'proofImageUrl',
      fallback: _string(data, 'paymentProofUrl'),
    );
    _showAdminTransactionDetail(
      title: _string(data, 'requestLabel', fallback: title),
      subtitle: title,
      icon: icon,
      rows: [
        _AdminDetailRow(
          icon: Icons.tag_rounded,
          label: 'Référence',
          value: _string(
            data,
            'reference',
            fallback: _string(data, 'paymentReference', fallback: doc.id),
          ),
          copyable: true,
        ),
        _AdminDetailRow(
          icon: Icons.person_rounded,
          label: 'Compte',
          value: _string(
            data,
            'userId',
            fallback: _string(
              data,
              'ownerId',
              fallback: _string(data, 'accountId', fallback: 'Non renseigné'),
            ),
          ),
          copyable: true,
        ),
        _AdminDetailRow(
          icon: Icons.payments_rounded,
          label: 'Montant',
          value: _formatMoney(amount, currency),
        ),
        _AdminDetailRow(
          icon: Icons.flag_rounded,
          label: 'Statut',
          value: _businessPaymentStatusLabel(
            _string(data, 'paymentStatus', fallback: _string(data, 'status')),
          ),
        ),
        if (_string(data, 'plan').isNotEmpty)
          _AdminDetailRow(
            icon: Icons.workspace_premium_rounded,
            label: 'Plan',
            value: ProGrowthService.planDisplayLabel(_string(data, 'plan')),
          ),
      ],
      timeline: ManagedPaymentTimelineEntry.listFrom(data['paymentTimeline']),
      actions: [
        if (proofImageUrl.isNotEmpty)
          _AdminCardAction(
            label: 'Voir preuve',
            icon: Icons.image_rounded,
            onTap: () => _showAdminProof(proofImageUrl, title),
          ),
        _AdminCardAction(
          label: 'Copier ref',
          icon: Icons.copy_rounded,
          onTap:
              () => _copyAdminValue(
                _string(
                  data,
                  'reference',
                  fallback: _string(data, 'paymentReference', fallback: doc.id),
                ),
                'Référence copiée',
              ),
        ),
      ],
    );
  }

  void _showAdminDocumentDetail({
    required String title,
    required String subtitle,
    required IconData icon,
    required Map<String, dynamic> data,
    required String targetId,
  }) {
    final preferredKeys = [
      'status',
      'paymentStatus',
      'email',
      'phone',
      'telephone',
      'displayName',
      'sellerId',
      'ownerId',
      'userId',
      'category',
      'city',
      'country',
      'paymentReference',
      'amount',
      'currency',
    ];
    final rows = <_AdminDetailRow>[
      _AdminDetailRow(
        icon: Icons.tag_rounded,
        label: 'Identifiant',
        value: targetId,
        copyable: true,
      ),
      for (final key in preferredKeys)
        if (_string(data, key).isNotEmpty)
          _AdminDetailRow(
            icon: Icons.info_outline_rounded,
            label: key,
            value: _string(data, key),
            copyable:
                key.toLowerCase().contains('id') ||
                key.toLowerCase().contains('reference') ||
                key == 'email' ||
                key == 'phone',
          ),
    ];
    _showAdminTransactionDetail(
      title: title,
      subtitle: subtitle,
      icon: icon,
      rows: rows.take(14).toList(),
      timeline: ManagedPaymentTimelineEntry.listFrom(data['paymentTimeline']),
      actions: [
        _AdminCardAction(
          label: 'Copier ID',
          icon: Icons.copy_rounded,
          onTap: () => _copyAdminValue(targetId, 'Identifiant copié'),
        ),
      ],
    );
  }

  Future<void> _reviewSellerPayout(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String decision,
    bool danger = false,
  }) async {
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => _AdminNoteDialog(
            title:
                decision == 'settled'
                    ? 'Confirmer le reversement'
                    : 'Bloquer le reversement',
            subtitle:
                decision == 'settled'
                    ? 'Confirmez uniquement après paiement réel du vendeur.'
                    : 'Ajoutez la raison du blocage pour le suivi finance.',
            primaryLabel: decision == 'settled' ? 'Marquer payé' : 'Bloquer',
            danger: danger,
          ),
    );
    if (note == null) return;

    final freshSnapshot = await doc.reference.get();
    final data = freshSnapshot.data() ?? doc.data();
    final currentStatus = _string(
      data,
      'status',
      fallback: 'pending_settlement',
    );
    if (currentStatus == 'settled' || currentStatus == 'blocked') {
      _showAdminSnack('Ce reversement est déjà traité.', danger: true);
      return;
    }
    final sellerId = _string(data, 'sellerId');
    final orderId = _string(data, 'orderId', fallback: doc.id);
    final payout = _number(data, 'sellerPayout') ?? 0;
    final now = FieldValue.serverTimestamp();

    try {
      final batch = _firestore.batch();
      batch.set(
        doc.reference,
        AdminWorkflowDecision.payoutCommissionPatch(
          decision: decision,
          note: note,
          adminId: _auth.currentUser?.uid,
          now: now,
        ),
        SetOptions(merge: true),
      );

      final payoutRef = _firestore.collection('seller_payouts').doc(doc.id);
      batch.set(
        payoutRef,
        AdminWorkflowDecision.sellerPayoutPatch(
          commissionId: doc.id,
          orderId: orderId,
          sellerId: sellerId,
          amount: payout,
          decision: decision,
          note: note,
          adminId: _auth.currentUser?.uid,
          now: now,
        ),
        SetOptions(merge: true),
      );

      if (orderId.isNotEmpty) {
        batch.set(_firestore.collection('orders').doc(orderId), {
          'payoutStatus': decision,
          'payoutUpdatedAt': now,
          'updatedAt': now,
        }, SetOptions(merge: true));
      }

      await batch.commit();
      await _logAdminAction(
        action: 'seller_payout_$decision',
        targetId: doc.id,
        targetType: 'platform_commission',
        note: note,
      );
      await _notifyAdminDecision(
        recipientId: sellerId,
        title:
            decision == 'settled' ? 'Reversement payé' : 'Reversement bloqué',
        body:
            decision == 'settled'
                ? 'Votre reversement de ${_money(payout)} a été marqué comme payé.'
                : 'Votre reversement de ${_money(payout)} est temporairement bloqué. L’équipe vous contactera si nécessaire.',
        type: 'seller_payout_$decision',
        actionLabel: 'Voir le retrait',
        data: {
          'targetType': 'withdrawal',
          'targetId': doc.id,
          'commissionId': doc.id,
          'orderId': orderId,
          'amount': payout,
          'decision': decision,
        },
      );
      if (!mounted) return;
      _showAdminSnack(
        decision == 'settled'
            ? 'Reversement vendeur marqué payé'
            : 'Reversement vendeur bloqué',
      );
    } catch (e) {
      if (!mounted) return;
      _showAdminSnack('Action payout impossible: $e', danger: true);
    }
  }

  Future<void> _reviewWithdrawalRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String decision,
    bool danger = false,
  }) async {
    final currentStatus = _string(doc.data(), 'status');
    if (currentStatus != 'pending_admin_transfer') {
      _showAdminSnack(
        'Cette demande de retrait est déjà traitée.',
        danger: true,
      );
      return;
    }
    final data = doc.data();
    final orderId = _string(data, 'orderId');
    final listingId = _string(data, 'listingId');
    final sellerId = _string(data, 'sellerId');
    final amount = _number(data, 'amount') ?? 0;
    final currency = _string(data, 'currency', fallback: 'XOF');
    final reference = _string(data, 'paymentReference', fallback: doc.id);
    final preferredPayoutMethod = _string(data, 'preferredPayoutMethod');
    final preferredPayoutAccount = _string(data, 'preferredPayoutAccount');
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => _AdminNoteDialog(
            title:
                decision == 'settled'
                    ? 'Confirmer le transfert vendeur'
                    : 'Bloquer la demande de retrait',
            subtitle:
                decision == 'settled'
                    ? '${_formatMoney(amount, currency)} • $reference • ${preferredPayoutMethod.isEmpty ? 'compte vendeur' : preferredPayoutMethod}: ${preferredPayoutAccount.isEmpty ? 'non renseigné' : preferredPayoutAccount}. Confirmez seulement après transfert réel.'
                    : '${_formatMoney(amount, currency)} • $reference. Le solde sera placé en litige et restera traçable.',
            primaryLabel: decision == 'settled' ? 'Marquer payé' : 'Bloquer',
            danger: danger,
          ),
    );
    if (note == null) return;

    final freshSnapshot = await doc.reference.get();
    final freshStatus = _string(freshSnapshot.data() ?? doc.data(), 'status');
    if (freshStatus != 'pending_admin_transfer') {
      _showAdminSnack(
        'Cette demande de retrait vient déjà d’être traitée.',
        danger: true,
      );
      return;
    }

    final adminNote =
        note.trim().isEmpty
            ? (decision == 'settled'
                ? 'Transfert vendeur confirmé par admin'
                : 'Retrait bloqué par admin')
            : note.trim();
    final now = FieldValue.serverTimestamp();

    try {
      final batch = _firestore.batch();
      batch.set(
        doc.reference,
        AdminWorkflowDecision.withdrawalRequestPatch(
          decision: decision,
          note: adminNote,
          adminId: _auth.currentUser?.uid,
          now: now,
        ),
        SetOptions(merge: true),
      );
      if (orderId.isNotEmpty) {
        batch.set(
          _firestore.collection('orders').doc(orderId),
          AdminWorkflowDecision.orderWithdrawalPatch(
            decision: decision,
            sellerAmount: amount,
            currency: currency,
            note: adminNote,
            adminId: _auth.currentUser?.uid,
            now: now,
          ),
          SetOptions(merge: true),
        );
      }
      if (listingId.isNotEmpty) {
        final convertedStatus =
            decision == 'settled' ? 'withdrawn' : 'disputed';
        batch.set(
          _firestore.collection('secondhand_listings').doc(listingId),
          {
            'secondhandBalanceStatus': convertedStatus,
            'secondhandBalance.status': convertedStatus,
            if (decision == 'settled') ...{
              'secondhandBalance.availableBalance': 0.0,
              'secondhandBalance.withdrawnBalance': amount,
              'secondhandBalance.withdrawnAt': now,
            },
            if (decision == 'blocked') ...{
              'secondhandBalance.availableBalance': 0.0,
              'secondhandBalance.disputedBalance': amount,
              'secondhandBalance.blockedAt': now,
            },
            'paymentTimeline': FieldValue.arrayUnion([
              {
                'status':
                    decision == 'settled' ? 'withdrawn' : 'withdrawal_blocked',
                'label':
                    decision == 'settled'
                        ? 'Retrait vide-dressing payé par l’admin'
                        : 'Retrait vide-dressing bloqué par l’admin',
                'at': Timestamp.now(),
              },
            ]),
            'updatedAt': now,
          },
          SetOptions(merge: true),
        );
      }
      final payoutRef = _firestore.collection('seller_payouts').doc(doc.id);
      batch.set(payoutRef, {
        'withdrawalRequestId': doc.id,
        'orderId': orderId,
        if (listingId.isNotEmpty) 'listingId': listingId,
        'sellerId': sellerId,
        'amount': amount,
        'currency': currency,
        'payoutMethod': preferredPayoutMethod,
        'payoutAccount': preferredPayoutAccount,
        'status': decision,
        'note': adminNote,
        'reviewedBy': _auth.currentUser?.uid,
        if (decision == 'settled') 'paidAt': now,
        if (decision == 'blocked') 'blockedAt': now,
        'updatedAt': now,
        'createdAt': now,
      }, SetOptions(merge: true));

      await batch.commit();
      await _logAdminAction(
        action: 'withdrawal_request_$decision',
        targetId: doc.id,
        targetType: 'seller_withdrawal_request',
        note: adminNote,
        details: {
          'previousStatus': currentStatus,
          'newStatus': decision,
          'amount': amount,
          'currency': currency,
          'paymentReference': reference,
          'sellerId': sellerId,
          'orderId': orderId,
          if (listingId.isNotEmpty) 'listingId': listingId,
          'payoutMethod': preferredPayoutMethod,
          'payoutAccount': preferredPayoutAccount,
        },
      );
      await _notifyAdminDecision(
        recipientId: sellerId,
        title: decision == 'settled' ? 'Retrait payé' : 'Retrait bloqué',
        body:
            decision == 'settled'
                ? 'Votre retrait de ${_formatMoney(amount, currency)} a été marqué comme payé.'
                : 'Votre retrait de ${_formatMoney(amount, currency)} est temporairement bloqué pour vérification.',
        type: 'seller_withdrawal_$decision',
        actionLabel: 'Voir le retrait',
        data: {
          'targetType': 'withdrawal',
          'targetId': doc.id,
          'withdrawalRequestId': doc.id,
          'orderId': orderId,
          if (listingId.isNotEmpty) 'listingId': listingId,
          'amount': amount,
          'currency': currency,
          'decision': decision,
        },
      );
      if (!mounted) return;
      _showAdminSnack(
        decision == 'settled'
            ? 'Retrait vendeur marqué payé'
            : 'Retrait vendeur bloqué',
      );
    } catch (e) {
      if (!mounted) return;
      _showAdminSnack('Action retrait impossible: $e', danger: true);
    }
  }

  Widget _buildCouponsView() {
    return _AdminPageScaffold(
      title: 'Coupons & visibilité',
      subtitle:
          'Pilote les coupons checkout et garde les points clients dédiés à la visibilité.',
      icon: Icons.confirmation_number_rounded,
      onRefresh: _refreshData,
      trailing: _AdminTinyButton(
        icon: Icons.cloud_upload_rounded,
        label: 'Publier défauts',
        onTap: () async {
          await AdminCommerceConfigService().seedDefaultCheckoutRules();
          if (!mounted) return;
          _showAdminSnack('Coupons par défaut publiés');
        },
      ),
      children: [
        _AdminCollectionPanel(
          title: 'Coupons checkout',
          subtitle: 'Codes, remises et livraison offerte',
          collection: 'checkout_coupons',
          icon: Icons.confirmation_number_rounded,
          firestore: _firestore,
          primaryAction:
              (doc) =>
                  _updateDocument('checkout_coupons', doc.id, {'active': true}),
          primaryLabel: 'Activer',
          dangerAction:
              (doc) => _updateDocument('checkout_coupons', doc.id, {
                'active': false,
              }),
          dangerLabel: 'Désactiver',
        ),
      ],
    );
  }

  Widget _buildModerationView() {
    return _AdminPageScaffold(
      title: 'Modération',
      subtitle:
          'Traite les signalements, profils publics et contenus sensibles sans quitter le cockpit.',
      icon: Icons.shield_rounded,
      onRefresh: _refreshData,
      children: [
        _buildDisputeResolutionPanel(),
        const SizedBox(height: 16),
        _AdminCollectionPanel(
          title: 'Signalements',
          subtitle: 'Contenus signalés par la communauté',
          collection: 'reports',
          icon: Icons.report_rounded,
          firestore: _firestore,
          primaryAction:
              (doc) => _moderateDocument(
                collection: 'reports',
                id: doc.id,
                action: 'reviewed',
                targetType: 'report',
                fields: {'status': 'reviewed'},
              ),
          primaryLabel: 'Traité',
          secondaryAction:
              (doc) => _moderateDocument(
                collection: 'reports',
                id: doc.id,
                action: 'investigating',
                targetType: 'report',
                fields: {'status': 'investigating'},
              ),
          secondaryLabel: 'Enquête',
          dangerAction:
              (doc) => _moderateDocument(
                collection: 'reports',
                id: doc.id,
                action: 'blocked',
                targetType: 'report',
                fields: {'status': 'blocked'},
                danger: true,
              ),
          dangerLabel: 'Bloquer',
        ),
        const SizedBox(height: 16),
        _AdminCollectionPanel(
          title: 'Événements à valider',
          subtitle: 'Agenda public, lives, ateliers, pop-ups et castings',
          collection: 'events',
          icon: Icons.event_rounded,
          firestore: _firestore,
          primaryAction:
              (doc) => _moderateDocument(
                collection: 'events',
                id: doc.id,
                action: 'published',
                targetType: 'salon_event',
                fields: {'status': 'published', 'isPublic': true},
              ),
          primaryLabel: 'Publier',
          dangerAction:
              (doc) => _moderateDocument(
                collection: 'events',
                id: doc.id,
                action: 'hidden',
                targetType: 'salon_event',
                fields: {'status': 'hidden', 'isPublic': false},
                danger: true,
              ),
          dangerLabel: 'Masquer',
        ),
        const SizedBox(height: 16),
        _AdminCollectionPanel(
          title: 'Produits publics',
          subtitle: 'Fiches marketplace visibles dans Shopping',
          collection: 'products',
          icon: Icons.shopping_bag_rounded,
          firestore: _firestore,
          primaryAction:
              (doc) => _moderateDocument(
                collection: 'products',
                id: doc.id,
                action: 'approved',
                targetType: 'product',
                fields: {
                  'status': 'published',
                  'visibility': 'salon',
                  'isPublished': true,
                  'visibleInSalon': true,
                  'isPublic': true,
                },
              ),
          primaryLabel: 'Publier',
          secondaryAction:
              (doc) => _moderateDocument(
                collection: 'products',
                id: doc.id,
                action: 'featured',
                targetType: 'product',
                fields: {'featured': true, 'placement': 'shopping'},
              ),
          secondaryLabel: 'Mettre en avant',
          dangerAction:
              (doc) => _moderateDocument(
                collection: 'products',
                id: doc.id,
                action: 'hidden',
                targetType: 'product',
                fields: {
                  'status': 'hidden',
                  'visibility': 'private',
                  'isPublished': false,
                  'visibleInSalon': false,
                  'isPublic': false,
                },
                danger: true,
              ),
          dangerLabel: 'Masquer',
        ),
        const SizedBox(height: 16),
        _AdminCollectionPanel(
          title: 'Créations publiques',
          subtitle: 'Portfolio créateur visible dans Inspiration et Talents',
          collection: 'creations',
          icon: Icons.palette_rounded,
          firestore: _firestore,
          primaryAction:
              (doc) => _moderateDocument(
                collection: 'creations',
                id: doc.id,
                action: 'approved',
                targetType: 'creation',
                fields: {
                  'status': 'published',
                  'visibility': 'salon',
                  'isPublished': true,
                  'visibleInSalon': true,
                  'isPublic': true,
                },
              ),
          primaryLabel: 'Publier',
          secondaryAction:
              (doc) => _moderateDocument(
                collection: 'creations',
                id: doc.id,
                action: 'featured',
                targetType: 'creation',
                fields: {'featured': true, 'placement': 'inspiration'},
              ),
          secondaryLabel: 'Mettre en avant',
          dangerAction:
              (doc) => _moderateDocument(
                collection: 'creations',
                id: doc.id,
                action: 'hidden',
                targetType: 'creation',
                fields: {
                  'status': 'hidden',
                  'visibility': 'private',
                  'isPublished': false,
                  'visibleInSalon': false,
                  'isPublic': false,
                },
                danger: true,
              ),
          dangerLabel: 'Masquer',
        ),
      ],
    );
  }

  Widget _buildDisputeResolutionPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.danger.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.danger.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ModernColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.report_problem_rounded,
                  color: ModernColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Litiges commandes',
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      'Dossiers sensibles à analyser avec preuve, vendeur, client et historique.',
                      style: TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              _AdminTinyButton(
                icon: Icons.inbox_rounded,
                label: 'File',
                onTap:
                    () => setState(() {
                      _workQueueFilter = 'disputes';
                      _currentIndex = 8;
                    }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            future: _loadDisputeOrderDocs(),
            builder: (context, snapshot) {
              final docs = snapshot.data ?? const [];
              return _AdminStreamBody(
                loading: snapshot.connectionState == ConnectionState.waiting,
                error: snapshot.error,
                empty: docs.isEmpty,
                emptyTitle: 'Aucun litige ouvert',
                emptySubtitle:
                    'Les commandes contestées apparaîtront ici pour analyse admin.',
                child: Column(
                  children:
                      docs.take(12).map((doc) {
                        final data = doc.data();
                        final total =
                            _number(data, 'total') ??
                            _number(data, 'grandTotal') ??
                            _number(data, 'sellerPayout') ??
                            0;
                        final currency = _string(
                          data,
                          'currency',
                          fallback: 'XOF',
                        );
                        final status = _string(
                          data,
                          'orderStatus',
                          fallback: _string(data, 'status'),
                        );
                        final paymentStatus = _string(data, 'paymentStatus');
                        final reference = _string(
                          data,
                          'paymentReference',
                          fallback: doc.id,
                        );
                        final updatedAt =
                            _dateFrom(data['updatedAt']) ??
                            _dateFrom(data['createdAt']);
                        return _AdminActionCard(
                          icon: Icons.gavel_rounded,
                          title:
                              _string(data, 'orderNumber').isNotEmpty
                                  ? _string(data, 'orderNumber')
                                  : 'Litige ${_shortId(doc.id)}',
                          subtitle:
                              '${_string(data, 'customerName', fallback: 'Client')} • ${_string(data, 'sellerName', fallback: _string(data, 'sellerId', fallback: 'Vendeur'))}',
                          meta: [
                            _AdminStatusChip(
                              icon: Icons.payments_rounded,
                              label: _formatMoney(total, currency),
                              color: ModernColors.warning,
                            ),
                            _AdminStatusChip(
                              icon: Icons.flag_rounded,
                              label: ManagedPaymentCopy.orderStatusLabel(
                                status,
                              ),
                              color: _statusColor(status),
                            ),
                            _AdminStatusChip(
                              icon: Icons.verified_user_rounded,
                              label: ManagedPaymentCopy.paymentStatusLabel(
                                paymentStatus,
                              ),
                              color: _statusColor(paymentStatus),
                            ),
                            if (updatedAt != null)
                              _AdminStatusChip(
                                icon: Icons.schedule_rounded,
                                label: DateFormat(
                                  'dd/MM HH:mm',
                                ).format(updatedAt),
                                color: ModernColors.inkSoft,
                              ),
                          ],
                          actions: [
                            _AdminCardAction(
                              label: 'Fiche détail',
                              icon: Icons.open_in_new_rounded,
                              onTap: () => _showOrderTransactionDetail(doc),
                            ),
                            _AdminCardAction(
                              label: 'Copier ref',
                              icon: Icons.copy_rounded,
                              onTap:
                                  () => _copyAdminValue(
                                    reference,
                                    'Référence copiée',
                                  ),
                            ),
                            if (status != 'dispute_review')
                              _AdminCardAction(
                                label: 'Analyser',
                                icon: Icons.manage_search_rounded,
                                onTap: () => _markOrderDisputeInReview(doc),
                              ),
                          ],
                        );
                      }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityGovernancePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_rounded, color: ModernColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Communauté',
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      'Messages, accès au groupe et sanctions rapides',
                      style: TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _AdminTinyButton(
                icon: Icons.tune_rounded,
                label: 'Accès',
                onTap: _showCommunityAccessDialog,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCommunityGroupRequestsAdmin(),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                _firestore
                    .collection('community_questions')
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? const [];
              return _AdminStreamBody(
                loading: snapshot.connectionState == ConnectionState.waiting,
                error: snapshot.error,
                empty: docs.isEmpty,
                emptyTitle: 'Aucune discussion',
                emptySubtitle: 'Les nouveaux échanges apparaîtront ici.',
                child: Column(
                  children:
                      docs.map((doc) {
                        final data = doc.data();
                        final status = _string(
                          data,
                          'status',
                          fallback: 'published',
                        );
                        final authorId = _string(data, 'userId');
                        final author = _string(
                          data,
                          'userName',
                          fallback: 'Membre',
                        );
                        final text = _string(
                          data,
                          'question',
                          fallback: 'Message média',
                        );

                        return _AdminActionCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: text,
                          subtitle:
                              '$author • ${_string(data, 'category', fallback: 'Général')}',
                          meta: [
                            _AdminStatusChip(
                              icon: Icons.flag_rounded,
                              label: status,
                              color: _statusColor(status),
                            ),
                            _AdminStatusChip(
                              icon: Icons.reply_rounded,
                              label:
                                  '${_string(data, 'answersCount', fallback: '0')} réponses',
                              color: ModernColors.client,
                            ),
                          ],
                          actions: [
                            _AdminCardAction(
                              label: 'Valider',
                              icon: Icons.check_circle_rounded,
                              onTap:
                                  () => _moderateDocument(
                                    collection: 'community_questions',
                                    id: doc.id,
                                    action: 'approved',
                                    targetType: 'community_question',
                                    fields: {
                                      'status': 'published',
                                      'isPublic': true,
                                      'isDeleted': false,
                                    },
                                  ),
                            ),
                            _AdminCardAction(
                              label: 'Masquer',
                              icon: Icons.visibility_off_rounded,
                              danger: true,
                              onTap:
                                  () => _moderateDocument(
                                    collection: 'community_questions',
                                    id: doc.id,
                                    action: 'hidden',
                                    targetType: 'community_question',
                                    fields: {
                                      'status': 'hidden',
                                      'isPublic': false,
                                    },
                                    danger: true,
                                  ),
                            ),
                            _AdminCardAction(
                              label: 'Supprimer',
                              icon: Icons.delete_outline_rounded,
                              danger: true,
                              onTap: () => _deleteCommunityQuestionAsAdmin(doc),
                            ),
                            if (authorId.isNotEmpty)
                              _AdminCardAction(
                                label: 'Bloquer auteur',
                                icon: Icons.block_rounded,
                                danger: true,
                                onTap:
                                    () => _blockCommunityUser(authorId, author),
                              ),
                          ],
                        );
                      }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityGroupRequestsAdmin() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          _firestore
              .collection('community_groups')
              .where('status', isEqualTo: CommunityGroupStatuses.pending)
              .limit(10)
              .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Communautés à valider',
              style: TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            ...docs.map((doc) {
              final group = CommunityGroup.fromDoc(doc);
              return _AdminActionCard(
                icon: Icons.groups_3_rounded,
                title: group.name,
                subtitle:
                    '${group.category} • ${group.locationLabel} • ${group.ownerName}',
                meta: [
                  _AdminStatusChip(
                    icon: Icons.pending_actions_rounded,
                    label: group.status,
                    color: ModernColors.warning,
                  ),
                  _AdminStatusChip(
                    icon: Icons.lock_open_rounded,
                    label: group.accessMode,
                    color: ModernColors.primary,
                  ),
                ],
                actions: [
                  _AdminCardAction(
                    label: 'Valider',
                    icon: Icons.check_circle_rounded,
                    onTap: () => _approveCommunityGroup(doc),
                  ),
                  _AdminCardAction(
                    label: 'Refuser',
                    icon: Icons.close_rounded,
                    danger: true,
                    onTap:
                        () => _moderateDocument(
                          collection: 'community_groups',
                          id: doc.id,
                          action: 'rejected',
                          targetType: 'community_group',
                          fields: {'status': CommunityGroupStatuses.rejected},
                          danger: true,
                        ),
                  ),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _deleteCommunityQuestionAsAdmin(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => const _AdminNoteDialog(
            title: 'Supprimer la discussion',
            subtitle:
                'Le message sera retiré de la communauté, avec une trace pour audit.',
            primaryLabel: 'Supprimer',
            danger: true,
          ),
    );
    if (note == null) return;

    final data = doc.data();
    final recipientId = _recipientFromData(data);
    await doc.reference.set({
      'status': 'deleted',
      'isDeleted': true,
      'isPublic': false,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': _auth.currentUser?.uid,
      'deleteReason': note,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _logAdminAction(
      action: 'community_question_deleted',
      targetId: doc.id,
      targetType: 'community_question',
      note: note,
    );
    await _notifyAdminDecision(
      recipientId: recipientId,
      title: 'Message retiré',
      body: 'Un de vos messages communautaires a été retiré après modération.',
      type: 'community_moderation',
      data: {'questionId': doc.id, 'action': 'deleted'},
    );
    if (!mounted) return;
    _showAdminSnack('Discussion supprimée de la communauté');
  }

  Future<void> _blockCommunityUser(String userId, String userName) async {
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => _AdminNoteDialog(
            title: 'Bloquer $userName',
            subtitle:
                'Le membre pourra continuer à utiliser son compte, mais ne pourra plus publier dans la communauté.',
            primaryLabel: 'Bloquer',
            danger: true,
          ),
    );
    if (note == null) return;

    await _firestore.collection('users').doc(userId).set({
      'communityRestriction': {
        'status': 'blocked',
        'reason': note,
        'blockedAt': FieldValue.serverTimestamp(),
        'blockedBy': _auth.currentUser?.uid,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _firestore.collection('community_settings').doc('main').set({
      'blockedUserIds': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    }, SetOptions(merge: true));
    await _logAdminAction(
      action: 'community_user_blocked',
      targetId: userId,
      targetType: 'user',
      note: note,
    );
    await _notifyAdminDecision(
      recipientId: userId,
      title: 'Accès communauté limité',
      body: note,
      type: 'community_restriction',
      data: {'status': 'blocked'},
    );
    if (!mounted) return;
    _showAdminSnack('Membre bloqué dans la communauté');
  }

  Future<void> _showCommunityAccessDialog() async {
    final current =
        await _firestore.collection('community_settings').doc('main').get();
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CommunityAccessDialog(data: current.data()),
    );
    if (result == null) return;

    await _firestore.collection('community_settings').doc('main').set({
      ...result,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    }, SetOptions(merge: true));
    await _logAdminAction(
      action: 'community_access_updated',
      targetId: 'main',
      targetType: 'community_settings',
      note:
          '${result['mode']} • ${result['reason']?.toString() ?? 'sans motif'}',
    );
    if (!mounted) return;
    _showAdminSnack('Règles communauté mises à jour');
  }

  Future<void> _approveCommunityGroup(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => const _AdminNoteDialog(
            title: 'Valider la communauté',
            subtitle:
                'Le demandeur deviendra gestionnaire et pourra accepter les demandes d’adhésion.',
            primaryLabel: 'Valider',
          ),
    );
    if (note == null) return;

    final group = CommunityGroup.fromDoc(doc);
    final batch = _firestore.batch();
    batch.set(doc.reference, {
      'status': CommunityGroupStatuses.approved,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': _auth.currentUser?.uid,
      'adminNote': note,
      'memberIds': FieldValue.arrayUnion([group.ownerId]),
      'memberCount': group.memberCount <= 0 ? 1 : group.memberCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(
      doc.reference.collection('members').doc(group.ownerId),
      {
        'userId': group.ownerId,
        'userName': group.ownerName,
        'role': CommunityMemberRoles.owner,
        'status': 'active',
        'joinedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    await _logAdminAction(
      action: 'community_group_approved',
      targetId: doc.id,
      targetType: 'community_group',
      note: note,
    );
    await _notifyAdminDecision(
      recipientId: group.ownerId,
      title: 'Communauté validée',
      body:
          '${group.name} est maintenant visible. Vous êtes gestionnaire de cet espace.',
      type: 'community_group_approved',
      data: {'groupId': doc.id},
    );
    if (!mounted) return;
    _showAdminSnack('Communauté validée');
  }

  Widget _buildSettingsView() {
    return const _CommerceSettingsPanel();
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(ModernColors.primary),
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Chargement des données...",
            style: TextStyle(
              color: ModernColors.inkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ModernColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: ModernColors.danger,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Oups, une erreur est survenue",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 180,
              height: 48,
              child: FilledButton(
                onPressed: _refreshData,
                style: FilledButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  backgroundColor: ModernColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Réessayer",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _loadData();
  }

  Future<void> _updateDocument(
    String collection,
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      final ref = _firestore.collection(collection).doc(id);
      final snapshot = await ref.get();
      final before = snapshot.data() ?? const <String, dynamic>{};
      final patch = {...fields, 'updatedAt': FieldValue.serverTimestamp()};
      await ref.set(patch, SetOptions(merge: true));
      await _logAdminAction(
        action: 'update_document',
        targetId: id,
        targetType: collection,
        note: 'Mise à jour depuis Admin',
        details: {
          'collection': collection,
          ..._auditDiffDetails(before: before, patch: patch),
        },
      );
      if (!mounted) return;
      _showAdminSnack('Action appliquée');
    } catch (e) {
      debugPrint('Erreur admin action document: $e');
      if (!mounted) return;
      _showAdminSnack('Action impossible pour le moment.', danger: true);
    }
  }

  Future<void> _moderateDocument({
    required String collection,
    required String id,
    required String action,
    required String targetType,
    required Map<String, dynamic> fields,
    bool danger = false,
  }) async {
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => _AdminNoteDialog(
            title: _moderationTitle(action),
            subtitle:
                'Ajoutez une note courte pour garder une trace claire de cette décision.',
            primaryLabel: _moderationPrimaryLabel(action),
            danger: danger,
          ),
    );
    if (note == null) return;

    try {
      final snapshot = await _firestore.collection(collection).doc(id).get();
      final data = snapshot.data() ?? const {};
      final recipientId = _recipientFromData(data);
      final itemTitle = _collectionItemTitle(data, id);
      await _firestore
          .collection(collection)
          .doc(id)
          .set(
            AdminWorkflowDecision.moderationPatch(
              fields: fields,
              action: action,
              note: note,
              adminId: _auth.currentUser?.uid,
            ),
            SetOptions(merge: true),
          );
      await _logAdminAction(
        action: 'moderate_$action',
        targetId: id,
        targetType: targetType,
        note: note,
        details: {
          'collection': collection,
          ..._auditDiffDetails(before: data, patch: fields),
        },
      );
      await _notifyAdminDecision(
        recipientId: recipientId,
        title: _moderationNotificationTitle(action),
        body: _moderationNotificationBody(action, itemTitle),
        type: 'moderation_$action',
        data: {
          'collection': collection,
          'documentId': id,
          'targetType': targetType,
          'action': action,
        },
      );
      if (!mounted) return;
      _showAdminSnack('Décision de modération appliquée');
    } catch (e) {
      if (!mounted) return;
      _showAdminSnack('Modération impossible: $e', danger: true);
    }
  }

  static String _moderationTitle(String action) {
    return switch (action) {
      'approved' || 'published' => 'Valider le contenu',
      'featured' => 'Mettre en avant',
      'hidden' => 'Masquer le contenu',
      'blocked' => 'Bloquer le contenu',
      'reviewed' => 'Marquer comme traité',
      'investigating' => 'Ouvrir une enquête',
      _ => 'Décision de modération',
    };
  }

  static String _moderationPrimaryLabel(String action) {
    return switch (action) {
      'approved' => 'Valider',
      'published' => 'Publier',
      'featured' => 'Mettre en avant',
      'hidden' => 'Masquer',
      'blocked' => 'Bloquer',
      'reviewed' => 'Traiter',
      'investigating' => 'Enquêter',
      _ => 'Confirmer',
    };
  }

  static String _moderationNotificationTitle(String action) {
    return switch (action) {
      'approved' || 'published' => 'Contenu validé',
      'featured' => 'Contenu mis en avant',
      'hidden' => 'Contenu masqué',
      'blocked' => 'Contenu bloqué',
      'reviewed' => 'Signalement traité',
      'investigating' => 'Signalement en cours d’analyse',
      _ => 'Mise à jour de modération',
    };
  }

  static String _moderationNotificationBody(String action, String title) {
    return switch (action) {
      'approved' ||
      'published' => '$title est maintenant visible dans ElegantStyle.',
      'featured' => '$title bénéficie d’une mise en avant dans le Salon.',
      'hidden' =>
        '$title a été masqué. Consultez votre espace pour le corriger si nécessaire.',
      'blocked' =>
        '$title a été bloqué après vérification par l’administration.',
      'reviewed' => 'Votre signalement a été traité par l’administration.',
      'investigating' =>
        'Votre signalement est en cours d’analyse par l’administration.',
      _ => '$title a reçu une mise à jour de modération.',
    };
  }

  static String _collectionItemTitle(Map<String, dynamic> data, String id) {
    for (final key in [
      'title',
      'name',
      'displayName',
      'productName',
      'eventTitle',
      'code',
    ]) {
      final value = _string(data, key);
      if (value.isNotEmpty) return value;
    }
    return 'Élément ${_shortId(id)}';
  }

  Future<void> _approvePlanRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    if (!_isBusinessPaymentPending(data)) {
      _showAdminSnack('Cette demande de plan est déjà traitée.', danger: true);
      return;
    }
    final userId = _string(
      data,
      'userId',
      fallback: _string(data, 'accountId'),
    );
    if (userId.isEmpty) {
      _showAdminSnack('Demande sans utilisateur', danger: true);
      return;
    }

    final plan = _string(data, 'plan', fallback: 'pro');
    final monthlyPrice = _number(data, 'monthlyPrice') ?? 0;
    final currency = _string(data, 'currency', fallback: 'XOF');
    final durationDays = (_number(data, 'durationDays') ??
            _number(data, 'planDurationDays') ??
            30)
        .round()
        .clamp(1, 366);
    final reference = _string(
      data,
      'reference',
      fallback: _string(data, 'paymentReference'),
    );
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => _AdminNoteDialog(
            title:
                'Valider le paiement ${ProGrowthService.planDisplayLabel(plan)}',
            subtitle:
                '${_money(monthlyPrice)} $currency • $reference. Activez seulement après réception réelle du paiement.',
            primaryLabel: 'Activer plan',
          ),
    );
    if (note == null) return;
    final freshPlanSnapshot = await doc.reference.get();
    if (!_isBusinessPaymentPending(freshPlanSnapshot.data() ?? data)) {
      _showAdminSnack(
        'Cette demande de plan vient déjà d’être traitée.',
        danger: true,
      );
      return;
    }
    final adminNote =
        note.trim().isEmpty
            ? 'Paiement plan ${ProGrowthService.planDisplayLabel(plan)} validé'
            : note.trim();
    final rolesApplied =
        (data['rolesApplied'] as Iterable?)
            ?.map((role) => role.toString())
            .toList() ??
        const ['createur', 'boutique'];
    final now = DateTime.now();
    final startsAt = Timestamp.fromDate(now);
    final expiresAt = Timestamp.fromDate(now.add(Duration(days: durationDays)));

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('seller_subscriptions').doc(userId),
      {
        'sellerId': userId,
        'accountId': userId,
        'plan': plan,
        'status': 'active',
        'paymentStatus': 'paid',
        'monthlyPrice': monthlyPrice,
        'productLimit': plan == 'premium' ? 100 : 40,
        'boostCredits': plan == 'premium' ? 8 : 3,
        'analyticsEnabled': true,
        'verifiedBadge': true,
        'certificationBadge': plan == 'premium' ? 'signature' : 'pro',
        'reference': reference,
        'lastPaymentAmount': monthlyPrice,
        'lastPaymentCurrency': currency,
        'lastPaymentNote': adminNote,
        'rolesApplied': rolesApplied,
        'sharedAcrossRoles': true,
        'durationDays': durationDays,
        'startedAt': startsAt,
        'expiresAt': expiresAt,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _firestore.collection('users').doc(userId),
      AdminWorkflowDecision.planEntitlementPatch(
        plan: plan,
        rolesApplied: rolesApplied,
        startsAt: startsAt,
        expiresAt: expiresAt,
        durationDays: durationDays,
      ),
      SetOptions(merge: true),
    );
    batch.set(doc.reference, {
      'status': 'approved',
      'paymentStatus': 'paid',
      'adminNote': adminNote,
      'paymentReview': {
        'decision': 'paid',
        'note': adminNote,
        'reviewedBy': _auth.currentUser?.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      },
      'approvedBy': _auth.currentUser?.uid,
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    await _logAdminAction(
      action: 'pro_plan_approved',
      targetId: doc.id,
      targetType: 'pro_plan',
      note: adminNote,
    );
    await _notifyAdminDecision(
      recipientId: userId,
      title: 'Plan ${ProGrowthService.planDisplayLabel(plan)} activé',
      body:
          'Votre plan professionnel est actif sur vos espaces Créateur et Boutique.',
      type: 'pro_plan_approved',
      actionLabel: 'Voir mon espace Pro',
      data: {
        'targetType': 'pro_request',
        'targetId': doc.id,
        'requestId': doc.id,
        'plan': plan,
        'rolesApplied': rolesApplied,
      },
    );
    if (!mounted) return;
    _showAdminSnack(
      'Plan ${ProGrowthService.planDisplayLabel(plan)} activé sur tout le compte',
    );
  }

  Future<void> _activateBoost(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    if (!_isBusinessPaymentPending(data)) {
      _showAdminSnack('Cette mise en avant est déjà traitée.', danger: true);
      return;
    }
    final userId = _string(
      data,
      'ownerId',
      fallback: _string(data, 'accountId'),
    );
    if (userId.isEmpty) {
      _showAdminSnack('Mise en avant sans compte propriétaire', danger: true);
      return;
    }

    final amount = _number(data, 'amount') ?? _number(data, 'budget') ?? 0;
    final currency = _string(data, 'currency', fallback: 'XOF');
    final reference = _string(
      data,
      'reference',
      fallback: _string(data, 'paymentReference'),
    );
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => _AdminNoteDialog(
            title: 'Valider le paiement boost',
            subtitle:
                '${_money(amount)} $currency • $reference. Le boost démarre immédiatement après validation.',
            primaryLabel: 'Activer boost',
          ),
    );
    if (note == null) return;
    final freshBoostSnapshot = await doc.reference.get();
    if (!_isBusinessPaymentPending(freshBoostSnapshot.data() ?? data)) {
      _showAdminSnack(
        'Cette mise en avant vient déjà d’être traitée.',
        danger: true,
      );
      return;
    }
    final adminNote =
        note.trim().isEmpty ? 'Paiement boost validé' : note.trim();
    final rolesApplied =
        (data['rolesApplied'] as Iterable?)
            ?.map((role) => role.toString())
            .toList() ??
        const ['createur', 'boutique'];
    final now = DateTime.now();
    final endsAt =
        (data['endsAt'] is Timestamp)
            ? data['endsAt'] as Timestamp
            : Timestamp.fromDate(now.add(const Duration(days: 7)));

    final batch = _firestore.batch();
    batch.set(doc.reference, {
      'status': 'active',
      'paymentStatus': 'paid',
      'adminNote': adminNote,
      'paymentReview': {
        'decision': 'paid',
        'note': adminNote,
        'reviewedBy': _auth.currentUser?.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      },
      'approvedBy': _auth.currentUser?.uid,
      'activatedAt': FieldValue.serverTimestamp(),
      'startsAt': Timestamp.fromDate(now),
      'endsAt': endsAt,
      'sharedAcrossRoles': true,
      'rolesApplied': rolesApplied,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(
      _firestore.collection('users').doc(userId),
      AdminWorkflowDecision.boostEntitlementPatch(
        campaignId: doc.id,
        rolesApplied: rolesApplied,
        startsAt: Timestamp.fromDate(now),
        endsAt: endsAt,
      ),
      SetOptions(merge: true),
    );

    await batch.commit();
    await _logAdminAction(
      action: 'boost_activated',
      targetId: doc.id,
      targetType: 'boost',
      note: adminNote,
    );
    await _notifyAdminDecision(
      recipientId: userId,
      title: 'Mise en avant activée',
      body:
          'Votre mise en avant est active et améliore la visibilité de vos contenus professionnels dans le Salon.',
      type: 'boost_activated',
      actionLabel: 'Voir mon espace Pro',
      data: {
        'targetType': 'pro_request',
        'targetId': doc.id,
        'campaignId': doc.id,
        'rolesApplied': rolesApplied,
        'endsAt': endsAt.toDate().toIso8601String(),
      },
    );
    if (!mounted) return;
    _showAdminSnack('Mise en avant activée pour les espaces pro du compte');
  }

  Future<void> _rejectBusinessRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String type,
    required String recipientKey,
  }) async {
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => _AdminNoteDialog(
            title:
                type == 'boost'
                    ? 'Refuser la mise en avant'
                    : 'Refuser le plan',
            subtitle:
                'Ajoutez une raison courte. Elle sera transmise au compte concerné.',
            primaryLabel: 'Refuser',
            danger: true,
          ),
    );
    if (note == null) return;

    final data = doc.data();
    final recipientId = _string(
      data,
      recipientKey,
      fallback: _string(data, 'accountId', fallback: _string(data, 'userId')),
    );

    try {
      await doc.reference.set({
        'status': 'rejected',
        'paymentStatus': 'rejected',
        'adminNote': note,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (recipientId.isNotEmpty) {
        await _firestore.collection('users').doc(recipientId).set({
          'businessEntitlements': {
            if (type == 'boost')
              'boost': {
                'status': 'rejected',
                'reference': _string(
                  data,
                  'reference',
                  fallback: _string(data, 'paymentReference'),
                ),
                'rejectedAt': FieldValue.serverTimestamp(),
                'adminNote': note,
              }
            else ...{
              'plan': _string(data, 'plan', fallback: 'pro'),
              'status': 'rejected',
              'reference': _string(
                data,
                'reference',
                fallback: _string(data, 'paymentReference'),
              ),
              'rejectedAt': FieldValue.serverTimestamp(),
              'adminNote': note,
            },
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await _logAdminAction(
        action: '${type}_rejected',
        targetId: doc.id,
        targetType: type,
        note: note,
      );
      await _notifyAdminDecision(
        recipientId: recipientId,
        title:
            type == 'boost'
                ? 'Mise en avant refusée'
                : 'Plan professionnel refusé',
        body:
            type == 'boost'
                ? 'Votre demande de mise en avant n’a pas été validée. Consultez votre espace pour corriger ou contacter le support.'
                : 'Votre demande de plan professionnel n’a pas été validée. Consultez votre espace pour plus de détails.',
        type: '${type}_rejected',
        actionLabel: 'Voir la demande',
        data: {
          'targetType': 'pro_request',
          'targetId': doc.id,
          'requestId': doc.id,
          'note': note,
        },
      );
      if (!mounted) return;
      _showAdminSnack('Demande refusée');
    } catch (e) {
      if (!mounted) return;
      _showAdminSnack('Refus impossible: $e', danger: true);
    }
  }

  void _showAdminSnack(String message, {bool danger = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: danger ? ModernColors.danger : ModernColors.success,
      ),
    );
  }

  static String _shortId(String id) => id.length <= 7 ? id : id.substring(0, 7);

  static String _string(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static double? _number(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    return value.map(
      (key, entry) => MapEntry(key.toString(), entry?.toString() ?? ''),
    )..removeWhere((key, entry) => key.trim().isEmpty || entry.trim().isEmpty);
  }

  bool _matchesWithdrawalFilter(Map<String, dynamic> data) {
    final status = _string(data, 'status', fallback: 'pending_admin_transfer');
    final kind = _withdrawalKind(data);
    return switch (_withdrawalFilter) {
      'all' => true,
      'pending' => status == 'pending_admin_transfer',
      'pro_orders' => kind == 'managed_order',
      'secondhand' => kind == 'secondhand',
      'settled' => status == 'settled',
      'blocked' => status == 'blocked',
      _ => true,
    };
  }

  static String _withdrawalKind(Map<String, dynamic> data) {
    final requestType = _string(data, 'requestType');
    final listingId = _string(data, 'listingId');
    if (requestType == 'secondhand_client_withdrawal' || listingId.isNotEmpty) {
      return 'secondhand';
    }
    return 'managed_order';
  }

  static String _withdrawalKindLabel(String kind) {
    return switch (kind) {
      'secondhand' => 'Vide-dressing client',
      _ => 'Commande pro',
    };
  }

  static String _withdrawalSellerLabel(String kind) {
    return switch (kind) {
      'secondhand' => 'client vendeur',
      _ => 'vendeur',
    };
  }

  static IconData _withdrawalKindIcon(String kind) {
    return switch (kind) {
      'secondhand' => Icons.recycling_rounded,
      _ => Icons.storefront_rounded,
    };
  }

  static Color _withdrawalKindColor(String kind) {
    return switch (kind) {
      'secondhand' => ModernColors.client,
      _ => ModernColors.primary,
    };
  }

  static String _withdrawalRequestTypeLabel(String type) {
    return switch (type) {
      'secondhand_client_withdrawal' => 'Retrait client seconde main',
      'managed_order_withdrawal' => 'Retrait commande validée',
      _ => type,
    };
  }

  static String _money(double value) {
    return '${NumberFormat.decimalPattern('fr').format(value.round())} FCFA';
  }

  static String _formatMoney(double value, String currency) {
    final normalizedCurrency = currency.trim().toUpperCase();
    final amount = NumberFormat.decimalPattern('fr').format(value.round());
    if (normalizedCurrency.isEmpty ||
        normalizedCurrency == 'XOF' ||
        normalizedCurrency == 'FCFA') {
      return '$amount FCFA';
    }
    return '$amount $normalizedCurrency';
  }

  void _copyAdminValue(String value, String message) {
    if (value.isEmpty) {
      _showAdminSnack('Aucune valeur à copier', danger: true);
      return;
    }
    Clipboard.setData(ClipboardData(text: value));
    _showAdminSnack(message);
  }

  void _showAdminProof(String imageUrl, String title) {
    if (imageUrl.isEmpty) {
      _showAdminSnack('Aucune preuve disponible', danger: true);
      return;
    }
    showDialog<void>(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 520),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton.icon(
                    onPressed:
                        () => _copyAdminValue(imageUrl, 'Lien preuve copié'),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copier le lien'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  static String _financeStatusLabel(String status) {
    return switch (status) {
      'pending_admin_transfer' => 'À transférer',
      'pending_settlement' => 'À reverser',
      'settled' => 'Payé',
      'blocked' => 'Bloqué',
      'withdrawal_requested' => 'Demandé',
      'available' => 'Disponible',
      'payment_rejected' => 'Paiement refusé',
      'dispute' || 'disputed' => 'Litige',
      _ => status.isEmpty ? 'À suivre' : status,
    };
  }

  static String _auditActionLabel(String action) {
    return switch (action) {
      'review_payment_paid' => 'Paiement commande validé',
      'review_payment_payment_rejected' => 'Paiement commande refusé',
      'review_payment_dispute' => 'Litige commande ouvert',
      'dispute_review_started' => 'Litige passé en analyse',
      'withdrawal_request_settled' => 'Retrait vendeur payé',
      'withdrawal_request_blocked' => 'Retrait vendeur bloqué',
      'payout_settled' => 'Reversement vendeur payé',
      'payout_blocked' => 'Reversement vendeur bloqué',
      'pro_plan_approved' => 'Plan Pro activé',
      'boost_activated' => 'Boost activé',
      _ => action.isEmpty ? 'Action admin' : action.replaceAll('_', ' '),
    };
  }

  static String _auditFilterKey(String action) {
    final normalized = action.toLowerCase();
    if (normalized.contains('dispute')) return 'dispute';
    if (normalized.contains('withdrawal') || normalized.contains('payout')) {
      return 'withdrawal';
    }
    if (normalized.contains('pro_plan')) return 'pro';
    if (normalized.contains('boost')) return 'boost';
    if (normalized.contains('moderate')) return 'moderation';
    if (normalized.contains('payment')) return 'payment';
    return 'all';
  }

  static bool _isDisputeData(Map<String, dynamic> data) {
    final status =
        _string(
          data,
          'orderStatus',
          fallback: _string(data, 'status'),
        ).toLowerCase();
    final paymentStatus = _string(data, 'paymentStatus').toLowerCase();
    final dispute = data['dispute'];
    return status.contains('dispute') ||
        paymentStatus.contains('dispute') ||
        dispute is Map;
  }

  static bool _canReviewOrderPayment(String status, String paymentStatus) {
    final normalizedStatus = status.toLowerCase();
    final normalizedPayment = paymentStatus.toLowerCase();
    if (normalizedPayment == 'paid' ||
        normalizedPayment == 'payment_rejected' ||
        normalizedPayment == 'rejected') {
      return false;
    }
    if (normalizedStatus == 'payment_rejected' ||
        normalizedStatus == 'completed' ||
        normalizedStatus == 'cancelled' ||
        normalizedStatus == 'dispute' ||
        normalizedStatus == 'disputed') {
      return false;
    }
    return normalizedStatus.contains('awaiting_admin_payment') ||
        normalizedStatus.contains('pending') ||
        normalizedPayment == 'client_marked_paid' ||
        normalizedPayment == 'proof_submitted' ||
        normalizedPayment == 'pending' ||
        normalizedPayment == 'pending_payment';
  }

  static bool _isBusinessPaymentPending(Map<String, dynamic> data) {
    final status = _string(data, 'status', fallback: 'pending_payment');
    final paymentStatus = _string(data, 'paymentStatus', fallback: 'pending');
    return (status == 'pending_payment' || status == 'pending_review') &&
        (paymentStatus == 'pending' ||
            paymentStatus == 'client_marked_paid' ||
            paymentStatus == 'pending_payment');
  }

  static bool _isBusinessPaymentApproved(Map<String, dynamic> data) {
    final status = _string(data, 'status');
    final paymentStatus = _string(data, 'paymentStatus');
    return status == 'approved' ||
        status == 'active' ||
        paymentStatus == 'paid';
  }

  static int _businessRequestRank(Map<String, dynamic> data) {
    if (_isBusinessPaymentPending(data)) return 0;
    if (_string(data, 'status') == 'rejected') return 2;
    return 1;
  }

  static String _businessPaymentStatusLabel(String status) {
    return switch (status) {
      'pending_payment' => 'Paiement attendu',
      'pending_review' => 'À vérifier',
      'pending' => 'En attente',
      'client_marked_paid' => 'Paiement signalé',
      'approved' => 'Approuvé',
      'active' => 'Actif',
      'paid' => 'Payé',
      'rejected' => 'Refusé',
      _ => status.isEmpty ? 'À suivre' : status,
    };
  }

  static Color _statusColor(String status) {
    final value = status.toLowerCase();
    if (value.contains('client_marked_paid') ||
        value.contains('pending') ||
        value.contains('proof') ||
        value.contains('review') ||
        value.contains('attente') ||
        value.contains('awaiting')) {
      return ModernColors.warning;
    }
    if (value.contains('rejected') ||
        value.contains('hidden') ||
        value.contains('blocked') ||
        value.contains('cancel') ||
        value.contains('dispute') ||
        value.contains('inactive')) {
      return ModernColors.danger;
    }
    if (value.contains('approved') ||
        value.contains('active') ||
        value.contains('settled') ||
        value.contains('paid') ||
        value.contains('livr') ||
        value.contains('confirm')) {
      return ModernColors.success;
    }
    return ModernColors.primary;
  }

  Widget _buildAdminHero() {
    final email = _auth.currentUser?.email ?? 'admin@elegantstyle';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ModernColors.line),
        boxShadow: ModernShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ModernColors.admin.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: ModernColors.admin,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cockpit ElegantStyle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualiser',
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _openAdminGlobalSearch,
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Recherche globale',
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _confirmSignOut,
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Déconnexion',
                style: IconButton.styleFrom(
                  foregroundColor: ModernColors.danger,
                  backgroundColor: ModernColors.danger.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AdminStatusChip(
                icon: Icons.verified_user_rounded,
                label: 'Admin actif',
                color: ModernColors.primary,
              ),
              _AdminStatusChip(
                icon: AppIcons.salon,
                label: 'Salon actif',
                color: ModernColors.client,
              ),
              _AdminStatusChip(
                icon: Icons.payments_rounded,
                label: '${_totalRevenus.toStringAsFixed(0)} FCFA',
                color: ModernColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTodayPanel() {
    final proProfiles = _nbBoutiques + _nbCreators;
    final totalUsers = _users.length;
    final averageCommission =
        _nbCommandes == 0 ? 0 : (_totalRevenus / _nbCommandes);

    return _AdminTodayPanel(
      items: [
        _AdminTodayItem(
          icon: AppIcons.clients,
          color: ModernColors.primary,
          label: 'Comptes',
          value: totalUsers.toString(),
          subtitle: '$proProfiles profils pro',
          onTap: () => setState(() => _currentIndex = 1),
        ),
        _AdminTodayItem(
          icon: AppIcons.salon,
          color: ModernColors.client,
          label: 'Salon',
          value: proProfiles.toString(),
          subtitle: 'boutiques + créateurs',
          onTap: () => setState(() => _currentIndex = 2),
        ),
        _AdminTodayItem(
          icon: AppIcons.orders,
          color: ModernColors.accent,
          label: 'Commandes',
          value: _nbCommandes.toString(),
          subtitle: 'à suivre côté vendeurs',
          onTap: () => setState(() => _currentIndex = 3),
        ),
        _AdminTodayItem(
          icon: AppIcons.revenue,
          color: ModernColors.success,
          label: 'Commission moy.',
          value: '${averageCommission.toStringAsFixed(0)} F',
          subtitle: 'par commande',
          onTap: () => setState(() => _currentIndex = 4),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 1000) {
          return _buildStatsGrid(crossAxisCount: 5, childAspectRatio: 1.08);
        }
        if (width >= 600) {
          return _buildStatsGrid(crossAxisCount: 3, childAspectRatio: 1.35);
        }
        return _buildStatsGrid(crossAxisCount: 2, childAspectRatio: 1.18);
      },
    );
  }

  Widget _buildStatsGrid({
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        StatCard(
          title: "Clients",
          value: _nbClients.toString(),
          icon: Icons.people_alt_rounded,
          color: ModernColors.client,
          trend: Trend.neutral,
        ),
        StatCard(
          title: "Boutiques",
          value: _nbBoutiques.toString(),
          icon: Icons.storefront_rounded,
          color: ModernColors.shop,
          trend: Trend.neutral,
        ),
        StatCard(
          title: "Créateurs",
          value: _nbCreators.toString(),
          icon: Icons.brush_rounded,
          color: ModernColors.creator,
          trend: Trend.neutral,
        ),
        StatCard(
          title: "Commandes",
          value: _nbCommandes.toString(),
          icon: Icons.shopping_bag_rounded,
          color: ModernColors.accent,
          trend: Trend.neutral,
        ),
        StatCard(
          title: "Revenus",
          value: "${_totalRevenus.toStringAsFixed(0)} FCFA",
          icon: Icons.payments_rounded,
          color: ModernColors.success,
          trend: Trend.neutral,
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.line),
        boxShadow: ModernShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Revenus plateforme",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: ModernColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Commissions et frais service encaissés par mois",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ModernColors.inkSoft),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 280,
            child:
                _salesData.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bar_chart_rounded,
                            size: 48,
                            color: ModernColors.muted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Aucune commission enregistrée",
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: ModernColors.inkSoft),
                          ),
                        ],
                      ),
                    )
                    : SfCartesianChart(
                      plotAreaBorderWidth: 0,
                      title: ChartTitle(
                        text: '',
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: ModernColors.ink,
                        ),
                      ),
                      legend: Legend(
                        isVisible: true,
                        position: LegendPosition.top,
                        textStyle: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        color: Colors.white,
                        borderColor: ModernColors.line,
                        borderWidth: 1,
                        textStyle: const TextStyle(color: ModernColors.ink),
                        builder: (
                          dynamic data,
                          dynamic point,
                          dynamic series,
                          int pointIndex,
                          int seriesIndex,
                        ) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ModernColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: ModernColors.line),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${data.month}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${point.y.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: ModernColors.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      primaryXAxis: CategoryAxis(
                        title: AxisTitle(text: ''),
                        labelRotation: -45,
                        majorGridLines: const MajorGridLines(width: 0),
                        axisLine: const AxisLine(width: 0),
                        labelStyle: const TextStyle(
                          color: ModernColors.inkSoft,
                        ),
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: ''),
                        numberFormat: NumberFormat.currency(
                          symbol: 'FCFA',
                          decimalDigits: 0,
                          locale: 'fr',
                        ),
                        majorGridLines: const MajorGridLines(
                          color: ModernColors.line,
                        ),
                        axisLine: const AxisLine(width: 0),
                        labelStyle: const TextStyle(
                          color: ModernColors.inkSoft,
                        ),
                      ),
                      series: <CartesianSeries<SalesData, String>>[
                        ColumnSeries<SalesData, String>(
                          name: 'Ventes',
                          dataSource: _salesData,
                          animationDuration: 0,
                          xValueMapper: (SalesData sales, _) => sales.month,
                          yValueMapper: (SalesData sales, _) => sales.sales,
                          color: ModernColors.primary,
                          width: 0.6,
                          spacing: 0.2,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            labelAlignment: ChartDataLabelAlignment.top,
                            textStyle: TextStyle(
                              fontSize: 10,
                              color: ModernColors.inkSoft,
                            ),
                            builder: (
                              dynamic data,
                              dynamic point,
                              dynamic series,
                              int pointIndex,
                              int seriesIndex,
                            ) {
                              return Text('${point.y.toStringAsFixed(0)}');
                            },
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.line),
        boxShadow: ModernShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Activité Récente",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: ModernColors.ink,
                ),
              ),
              TextButton(
                onPressed: _showAllActivities,
                child: Text(
                  'Voir tout',
                  style: const TextStyle(color: ModernColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 48,
                    color: ModernColors.muted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Aucune activité récente",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ModernColors.inkSoft,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._recentActivities.map(
              (activity) => _buildActivityItem(activity),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: ModernColors.surfaceRaised,
        border: Border.all(color: ModernColors.line),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (activity['color'] as Color).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(activity['icon'], color: activity['color']),
        ),
        title: Text(
          activity['title'],
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity['description']),
            const SizedBox(height: 4),
            Text(
              activity['subtitle'],
              style: const TextStyle(fontSize: 12, color: ModernColors.inkSoft),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        onTap: () => _showActivityDetails(activity),
      ),
    );
  }

  Future<void> _showAllActivities() async {
    try {
      final snapshot =
          await _firestore
              .collection('activities')
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();
      final activities =
          snapshot.docs.map((doc) {
            final data = doc.data();
            final timestamp = data['timestamp'];
            final date =
                timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
            return {
              'type': data['type'] ?? 'activity',
              'title': data['title'] ?? 'Activité',
              'description': data['description'] ?? '',
              'subtitle': DateFormat('dd/MM/yyyy HH:mm').format(date),
              'icon': _getActivityIcon((data['type'] ?? '').toString()),
              'color': _getActivityColor((data['type'] ?? '').toString()),
            };
          }).toList();
      if (!mounted) return;
      _showActivityLogSheet(activities);
    } catch (e) {
      if (!mounted) return;
      _showAdminSnack('Impossible de charger les activités: $e', danger: true);
    }
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    _showActivityLogSheet([activity]);
  }

  void _showActivityLogSheet(List<Map<String, dynamic>> activities) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _AdminActivityLogSheet(
            activities: activities,
            emptyTitle: 'Aucune activité',
          ),
    );
  }

  Future<void> _openAdminGlobalSearch() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _AdminGlobalSearchSheet(
            onSearch: _searchAdmin,
            onCopy: _copyAdminValue,
          ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 280,
      elevation: 0,
      backgroundColor: ModernColors.canvas,
      child: _AdminSideNavigation(
        selectedIndex: _currentIndex,
        extended: true,
        badgeCounts: _adminNavigationBadges(),
        onSelect: (index) {
          setState(() => _currentIndex = index);
          Navigator.pop(context);
        },
        onSignOut: _confirmSignOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 800;
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar:
          _currentIndex == 0
              ? null
              : CustomAppBar(
                title: _getAppBarTitle(),
                actions: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: _openAdminGlobalSearch,
                      tooltip: 'Recherche globale',
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _refreshData,
                      tooltip: 'Actualiser',
                    ),
                  ),
                  if (_currentIndex == 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton.filled(
                          onPressed: _createNewUser,
                          tooltip: 'Nouvel utilisateur',
                          icon: const Icon(Icons.person_add_alt_rounded),
                        ),
                      ),
                    ),
                  if (_currentIndex != 1 && _currentIndex != 7)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton.filledTonal(
                          onPressed: () => setState(() => _currentIndex = 7),
                          tooltip: 'Paramètres commerce',
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton.filledTonal(
                        onPressed: _confirmSignOut,
                        tooltip: 'Déconnexion',
                        icon: const Icon(Icons.logout_rounded),
                        style: IconButton.styleFrom(
                          foregroundColor: ModernColors.danger,
                          backgroundColor: ModernColors.danger.withValues(
                            alpha: 0.08,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      drawer: isMobile ? _buildDrawer() : null,
      body:
          _isLoading
              ? _buildLoadingView()
              : _errorMessage != null
              ? _buildErrorView()
              : SizedBox.expand(child: _buildMainContent()),
      bottomNavigationBar:
          isMobile
              ? _AdminBottomNavigation(
                selectedIndex: _currentIndex,
                badgeCounts: _adminNavigationBadges(),
                onSelect: (index) => setState(() => _currentIndex = index),
              )
              : null,
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Accueil admin';
      case 1:
        return 'Comptes utilisateurs';
      case 2:
        return 'Salon';
      case 3:
        return 'Commandes';
      case 4:
        return 'Transactions';
      case 5:
        return 'Coupons';
      case 6:
        return 'Modération';
      case 7:
        return 'Paramètres';
      case 8:
        return 'À traiter';
      default:
        return 'Admin ElegantStyle';
    }
  }
}
