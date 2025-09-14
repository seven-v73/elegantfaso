// lib/chat_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gemini_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final GeminiApiService _geminiService = GeminiApiService();
  final FocusNode _textFieldFocus = FocusNode();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _webSearchEnabled = false;
  bool _showScrollToBottom = false;
  String _userName = '';
  String _userPhotoUrl = '';
  bool _isLoadingUser = true;
  String _currentEmotion = 'neutre';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _typingController;
  late AnimationController _welcomeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _welcomeOpacity;
  late AnimationController _sendButtonController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _scrollController.addListener(_onScroll);
    _controller.addListener(_onTextChanged);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Curves.easeOutBack,
      ),
    );

    _welcomeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _onTextChanged() {
    if (_controller.text.isNotEmpty && _sendButtonController.status != AnimationStatus.completed) {
      _sendButtonController.forward();
    } else if (_controller.text.isEmpty && _sendButtonController.status != AnimationStatus.dismissed) {
      _sendButtonController.reverse();
    }
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset <
        _scrollController.position.maxScrollExtent - 100;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _userName = userData['displayName'] ?? userData['nom'] ?? user.displayName ?? 'Utilisateur';
            _userPhotoUrl = userData['photoURL'] ?? user.photoURL ?? '';
            _isLoadingUser = false;
          });
        } else {
          setState(() {
            _userName = user.displayName ?? 'Utilisateur';
            _userPhotoUrl = user.photoURL ?? '';
            _isLoadingUser = false;
          });
        }
      } else {
        setState(() {
          _userName = 'Utilisateur';
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      setState(() {
        _userName = 'Utilisateur';
        _isLoadingUser = false;
      });
    }

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _welcomeController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _welcomeController.dispose();
    _typingController.dispose();
    _sendButtonController.dispose();
    _scrollController.dispose();
    _textFieldFocus.dispose();
    _controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    // Analyser l'émotion du message utilisateur
    final emotionalData = _geminiService.analyzeEmotions(text);
    final dominantEmotion = emotionalData['dominant_emotion'] ?? 'neutre';

    setState(() {
      _messages.add({
        'role': 'user',
        'text': text,
        'timestamp': DateTime.now(),
        'hasWebSearch': _webSearchEnabled,
        'emotion': dominantEmotion,
      });
      _isLoading = true;
      _webSearchEnabled = false;
    });

    _controller.clear();
    _scrollToBottom();
    _textFieldFocus.unfocus();

    try {
      String response;
      if (_webSearchEnabled) {
        response = await _geminiService.searchFashionInfo(text);
      } else {
        response = await _geminiService.generateContent(text);
      }

      setState(() {
        _messages.add({
          'role': 'model',
          'text': response,
          'timestamp': DateTime.now(),
          'hasLinks': _extractLinks(response).isNotEmpty,
          'isWebSearch': _webSearchEnabled,
          'emotion': dominantEmotion,
        });
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'model',
          'text': 'Désolé, une erreur s\'est produite. Peux-tu réessayer ?',
          'timestamp': DateTime.now(),
          'isError': true,
          'emotion': 'neutre',
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  List<String> _extractLinks(String text) {
    final RegExp linkRegex = RegExp(r'https?://[^\s]+');
    return linkRegex.allMatches(text).map((match) => match.group(0)!).toList();
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir le lien: $url'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildMessageContent(Map<String, dynamic> message) {
    final text = message['text'] as String;
    final links = _extractLinks(text);
    final isWebSearch = message['isWebSearch'] == true;
    final emotion = message['emotion'] ?? 'neutre';

    // Styles adaptés à l'émotion
    final emotionColors = {
      'joie': Colors.orange[800],
      'excitation': Colors.yellow[800],
      'stress': Colors.blue[800],
      'tristesse': Colors.purple[800],
      'colère': Colors.red[800],
      'confiance': Colors.green[800],
      'doute': Colors.indigo[800],
      'fatigue': Colors.brown[800],
      'curiosité': Colors.teal[800],
      'amour': Colors.pink[800],
      'neutre': Colors.grey[800],
    };

    final textColor = emotionColors[emotion] ?? Colors.grey[800];
    final bgColor = emotionColors[emotion]?.withOpacity(0.1) ?? Colors.grey[100];

    if (links.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: isWebSearch ? Colors.blue[50] : bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: message['role'] == 'user'
                ? Colors.white
                : message['isError'] == true
                ? Colors.red[700]
                : textColor,
            height: 1.4,
          ),
        ),
      );
    }

    final spans = <TextSpan>[];
    String remainingText = text;

    for (final link in links) {
      final parts = remainingText.split(link);
      if (parts.isNotEmpty) {
        spans.add(TextSpan(
          text: parts[0],
          style: TextStyle(
            fontSize: 16,
            color: message['role'] == 'user' ? Colors.white : textColor,
            height: 1.4,
          ),
        ));

        spans.add(TextSpan(
          text: link,
          style: TextStyle(
            fontSize: 16,
            color: message['role'] == 'user' ? Colors.white : Colors.blue[600],
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launchUrl(link),
        ));

        remainingText = parts.length > 1 ? parts.sublist(1).join(link) : '';
      }
    }

    if (remainingText.isNotEmpty) {
      spans.add(TextSpan(
        text: remainingText,
        style: TextStyle(
          fontSize: 16,
          color: message['role'] == 'user' ? Colors.white : textColor,
          height: 1.4,
        ),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: isWebSearch ? Colors.blue[50] : bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: RichText(
        text: TextSpan(children: spans),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: AnimatedBuilder(
            animation: _typingController,
            builder: (context, child) {
              final animationValue = (index + 1) * 0.2;
              final opacity = _typingController.value > animationValue
                  ? _typingController.value - animationValue
                  : 0.0;

              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green[400]!.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.transparent,
        backgroundImage: _userPhotoUrl.isNotEmpty
            ? NetworkImage(_userPhotoUrl)
            : null,
        child: _userPhotoUrl.isEmpty
            ? const Icon(
          Icons.person,
          color: Colors.white,
          size: 30,
        )
            : null,
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    if (_isLoadingUser) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
          ),
        ),
      );
    }

    return Expanded(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'avatar',
                          child: _buildUserAvatar(),
                        ),
                        const SizedBox(height: 40),
                        AnimatedBuilder(
                          animation: _welcomeOpacity,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: Opacity(
                                opacity: _welcomeOpacity.value,
                                child: Column(
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [
                                          Colors.green[600]!,
                                          Colors.green[800]!,
                                        ],
                                      ).createShader(bounds),
                                      child: Text(
                                        'Salut ${_userName.split(' ')[0]} ! 👋',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Comment puis-je t\'aider aujourd\'hui ?',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.green[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        AnimatedBuilder(
                          animation: _welcomeController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value + 20),
                              child: Opacity(
                                opacity: _welcomeOpacity.value,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.green[50]!,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green[200]!.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        color: Colors.green[700],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Je suis Iris, ta conseillère mode africaine personnelle. Pose-moi tes questions sur la mode, les styles traditionnels, ou demande-moi des conseils !',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w400,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: 'app_avatar',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[900]!],
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Iris - Elegant Faso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Conseillère Mode Africaine',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[700]!, Colors.green[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearChat,
            tooltip: 'Effacer la conversation',
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: _exportConversation,
            tooltip: 'Exporter la conversation',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[700]!.withOpacity(0.05),
              Colors.green[50]!.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            if (_messages.isEmpty)
              _buildWelcomeScreen()
            else
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 100,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUserMessage = message['role'] == 'user';
                    final timestamp = message['timestamp'] as DateTime;
                    final isWebSearch = message['isWebSearch'] == true;

                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: GestureDetector(
                              onLongPress: () => _showMessageOptions(message, index),
                              child: _buildMessageBubble(
                                  message, isUserMessage, timestamp, isWebSearch),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.green[100]!, Colors.green[200]!],
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.person,
                          color: Colors.green[700],
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[100]!, Colors.grey[200]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTypingIndicator(),
                          const SizedBox(width: 8),
                          Text(
                            'Iris écrit...',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            _buildInputArea(),
          ],
        ),
      ),
      floatingActionButton: _showScrollToBottom
          ? FloatingActionButton.small(
        backgroundColor: Colors.green[700],
        onPressed: _scrollToBottom,
        child: const Icon(Icons.arrow_downward, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.green[50]!.withOpacity(0.3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 15,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_webSearchEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.blue[800],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recherche web activée',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => _webSearchEnabled = false);
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue[200],
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.blue[800],
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _webSearchEnabled
                          ? LinearGradient(
                        colors: [Colors.blue[300]!, Colors.blue[600]!],
                      )
                          : null,
                      boxShadow: _webSearchEnabled
                          ? [
                        BoxShadow(
                          color: Colors.blue[300]!.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                          : null,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.search,
                        color: _webSearchEnabled ? Colors.white : Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _webSearchEnabled = !_webSearchEnabled;
                        });
                        HapticFeedback.lightImpact();
                      },
                      tooltip: 'Recherche web',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[50]!, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _webSearchEnabled
                              ? Colors.blue[300]!
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _textFieldFocus,
                        decoration: InputDecoration(
                          hintText: _webSearchEnabled
                              ? 'Chercher sur le web...'
                              : 'Écris ton message...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey[500],
                            ),
                            onPressed: () {
                              _controller.clear();
                              setState(() {});
                            },
                          )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isLoading,
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _sendButtonController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _sendButtonController.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _controller.text.isNotEmpty
                                ? LinearGradient(
                              colors: [Colors.green[600]!, Colors.green[800]!],
                            )
                                : null,
                            boxShadow: _controller.text.isNotEmpty
                                ? [
                              BoxShadow(
                                color: Colors.green[600]!.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                                : null,
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: IconButton(
                              icon: Icon(
                                _isLoading ? Icons.hourglass_bottom : Icons.send_rounded,
                                color: _controller.text.isNotEmpty
                                    ? Colors.white
                                    : Colors.grey[400],
                              ),
                              onPressed: _controller.text.isNotEmpty && !_isLoading
                                  ? _sendMessage
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isUserMessage, DateTime timestamp, bool isWebSearch) {
    final emotion = message['emotion'] ?? 'neutre';

    // Couleurs basées sur l'émotion
    final emotionColors = {
      'joie': [Colors.orange[50]!, Colors.orange[800]!],
      'excitation': [Colors.yellow[50]!, Colors.yellow[800]!],
      'stress': [Colors.blue[50]!, Colors.blue[800]!],
      'tristesse': [Colors.purple[50]!, Colors.purple[800]!],
      'colère': [Colors.red[50]!, Colors.red[800]!],
      'confiance': [Colors.green[50]!, Colors.green[800]!],
      'doute': [Colors.indigo[50]!, Colors.indigo[800]!],
      'fatigue': [Colors.brown[50]!, Colors.brown[800]!],
      'curiosité': [Colors.teal[50]!, Colors.teal[800]!],
      'amour': [Colors.pink[50]!, Colors.pink[800]!],
      'neutre': [Colors.grey[50]!, Colors.grey[800]!],
    };

    final colors = emotionColors[emotion] ?? [Colors.grey[50]!, Colors.grey[800]!];

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment:
          isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUserMessage
                    ? LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : message['isError'] == true
                    ? LinearGradient(
                  colors: [Colors.red[50]!, Colors.red[100]!],
                )
                    : isWebSearch
                    ? LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                )
                    : LinearGradient(
                  colors: [colors[0], colors[0]],
                ),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isUserMessage ? const Radius.circular(4) : null,
                  bottomLeft: !isUserMessage ? const Radius.circular(4) : null,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(message),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: isUserMessage
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isUserMessage) ...[
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.green[100]!, Colors.green[200]!],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        Icons.person,
                        color: Colors.green[700],
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (message['hasWebSearch'] == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.blue[700],
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Web',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (message['hasLinks'] == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link,
                          color: Colors.orange[700],
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Liens',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isUserMessage) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[700]!],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.transparent,
                      backgroundImage: _userPhotoUrl.isNotEmpty
                          ? NetworkImage(_userPhotoUrl)
                          : null,
                      child: _userPhotoUrl.isEmpty
                          ? const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      )
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer la conversation'),
        content: const Text('Êtes-vous sûr de vouloir effacer toute la conversation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> message, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier le texte'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message['text']));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Texte copié !'),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
            if (message['role'] == 'model') ...[
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Régénérer la réponse'),
                onTap: () {
                  Navigator.pop(context);
                  _regenerateResponse(index);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer le message',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(index);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _regenerateResponse(int index) async {
    if (index <= 0) return;

    final userMessage = _messages[index - 1];
    final isWebSearch = userMessage['hasWebSearch'] ?? false;
    final dominantEmotion = userMessage['emotion'] ?? 'neutre';

    setState(() {
      _messages.removeAt(index);
      _isLoading = true;
    });

    try {
      String response;
      if (isWebSearch) {
        response = await _geminiService.searchFashionInfo(userMessage['text']);
      } else {
        response = await _geminiService.generateContent(userMessage['text']);
      }

      setState(() {
        _messages.insert(index, {
          'role': 'model',
          'text': response,
          'timestamp': DateTime.now(),
          'hasLinks': _extractLinks(response).isNotEmpty,
          'isWebSearch': isWebSearch,
          'emotion': dominantEmotion,
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.insert(index, {
          'role': 'model',
          'text': 'Désolé, une erreur s\'est produite lors de la régénération.',
          'timestamp': DateTime.now(),
          'isError': true,
          'emotion': 'neutre',
        });
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _deleteMessage(int index) {
    setState(() {
      _messages.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _exportConversation() async {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aucune conversation à exporter'),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Conversation avec Iris - Elegant Faso');
    buffer.writeln('Exportée le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln('${'-' * 50}\n');

    for (final message in _messages) {
      final role = message['role'] == 'user' ? _userName : 'Iris';
      final timestamp = message['timestamp'] as DateTime;
      final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

      buffer.writeln('[$timeStr] $role:');
      buffer.writeln(message['text']);
      buffer.writeln();
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Conversation copiée dans le presse-papiers !'),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}