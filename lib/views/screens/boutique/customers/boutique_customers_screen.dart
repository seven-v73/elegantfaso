import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../widgets/common/app_action_empty_state.dart';
import '../../messages/user_model.dart';
import '../../messages/chat_screen.dart';
import '../../global/salon_mode_burkinabe.dart';

class BoutiqueCustomersScreen extends StatefulWidget {
  const BoutiqueCustomersScreen({super.key});

  @override
  State<BoutiqueCustomersScreen> createState() =>
      _BoutiqueCustomersScreenState();
}

class _BoutiqueCustomersScreenState extends State<BoutiqueCustomersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, UserModel> _userCache = {};

  String _boutiqueId = '';
  String _segment = 'recent';
  bool _isLoading = true;
  bool _isAuthenticated = false;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _isAuthenticated = user != null;
          _boutiqueId = user?.uid ?? '';
        });

        if (_isAuthenticated) {
          _loadBoutiqueFollowers();
        } else {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _loadBoutiqueFollowers() async {
    if (_boutiqueId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final boutiqueDoc =
          await _firestore.collection('users').doc(_boutiqueId).get();
      if (boutiqueDoc.exists) {
        final boutiqueData = boutiqueDoc.data() ?? {};
        final followers = boutiqueData['followers'] as List<dynamic>? ?? [];
        final followerIds = followers.map((e) => e.toString()).toList();

        if (followerIds.isNotEmpty) {
          _userCache.clear();
          await _cacheUsers(followerIds);
        }
      }
    } catch (e) {
      debugPrint('Erreur de chargement: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Stream<List<_BoutiqueCustomerInsight>> _getBoutiqueFollowers() {
    if (_boutiqueId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore.collection('users').doc(_boutiqueId).snapshots().asyncMap((
      boutiqueSnapshot,
    ) async {
      if (!boutiqueSnapshot.exists) return [];

      final boutiqueData = boutiqueSnapshot.data()!;
      final List<dynamic> followers = boutiqueData['followers'] ?? [];
      final List<String> followerIds =
          followers.map((id) => id.toString()).toList();

      if (followerIds.isEmpty) return [];

      // Filtrer les IDs non encore en cache
      final newIds =
          followerIds.where((id) => !_userCache.containsKey(id)).toList();

      if (newIds.isNotEmpty) await _cacheUsers(newIds);

      final orderStats = await _loadOrderStats(followerIds);
      final insights =
          followerIds
              .where((id) => _userCache.containsKey(id))
              .map(
                (id) => _BoutiqueCustomerInsight(
                  user: _userCache[id]!,
                  ordersCount: orderStats[id]?.ordersCount ?? 0,
                  lastOrderAt: orderStats[id]?.lastOrderAt,
                  // Un abonnement depuis le Salon est déjà un signal d'intérêt.
                  likedCount: orderStats[id]?.likedCount ?? 1,
                ),
              )
              .toList();
      insights.sort((a, b) {
        final aDate = a.lastOrderAt ?? a.user.lastSeen;
        final bDate = b.lastOrderAt ?? b.user.lastSeen;
        return bDate.compareTo(aDate);
      });
      return insights;
    });
  }

  Future<Map<String, _CustomerOrderStats>> _loadOrderStats(
    List<String> followerIds,
  ) async {
    final docs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final field in const ['sellerId', 'boutiqueId']) {
      final snapshot =
          await _firestore
              .collection('orders')
              .where(field, isEqualTo: _boutiqueId)
              .limit(120)
              .get();
      for (final doc in snapshot.docs) {
        docs[doc.id] = doc;
      }
    }

    final followerSet = followerIds.toSet();
    final stats = <String, _CustomerOrderStats>{};
    for (final doc in docs.values) {
      final data = doc.data();
      final customerId =
          data['customerId']?.toString() ??
          data['clientId']?.toString() ??
          data['userId']?.toString() ??
          '';
      if (!followerSet.contains(customerId)) continue;
      final current = stats[customerId] ?? const _CustomerOrderStats();
      stats[customerId] = current.copyWith(
        ordersCount: current.ordersCount + 1,
        lastOrderAt: _latestDate(current.lastOrderAt, _dateFrom(data)),
      );
    }
    return stats;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          if (_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBoutiqueFollowers,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isAuthenticated) {
      return _buildAuthErrorState();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<_BoutiqueCustomerInsight>>(
      stream: _getBoutiqueFollowers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Erreur CRM boutique: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: AppActionEmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Clients indisponibles',
                message: 'Réessayez dans un instant.',
                actionLabel: 'Actualiser',
                onAction: _loadBoutiqueFollowers,
                accent: ModernColors.rose,
              ),
            ),
          );
        }

        final allCustomers = snapshot.data ?? [];
        final followers = _filterCustomers(allCustomers);

        if (allCustomers.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadBoutiqueFollowers,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            itemCount: followers.isEmpty ? 3 : followers.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) return _CrmHeader(customers: allCustomers);
              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CustomerSegments(
                    selected: _segment,
                    onSelected: (value) => setState(() => _segment = value),
                  ),
                );
              }
              if (followers.isEmpty) {
                return _SegmentEmptyCard(segment: _segment);
              }
              return _buildCustomerCard(followers[index - 2]);
            },
          ),
        );
      },
    );
  }

  List<_BoutiqueCustomerInsight> _filterCustomers(
    List<_BoutiqueCustomerInsight> customers,
  ) {
    return switch (_segment) {
      'followup' =>
        customers.where((customer) => customer.ordersCount == 0).toList(),
      'orders' =>
        customers.where((customer) => customer.ordersCount > 0).toList(),
      'liked' =>
        customers.where((customer) => customer.likedCount > 0).toList(),
      _ => customers,
    };
  }

  Widget _buildAuthErrorState() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: AppActionEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Connexion requise',
          message: 'Ouvrez votre espace boutique.',
          accent: ModernColors.rose,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadBoutiqueFollowers,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 150,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppActionEmptyState(
                icon: Icons.groups_2_outlined,
                title: 'Aucun client',
                message: 'Vos abonnés Salon apparaîtront ici.',
                actionLabel: 'Voir ma vitrine',
                onAction:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SalonModeBurkinabeScreen(),
                      ),
                    ),
                accent: ModernColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(_BoutiqueCustomerInsight insight) {
    final user = insight.user;
    final relation =
        insight.ordersCount > 0
            ? '${insight.ordersCount} commande${insight.ordersCount > 1 ? 's' : ''}'
            : 'À relancer';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        elevated: false,
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: ModernColors.surfaceRaised,
              backgroundImage:
                  user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(user.photoUrl!)
                      : null,
              child:
                  user.photoUrl == null || user.photoUrl!.isEmpty
                      ? const Icon(
                        Icons.person_rounded,
                        color: ModernColors.inkSoft,
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.isOnline ? 'Actif maintenant' : relation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: () => _startChatWithCustomer(user),
              icon: const Icon(Icons.chat_rounded, size: 17),
              label: const Text('Message'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cacheUsers(List<String> ids) async {
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.skip(i).take(10).toList();
      if (chunk.isEmpty) continue;
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
      for (final doc in usersSnapshot.docs) {
        _userCache[doc.id] = UserModel.fromDocument(doc);
      }
    }
  }

  void _startChatWithCustomer(UserModel customer) async {
    if (_boutiqueId.isEmpty) return;

    try {
      final boutiqueDoc =
          await _firestore.collection('users').doc(_boutiqueId).get();
      if (!mounted) return;

      if (!boutiqueDoc.exists) {
        _showSnack('Profil boutique introuvable.');
        return;
      }

      final boutiqueUser = UserModel.fromDocument(boutiqueDoc);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatScreen(
                utilisateurCourant: boutiqueUser,
                autreUtilisateur: customer,
                currentRole: 'boutique',
                otherRole: 'client',
              ),
        ),
      );
    } catch (e) {
      debugPrint('Erreur ouverture conversation boutique: $e');
      if (!mounted) return;
      _showSnack('Conversation indisponible pour ce client.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _BoutiqueCustomerInsight {
  const _BoutiqueCustomerInsight({
    required this.user,
    required this.ordersCount,
    required this.likedCount,
    this.lastOrderAt,
  });

  final UserModel user;
  final int ordersCount;
  final int likedCount;
  final DateTime? lastOrderAt;
}

class _CustomerOrderStats {
  const _CustomerOrderStats({
    this.ordersCount = 0,
    this.likedCount = 0,
    this.lastOrderAt,
  });

  final int ordersCount;
  final int likedCount;
  final DateTime? lastOrderAt;

  _CustomerOrderStats copyWith({
    int? ordersCount,
    int? likedCount,
    DateTime? lastOrderAt,
  }) {
    return _CustomerOrderStats(
      ordersCount: ordersCount ?? this.ordersCount,
      likedCount: likedCount ?? this.likedCount,
      lastOrderAt: lastOrderAt ?? this.lastOrderAt,
    );
  }
}

class _CrmHeader extends StatelessWidget {
  const _CrmHeader({required this.customers});

  final List<_BoutiqueCustomerInsight> customers;

  @override
  Widget build(BuildContext context) {
    final ordered =
        customers.where((customer) => customer.ordersCount > 0).length;
    final followup = customers.length - ordered;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Row(
        children: [
          _CrmMetric(label: 'Clients', value: '${customers.length}'),
          _CrmMetric(label: 'Commandes', value: '$ordered'),
          _CrmMetric(label: 'À relancer', value: '$followup'),
        ],
      ),
    );
  }
}

class _CrmMetric extends StatelessWidget {
  const _CrmMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: ModernColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSegments extends StatelessWidget {
  const _CustomerSegments({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const _items = [
    ('recent', 'Récents'),
    ('followup', 'À relancer'),
    ('orders', 'Ont commandé'),
    ('liked', 'Ont aimé'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ChoiceChip(
            label: Text(item.$2),
            selected: selected == item.$1,
            onSelected: (_) => onSelected(item.$1),
          );
        },
      ),
    );
  }
}

class _SegmentEmptyCard extends StatelessWidget {
  const _SegmentEmptyCard({required this.segment});

  final String segment;

  @override
  Widget build(BuildContext context) {
    final label = switch (segment) {
      'followup' => 'Aucun client à relancer',
      'orders' => 'Aucune commande client',
      'liked' => 'Aucun intérêt récent',
      _ => 'Aucun client ici',
    };
    return AppCard(
      padding: const EdgeInsets.all(18),
      elevated: false,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ModernColors.surfaceRaised,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.group_outlined,
              color: ModernColors.inkSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DateTime? _dateFrom(Map<String, dynamic> data) {
  final raw = data['createdAt'] ?? data['updatedAt'] ?? data['orderedAt'];
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

DateTime? _latestDate(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isAfter(b) ? a : b;
}
