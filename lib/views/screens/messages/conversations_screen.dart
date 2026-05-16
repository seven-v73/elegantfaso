import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../design/app_icons.dart';
import 'chat_service.dart';
import 'user_model.dart';
import 'chat_screen.dart';
import 'message_model.dart';
import '../../../models/messages/conversation_context.dart';
part 'conversation_list_item.dart';

class ConversationsScreen extends StatefulWidget {
  final UserModel currentUser;

  const ConversationsScreen({super.key, required this.currentUser});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  late Stream<QuerySnapshot> _conversationsStream;
  String _searchQuery = '';
  String _selectedFilter = 'Tous';
  bool _isLoading = false;
  final Map<String, UserModel> _userCache = {};

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    setState(() => _isLoading = true);
    _conversationsStream = _chatService.streamConversations(
      widget.currentUser.id,
    );
    setState(() => _isLoading = false);
  }

  Future<UserModel?> _getUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (doc.exists) {
        final user = UserModel.fromDocument(doc);
        _userCache[userId] = user;
        return user;
      }
    } catch (e) {
      debugPrint('Error fetching user $userId: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Conversations',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadConversations,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterRail(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _conversationsStream,
                builder: (context, snapshot) {
                  if (_isLoading) {
                    return _buildLoadingList();
                  }

                  if (snapshot.hasError) {
                    debugPrint(
                      'Erreur chargement conversations: ${snapshot.error}',
                    );
                    return const Center(
                      child: Text('Conversations indisponibles.'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final conversations = _filterConversations(
                    snapshot.data!.docs,
                    _searchQuery,
                  );

                  return RefreshIndicator(
                    onRefresh: () async => _loadConversations(),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 16),
                      itemCount: conversations.length,
                      separatorBuilder:
                          (context, index) =>
                              const Divider(height: 0, indent: 72),
                      itemBuilder: (context, index) {
                        return ConversationListItem(
                          doc: conversations[index],
                          currentUser: widget.currentUser,
                          onDelete: _deleteConversation,
                          getUser: _getUser,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _startNewConversation,
        backgroundColor: const Color(0xFF6C56F9),
        tooltip: 'Nouvelle conversation',
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterRail() {
    final filters = _filtersForRole(widget.currentUser.role);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter == _selectedFilter;
          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            showCheckmark: false,
            selectedColor: const Color(0xFF0F766E),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected ? const Color(0xFF0F766E) : Colors.grey.shade200,
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w800,
            ),
            onSelected: (_) => setState(() => _selectedFilter = filter),
          );
        },
      ),
    );
  }

  List<String> _filtersForRole(String role) {
    if (role == 'boutique') {
      return const [
        'Tous',
        'Commandes',
        'Produits',
        'Clients',
        'Paiements',
        'RDV',
      ];
    }
    if (role == 'createur') {
      return const [
        'Tous',
        'Demandes',
        'RDV',
        'Créations',
        'Mesures',
        'Archives',
      ];
    }
    return const [
      'Tous',
      'Commandes',
      'Vide-dressing',
      'Créateurs',
      'Boutiques',
      'RDV',
      'Support',
    ];
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher des conversations...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  List<DocumentSnapshot> _filterConversations(
    List<DocumentSnapshot> docs,
    String query,
  ) {
    final visibleDocs =
        docs.where((doc) {
          final data = Map<String, dynamic>.from(
            (doc.data() as Map?) ?? const <String, dynamic>{},
          );
          final archivedFor = _stringList(data['archivedFor']);
          final isArchived = archivedFor.contains(widget.currentUser.id);
          if (_selectedFilter == 'Archives') return isArchived;
          if (isArchived) return false;

          final participantRoles = Map<String, dynamic>.from(
            data['participantRoles'] ?? const {},
          );
          final currentRole =
              participantRoles[widget.currentUser.id]?.toString() ??
              widget.currentUser.role;
          if (currentRole != widget.currentUser.role) return false;

          final contextType = data['contextType']?.toString() ?? 'general';
          return _matchesFilter(contextType, participantRoles);
        }).toList();

    if (query.isEmpty) return visibleDocs;

    final queryLower = query.toLowerCase();
    return visibleDocs.where((doc) {
      final data = Map<String, dynamic>.from(
        (doc.data() as Map?) ?? const <String, dynamic>{},
      );
      final lastMessage = data['dernierMessage'] as String? ?? '';
      final contextTitle = data['contextTitle']?.toString() ?? '';
      if ('$lastMessage $contextTitle'.toLowerCase().contains(queryLower)) {
        return true;
      }

      final participants = _stringList(data['participants']);
      final otherUserId = participants.firstWhere(
        (id) => id != widget.currentUser.id,
        orElse: () => '',
      );

      final cachedUser = _userCache[otherUserId];
      if (cachedUser != null) {
        return cachedUser.displayName.toLowerCase().contains(queryLower);
      }
      return false;
    }).toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is Iterable) return value.map((item) => item.toString()).toList();
    return const [];
  }

  bool _matchesFilter(
    String contextType,
    Map<String, dynamic> participantRoles,
  ) {
    if (_selectedFilter == 'Tous' || _selectedFilter == 'Archives') return true;
    final otherRole =
        participantRoles.entries
            .where((entry) => entry.key != widget.currentUser.id)
            .map((entry) => entry.value.toString())
            .firstOrNull;
    return switch (_selectedFilter) {
      'Commandes' => contextType == ConversationContextTypes.order,
      'Produits' => contextType == ConversationContextTypes.product,
      'Vide-dressing' => contextType == ConversationContextTypes.secondhand,
      'Paiements' => contextType == ConversationContextTypes.order,
      'RDV' => contextType == ConversationContextTypes.appointment,
      'Créations' ||
      'Demandes' => contextType == ConversationContextTypes.creation,
      'Mesures' => contextType == ConversationContextTypes.measurement,
      'Support' => contextType == ConversationContextTypes.support,
      'Créateurs' => otherRole == 'createur',
      'Boutiques' => otherRole == 'boutique',
      'Clients' => otherRole == 'client',
      _ => true,
    };
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16, width: 150, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 200, color: Colors.white),
                    ],
                  ),
                ),
                Container(width: 40, height: 40, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'Aucune conversation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Commencez une nouvelle conversation avec vos contacts',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startNewConversation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C56F9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Nouvelle conversation'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNewConversation() async {
    final target = await showModalBottomSheet<_ConversationTarget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _NewConversationSheet(currentUser: widget.currentUser),
    );
    if (target == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatScreen(
              utilisateurCourant: widget.currentUser,
              autreUtilisateur: target.user,
              currentRole: widget.currentUser.role,
              otherRole: target.role,
              conversationContext: const ConversationContext(
                type: ConversationContextTypes.general,
                title: 'Nouvelle discussion',
              ),
            ),
      ),
    );
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      await _chatService.archiverConversation(
        conversationId,
        widget.currentUser.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation archivée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ConversationTarget {
  const _ConversationTarget({required this.user, required this.role});

  final UserModel user;
  final String role;
}

class _NewConversationSheet extends StatefulWidget {
  const _NewConversationSheet({required this.currentUser});

  final UserModel currentUser;

  @override
  State<_NewConversationSheet> createState() => _NewConversationSheetState();
}

class _NewConversationSheetState extends State<_NewConversationSheet> {
  final _searchController = TextEditingController();
  late final Future<QuerySnapshot<Map<String, dynamic>>> _usersFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _usersFuture =
        FirebaseFirestore.instance.collection('users').limit(120).get();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF3F5F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nouvelle conversation',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choisissez un client, créateur ou boutique. Les comptes admin restent invisibles.',
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Rechercher par nom, métier, ville...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F766E),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  future: _usersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      debugPrint(
                        'Erreur chargement contacts: ${snapshot.error}',
                      );
                      return const Center(
                        child: Text('Contacts indisponibles.'),
                      );
                    }

                    final targets = _buildTargets(snapshot.data?.docs ?? []);
                    if (targets.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Aucun contact disponible pour le moment.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      itemCount: targets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final target = targets[index];
                        return _TargetTile(target: target);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_ConversationTarget> _buildTargets(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final query = _query.trim().toLowerCase();
    final targets = <_ConversationTarget>[];

    for (final doc in docs) {
      if (doc.id == widget.currentUser.id) continue;
      final data = doc.data();
      final user = UserModel.fromMap(data, docId: doc.id);
      if (user.isAdmin) continue;
      final status =
          data['accountStatus']?.toString().toLowerCase() ?? 'active';
      if (status == 'closed' || status == 'suspended' || status == 'disabled') {
        continue;
      }

      final searchable =
          [
            user.displayName,
            user.boutiqueName,
            user.specialty,
            user.location,
            user.bio,
            user.email,
          ].whereType<String>().join(' ').toLowerCase();
      if (query.isNotEmpty && !searchable.contains(query)) continue;

      for (final role in _visibleRoles(user)) {
        targets.add(_ConversationTarget(user: user, role: role));
      }
    }

    targets.sort((a, b) => _displayName(a).compareTo(_displayName(b)));
    return targets;
  }

  List<String> _visibleRoles(UserModel user) {
    final roles = <String>{...user.roles};
    roles.remove('admin');
    if (roles.isEmpty) roles.add('client');

    if (widget.currentUser.role == 'client') {
      final proRoles = roles.where((role) => role != 'client').toList();
      return proRoles.isEmpty ? ['client'] : proRoles;
    }

    if (roles.contains('client')) return ['client'];
    return roles.toList();
  }

  static String _displayName(_ConversationTarget target) {
    if (target.role == 'boutique') {
      return target.user.boutiqueName ?? target.user.displayName;
    }
    return target.user.displayName;
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({required this.target});

  final _ConversationTarget target;

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(target.role);
    final name =
        target.role == 'boutique'
            ? target.user.boutiqueName ?? target.user.displayName
            : target.user.displayName;
    final subtitle = [
      _roleLabel(target.role),
      target.user.specialty,
      target.user.location,
    ].whereType<String>().where((item) => item.trim().isNotEmpty).join(' • ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pop(context, target),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: CachedNetworkImageProvider(
                  target.user.safePhotoUrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle.isEmpty ? target.user.email : subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _roleLabel(target.role),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _roleColor(String role) {
    return switch (role) {
      'boutique' => const Color(0xFFF97316),
      'createur' => const Color(0xFF7C3AED),
      _ => const Color(0xFF2563EB),
    };
  }

  static String _roleLabel(String role) {
    return switch (role) {
      'boutique' => 'Boutique',
      'createur' => 'Créateur',
      _ => 'Client',
    };
  }
}
