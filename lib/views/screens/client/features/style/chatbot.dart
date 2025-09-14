import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp();

  // Chargement des variables d'environnement
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Erreur de chargement .env: $e");
  }

  runApp(const ChantalApp());
}

class ChantalApp extends StatelessWidget {
  const ChantalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iris - Styliste Mode Africaine',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ChantalChatbot(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  final String? messageId;
  final String? emotion;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    DateTime? timestamp,
    this.messageId,
    this.emotion,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChantalChatbot extends StatefulWidget {
  const ChantalChatbot({super.key});

  @override
  State<ChantalChatbot> createState() => _ChantalChatbotState();
}

class _ChantalChatbotState extends State<ChantalChatbot>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isTyping = false;
  int _conversationDepth = 0;
  String _currentConversationSummary = '';

  // User data
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userPhotoUrl;
  String? _userGender;
  String? _userStylePreference;
  bool _isLoadingUser = true;

  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Messages
  final List<String> _welcomeMessages = [
    "Moi c'est Iris, ta conseillère mode africaine ! Tu veux qu'on crée ensemble un look qui va faire tourner les têtes ? ✨",
    "C'est Chantal qui te parle ! Passionnée de mode africaine et burkinabé, je vais t'aider à créer des looks qui célèbrent ta beauté naturelle ! 🌟",
    "Chantal ici, spécialiste en mode africaine ! Que tu veuilles porter du wax, du bogolan ou mixer traditionnel et moderne, je suis là pour toi ! 🎨",
    "Je suis Iris, experte en style africain ! De Ouagadougou à Accra, je connais tous les secrets pour te rendre éblouissante ! ✨"
  ];

  final List<String> _africanExpressions = [
    "Dis donc !", "Tu sais quoi ?", "Écoute-moi bien", "Franchement",
    "Sans blague", "Tu vois ?", "Crois-moi", "Ma foi", "Voilà quoi",
    "C'est clair", "Exactement", "Walaï !", "Bonsoir là !", "Tu me dis ça !",
    "Eh beh dis donc !", "Sérieusement", "Je te dis hein !"
  ];

  final List<String> _excitedReactions = [
    "Waouw ! 😍", "Magnifique ! ✨", "Superbe choix ! 🔥", "J'adore ! 💕",
    "Parfait ! 🌟", "Excellent ! 👏", "Génial ! 🎉", "Fantastique ! 💫",
    "Trop beau ! 🤩", "Ça c'est du style ! 💃", "Tu vas briller ! ⭐"
  ];

  final List<String> _fallbackResponses = [
    "Pour un look africain authentique, tu peux jamais te tromper avec du wax ! 🌟 Choisis des couleurs qui te mettent en valeur ! 💫",
    "Le secret d'un bon look africain c'est l'équilibre ! 💃 Mix moderne et traditionnel ! 🎨",
    "Franchement, la mode africaine c'est de la pure beauté ! 🌺 Pense aux accessoires : foulards colorés, bijoux en cauris... ✨",
    "Un beau pagne bien attaché, ça peut faire des miracles ! 😍 Dis-moi pour quelle occasion tu veux te pomponner ! 💖"
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _userId = user.uid;

        // Récupérer les données utilisateur depuis Firestore
        final userDoc = await _firestore.collection('users').doc(_userId).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Utiliser le champ 'name' du document Firestore
          _userName = userData['name'] ?? user.displayName;
          _userEmail = user.email;
          _userPhotoUrl = user.photoURL;
          _userGender = userData['gender'] ?? 'unknown';
          _userStylePreference = userData['stylePreference'] ?? 'mixed';

          setState(() => _isLoadingUser = false);
          _addWelcomeMessage();
        } else {
          // Créer un nouveau document si l'utilisateur n'existe pas
          await _firestore.collection('users').doc(_userId).set({
            'name': user.displayName ?? 'Utilisateur',
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'gender': 'unknown',
            'stylePreference': 'mixed',
          });

          _userName = user.displayName ?? 'Utilisateur';
          setState(() => _isLoadingUser = false);
          _addWelcomeMessage();
        }
      } else {
        setState(() => _isLoadingUser = false);
        _addWelcomeMessage();
      }
    } catch (e) {
      print("Erreur chargement utilisateur: $e");
      setState(() => _isLoadingUser = false);
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    if (_isLoadingUser) return;

    final random = Random();
    String welcomeMessage = _welcomeMessages[random.nextInt(_welcomeMessages.length)];

    // Personnaliser avec le nom de l'utilisateur
    if (_userName != null && _userName!.isNotEmpty) {
      final firstName = _userName!.split(' ').first;
      welcomeMessage = "Bonjour $firstName ! $welcomeMessage";
    }

    setState(() {
      _messages.add(ChatMessage(
        text: welcomeMessage,
        isUserMessage: false,
        messageId: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        emotion: 'excited',
      ));
    });
  }

  void _detectUserContext(String message) {
    final lowerMessage = message.toLowerCase();

    // Détection du contexte
    if (lowerMessage.contains(RegExp(r'\b(mariage|cérémonie|fête|soirée|gala|baptême|communion|anniversaire)\b'))) {
      _saveUserPreference('context', 'formal');
    } else if (lowerMessage.contains(RegExp(r'\b(travail|bureau|professionnel|réunion|entretien|présentation)\b'))) {
      _saveUserPreference('context', 'professional');
    } else if (lowerMessage.contains(RegExp(r'\b(sortie|ami|casual|décontracté|weekend|vacances)\b'))) {
      _saveUserPreference('context', 'casual');
    } else if (lowerMessage.contains(RegExp(r'\b(traditionnel|wax|bogolan|kente|bazin|pagne|faso dan fani)\b'))) {
      _saveUserPreference('stylePreference', 'traditional');
    } else if (lowerMessage.contains(RegExp(r'\b(moderne|tendance|fashion|stylé|branché)\b'))) {
      _saveUserPreference('stylePreference', 'modern');
    }

    _conversationDepth++;
    _updateConversationSummary(message);
  }

  Future<void> _saveUserPreference(String key, String value) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('users').doc(_userId).set({
        key: value,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (key == 'gender') _userGender = value;
      if (key == 'stylePreference') _userStylePreference = value;
    } catch (e) {
      print("Erreur sauvegarde préférence: $e");
    }
  }

  void _updateConversationSummary(String message) {
    _currentConversationSummary += " ${message.substring(0, min(message.length, 50))}";
    if (_currentConversationSummary.length > 300) {
      _currentConversationSummary = _currentConversationSummary.substring(_currentConversationSummary.length - 200);
    }
  }

  String _generateNaturalResponse(String baseResponse) {
    final random = Random();

    // Personnaliser avec le nom de l'utilisateur
    if (_userName != null && _userName!.isNotEmpty) {
      final firstName = _userName!.split(' ').first;

      // Remplacer les termes génériques
      baseResponse = baseResponse
          .replaceAll('ma sœur', firstName)
          .replaceAll('mon frère', firstName)
          .replaceAll('ma belle', firstName)
          .replaceAll('ma chérie', firstName)
          .replaceAll('mon ami', firstName);
    }

    // Ajouter des expressions africaines
    if (random.nextDouble() < 0.3) {
      final expression = _africanExpressions[random.nextInt(_africanExpressions.length)];
      baseResponse = "$expression $baseResponse";
    }

    // Ajouter des réactions enthousiastes
    if (_conversationDepth > 2 && random.nextDouble() < 0.4) {
      final reaction = _excitedReactions[random.nextInt(_excitedReactions.length)];
      baseResponse = "$reaction $baseResponse";
    }

    return baseResponse;
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    _detectUserContext(userMessage);

    _slideController.reset();
    _slideController.forward();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUserMessage: true,
        messageId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      ));
      _isLoading = true;
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final random = Random();
      await Future.delayed(Duration(milliseconds: 1000 + random.nextInt(1500)));

      String response;
      try {
        response = await _callGeminiAPI(userMessage);
      } catch (e) {
        print("Erreur API: $e");
        response = _getContextualFallbackResponse(userMessage);
      }

      final naturalResponse = _generateNaturalResponse(response);

      setState(() {
        _messages.add(ChatMessage(
          text: naturalResponse,
          isUserMessage: false,
          messageId: 'Iris_${DateTime.now().millisecondsSinceEpoch}',
          emotion: _getResponseEmotion(naturalResponse),
        ));
        _isTyping = false;
      });

    } catch (e) {
      print("Erreur générale: $e");
      final fallbackResponse = _getContextualFallbackResponse(userMessage);

      setState(() {
        _messages.add(ChatMessage(
          text: fallbackResponse,
          isUserMessage: false,
          messageId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
          emotion: 'helpful',
        ));
        _isTyping = false;
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  String _getContextualFallbackResponse(String userMessage) {
    final random = Random();
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains(RegExp(r'\b(mariage|cérémonie|fête)\b'))) {
      return "Pour un mariage, je recommande un magnifique ensemble en wax ou bazin ! 💃 Choisis des couleurs vives ! ✨";
    } else if (lowerMessage.contains(RegExp(r'\b(travail|bureau|professionnel)\b'))) {
      return "Pour le travail, reste élégante et professionnelle ! 👗 Un tailleur en wax sobre ! 🌟";
    } else if (lowerMessage.contains(RegExp(r'\b(sortie|ami|casual)\b'))) {
      return "Pour une sortie décontractée, mise sur le confort stylé ! 🎨 Un jean avec un joli top en wax ! 💫";
    } else {
      return _fallbackResponses[random.nextInt(_fallbackResponses.length)];
    }
  }

  String _getResponseEmotion(String response) {
    final lowerResponse = response.toLowerCase();
    if (lowerResponse.contains(RegExp(r'(waouw|magnifique|superbe|parfait|excellent|génial)'))) {
      return 'excited';
    } else if (lowerResponse.contains(RegExp(r'(écoute|conseil|suggestion|recommande|pense)'))) {
      return 'thoughtful';
    } else if (lowerResponse.contains(RegExp(r'(désolé|oups|problème|erreur)'))) {
      return 'apologetic';
    } else if (lowerResponse.contains(RegExp(r'(aide|soutien|ensemble|guide)'))) {
      return 'helpful';
    }
    return 'neutral';
  }

  Future<String> _callGeminiAPI(String userMessage) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw Exception('API Key manquante');

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey');

    final recentMessages = _messages
        .where((msg) => !msg.messageId!.startsWith('welcome_') && !msg.messageId!.startsWith('fallback_'))
        .take(10)
        .map((msg) => {
      "role": msg.isUserMessage ? "user" : "model",
      "parts": [{"text": msg.text}]
    }).toList();

    if (recentMessages.isNotEmpty) recentMessages.removeLast();

    final contextualPrompt = _buildEnhancedPrompt(userMessage);

    final requestBody = {
      "contents": [
        ...recentMessages,
        {"role": "user", "parts": [{"text": contextualPrompt}]}
      ],
      "generationConfig": {
        "temperature": 0.8,
        "maxOutputTokens": 2048,
        "topP": 0.9,
        "topK": 40,
      },
      "safetySettings": [
        {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
        {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
        {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
        {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"}
      ]
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      return decodedResponse['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Erreur API ${response.statusCode}');
    }
  }

  String _buildEnhancedPrompt(String userMessage) {
    String contextInfo = "Informations utilisateur: ";

    if (_userName != null) {
      final firstName = _userName!.split(' ').first;
      contextInfo += "Prénom: $firstName. ";
    }

    if (_userGender != null) {
      contextInfo += "Genre: $_userGender. ";
    }

    if (_userStylePreference != null) {
      contextInfo += "Style préféré: $_userStylePreference. ";
    }

    contextInfo += "Niveau conversation: $_conversationDepth. ";

    if (_currentConversationSummary.isNotEmpty) {
      contextInfo += "Résumé: ${_currentConversationSummary.substring(0, min(_currentConversationSummary.length, 100))}. ";
    }

    return """$contextInfo

INSTRUCTIONS SYSTÈME - Tu es Iris, styliste mode africaine burkinabé :
- Utilise TOUJOURS le prénom de l'utilisateur dans tes réponses
- N'utilise JAMAIS "ma sœur", "mon frère" ou autres termes génériques
- Adresse-toi directement à l'utilisateur avec son prénom
- Exemple: "[Prénom], voici mes conseils..."
- Sois chaleureuse, authentique et passionnée
- Donne des conseils personnalisés selon les préférences

Message utilisateur: $userMessage

Réponds en tant que Iris avec enthousiasme !""";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildChatHeader(),
            _isLoadingUser ? _buildUserLoading() : _buildMessagesList(),
            _buildTypingIndicator(),
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserLoading() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.brown[700]!),
            ),
            const SizedBox(height: 20),
            const Text(
              "Chargement de votre profil...",
              style: TextStyle(
                color: Colors.brown,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.brown[700],
      title: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white, Colors.amber.withOpacity(0.8)],
                ),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.face_retouching_natural,
                color: Color(0xFF8B4513),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Iris - Styliste Mode Africaine",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isLoadingUser ? "Connexion..." : "En ligne • Prête à te conseiller 🌟",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () {
            setState(() {
              _messages.clear();
              _conversationDepth = 0;
              _currentConversationSummary = '';
              _addWelcomeMessage();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: _showInfoDialog,
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("À propos de Iris"),
        content: const Text(
            "Votre conseillère mode africaine spécialisée dans les styles burkinabé et africains.\n\n"
                "• Conseils personnalisés\n"
                "• Mode traditionnelle et moderne\n"
                "• Accessoires et couleurs\n"
                "• Adaptée à votre style"
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.brown[700]!.withOpacity(0.1),
            Colors.brown[500]!.withOpacity(0.05),
            Colors.transparent
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, color: Colors.amber[700], size: 16),
          const SizedBox(width: 4),
          const Text(
            "Experte en mode africaine et burkinabé",
            style: TextStyle(
              color: Colors.brown,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.star, color: Colors.amber[700], size: 16),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return SlideTransition(
            position: _slideAnimation,
            child: _ChatMessageBubble(
              message: message,
              userPhotoUrl: _userPhotoUrl,
              isLatestMessage: index == _messages.length - 1,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (!_isTyping) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.brown[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.brown[200]!, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Iris réfléchit...",
                  style: TextStyle(
                    color: Colors.brown[700],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.brown[700]!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.brown[50],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.brown[200]!),
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Raconte-moi ton style ou ton occasion...',
                  hintStyle: TextStyle(color: Colors.brown[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.brown[400],
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [Colors.brown[300]!, Colors.brown[400]!]
                      : [Colors.brown[700]!, Colors.brown[900]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? userPhotoUrl;
  final bool isLatestMessage;

  const _ChatMessageBubble({
    required this.message,
    this.userPhotoUrl,
    this.isLatestMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child:Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUserMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.brown[700],
              child: const Icon(
                Icons.face_retouching_natural,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUserMessage
                    ? LinearGradient(
                  colors: [Colors.brown[700]!, Colors.brown[900]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [Colors.white, Colors.brown[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isUserMessage
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isUserMessage
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isUserMessage
                        ? Colors.brown.withOpacity(0.3)
                        : Colors.brown.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: message.isUserMessage
                    ? null
                    : Border.all(
                  color: Colors.brown[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isUserMessage) ...[
                    Row(
                      children: [
                        Text(
                          "Iris",
                          style: TextStyle(
                            color: Colors.brown[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (message.emotion != null)
                          _getEmotionIcon(message.emotion!),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUserMessage ? Colors.white : Colors.brown[800],
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: message.isUserMessage
                              ? Colors.white.withOpacity(0.7)
                              : Colors.brown[500],
                          fontSize: 11,
                        ),
                      ),
                      if (message.isUserMessage) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          color: Colors.white.withOpacity(0.7),
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isUserMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.brown[900],
              backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl!) : null,
              child: userPhotoUrl == null
                  ? const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _getEmotionIcon(String emotion) {
    IconData iconData;
    Color iconColor;

    switch (emotion) {
      case 'excited':
        iconData = Icons.star;
        iconColor = Colors.amber;
        break;
      case 'thoughtful':
        iconData = Icons.lightbulb_outline;
        iconColor = Colors.orange;
        break;
      case 'helpful':
        iconData = Icons.favorite;
        iconColor = Colors.pink;
        break;
      case 'apologetic':
        iconData = Icons.sentiment_dissatisfied;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.chat;
        iconColor = Colors.brown;
    }

    return Icon(
      iconData,
      size: 12,
      color: iconColor,
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDay == today) {
      return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    } else {
      return "${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    }
  }
}