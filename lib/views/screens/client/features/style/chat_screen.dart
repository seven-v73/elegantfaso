import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../design/app_icons.dart';
import 'gemini_service.dart';

enum ChatRole { user, model }

enum _IrisMode { advise, outfit, community, nearby, trend, occasion }

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.usedWebSearch = false,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();

  final ChatRole role;
  final String text;
  final DateTime timestamp;
  final bool usedWebSearch;
  final bool isError;

  bool get isUser => role == ChatRole.user;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.initialDraft});

  final String? initialDraft;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocus = FocusNode();
  final List<ChatMessage> _chatMessages = [];
  final GeminiApiService _geminiService = GeminiApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _webSearchEnabled = false;
  bool _showScrollToBottom = false;
  bool _isLoadingUser = true;
  String _userName = 'Utilisateur';
  String _userPhotoUrl = '';
  _IrisMode _selectedMode = _IrisMode.advise;
  int _requestToken = 0;
  ChatMessage? _lastDeletedMessage;
  int? _lastDeletedIndex;

  late AnimationController _introController;
  late AnimationController _welcomeController;
  late AnimationController _typingController;
  late AnimationController _sendButtonController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _welcomeOpacity;

  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _amberAccent = Color(0xFFF59E0B);
  static const Color _blueInfo = Color(0xFF2563EB);
  static const Color _successGreen = Color(0xFF16A34A);
  static const Color _errorRed = Color(0xFFDC2626);
  static const Color _bgColor = Color(0xFFF3F5F7);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1F2933);
  static const Color _textSecondary = Color(0xFF7B8492);
  static const Color _borderColor = Color(0xFFE4E8EE);
  static const Color _errorSoft = Color(0xFFFFEEF2);

  static const List<_PromptSuggestion> _suggestions = [
    _PromptSuggestion(
      label: 'Tenue pour mariage',
      prompt:
          'Propose-moi une tenue élégante pour un mariage, avec une touche africaine moderne.',
      icon: AppIcons.appointments,
    ),
    _PromptSuggestion(
      label: 'Look bureau',
      prompt:
          'Aide-moi à composer un look bureau chic, confortable et professionnel.',
      icon: Icons.work_outline_rounded,
    ),
    _PromptSuggestion(
      label: 'Associer un textile',
      prompt:
          'J’ai une pièce en textile traditionnel ou imprimé et je veux l’associer avec des pièces modernes.',
      icon: AppIcons.wardrobe,
    ),
    _PromptSuggestion(
      label: 'Couleurs qui me vont',
      prompt:
          'Aide-moi à choisir des couleurs qui me mettent en valeur pour mes tenues.',
      icon: AppIcons.style,
    ),
    _PromptSuggestion(
      label: 'Tenue selon ma morphologie',
      prompt:
          'Conseille-moi une tenue adaptée à ma morphologie et à mon style.',
      icon: AppIcons.measurements,
    ),
    _PromptSuggestion(
      label: 'Tradition moderne',
      prompt:
          'Donne-moi des idées de looks modernes qui valorisent un savoir-faire textile local ou culturel.',
      icon: AppIcons.inspiration,
    ),
  ];

  static const List<_IrisModeOption> _modes = [
    _IrisModeOption(
      mode: _IrisMode.advise,
      label: 'Me conseiller',
      hint:
          'Réponds comme Iris, avec un conseil personnel, inclusif et actionnable.',
      icon: AppIcons.style,
    ),
    _IrisModeOption(
      mode: _IrisMode.outfit,
      label: 'Tenue',
      hint:
          'Compose un look complet avec garde-robe, pièces manquantes et budget.',
      icon: AppIcons.wardrobe,
    ),
    _IrisModeOption(
      mode: _IrisMode.community,
      label: 'Communauté',
      hint:
          'Aide à formuler une question utile ou à résumer des avis de la communauté.',
      icon: Icons.forum_rounded,
    ),
    _IrisModeOption(
      mode: _IrisMode.nearby,
      label: 'Autour de moi',
      hint:
          'Cherche des pistes locales: boutiques, créateurs, stories, Salon et contact.',
      icon: Icons.place_rounded,
    ),
    _IrisModeOption(
      mode: _IrisMode.trend,
      label: 'Tendance',
      hint:
          'Explique une tendance avec prudence et adapte-la au style de l’utilisateur.',
      icon: Icons.travel_explore_rounded,
    ),
    _IrisModeOption(
      mode: _IrisMode.occasion,
      label: 'Occasion',
      hint:
          'Prépare une tenue selon événement, confort, codes sociaux et météo probable.',
      icon: AppIcons.appointments,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _scrollController.addListener(_onScroll);
    _controller.addListener(_onTextChanged);
    final draft = widget.initialDraft?.trim();
    if (draft != null && draft.isNotEmpty) {
      _controller.text = draft;
      _controller.selection = TextSelection.collapsed(offset: draft.length);
    }
  }

  void _initializeAnimations() {
    _introController = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );
    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<double>(begin: 22, end: 0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeOutCubic),
    );
    _welcomeOpacity = CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (!mounted) return;
        final userData = userDoc.data();
        setState(() {
          _userName =
              userData?['displayName'] ??
              userData?['name'] ??
              userData?['nom'] ??
              user.displayName ??
              'Utilisateur';
          _userPhotoUrl = userData?['photoURL'] ?? user.photoURL ?? '';
          _isLoadingUser = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingUser = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
    }

    if (!mounted) return;
    _introController.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _welcomeController.forward();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _welcomeController.dispose();
    _typingController.dispose();
    _sendButtonController.dispose();
    _scrollController.dispose();
    _textFieldFocus.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText && _sendButtonController.status != AnimationStatus.completed) {
      _sendButtonController.forward();
    } else if (!hasText &&
        _sendButtonController.status != AnimationStatus.dismissed) {
      _sendButtonController.reverse();
    }
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final shouldShow =
        _scrollController.offset <
        _scrollController.position.maxScrollExtent - 140;
    if (shouldShow != _showScrollToBottom && mounted) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage({
    String? overrideText,
    bool keepDraft = false,
  }) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    final useWebSearch = _webSearchEnabled;
    final token = ++_requestToken;
    final context = _buildConversationContext();
    HapticFeedback.lightImpact();

    setState(() {
      _chatMessages.add(
        ChatMessage(
          role: ChatRole.user,
          text: text,
          usedWebSearch: useWebSearch,
        ),
      );
      _isLoading = true;
      _webSearchEnabled = false;
      _lastDeletedMessage = null;
      _lastDeletedIndex = null;
    });

    if (!keepDraft) _controller.clear();
    _textFieldFocus.requestFocus();
    _scrollToBottom();

    try {
      final response = await _geminiService.generateChatContent(
        prompt: _buildModePrompt(text),
        conversationContext: context,
        useWebSearch: useWebSearch,
      );
      if (!mounted || token != _requestToken) return;
      setState(() {
        _chatMessages.add(ChatMessage(role: ChatRole.model, text: response));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted || token != _requestToken) return;
      setState(() {
        _chatMessages.add(
          ChatMessage(
            role: ChatRole.model,
            text: 'Désolé, une erreur est survenue. Réessaie.',
            isError: true,
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  String _buildConversationContext() {
    final recent =
        _chatMessages.length > 10
            ? _chatMessages.sublist(_chatMessages.length - 10)
            : _chatMessages;
    return recent
        .map((message) {
          final role = message.isUser ? _userName : 'Conseiller style';
          return '$role: ${message.text}';
        })
        .join('\n');
  }

  List<String> _extractLinks(String text) {
    final linkRegex = RegExp(r'https?://[^\s<>()"]+');
    return linkRegex
        .allMatches(text)
        .map((match) => match.group(0)!)
        .map((url) => url.replaceFirst(RegExp(r'[.,;:!?]+$'), ''))
        .toSet()
        .toList();
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Impossible d’ouvrir le lien: $url', _errorRed);
    }
  }

  void _useSuggestion(_PromptSuggestion suggestion) {
    _controller.text = suggestion.prompt;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _textFieldFocus.requestFocus();
  }

  void _stopGeneration() {
    if (!_isLoading) return;
    HapticFeedback.selectionClick();
    setState(() {
      _requestToken++;
      _isLoading = false;
    });
    _showSnack('Génération arrêtée', _amberAccent);
  }

  Future<void> _retryLastUserMessage() async {
    for (var i = _chatMessages.length - 1; i >= 0; i--) {
      if (_chatMessages[i].isUser) {
        final message = _chatMessages[i];
        if (_chatMessages.isNotEmpty && _chatMessages.last.isError) {
          setState(() => _chatMessages.removeLast());
        }
        _webSearchEnabled = message.usedWebSearch;
        await _sendMessage(overrideText: message.text);
        return;
      }
    }
  }

  Future<void> _regenerateResponse(int index) async {
    if (_isLoading || index < 0 || index >= _chatMessages.length) return;
    final userIndex = _findPreviousUserMessageIndex(index);
    if (userIndex == null) {
      _showSnack('Aucun message utilisateur associé', _amberAccent);
      return;
    }

    final userMessage = _chatMessages[userIndex];
    final token = ++_requestToken;
    final context = _buildConversationContextBefore(userIndex);

    setState(() {
      _chatMessages.removeAt(index);
      _isLoading = true;
    });

    try {
      final response = await _geminiService.generateChatContent(
        prompt: _buildModePrompt(userMessage.text),
        conversationContext: context,
        useWebSearch: userMessage.usedWebSearch,
      );
      if (!mounted || token != _requestToken) return;
      setState(() {
        final safeIndex = index.clamp(0, _chatMessages.length);
        _chatMessages.insert(
          safeIndex,
          ChatMessage(role: ChatRole.model, text: response),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted || token != _requestToken) return;
      setState(() {
        final safeIndex = index.clamp(0, _chatMessages.length);
        _chatMessages.insert(
          safeIndex,
          ChatMessage(
            role: ChatRole.model,
            text: 'Désolé, une erreur est survenue lors de la régénération.',
            isError: true,
          ),
        );
        _isLoading = false;
      });
    }
  }

  int? _findPreviousUserMessageIndex(int index) {
    for (var i = index - 1; i >= 0; i--) {
      if (_chatMessages[i].isUser) return i;
    }
    return null;
  }

  String _buildConversationContextBefore(int index) {
    final start = (index - 10).clamp(0, _chatMessages.length);
    return _chatMessages
        .sublist(start, index)
        .map((message) {
          final role = message.isUser ? _userName : 'Conseiller style';
          return '$role: ${message.text}';
        })
        .join('\n');
  }

  String _buildModePrompt(String userText) {
    final mode = _modes.firstWhere(
      (item) => item.mode == _selectedMode,
      orElse: () => _modes.first,
    );
    return '''
Mode Iris choisi: ${mode.label}
Intention UX: ${mode.hint}

Demande utilisateur:
$userText

Réponds avec une aide concrète. Termine par 1 à 3 prochaines actions possibles, par exemple: chercher dans le Salon, demander à la communauté, contacter un pro, sauvegarder une idée, essayer avec la garde-robe ou activer la recherche web si nécessaire.''';
  }

  void _editAndResend(ChatMessage message) {
    _controller.text = message.text;
    _controller.selection = TextSelection.collapsed(
      offset: message.text.length,
    );
    setState(() => _webSearchEnabled = message.usedWebSearch);
    _textFieldFocus.requestFocus();
  }

  void _deleteMessage(int index) {
    if (index < 0 || index >= _chatMessages.length) return;
    final deleted = _chatMessages[index];
    setState(() {
      _lastDeletedMessage = deleted;
      _lastDeletedIndex = index;
      _chatMessages.removeAt(index);
    });
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message supprimé'),
        backgroundColor: _textPrimary,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Annuler',
          textColor: Colors.white,
          onPressed: _undoDelete,
        ),
      ),
    );
  }

  void _undoDelete() {
    final message = _lastDeletedMessage;
    final index = _lastDeletedIndex;
    if (message == null || index == null) return;
    setState(() {
      _chatMessages.insert(index.clamp(0, _chatMessages.length), message);
      _lastDeletedMessage = null;
      _lastDeletedIndex = null;
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Effacer la conversation'),
            content: const Text(
              'Êtes-vous sûr de vouloir effacer toute la conversation ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: _textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _chatMessages.clear());
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                },
                child: const Text(
                  'Effacer',
                  style: TextStyle(color: _errorRed),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _exportConversation() async {
    if (_chatMessages.isEmpty) {
      _showSnack('Aucune conversation à exporter', _amberAccent);
      return;
    }

    final buffer =
        StringBuffer()
          ..writeln('Conversation style - ElegantStyle')
          ..writeln(
            'Exportée le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          )
          ..writeln('${'-' * 50}\n');

    for (final message in _chatMessages) {
      final role = message.isUser ? _userName : 'Conseiller style';
      final time =
          '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';
      buffer
        ..writeln('[$time] $role:')
        ..writeln(message.text)
        ..writeln();
    }

    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: 'Conversation style',
        title: 'Conversation style',
      ),
    );
  }

  void _showMessageOptions(ChatMessage message, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  _MessageActionTile(
                    icon: Icons.copy_rounded,
                    label: 'Copier le texte',
                    color: _primaryColor,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.text));
                      Navigator.pop(context);
                      _showSnack('Texte copié', _successGreen);
                    },
                  ),
                  if (message.isUser)
                    _MessageActionTile(
                      icon: Icons.edit_rounded,
                      label: 'Modifier et renvoyer',
                      color: _blueInfo,
                      onTap: () {
                        Navigator.pop(context);
                        _editAndResend(message);
                      },
                    ),
                  if (!message.isUser)
                    _MessageActionTile(
                      icon: Icons.refresh_rounded,
                      label: 'Régénérer la réponse',
                      color: _primaryColor,
                      onTap: () {
                        Navigator.pop(context);
                        _regenerateResponse(index);
                      },
                    ),
                  _MessageActionTile(
                    icon: Icons.delete_rounded,
                    label: 'Supprimer le message',
                    color: _errorRed,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteMessage(index);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) return 'À l’instant';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}j';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    final previous = _chatMessages[index - 1].timestamp;
    final current = _chatMessages[index].timestamp;
    return previous.year != current.year ||
        previous.month != current.month ||
        previous.day != current.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    if (messageDate == today) return 'Aujourd’hui';
    if (messageDate == today.subtract(const Duration(days: 1))) return 'Hier';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_chatMessages.isEmpty)
            _buildWelcomeScreen()
          else
            Expanded(child: _buildMessageList()),
          if (_isLoading) _buildTypingPanel(),
          _buildInputArea(),
        ],
      ),
      floatingActionButton:
          _showScrollToBottom
              ? FloatingActionButton.small(
                heroTag: null,
                backgroundColor: _primaryColor,
                onPressed: _scrollToBottom,
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: Colors.white,
                ),
              )
              : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _cardColor,
      foregroundColor: _textPrimary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleSpacing: 0,
      title: Row(
        children: [
          _buildIrisAvatar(size: 40),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conseiller style',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
                Row(
                  children: [
                    _StatusDot(),
                    SizedBox(width: 6),
                    Text(
                      'En ligne',
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Options',
          icon: const Icon(Icons.more_vert_rounded, color: _textSecondary),
          onSelected: (value) {
            if (value == 'export') _exportConversation();
            if (value == 'clear') _clearChat();
          },
          itemBuilder:
              (context) => const [
                PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.ios_share_rounded),
                    title: Text('Partager la conversation'),
                  ),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: ListTile(
                    leading: Icon(Icons.delete_sweep_rounded, color: _errorRed),
                    title: Text('Effacer'),
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildWelcomeScreen() {
    if (_isLoadingUser) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    return Expanded(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 110),
            child: Column(
              children: [
                _buildUserAvatar(),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _welcomeController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _welcomeOpacity.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        'Conseil style personnel',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Dis-moi l’occasion, ton style ou la pièce que tu veux porter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: _textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _buildModeScroller(compact: false),
                const SizedBox(height: 14),
                _buildSuggestionPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Hero(
      tag: 'avatar',
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _primaryColor.withValues(alpha: 0.1),
          border: Border.all(
            color: _primaryColor.withValues(alpha: 0.18),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.white,
              offset: Offset(-3, -3),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Color(0x1A0F172A),
              offset: Offset(4, 4),
              blurRadius: 10,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child:
            _userPhotoUrl.isNotEmpty
                ? Image.network(_userPhotoUrl, fit: BoxFit.cover)
                : const Icon(AppIcons.profile, color: _primaryColor, size: 42),
      ),
    );
  }

  Widget _buildIrisAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _primaryColor.withValues(alpha: 0.1),
      ),
      child: const Icon(AppIcons.style, color: _primaryColor),
    );
  }

  Widget _buildSuggestionPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Color(0x140F172A),
            offset: Offset(6, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(AppIcons.style, color: _amberAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'Commencer rapidement',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _suggestions
                    .map(
                      (suggestion) => ActionChip(
                        avatar: Icon(
                          suggestion.icon,
                          color: _primaryColor,
                          size: 18,
                        ),
                        label: Text(suggestion.label),
                        labelStyle: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        backgroundColor: _bgColor,
                        side: const BorderSide(color: _borderColor),
                        onPressed: () => _useSuggestion(suggestion),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeScroller({required bool compact}) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children:
              _modes.map((mode) {
                final selected = mode.mode == _selectedMode;
                return Padding(
                  padding: EdgeInsets.only(right: compact ? 8 : 10),
                  child: ChoiceChip(
                    selected: selected,
                    avatar: Icon(
                      mode.icon,
                      size: 17,
                      color: selected ? Colors.white : _primaryColor,
                    ),
                    label: Text(mode.label),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : _textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 12 : 13,
                    ),
                    selectedColor: _primaryColor,
                    backgroundColor: _cardColor,
                    side: BorderSide(
                      color:
                          selected
                              ? _primaryColor
                              : _primaryColor.withValues(alpha: 0.18),
                    ),
                    onSelected:
                        _isLoading
                            ? null
                            : (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedMode = mode.mode);
                            },
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _chatMessages.length,
      itemBuilder: (context, index) {
        final message = _chatMessages[index];
        return Column(
          children: [
            if (_shouldShowDateSeparator(index))
              _DateSeparator(label: _formatDateSeparator(message.timestamp)),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 260),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: GestureDetector(
                onLongPress: () => _showMessageOptions(message, index),
                child: _buildMessageBubble(message, index),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final bubbleColor =
        message.isError
            ? _errorSoft
            : message.isUser
            ? _primaryColor
            : _cardColor;
    final textColor = message.isUser ? Colors.white : _textPrimary;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment:
              message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                border:
                    message.isError
                        ? Border.all(color: _errorRed.withValues(alpha: 0.25))
                        : null,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: message.isUser ? const Radius.circular(4) : null,
                  bottomLeft: !message.isUser ? const Radius.circular(4) : null,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        message.isUser
                            ? _primaryColor.withValues(alpha: 0.18)
                            : const Color(0x140F172A),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(message, textColor),
                  if (message.isError) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _retryLastUserMessage,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Réessayer'),
                      style: TextButton.styleFrom(
                        foregroundColor: _errorRed,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 5),
            _buildMessageMeta(message, index),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, Color textColor) {
    final links = _extractLinks(message.text);
    if (links.isEmpty) {
      return Text(
        message.text,
        style: TextStyle(
          fontSize: 15,
          color: message.isError ? _errorRed : textColor,
          height: 1.42,
          fontWeight: message.isUser ? FontWeight.w500 : FontWeight.w400,
        ),
      );
    }

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in RegExp(
      r'https?://[^\s<>()"]+',
    ).allMatches(message.text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: message.text.substring(cursor, match.start)));
      }
      final cleanUrl = match.group(0)!.replaceFirst(RegExp(r'[.,;:!?]+$'), '');
      spans.add(
        TextSpan(
          text: cleanUrl,
          style: const TextStyle(
            color: _blueInfo,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w700,
          ),
          recognizer:
              TapGestureRecognizer()..onTap = () => _launchUrl(cleanUrl),
        ),
      );
      cursor = match.end;
    }
    if (cursor < message.text.length) {
      spans.add(TextSpan(text: message.text.substring(cursor)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 15, color: textColor, height: 1.42),
        children: spans,
      ),
    );
  }

  Widget _buildMessageMeta(ChatMessage message, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(
            _formatTimestamp(message.timestamp),
            style: const TextStyle(fontSize: 11, color: _textSecondary),
          ),
          if (_extractLinks(message.text).isNotEmpty)
            const _MetaBadge(
              icon: Icons.link_rounded,
              label: 'Liens',
              color: _primaryColor,
            ),
          if (message.usedWebSearch)
            const _MetaBadge(
              icon: Icons.search_rounded,
              label: 'Web',
              color: _blueInfo,
            ),
          _InlineAction(
            icon: Icons.copy_rounded,
            tooltip: 'Copier',
            onTap: () {
              Clipboard.setData(ClipboardData(text: message.text));
              _showSnack('Texte copié', _successGreen);
            },
          ),
          if (message.isUser)
            _InlineAction(
              icon: Icons.edit_rounded,
              tooltip: 'Modifier et renvoyer',
              onTap: () => _editAndResend(message),
            ),
          if (!message.isUser)
            _InlineAction(
              icon: Icons.refresh_rounded,
              tooltip: 'Régénérer',
              onTap: () => _regenerateResponse(index),
            ),
          _InlineAction(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Supprimer',
            onTap: () => _deleteMessage(index),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Row(
        children: [
          _buildIrisAvatar(size: 36),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingIndicator(),
                const SizedBox(width: 8),
                const Text(
                  'Réponse en cours...',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _stopGeneration,
            icon: const Icon(Icons.stop_circle_outlined, size: 18),
            label: const Text('Stop'),
            style: TextButton.styleFrom(foregroundColor: _errorRed),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedBuilder(
            animation: _typingController,
            builder: (context, child) {
              final phase = (_typingController.value + index * 0.22) % 1;
              return Opacity(opacity: 0.35 + (phase * 0.65), child: child);
            },
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInputArea() {
    final canSend = _controller.text.trim().isNotEmpty && !_isLoading;
    return Container(
      decoration: const BoxDecoration(
        color: _cardColor,
        border: Border(top: BorderSide(color: _borderColor, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeScroller(compact: true),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Tooltip(
                    message:
                        _webSearchEnabled
                            ? 'Recherche web activée'
                            : 'Activer la recherche web',
                    child: IconButton(
                      icon: Icon(
                        _webSearchEnabled
                            ? Icons.travel_explore_rounded
                            : Icons.search_rounded,
                        color: _webSearchEnabled ? _blueInfo : _textSecondary,
                      ),
                      onPressed:
                          _isLoading
                              ? null
                              : () => setState(
                                () => _webSearchEnabled = !_webSearchEnabled,
                              ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 128),
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              _webSearchEnabled
                                  ? _blueInfo.withValues(alpha: 0.35)
                                  : _borderColor,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _textFieldFocus,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              _webSearchEnabled
                                  ? 'Message avec recherche web...'
                                  : 'Écris ton message...',
                          hintStyle: const TextStyle(color: _textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon:
                              _controller.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: _textSecondary,
                                    ),
                                    onPressed: _controller.clear,
                                  )
                                  : null,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder:
                        (child, animation) => ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                    child:
                        _isLoading
                            ? IconButton.filledTonal(
                              key: const ValueKey('stop'),
                              tooltip: 'Stop',
                              onPressed: _stopGeneration,
                              icon: const Icon(Icons.stop_rounded),
                              color: _errorRed,
                            )
                            : IconButton.filled(
                              key: const ValueKey('send'),
                              tooltip: 'Envoyer',
                              onPressed: canSend ? _sendMessage : null,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    canSend ? _primaryColor : _borderColor,
                                foregroundColor:
                                    canSend ? Colors.white : _textSecondary,
                              ),
                              icon: const Icon(Icons.send_rounded),
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IrisModeOption {
  const _IrisModeOption({
    required this.mode,
    required this.label,
    required this.hint,
    required this.icon,
  });

  final _IrisMode mode;
  final String label;
  final String hint;
  final IconData icon;
}

class _PromptSuggestion {
  const _PromptSuggestion({
    required this.label,
    required this.prompt,
    required this.icon,
  });

  final String label;
  final String prompt;
  final IconData icon;
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: _ChatScreenState._successGreen,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _ChatScreenState._cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _ChatScreenState._borderColor),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _ChatScreenState._textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(icon, size: 15, color: _ChatScreenState._textSecondary),
        ),
      ),
    );
  }
}

class _MessageActionTile extends StatelessWidget {
  const _MessageActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
