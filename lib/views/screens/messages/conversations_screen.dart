import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'chat_service.dart';
import 'user_model.dart';
import 'chat_screen.dart';
import 'message_model.dart';
import 'product_model.dart';

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
  bool _isLoading = false;
  final Map<String, UserModel> _userCache = {};

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    setState(() => _isLoading = true);
    _conversationsStream = _chatService.streamConversations(widget.currentUser.id);
    setState(() => _isLoading = false);
  }

  Future<UserModel?> _getUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('utilisateurs')
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
        title: const Text('Conversations', style: TextStyle(color: Colors.black)),
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
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final conversations = _filterConversations(
                      snapshot.data!.docs,
                      _searchQuery
                  );

                  return RefreshIndicator(
                    onRefresh: () async => _loadConversations(),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 16),
                      itemCount: conversations.length,
                      separatorBuilder: (context, index) => const Divider(height: 0, indent: 72),
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
        onPressed: _startNewConversation,
        backgroundColor: const Color(0xFF6C56F9),
        child: const Icon(Icons.message, color: Colors.white),
        tooltip: 'Nouvelle conversation',
      ),
    );
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher des conversations...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  List<DocumentSnapshot> _filterConversations(
      List<DocumentSnapshot> docs,
      String query
      ) {
    if (query.isEmpty) return docs;

    final queryLower = query.toLowerCase();
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final lastMessage = data['dernierMessage'] as String? ?? '';
      if (lastMessage.toLowerCase().contains(queryLower)) {
        return true;
      }

      final participants = List<String>.from(data['participants']);
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startNewConversation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C56F9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle conversation'),
        content: const Text('Sélectionnez un utilisateur pour démarrer une nouvelle conversation'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Naviguer vers l'écran de sélection des utilisateurs
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      await _chatService.effacerHistoriqueChat(conversationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation supprimée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class ConversationListItem extends StatefulWidget {
  final DocumentSnapshot doc;
  final UserModel currentUser;
  final Function(String) onDelete;
  final Future<UserModel?> Function(String) getUser;

  const ConversationListItem({
    super.key,
    required this.doc,
    required this.currentUser,
    required this.onDelete,
    required this.getUser,
  });

  @override
  State<ConversationListItem> createState() => _ConversationListItemState();
}

class _ConversationListItemState extends State<ConversationListItem> {
  late Map<String, dynamic> _data;
  late String _otherUserId;
  UserModel? _otherUser;
  bool _isLoadingUser = true;
  bool _isOnline = false;
  StreamSubscription<DocumentSnapshot>? _userStatusSubscription;

  @override
  void initState() {
    super.initState();
    _loadConversationData();
  }

  @override
  void dispose() {
    _userStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConversationData() async {
    _data = widget.doc.data() as Map<String, dynamic>;
    final participants = List<String>.from(_data['participants']);
    _otherUserId = participants.firstWhere(
          (id) => id != widget.currentUser.id,
      orElse: () => '',
    );

    if (_otherUserId.isNotEmpty) {
      _otherUser = await widget.getUser(_otherUserId);

      if (_otherUser != null) {
        // Écouter le statut en ligne en temps réel
        _userStatusSubscription = FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(_otherUserId)
            .snapshots()
            .listen((snapshot) {
          if (mounted) {
            setState(() {
              _isOnline = snapshot.get('isOnline') ?? false;
            });
          }
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return _buildLoadingItem();
    }

    if (_otherUser == null) {
      return _buildUnknownUserItem();
    }

    final unreadCount = (_data['compteurNonLu'] as Map<String, dynamic>)
    [widget.currentUser.id] as int? ?? 0;

    final lastMessage = _data['dernierMessage'] ?? '';
    final lastMessageType = TypeMessage.values.firstWhere(
          (e) => e.toString().split('.').last == (_data['typeDernierMessage'] ?? 'texte'),
      orElse: () => TypeMessage.texte,
    );

    final timestamp = (_data['horodatageDernierMessage'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Dismissible(
      key: Key(widget.doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) => _confirmDeletion(),
      child: InkWell(
        onTap: _openChatScreen,
        onLongPress: _showConversationOptions,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              _buildUserAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _otherUser!.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: unreadCount > 0
                                  ? const Color(0xFF6C56F9)
                                  : Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat.Hm().format(timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (lastMessageType != TypeMessage.texte)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              _getMessageTypeIcon(lastMessageType),
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unreadCount > 0 ? Colors.black : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C56F9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _isOnline ? const Color(0xFF6C56F9) : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: _otherUser?.safePhotoUrl ?? '',
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: Center(child: Icon(Icons.person, color: Colors.grey[400])),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: Center(child: Icon(Icons.person, color: Colors.grey[400])),
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (_isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  IconData _getMessageTypeIcon(TypeMessage type) {
    switch (type) {
      case TypeMessage.image: return Icons.image;
      case TypeMessage.video: return Icons.videocam;
      case TypeMessage.audio: return Icons.mic;
      case TypeMessage.document: return Icons.insert_drive_file;
      case TypeMessage.produit: return Icons.shopping_bag;
      case TypeMessage.localisation: return Icons.location_on;
      default: return Icons.text_snippet;
    }
  }

  Widget _buildLoadingItem() {
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
  }

  Widget _buildUnknownUserItem() {
    return ListTile(
      leading: CircleAvatar(child: Icon(Icons.person_off, color: Colors.grey[400])),
      title: const Text('Utilisateur inconnu'),
      subtitle: const Text('Cette conversation ne peut pas être affichée'),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => widget.onDelete(widget.doc.id),
      ),
    );
  }

  Future<bool> _confirmDeletion() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette conversation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showConversationOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.delete,
              label: 'Supprimer la conversation',
              value: 'delete',
              color: Colors.red,
            ),
            _buildOptionTile(
              icon: Icons.notifications_off,
              label: 'Désactiver les notifications',
              value: 'mute',
            ),
            _buildOptionTile(
              icon: Icons.archive,
              label: 'Archiver la conversation',
              value: 'archive',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (choice == 'delete') {
      if (await _confirmDeletion()) {
        widget.onDelete(widget.doc.id);
      }
    }
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(label, style: TextStyle(color: color ?? Colors.black)),
      onTap: () => Navigator.pop(context, value),
    );
  }

  void _openChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          utilisateurCourant: widget.currentUser,
          autreUtilisateur: _otherUser!,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadConversationData();
      }
    });
  }
}