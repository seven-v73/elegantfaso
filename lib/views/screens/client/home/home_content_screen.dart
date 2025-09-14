import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreenContent extends StatefulWidget {
  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  // Chargement des variables d'environnement
  final String? _geminiApiKey = dotenv.env['GEMINI_API_KEY'];
  String get _geminiApiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_geminiApiKey';

  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data Streams
  StreamSubscription<DocumentSnapshot>? _userStream;
  StreamSubscription<DocumentSnapshot>? _missionsStream;

  // User Data
  User? _currentUser;
  UserData _userData = UserData();
  DailyMissions _todayMissions = DailyMissions.createDefault(DateFormat('yyyy-MM-dd').format(DateTime.now()));
  List<CreatorData> _creators = [];
  Map<String, dynamic>? _appConfig;
  List<Map<String, dynamic>> _fashionEvents = [];

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _bounceController;
  late AnimationController _rotateController;
  late AnimationController _streakController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _streakAnimation;

  // UI State
  bool _isLoading = true;
  bool _showSpecialOffers = false;
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  bool _isPremium = false;
  int _activeOfferIndex = 0;
  bool _hasMoreCreators = true;
  int _creatorsPage = 1;
  DocumentSnapshot? _lastCreator;
  bool _isLoadingCreators = false;
  bool _isShowingQuiz = false;
  Map<String, dynamic>? _currentQuiz;
  String? _currentMissionType;

  // Nouvelle palette de couleurs sobres et élégantes
  static const _indigoDeep = Color(0xFF2C387E);
  static const _earthBrown = Color(0xFF7D6E5D);
  static const _sandBeige = Color(0xFFD8C4A8);
  static const _clayRed = Color(0xFFA15843);
  static const _goldAccent = Color(0xFFC8A951);
  static const _ivory = Color(0xFFF8F5F0);
  static const _charcoal = Color(0xFF333333);
  static const _lightGrey = Color(0xFFE5E3DF);

  static const _primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_indigoDeep, Color(0xFF4A5CA8)],
  );

  static const _secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_earthBrown, Color(0xFF9C8A7A)],
  );

  static const _successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_goldAccent, Color(0xFFE1C46E)],
  );

  static const _premiumGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_indigoDeep, _goldAccent],
  );

  static const _primaryColor = _indigoDeep;
  static const _accentColor = _goldAccent;
  static const _cardRadius = 16.0;
  static const _smallRadius = 12.0;
  static const _spacing = 24.0;
  static const _smallSpacing = 16.0;

  // Cache pour éviter les répétitions de questions
  final Set<String> _usedQuestions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeUser();
    _loadAppConfig();
    _loadCreators();
    _loadFashionEvents();
    _loadUsedQuestions();
  }

  Future<void> _loadUsedQuestions() async {
    if (_currentUser == null) return;

    final snapshot = await _firestore.collection('used_questions').doc(_currentUser?.uid).get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final questions = data['questions'] as List<dynamic>? ?? [];
      setState(() {
        _usedQuestions.addAll(questions.cast<String>());
      });
    }
  }

  Future<void> _saveUsedQuestions() async {
    if (_currentUser == null) return;

    await _firestore.collection('used_questions').doc(_currentUser?.uid).set({
      'questions': _usedQuestions.toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _loadFashionEvents() async {
    try {
      final snapshot = await _firestore.collection('fashion_events').get();
      setState(() {
        _fashionEvents = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['name'] ?? 'Événement Mode',
            'date': data['date'] ?? '',
            'image': data['image'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading fashion events: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkUserStatus();
      _resetDailyMissionsIfNeeded();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeResources();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _streakController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _streakAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _streakController, curve: Curves.easeOut),
    );
  }

  void _initializeUser() async {
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _setupRealtimeListeners();
    _startCountdownTimer();

    if (mounted) {
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _slideController.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _progressController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _bounceController.forward();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadAppConfig() async {
    try {
      final doc = await _firestore.collection('app_config').doc('home_settings').get();
      if (doc.exists && mounted) {
        setState(() => _appConfig = doc.data());
      }
    } catch (e) {
      debugPrint('Error loading app config: $e');
    }
  }

  void _setupRealtimeListeners() {
    if (_currentUser == null) return;

    _userStream = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .snapshots()
        .handleError((e) => debugPrint('User stream error: $e'))
        .listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists && snapshot.data() != null) {
        final userData = UserData.fromMap(snapshot.data()!);
        setState(() {
          final wasPremium = _isPremium;
          _userData = userData;
          _isPremium = userData.isPremium;

          if (!wasPremium && _isPremium) {
            _streakController.forward(from: 0);
          }

          _checkUserStatus();
        });
      }
    });

    final today = _getFormattedDate();
    _missionsStream = _firestore
        .collection('daily_missions')
        .doc(_currentUser!.uid)
        .collection('missions')
        .doc(today)
        .snapshots()
        .handleError((e) => debugPrint('Missions stream error: $e'))
        .listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          _todayMissions = DailyMissions.fromMap(snapshot.data()!);
        });
      } else {
        _createDailyMissions(today);
      }
    });
  }

  Future<void> _loadCreators() async {
    if (!_hasMoreCreators || _isLoadingCreators) return;

    setState(() => _isLoadingCreators = true);

    try {
      Query query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'createur')
          .limit(10);

      if (_lastCreator != null) {
        query = query.startAfterDocument(_lastCreator!);
      }

      final result = await query.get();

      if (!mounted) return;

      if (result.docs.isNotEmpty) {
        _lastCreator = result.docs.last;
      }

      final newCreators = result.docs
          .map((doc) => CreatorData.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      setState(() {
        if (result.docs.length < 10) {
          _hasMoreCreators = false;
        }
        _creators.addAll(newCreators);
      });
    } catch (e) {
      debugPrint('Error loading creators: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCreators = false);
      }
    }
  }

  void _disposeResources() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.stop();
    _pulseController.dispose();
    _progressController.dispose();
    _bounceController.dispose();
    _rotateController.stop();
    _rotateController.dispose();
    _streakController.dispose();
    _userStream?.cancel();
    _missionsStream?.cancel();
    _countdownTimer?.cancel();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day + 1);
      if (!mounted) return;

      setState(() {
        _timeRemaining = midnight.difference(now);
        if (_timeRemaining.isNegative) {
          _timeRemaining = Duration.zero;
          _resetDailyMissions();
        }
      });
    });
  }

  Future<void> _createDailyMissions(String date) async {
    try {
      final missions = await _generateGeminiMissions();
      await _firestore
          .collection('daily_missions')
          .doc(_currentUser!.uid)
          .collection('missions')
          .doc(date)
          .set(missions.toMap());
    } catch (e) {
      debugPrint('Error creating daily missions: $e');
      final defaultMissions = _getFallbackMissions();
      await _firestore
          .collection('daily_missions')
          .doc(_currentUser!.uid)
          .collection('missions')
          .doc(date)
          .set(defaultMissions.toMap());
    }
  }

  Future<DailyMissions> _generateGeminiMissions() async {
    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      throw Exception('Gemini API key not configured');
    }

    try {
      final today = _getFormattedDate();

      final prompt = """
        En tant qu'expert en gamification pour une application de mode au Burkina Faso, 
        crée 3 missions quotidiennes personnalisées basées sur les principes "Job to be Done". 
        Chaque mission doit avoir:
        - Un titre accrocheur en français
        - Une description motivante
        - Un objectif numérique réaliste (entre 1 et 10)
        - Des points de récompense proportionnels (entre 10 et 30 points)
        - Pour chaque mission, inclure un quiz avec:
            * Une question thématique sur la mode africaine ou la culture burkinabè
            * 4 options de réponse
            * L'index de la bonne réponse (0 à 3)

        IMPORTANT: Les questions doivent être inédites et variées. 
        Évitez les répétitions des jours précédents. Voici quelques thèmes suggérés:

        1. Techniques de tissage traditionnel (ex: technique du bogolan)
        2. Symbolisme des motifs et couleurs dans la culture burkinabè
        3. Grands créateurs de mode contemporaine au Burkina Faso
        4. Événements et festivals de mode locaux (ex: FESPACO, SIAO)
        5. Matériaux et textiles locaux (ex: coton, fibres de baobab)
        6. Influence des ethnies (Mossi, Bobo, Lobi) sur les styles vestimentaires
        7. Accessoires traditionnels et leur signification
        8. Évolution historique des tenues traditionnelles
        9. Techniques de teinture naturelle avec des plantes locales
        10. Rôle social du vêtement dans les différentes communautés

        Format de réponse STRICTEMENT en JSON:
        {
          "discovery": {
            "title": "...", 
            "description": "...", 
            "target": 1, 
            "points": 20,
            "type": "quiz",
            "question": "...",
            "options": ["...", "...", "...", "..."],
            "correctAnswer": 0
          },
          "engagement": {
            "title": "...", 
            "description": "...", 
            "target": 1, 
            "points": 15,
            "type": "quiz",
            "question": "...",
            "options": ["...", "...", "...", "..."],
            "correctAnswer": 1
          },
          "learning": {
            "title": "...", 
            "description": "...", 
            "target": 1, 
            "points": 25,
            "type": "quiz",
            "question": "...",
            "options": ["...", "...", "...", "..."],
            "correctAnswer": 2
          }
        }
      """;

      final response = await http.post(
        Uri.parse(_geminiApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{"text": prompt}]
          }],
          "generationConfig": {
            "temperature": 0.9,
            "maxOutputTokens": 1000,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        final startIndex = content.indexOf('{');
        final endIndex = content.lastIndexOf('}');
        final jsonContent = content.substring(startIndex, endIndex + 1);
        final missionsData = jsonDecode(jsonContent);

        // CORRECTION : Conversion et vérification des questions
        final List<String> newQuestions = [
          missionsData['discovery']['question'].toString(),
          missionsData['engagement']['question'].toString(),
          missionsData['learning']['question'].toString()
        ];

        for (final question in newQuestions) {
          if (_usedQuestions.contains(question)) {
            throw Exception('Question déjà utilisée: $question');
          }
        }

        // Ajouter les nouvelles questions au cache
        setState(() {
          _usedQuestions.addAll(newQuestions);
        });
        await _saveUsedQuestions();

        return DailyMissions(
          date: today,
          discovery: {
            ...missionsData['discovery'],
            'progress': 0,
            'completed': false
          },
          engagement: {
            ...missionsData['engagement'],
            'progress': 0,
            'completed': false
          },
          learning: {
            ...missionsData['learning'],
            'progress': 0,
            'completed': false
          },
          bonusClaimed: false,
        );
      } else {
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gemini mission generation failed: $e');
      return _getFallbackMissions();
    }
  }

  DailyMissions _getFallbackMissions() {
    final today = _getFormattedDate();
    final defaultMissions = DailyMissions.createDefault(today);

    // Rotation des questions par défaut
    final questions = [
      {
        'question': 'Quelle est la signification du motif "zig-zag" dans le bogolan?',
        'options': ['La pluie', 'Le parcours de vie', 'La force', 'La fertilité'],
        'correctAnswer': 1
      },
      {
        'question': 'Quelle plante est traditionnellement utilisée pour la teinture jaune?',
        'options': ['Le néré', 'Le karité', "L'écorce de caïlcédrat", 'Le henné'],
        'correctAnswer': 2
      },
      {
        'question': 'Quel accessoire est typique de la tenue traditionnelle mossi?',
        'options': ['Le chapeau conique', 'Le collier de perles', 'Le bracelet en argent', 'La ceinture en cuir'],
        'correctAnswer': 0
      }
    ];

    return DailyMissions(
      date: today,
      discovery: {
        ...defaultMissions.discovery,
        'question': questions[0]['question'],
        'options': questions[0]['options'],
        'correctAnswer': questions[0]['correctAnswer'],
      },
      engagement: {
        ...defaultMissions.engagement,
        'question': questions[1]['question'],
        'options': questions[1]['options'],
        'correctAnswer': questions[1]['correctAnswer'],
      },
      learning: {
        ...defaultMissions.learning,
        'question': questions[2]['question'],
        'options': questions[2]['options'],
        'correctAnswer': questions[2]['correctAnswer'],
      },
      bonusClaimed: false,
    );
  }

  Future<void> _resetDailyMissions() async {
    await _createDailyMissions(_getFormattedDate());
  }

  void _resetDailyMissionsIfNeeded() {
    final lastMissionDate = _todayMissions.date;
    final today = _getFormattedDate();
    if (lastMissionDate != today) {
      _resetDailyMissions();
    }
  }

  void _checkUserStatus() {
    final daysSinceLastActivity = _userData.daysSinceLastActivity;

    if (daysSinceLastActivity >= 3) {
      _resetUserProgress();
      if (mounted) setState(() => _showSpecialOffers = true);
    }
    else if (daysSinceLastActivity >= 2) {
      if (mounted) setState(() => _showSpecialOffers = true);
      _applyStreakPenalty(daysSinceLastActivity);
    }
    else if (_userData.isCloseToLevelDown) {
      if (mounted) setState(() => _showSpecialOffers = true);
    }
  }

  void _resetUserProgress() async {
    final newData = _userData.copyWith(
      points: 0,
      totalPoints: 0,
      streak: 0,
      multiplier: 1.0,
      level: 'Apprenti',
      wardrobe: [],
    );

    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update(newData.toMap());

      if (mounted) {
        setState(() => _userData = newData);
      }
    } catch (e) {
      debugPrint('Error resetting user progress: $e');
    }
  }

  void _applyStreakPenalty(int days) {
    final penalty = math.min((days - 1) * 20, 100);
    final newPoints = math.max(0, _userData.points - penalty);
    final newData = _userData.copyWith(
      points: newPoints,
      streak: 0,
      multiplier: 1.0,
    );

    _updateUserData(newData);
  }

  Future<void> _updateUserData(UserData newData) async {
    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update(newData.toMap());

      if (mounted) {
        setState(() => _userData = newData);
      }
    } catch (e) {
      debugPrint('Error updating user data: $e');
    }
  }

  String _getFormattedDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  // Gestion des quiz
  void _showQuizDialog(String missionType, Map<String, dynamic> mission) {
    setState(() {
      _isShowingQuiz = true;
      _currentQuiz = mission;
      _currentMissionType = missionType;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Shimmer.fromColors(
          baseColor: _primaryColor,
          highlightColor: Colors.amber,
          child: Text(
            mission['title'] ?? 'Quiz Mode',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mission['question'] ?? 'Question de mode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _charcoal,
              ),
            ),
            const SizedBox(height: 20),
            ..._buildQuizOptions(mission),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isShowingQuiz = false;
                _currentMissionType = null;
              });
              Navigator.pop(context);
            },
            child: Text(
              'Passer',
              style: TextStyle(color: _primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildQuizOptions(Map<String, dynamic> mission) {
    final options = mission['options'] as List<dynamic>? ?? [];
    return options.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value as String;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ElevatedButton(
          onPressed: () => _checkQuizAnswer(mission, index),
          style: ElevatedButton.styleFrom(
            backgroundColor: _ivory,
            foregroundColor: _primaryColor,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _primaryColor.withOpacity(0.3)),
            ),
          ),
          child: Text(
            option,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
    }).toList();
  }

  void _checkQuizAnswer(Map<String, dynamic> mission, int selectedIndex) {
    final correctIndex = mission['correctAnswer'] as int? ?? 0;
    final isCorrect = selectedIndex == correctIndex;

    if (isCorrect) {
      final points = mission['points'] as int? ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bonne réponse! +$points points'),
          backgroundColor: Colors.green,
        ),
      );

      if (_currentMissionType != null) {
        _completeMission(_currentMissionType!);
      }

      Navigator.pop(context);
      setState(() => _isShowingQuiz = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mauvaise réponse, essayez encore!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isVerySmallScreen = mediaQuery.size.height < 600;

    return _isLoading
        ? _buildLoadingScreen()
        : MediaQuery(
      data: mediaQuery.copyWith(
        textScaleFactor: isVerySmallScreen
            ? math.min(mediaQuery.textScaleFactor, 0.9)
            : 1.0,
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          _progressController.reset();
          _bounceController.reset();
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            _progressController.forward();
            _bounceController.forward();
          }
          await _loadAppConfig();
          setState(() {
            _creatorsPage = 1;
            _hasMoreCreators = true;
            _creators.clear();
            _lastCreator = null;
          });
          await _loadCreators();
          await _loadFashionEvents();
        },
        color: _primaryColor,
        backgroundColor: _ivory,
        strokeWidth: 3,
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) => Opacity(
            opacity: _fadeAnimation.value,
            child: _buildMainContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_indigoDeep.withOpacity(0.9), _indigoDeep],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) => Transform.rotate(
                angle: _rotateAnimation.value * 2 * math.pi,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _goldAccent.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.stars,
                    color: _ivory,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                '✨ Chargement de votre univers mode ✨',
                style: TextStyle(
                  color: _ivory,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenHeight < 700;
        final screenWidth = constraints.maxWidth;
        final isNarrowScreen = screenWidth < 400;

        return Container(
          color: _ivory,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernSliverAppBar(isSmallScreen: isSmallScreen),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
                  child: Column(
                    children: [
                      if (_showSpecialOffers) ...[
                        SlideTransition(
                          position: _slideAnimation,
                          child: _buildDynamicOffersSection(),
                        ),
                        SizedBox(height: isSmallScreen ? 12.0 : _spacing),
                      ],
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildGamifiedMissionsSection(isSmallScreen: isSmallScreen),
                      ),
                      SizedBox(height: isSmallScreen ? 12.0 : _spacing),
                      _buildEnhancedProgressSection(isSmallScreen: isSmallScreen),
                      SizedBox(height: isSmallScreen ? 12.0 : _spacing),
                      _buildCulturalEventsSection(isSmallScreen: isSmallScreen),
                      SizedBox(height: isSmallScreen ? 12.0 : _spacing),
                      _buildFirebaseCreatorsSection(isSmallScreen: isSmallScreen),
                      SizedBox(height: isSmallScreen ? 12.0 : _spacing),
                      _buildAchievementsSection(isSmallScreen: isSmallScreen),
                      SizedBox(height: isSmallScreen ? 60.0 : 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernSliverAppBar({bool isSmallScreen = false}) {
    return SliverAppBar(
      expandedHeight: isSmallScreen ? 220 : (_isPremium ? 300 : 260),
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_indigoDeep, _indigoDeep.withOpacity(0.8)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildDynamicWelcomeHeader(isSmallScreen: isSmallScreen),
                  const SizedBox(height: 20),
                  _buildEnhancedQuickStats(isSmallScreen: isSmallScreen),
                  if (_isPremium) ...[
                    const SizedBox(height: 15),
                    _buildPremiumBadge(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _goldAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _goldAccent, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: _goldAccent, size: 18),
          const SizedBox(width: 6),
          Text(
            'Membre Premium',
            style: TextStyle(
              color: _ivory,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicWelcomeHeader({bool isSmallScreen = false}) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _userData.levelIcon,
              color: _ivory,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_getGreeting()} ',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 20,
                        color: _ivory.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _userData.level,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: _ivory,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _goldAccent.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_userData.points} pts',
                        style: TextStyle(
                          color: _ivory,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _clayRed.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department, color: _ivory, size: isSmallScreen ? 14 : 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_userData.streak}',
                            style: TextStyle(
                              color: _ivory,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_userData.multiplier > 1.0)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: _goldAccent.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _goldAccent.withOpacity(0.5)),
                  ),
                  child: Text(
                    'x${_userData.multiplier.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: _ivory,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickStats({bool isSmallScreen = false}) {
    final stats = [
      {'icon': Icons.emoji_events, 'title': 'Niveau', 'value': _userData.level, 'color': _goldAccent},
      {'icon': Icons.local_fire_department, 'title': 'Série', 'value': '${_userData.streak}j', 'color': _clayRed},
      {'icon': Icons.stars, 'title': 'Total', 'value': _formatNumber(_userData.totalPoints), 'color': _indigoDeep},
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: index == stats.length - 1 ? 0 : 8,
            ),
            child: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) => Transform.scale(
                scale: 0.8 + (_bounceAnimation.value * 0.2),
                child: Opacity(
                  opacity: _bounceAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 10), // Further reduced padding
                    decoration: BoxDecoration(
                      color: (stat['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(_smallRadius),
                      border: Border.all(color: (stat['color'] as Color).withOpacity(0.3)),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            stat['icon'] as IconData,
                            color: stat['color'] as Color,
                            size: isSmallScreen ? 14 : 18, // Further reduced icon size
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4), // Further reduced spacing
                          Flexible(
                            child: Text(
                              stat['value'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 11 : 13, // Further reduced font size
                                color: _charcoal,
                                height: 1.0, // Tight line height
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 1 : 2), // Minimal spacing
                          Flexible(
                            child: Text(
                              stat['title'] as String,
                              style: TextStyle(
                                color: _charcoal.withOpacity(0.6),
                                fontSize: isSmallScreen ? 8 : 9, // Further reduced font size
                                height: 1.0, // Tight line height
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDynamicOffersSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _earthBrown.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _earthBrown.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _earthBrown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _earthBrown.withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.flash_on,
                      color: _earthBrown,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Offres Spéciales',
                  style: TextStyle(
                    color: _charcoal,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _earthBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _formatTimeRemaining(),
                  style: TextStyle(
                    color: _earthBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEnhancedOfferButtons(),
        ],
      ),
    );
  }

  Widget _buildEnhancedOfferButtons() {
    final offers = [
      {
        'title': 'Récupération',
        'subtitle': '30 pts + Série',
        'price': '100 FCFA',
        'color': _goldAccent,
        'onPressed': () => _handleRecoveryPurchase(),
      },
      {
        'title': 'Tissu Bogolan',
        'subtitle': 'Nouveau tissu virtuel',
        'price': '500 FCFA',
        'color': _clayRed,
        'onPressed': () => _handleFabricPurchase(),
      },
      if (_appConfig?['show_premium_offer'] == true)
        {
          'title': 'Premium',
          'subtitle': 'Accès exclusif',
          'price': '1500 FCFA',
          'color': _indigoDeep,
          'onPressed': () => _handlePremiumPurchase(),
        },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: offers.map((offer) => Container(
          width: 180,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: (offer['color'] as Color).withOpacity(0.05),
            borderRadius: BorderRadius.circular(_smallRadius),
            border: Border.all(color: (offer['color'] as Color).withOpacity(0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: offer['onPressed'] as VoidCallback?,
              borderRadius: BorderRadius.circular(_smallRadius),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      offer['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: offer['color'] as Color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer['subtitle'] as String,
                      style: TextStyle(
                        color: _charcoal.withOpacity(0.7),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (offer['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: (offer['color'] as Color).withOpacity(0.3)),
                      ),
                      child: Text(
                        offer['price'] as String,
                        style: TextStyle(
                          color: offer['color'] as Color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildGamifiedMissionsSection({bool isSmallScreen = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : _cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmallScreen ? 12.0 : _cardRadius),
                topRight: Radius.circular(isSmallScreen ? 12.0 : _cardRadius),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Missions Quotidiennes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimeRemaining(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
            child: Column(
              children: [
                _MissionTile(
                  type: 'discovery',
                  icon: Icons.style,
                  color: _primaryColor,
                  emoji: '👗',
                  mission: _todayMissions.getMission('discovery'),
                  pulseAnimation: _pulseAnimation,
                  onComplete: _completeMission,
                  showQuiz: _showQuizDialog,
                  isQuiz: _todayMissions.getMission('discovery')['type'] == 'quiz',
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8.0 : _smallSpacing),
                _MissionTile(
                  type: 'engagement',
                  icon: Icons.favorite_outline,
                  color: _earthBrown,
                  emoji: '❤️',
                  mission: _todayMissions.getMission('engagement'),
                  pulseAnimation: _pulseAnimation,
                  onComplete: _completeMission,
                  showQuiz: _showQuizDialog,
                  isQuiz: _todayMissions.getMission('engagement')['type'] == 'quiz',
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8.0 : _smallSpacing),
                _MissionTile(
                  type: 'learning',
                  icon: Icons.school_outlined,
                  color: _goldAccent,
                  emoji: '🎓',
                  mission: _todayMissions.getMission('learning'),
                  pulseAnimation: _pulseAnimation,
                  onComplete: _completeMission,
                  showQuiz: _showQuizDialog,
                  isQuiz: _todayMissions.getMission('learning')['type'] == 'quiz',
                  isSmallScreen: isSmallScreen,
                ),
                if (_todayMissions.canClaimBonus) ...[
                  SizedBox(height: isSmallScreen ? 8.0 : _smallSpacing),
                  _buildDynamicBonusSection(isSmallScreen: isSmallScreen),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeMission(String missionType) async {
    // Sauvegarder l'état actuel pour restauration en cas d'erreur
    final oldMissions = _todayMissions;
    final oldUserData = _userData;

    try {
      setState(() {
        // Mettre à jour la progression localement
        final mission = _todayMissions.getMission(missionType);
        final newProgress = (mission['progress'] as int) + 1;
        final target = mission['target'] as int;
        final isCompleted = newProgress >= target;

        // Mettre à jour l'objet de mission
        _todayMissions = _todayMissions.copyWithMission(
          missionType,
          newProgress,
          isCompleted,
        );

        // Mettre à jour les points si mission complétée
        if (isCompleted) {
          final points = mission['points'] as int;
          final newStreak = _userData.streak + 1;
          final newMultiplier = 1.0 + (newStreak ~/ 7) * 0.1;

          _userData = _userData.copyWith(
            points: _userData.points + points,
            totalPoints: _userData.totalPoints + points,
            streak: newStreak,
            multiplier: newMultiplier,
            lastActiveDate: DateTime.now(),
          );
        }
      });

      // Envoyer la mise à jour à Firebase
      final today = _getFormattedDate();
      final missionRef = _firestore
          .collection('daily_missions')
          .doc(_currentUser!.uid)
          .collection('missions')
          .doc(today);

      await missionRef.update({
        '$missionType.progress': FieldValue.increment(1),
        '$missionType.completed': _todayMissions.getMission(missionType)['completed'],
      });

      // Si mission complétée, mettre à jour Firestore
      if (_todayMissions.getMission(missionType)['completed']) {
        final mission = _todayMissions.getMission(missionType);
        final points = mission['points'] as int;

        await _firestore.collection('users').doc(_currentUser!.uid).update({
          'points': FieldValue.increment(points),
          'totalPoints': FieldValue.increment(points),
          'streak': FieldValue.increment(1),
          'multiplier': 1.0 + ((_userData.streak) ~/ 7) * 0.1,
          'lastActiveDate': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Restaurer l'état précédent en cas d'erreur
      setState(() {
        _todayMissions = oldMissions;
        _userData = oldUserData;
      });
      debugPrint('Error completing mission: $e');
    }
  }

  Widget _buildDynamicBonusSection({bool isSmallScreen = false}) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            color: _goldAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_smallRadius),
            border: Border.all(color: _goldAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _goldAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonus Spécial Disponible !',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Toutes les missions terminées +50 pts',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _claimDailyBonus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _goldAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Récupérer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedProgressSection({bool isSmallScreen = false}) {
    final progress = _userData.levelProgress;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: _primaryColor,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Progression vers ${_userData.nextLevel}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: _charcoal,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) => Column(
              children: [
                LinearProgressIndicator(
                  value: _progressAnimation.value * progress,
                  backgroundColor: _lightGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  minHeight: isSmallScreen ? 8 : 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatNumber(_userData.points)} pts',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: _charcoal.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '${_formatNumber(_userData.nextLevelThreshold)} pts',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: _charcoal.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(_smallRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: _primaryColor,
                  size: isSmallScreen ? 18 : 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Plus que ${_formatNumber(_userData.nextLevelThreshold - _userData.points)} points pour passer ${_userData.nextLevel}!',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Naviguer vers l'écran du dressing
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _earthBrown,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Voir mon dressing virtuel',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCulturalEventsSection({bool isSmallScreen = false}) {
    if (_fashionEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _earthBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.event, color: _earthBrown, size: isSmallScreen ? 20 : 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Événements Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: isSmallScreen ? 150 : 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _fashionEvents.length,
              itemBuilder: (context, index) {
                final event = _fashionEvents[index];
                return Container(
                  width: isSmallScreen ? 150 : 180,
                  margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: event['image'] != null && event['image'].isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(event['image']),
                      fit: BoxFit.cover,
                    )
                        : null,
                    color: _lightGrey,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          event['name'] as String? ?? 'Événement',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        Text(
                          event['date'] as String? ?? '',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseCreatorsSection({bool isSmallScreen = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_cardRadius),
                topRight: Radius.circular(_cardRadius),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Créateurs Burkinabè',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${_creators.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _creators.isEmpty && _isLoadingCreators
              ? _buildCreatorsLoading()
              : _creators.isEmpty
              ? _buildNoCreators()
              : Column(
            children: [
              ..._creators.asMap().entries.map((entry) {
                final index = entry.key;
                final creator = entry.value;
                return _CreatorTile(
                  creator: creator,
                  rank: index + 1,
                  primaryColor: _primaryColor,
                  isSmallScreen: isSmallScreen,
                );
              }),
              if (_hasMoreCreators)
                _buildLoadMoreButton(isSmallScreen: isSmallScreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorsLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: _lightGrey,
        highlightColor: Colors.white,
        child: Column(
          children: List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildNoCreators() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 64, color: _lightGrey),
          const SizedBox(height: 16),
          Text(
            'Aucun créateur trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _charcoal.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Revenez plus tard pour découvrir les créateurs',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _charcoal.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton({bool isSmallScreen = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isLoadingCreators ? null : () {
          setState(() => _creatorsPage++);
          _loadCreators();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isLoadingCreators
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          'Charger plus de créateurs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection({bool isSmallScreen = false}) {
    final recentAchievements = _userData.recentAchievements.take(3).toList();

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _goldAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.military_tech,
                  color: _goldAccent,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Succès Débloqués',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recentAchievements.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _lightGrey,
                borderRadius: BorderRadius.circular(_smallRadius),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 48, color: _charcoal.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text(
                      'Complétez des missions pour débloquer des succès !',
                      style: TextStyle(
                        color: _charcoal.withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentAchievements.map((achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(_smallRadius),
                  border: Border.all(color: _primaryColor.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Text(
                      achievement.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                              color: _charcoal,
                            ),
                          ),
                          Text(
                            achievement.description,
                            style: TextStyle(
                              color: _charcoal.withOpacity(0.7),
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '+${achievement.points}',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
        ],
      ),
    );
  }

  // Helper Methods
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 17) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatTimeRemaining() {
    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  // Action Methods
  Future<void> _handleRecoveryPurchase() async {
    try {
      final newPoints = _userData.points + 30;
      final newStreak = _userData.streak + 1;
      final newData = _userData.copyWith(
        points: newPoints,
        totalPoints: _userData.totalPoints + 30,
        streak: newStreak,
      );

      await _updateUserData(newData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Achat réussi ! 30 points ajoutés et série augmentée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleFabricPurchase() async {
    try {
      final newItem = 'bogolan_bf_001';
      final newWardrobe = [..._userData.wardrobe, newItem];
      final newData = _userData.copyWith(wardrobe: newWardrobe);

      await _updateUserData(newData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tissu Bogolan ajouté à votre dressing !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handlePremiumPurchase() async {
    try {
      final newData = _userData.copyWith(
        isPremium: true,
        premiumExpiry: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      );

      await _updateUserData(newData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Félicitations ! Vous êtes maintenant membre Premium'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _claimDailyBonus() async {
    try {
      final bonusPoints = 50;
      final newData = _userData.copyWith(
        points: _userData.points + bonusPoints,
        totalPoints: _userData.totalPoints + bonusPoints,
      );

      await _updateUserData(newData);

      final today = _getFormattedDate();
      await _firestore
          .collection('daily_missions')
          .doc(_currentUser!.uid)
          .collection('missions')
          .doc(today)
          .update({'bonusClaimed': true});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bonus de 50 points récupéré avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _MissionTile extends StatelessWidget {
  final String type;
  final IconData icon;
  final Color color;
  final String emoji;
  final Map<String, dynamic> mission;
  final Animation<double> pulseAnimation;
  final Function(String) onComplete;
  final Function(String, Map<String, dynamic>) showQuiz;
  final bool isQuiz;
  final bool isSmallScreen;

  const _MissionTile({
    required this.type,
    required this.icon,
    required this.color,
    required this.emoji,
    required this.mission,
    required this.pulseAnimation,
    required this.onComplete,
    required this.showQuiz,
    required this.isQuiz,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (mission['progress'] as int?) ?? 0;
    final target = (mission['target'] as int?) ?? 1;
    final isCompleted = (mission['completed'] as bool?) ?? false;
    final progressPercent = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrowScreen = constraints.maxWidth < 400;

          return GestureDetector(
            onTap: isCompleted ? null : () {
              if (isQuiz) {
                showQuiz(type, mission);
              } else {
                onComplete(type);
              }
            },
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) => Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
                decoration: BoxDecoration(
                  color: isCompleted ? color.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted ? color : const Color(0xFFE5E3DF),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                          decoration: BoxDecoration(
                            color: isCompleted ? color.withOpacity(0.2) : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            icon,
                            color: isCompleted ? color : color.withOpacity(0.7),
                            size: isSmallScreen ? 18 : 22,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isQuiz ? '❓' : emoji,
                                    style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                                  ),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  Expanded(
                                    child: Text(
                                      mission['title'] ?? _getMissionTitle(type),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isNarrowScreen ? 13 : (isSmallScreen ? 14 : 15),
                                        color: isCompleted ? color : const Color(0xFF333333),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 4 : 6),
                              Text(
                                isQuiz
                                    ? 'Quiz - ${progress > 0 ? 'Déjà tenté' : 'À compléter'}'
                                    : '$progress / $target ${_getMissionUnit(type)}',
                                style: TextStyle(
                                  color: isCompleted ? color.withOpacity(0.7) : const Color(0xFF666666),
                                  fontSize: isNarrowScreen ? 11 : (isSmallScreen ? 12 : 13),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isCompleted)
                          AnimatedBuilder(
                            animation: pulseAnimation,
                            builder: (context, child) => Transform.scale(
                              scale: pulseAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  color: color,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: isCompleted ? color.withOpacity(0.2) : const Color(0xFFE5E3DF),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: isSmallScreen ? 5 : 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  String _getMissionTitle(String type) {
    switch (type) {
      case 'discovery': return 'Explorer styles';
      case 'engagement': return 'Aimer créations';
      case 'learning': return 'Apprendre mode';
      default: return 'Mission';
    }
  }

  String _getMissionUnit(String type) {
    switch (type) {
      case 'discovery': return 'styles';
      case 'engagement': return 'créations';
      case 'learning': return 'min';
      default: return 'actions';
    }
  }
}

class _CreatorTile extends StatelessWidget {
  final CreatorData creator;
  final int rank;
  final Color primaryColor;
  final bool isSmallScreen;

  const _CreatorTile({
    required this.creator,
    required this.rank,
    required this.primaryColor,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final rankColors = [
      const Color(0xFFFFD700), // Or
      const Color(0xFFC0C0C0), // Argent
      const Color(0xFFCD7F32), // Bronze
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: rank <= 3 ? rankColors[rank - 1].withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank <= 3 ? rankColors[rank - 1].withOpacity(0.2) : const Color(0xFFE5E3DF),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 30 : 36,
            height: isSmallScreen ? 30 : 36,
            decoration: BoxDecoration(
              color: rank <= 3 ? rankColors[rank - 1].withOpacity(0.2) : primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 15 : 18),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank <= 3 ? rankColors[rank - 1] : primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          CircleAvatar(
            radius: isSmallScreen ? 18 : 22,
            backgroundImage: creator.profilePicture != null
                ? NetworkImage(creator.profilePicture!)
                : null,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: creator.profilePicture == null
                ? Icon(Icons.person, color: primaryColor, size: isSmallScreen ? 18 : 22)
                : null,
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 16,
                    color: const Color(0xFF333333),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  '${_formatNumber(creator.followersCount)} abonnés',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                )
              ],
            ),
          ),
          if (rank <= 3)
            Icon(
              Icons.emoji_events,
              color: rankColors[rank - 1],
              size: isSmallScreen ? 20 : 24,
            ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

// Classes de données
class UserData {
  final int points;
  final int totalPoints;
  final int streak;
  final double multiplier;
  final String level;
  final List<Achievement> recentAchievements;
  final bool isPremium;
  final String? premiumExpiry;
  final DateTime? lastActiveDate;
  final List<String> wardrobe;

  UserData({
    this.points = 0,
    this.totalPoints = 0,
    this.streak = 0,
    this.multiplier = 1.0,
    this.level = 'Apprenti',
    this.recentAchievements = const [],
    this.isPremium = false,
    this.premiumExpiry,
    this.lastActiveDate,
    this.wardrobe = const [],
  });

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      points: (map['points'] as num?)?.toInt() ?? 0,
      totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      multiplier: (map['multiplier'] as num?)?.toDouble() ?? 1.0,
      level: map['level'] as String? ?? 'Apprenti',
      recentAchievements: (map['recentAchievements'] is List)
          ? (map['recentAchievements'] as List).map((e) => Achievement.fromMap(e as Map<String, dynamic>)).toList()
          : [],
      isPremium: map['isPremium'] as bool? ?? false,
      premiumExpiry: map['premiumExpiry'] as String?,
      lastActiveDate: map['lastActiveDate'] != null
          ? DateTime.tryParse(map['lastActiveDate'] as String)
          : null,
      wardrobe: List<String>.from(map['wardrobe'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'points': points,
      'totalPoints': totalPoints,
      'streak': streak,
      'multiplier': multiplier,
      'level': level,
      'recentAchievements': recentAchievements.map((e) => e.toMap()).toList(),
      'isPremium': isPremium,
      'premiumExpiry': premiumExpiry,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'wardrobe': wardrobe,
    };
  }

  UserData copyWith({
    int? points,
    int? totalPoints,
    int? streak,
    double? multiplier,
    String? level,
    List<Achievement>? recentAchievements,
    bool? isPremium,
    String? premiumExpiry,
    DateTime? lastActiveDate,
    List<String>? wardrobe,
  }) {
    return UserData(
      points: points ?? this.points,
      totalPoints: totalPoints ?? this.totalPoints,
      streak: streak ?? this.streak,
      multiplier: multiplier ?? this.multiplier,
      level: level ?? this.level,
      recentAchievements: recentAchievements ?? this.recentAchievements,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      wardrobe: wardrobe ?? this.wardrobe,
    );
  }

  IconData get levelIcon {
    switch (level) {
      case 'Apprenti': return Icons.star_border;
      case 'Styliste': return Icons.star_half;
      case 'Designer': return Icons.star;
      case 'Maître Tailleur': return Icons.stars;
      default: return Icons.star_border;
    }
  }

  String get nextLevel {
    switch (level) {
      case 'Apprenti': return 'Styliste';
      case 'Styliste': return 'Designer';
      case 'Designer': return 'Maître Tailleur';
      case 'Maître Tailleur': return 'Légende';
      default: return 'Styliste';
    }
  }

  int get nextLevelThreshold {
    switch (level) {
      case 'Apprenti': return 1000;
      case 'Styliste': return 2500;
      case 'Designer': return 5000;
      case 'Maître Tailleur': return 10000;
      default: return 1000;
    }
  }

  int get currentLevelThreshold {
    switch (level) {
      case 'Apprenti': return 0;
      case 'Styliste': return 1000;
      case 'Designer': return 2500;
      case 'Maître Tailleur': return 5000;
      default: return 0;
    }
  }

  double get levelProgress {
    final next = nextLevelThreshold - currentLevelThreshold;
    return next > 0 ? (points - currentLevelThreshold) / next : 0.0;
  }

  int get daysSinceLastActivity {
    if (lastActiveDate == null) return 0;
    final now = DateTime.now();
    return now.difference(lastActiveDate!).inDays;
  }

  bool get isCloseToLevelDown {
    return levelProgress < 0.2 && points > 100;
  }
}

class DailyMissions {
  final String date;
  final Map<String, dynamic> discovery;
  final Map<String, dynamic> engagement;
  final Map<String, dynamic> learning;
  final bool bonusClaimed;

  DailyMissions({
    required this.date,
    required this.discovery,
    required this.engagement,
    required this.learning,
    this.bonusClaimed = false,
  });

  factory DailyMissions.createDefault(String date) {
    return DailyMissions(
      date: date,
      discovery: {
        'type': 'quiz',
        'title': 'Explorer les nouvelles tendances',
        'description': 'Découvrez 5 nouvelles créations',
        'target': 1,
        'progress': 0,
        'completed': false,
        'points': 20,
        'question': 'Quel est le tissu traditionnel du Burkina Faso?',
        'options': ['Kente', 'Bogolan', 'Dashiki', 'Bazin'],
        'correctAnswer': 1
      },
      engagement: {
        'type': 'quiz',
        'title': 'Quiz Mode Africaine',
        'description': 'Testez vos connaissances',
        'target': 1,
        'progress': 0,
        'completed': false,
        'points': 30,
        'question': 'Quelle technique utilise-t-on pour teindre le bogolan?',
        'options': ['Batik', 'Réserve à la boue', 'Tie-dye', 'Shibori'],
        'correctAnswer': 1
      },
      learning: {
        'type': 'quiz',
        'title': 'Apprendre une technique',
        'description': 'Consacrez 15 minutes à apprendre',
        'target': 1,
        'progress': 0,
        'completed': false,
        'points': 25,
        'question': 'Combien de temps faut-il pour sécher un bogolan traditionnel?',
        'options': ['1 jour', '1 semaine', '2 semaines', '1 mois'],
        'correctAnswer': 2
      },
    );
  }

  factory DailyMissions.fromMap(Map<String, dynamic> map) {
    return DailyMissions(
      date: map['date'] as String? ?? '',
      discovery: _parseMissionMap(map['discovery'], 'discovery'),
      engagement: _parseMissionMap(map['engagement'], 'engagement'),
      learning: _parseMissionMap(map['learning'], 'learning'),
      bonusClaimed: map['bonusClaimed'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _parseMissionMap(dynamic data, String type) {
    if (data is! Map<String, dynamic>) {
      return {
        'type': 'quiz',
        'title': 'Mission $type',
        'description': 'Description par défaut',
        'target': 1,
        'progress': 0,
        'completed': false,
        'points': 20,
        'question': 'Question par défaut',
        'options': ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        'correctAnswer': 0
      };
    }

    return {
      'type': data['type'] as String? ?? 'quiz',
      'title': data['title'] as String? ?? 'Mission $type',
      'description': data['description'] as String? ?? 'Description par défaut',
      'target': data['target'] as int? ?? 1,
      'progress': data['progress'] as int? ?? 0,
      'completed': data['completed'] as bool? ?? false,
      'points': data['points'] as int? ?? 20,
      'question': data['question'] as String? ?? 'Question par défaut',
      'options': data['options'] as List<dynamic>? ?? ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
      'correctAnswer': data['correctAnswer'] as int? ?? 0,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'discovery': discovery,
      'engagement': engagement,
      'learning': learning,
      'bonusClaimed': bonusClaimed,
    };
  }

  Map<String, dynamic> getMission(String type) {
    switch (type) {
      case 'discovery': return discovery;
      case 'engagement': return engagement;
      case 'learning': return learning;
      default: return {
        'title': 'Mission $type',
        'description': 'Description',
        'target': 1,
        'progress': 0,
        'completed': false,
        'points': 10
      };
    }
  }

  bool get canClaimBonus {
    return (discovery['completed'] as bool? ?? false) &&
        (engagement['completed'] as bool? ?? false) &&
        (learning['completed'] as bool? ?? false) &&
        !bonusClaimed;
  }

  DailyMissions copyWithMission(String type, int newProgress, bool isCompleted) {
    final mission = getMission(type);
    final updatedMission = {
      ...mission,
      'progress': newProgress,
      'completed': isCompleted,
    };

    return DailyMissions(
      date: date,
      discovery: type == 'discovery' ? updatedMission : discovery,
      engagement: type == 'engagement' ? updatedMission : engagement,
      learning: type == 'learning' ? updatedMission : learning,
      bonusClaimed: bonusClaimed,
    );
  }
}

class CreatorData {
  final String id;
  final String displayName;
  final String? profilePicture;
  final int totalPoints;
  final int followersCount;
  final bool isActive;
  final String specialty;

  CreatorData({
    required this.id,
    required this.displayName,
    this.profilePicture,
    required this.totalPoints,
    required this.followersCount,
    this.isActive = true,
    this.specialty = 'Mode',
  });

  factory CreatorData.fromMap(Map<String, dynamic> map, String id) {
    return CreatorData(
      id: id,
      displayName: map['name'] as String? ?? 'Créateur Burkinabè',
      profilePicture: map['photoUrl'] as String?,
      totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
      followersCount: (map['followersCount'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      specialty: map['specialty'] as String? ?? 'Mode traditionnelle',
    );
  }
}

class Achievement {
  final String title;
  final String description;
  final String emoji;
  final int points;
  final DateTime unlockedAt;

  Achievement({
    required this.title,
    required this.description,
    required this.emoji,
    required this.points,
    required this.unlockedAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '🏆',
      points: (map['points'] as num?)?.toInt() ?? 0,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['unlockedAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'emoji': emoji,
      'points': points,
      'unlockedAt': unlockedAt.millisecondsSinceEpoch,
    };
  }
}