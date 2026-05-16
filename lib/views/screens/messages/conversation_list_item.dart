part of 'conversations_screen.dart';

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
  ConversationContext _context = const ConversationContext();
  String _otherRole = 'client';
  String _currentRole = 'client';
  StreamSubscription<DocumentSnapshot>? _userStatusSubscription;

  @override
  void initState() {
    super.initState();
    _loadConversationData();
  }

  @override
  void didUpdateWidget(covariant ConversationListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc.id != widget.doc.id ||
        _conversationVersion(oldWidget.doc) !=
            _conversationVersion(widget.doc)) {
      _userStatusSubscription?.cancel();
      _userStatusSubscription = null;
      _isLoadingUser = true;
      _loadConversationData();
    }
  }

  @override
  void dispose() {
    _userStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConversationData() async {
    _data = Map<String, dynamic>.from(
      (widget.doc.data() as Map?) ?? const <String, dynamic>{},
    );
    final participants = _stringList(_data['participants']);
    final participantRoles = Map<String, dynamic>.from(
      _data['participantRoles'] ?? const {},
    );
    final participantNames = Map<String, dynamic>.from(
      _data['participantNames'] ?? const {},
    );
    final participantPhotos = Map<String, dynamic>.from(
      _data['participantPhotos'] ?? const {},
    );
    _currentRole =
        participantRoles[widget.currentUser.id]?.toString() ??
        widget.currentUser.role;
    _otherUserId = participants.firstWhere(
      (id) => id != widget.currentUser.id,
      orElse: () => '',
    );
    _otherRole =
        participantRoles[_otherUserId]?.toString() ??
        (_otherUser?.role ?? 'client');
    _context = ConversationContext.fromMap(
      _data['context'] is Map
          ? Map<String, dynamic>.from(_data['context'])
          : null,
    );

    if (_otherUserId.isNotEmpty) {
      _otherUser = await widget.getUser(_otherUserId);
      _otherRole =
          participantRoles[_otherUserId]?.toString() ??
          (_otherUser?.role ?? 'client');
      _otherUser ??= UserModel.fromMap({
        'id': _otherUserId,
        'displayName': participantNames[_otherUserId]?.toString() ?? 'Client',
        'role': _otherRole,
        'roles': [_otherRole],
        'photoUrl': participantPhotos[_otherUserId]?.toString(),
      });

      if (_otherUser != null) {
        // Écouter le statut en ligne en temps réel
        _userStatusSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(_otherUserId)
            .snapshots()
            .listen(
              (snapshot) {
                if (mounted) {
                  final data = snapshot.data() ?? {};
                  setState(() {
                    _isOnline = data['isOnline'] == true;
                  });
                }
              },
              onError: (_) {
                if (mounted) {
                  setState(() {
                    _isOnline = _otherUser?.isOnline == true;
                  });
                }
              },
            );
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

    final unreadCount = _intFromMap(
      _data['compteurNonLu'],
      widget.currentUser.id,
    );

    final lastMessage = _data['dernierMessage'] ?? '';
    final participantNames = Map<String, dynamic>.from(
      _data['participantNames'] ?? const {},
    );
    final displayName =
        participantNames[_otherUserId]?.toString() ?? _otherUser!.mainName;
    final lastMessageType = TypeMessage.values.firstWhere(
      (e) =>
          e.toString().split('.').last ==
          (_data['typeDernierMessage'] ?? 'texte'),
      orElse: () => TypeMessage.texte,
    );

    final timestamp = _dateFromAny(
      _data['horodatageDernierMessage'] ?? _data['misAJourLe'],
    );

    return Dismissible(
      key: Key(widget.doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.orange,
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
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:
                                  unreadCount > 0
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
                    if (_context.hasContent) ...[
                      Text(
                        '${_contextLabel(_context.type)} • ${_context.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF0F766E),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
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
                              color:
                                  unreadCount > 0
                                      ? Colors.black
                                      : Colors.grey[600],
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
                ),
              const SizedBox(width: 8),
              _roleBadge(_otherRole),
            ],
          ),
        ),
      ),
    );
  }

  static Object? _conversationVersion(DocumentSnapshot doc) {
    final data = (doc.data() as Map?) ?? const {};
    return [
      data['misAJourLe'],
      data['horodatageDernierMessage'],
      data['dernierMessage'],
      data['compteurNonLu'],
    ].join('|');
  }

  static List<String> _stringList(dynamic value) {
    if (value is Iterable) return value.map((item) => item.toString()).toList();
    return const [];
  }

  static int _intFromMap(dynamic value, String key) {
    if (value is! Map) return 0;
    final raw = value[key];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static DateTime _dateFromAny(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Widget _roleBadge(String role) {
    final color =
        role == 'boutique'
            ? const Color(0xFFF97316)
            : role == 'createur'
            ? const Color(0xFF7C3AED)
            : const Color(0xFF2563EB);
    final label =
        role == 'boutique'
            ? 'Boutique'
            : role == 'createur'
            ? 'Créateur'
            : 'Client';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }

  String _contextLabel(String type) {
    return switch (type) {
      ConversationContextTypes.product => 'Produit',
      ConversationContextTypes.creation => 'Création',
      ConversationContextTypes.secondhand => 'Vide-dressing',
      ConversationContextTypes.order => 'Commande',
      ConversationContextTypes.appointment => 'RDV',
      ConversationContextTypes.measurement => 'Mesures',
      ConversationContextTypes.support => 'Support',
      _ => 'Discussion',
    };
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
              placeholder:
                  (context, url) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.person, color: Colors.grey[400]),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.person, color: Colors.grey[400]),
                    ),
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
      case TypeMessage.image:
        return Icons.image;
      case TypeMessage.video:
        return Icons.videocam;
      case TypeMessage.audio:
        return Icons.mic;
      case TypeMessage.document:
        return Icons.insert_drive_file;
      case TypeMessage.produit:
        return AppIcons.shop;
      case TypeMessage.localisation:
        return Icons.location_on;
      default:
        return Icons.text_snippet;
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
      leading: CircleAvatar(
        child: Icon(Icons.person_off, color: Colors.grey[400]),
      ),
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
          builder:
              (context) => AlertDialog(
                title: const Text('Archiver la conversation'),
                content: const Text(
                  'Elle disparaîtra de votre boîte principale, sans supprimer les messages pour l’autre personne.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Archiver'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _showConversationOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
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
                  icon: Icons.archive,
                  label: 'Archiver la conversation',
                  value: 'delete',
                  color: Colors.orange,
                ),
                _buildOptionTile(
                  icon: Icons.notifications_off,
                  label: 'Désactiver les notifications',
                  value: 'mute',
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
        builder:
            (context) => ChatScreen(
              utilisateurCourant: widget.currentUser,
              autreUtilisateur: _otherUser!,
              currentRole: _currentRole,
              otherRole: _otherRole,
              conversationContext: _context,
              conversationId: widget.doc.id,
            ),
      ),
    ).then((_) {
      if (mounted) {
        _loadConversationData();
      }
    });
  }
}
