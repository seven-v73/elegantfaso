import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';
import 'dart:convert';

// Configuration
const String geminiApiKey = 'AIzaSyDE3pGduZJpJFyMkCGdPFRbvWbx5Jm8yTY'; // Remplacer par votre clé Gemini

// Modèles de données
class UserProfile {
  final String uid;
  final int currentStreak;
  final int totalPoints;
  final DateTime? lastStyleCheck;
  final List<String> unlockedBadges;
  final int maxStreak;
  final String? profileImageUrl;
  final Map<String, dynamic> learningProgress;

  UserProfile({
    required this.uid,
    required this.currentStreak,
    required this.totalPoints,
    this.lastStyleCheck,
    required this.unlockedBadges,
    required this.maxStreak,
    this.profileImageUrl,
    required this.learningProgress,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      currentStreak: data['currentStreak'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
      lastStyleCheck: data['lastStyleCheck']?.toDate(),
      unlockedBadges: List<String>.from(data['unlockedBadges'] ?? []),
      maxStreak: data['maxStreak'] ?? 0,
      profileImageUrl: data['profileImageUrl'],
      learningProgress: Map<String, dynamic>.from(data['learningProgress'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currentStreak': currentStreak,
      'totalPoints': totalPoints,
      'lastStyleCheck': lastStyleCheck,
      'unlockedBadges': unlockedBadges,
      'maxStreak': maxStreak,
      'profileImageUrl': profileImageUrl,
      'learningProgress': learningProgress,
    };
  }
}

class DailyOutfit {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String weather;
  final String occasion;
  final List<Color> colors;
  final DateTime date;
  final String? stylistName;
  final String? stylistPhoto;

  DailyOutfit({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.weather,
    required this.occasion,
    required this.colors,
    required this.date,
    this.stylistName,
    this.stylistPhoto,
  });

  factory DailyOutfit.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return DailyOutfit(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      weather: data['weather'] ?? '',
      occasion: data['occasion'] ?? '',
      colors: (data['colors'] as List<dynamic>?)
          ?.map((color) => Color(color as int))
          .toList() ?? [],
      date: data['date']?.toDate() ?? DateTime.now(),
      stylistName: data['stylistName'],
      stylistPhoto: data['stylistPhoto'],
    );
  }
}

class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final DateTime endDate;
  final int participants;
  final int submissions;
  final String prize;

  WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.endDate,
    required this.participants,
    required this.submissions,
    required this.prize,
  });

  int get daysLeft {
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  factory WeeklyChallenge.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return WeeklyChallenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      endDate: data['endDate']?.toDate() ?? DateTime.now(),
      participants: data['participants'] ?? 0,
      submissions: data['submissions'] ?? 0,
      prize: data['prize'] ?? 'Badge exclusif',
    );
  }
}

class Achievement {
  final String id;
  final String name;
  final String emoji;
  final int requiredStreak;
  final String description;
  final int points;
  final String? rewardDescription;

  Achievement({
    required this.id,
    required this.name,
    required this.emoji,
    required this.requiredStreak,
    required this.description,
    required this.points,
    this.rewardDescription,
  });

  static List<Achievement> getAchievements() {
    return [
      Achievement(
          id: 'style_beginner',
          name: 'Style Débutant',
          emoji: '🌟',
          requiredStreak: 1,
          description: 'Premier pas vers l\'élégance',
          points: 10,
          rewardDescription: 'Accès aux conseils de base'),
      Achievement(
          id: 'style_regular',
          name: 'Style Régulier',
          emoji: '✨',
          requiredStreak: 3,
          description: 'Constance dans le style',
          points: 25,
          rewardDescription: '10% de réduction chez nos partenaires'),
      Achievement(
          id: 'style_elite',
          name: 'Style Élite',
          emoji: '🏆',
          requiredStreak: 5,
          description: 'Excellence vestimentaire',
          points: 50,
          rewardDescription: 'Consultation gratuite avec un styliste'),
      Achievement(
          id: 'style_master',
          name: 'Style Master',
          emoji: '👑',
          requiredStreak: 10,
          description: 'Maîtrise parfaite',
          points: 100,
          rewardDescription: 'Tenue VIP personnalisée'),
      Achievement(
          id: 'style_legend',
          name: 'Style Legend',
          emoji: '🔥',
          requiredStreak: 30,
          description: 'Légende du style',
          points: 300,
          rewardDescription: 'Forfait shopping complet'),
    ];
  }
}

class LearningModule {
  final String id;
  final String title;
  final String category;
  final int difficulty;
  final String content;
  final List<String> keyConcepts;
  final List<QuizQuestion> quizQuestions;
  final String geminiPrompt;

  LearningModule({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.content,
    required this.keyConcepts,
    required this.quizQuestions,
    required this.geminiPrompt,
  });

  factory LearningModule.fromJson(Map<String, dynamic> json) {
    return LearningModule(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      difficulty: json['difficulty'],
      content: json['content'],
      keyConcepts: List<String>.from(json['keyConcepts']),
      quizQuestions: (json['quizQuestions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      geminiPrompt: json['geminiPrompt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'difficulty': difficulty,
      'content': content,
      'keyConcepts': keyConcepts,
      'quizQuestions': quizQuestions.map((q) => q.toJson()).toList(),
      'geminiPrompt': geminiPrompt,
    };
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correctAnswerIndex'],
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }
}

// Services
class AIService {
  final GenerativeModel _model;

  AIService() : _model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: geminiApiKey,
  );

  Future<LearningModule> generateLearningModule(String topic, int difficulty) async {
    final difficultyText = ['débutant', 'intermédiaire', 'avancé'][difficulty - 1];

    final prompt = """
Tu es un expert en mode africaine, spécialement en $topic. 
Crée un module d'apprentissage de niveau $difficultyText sur le sujet '$topic'. 

Structure:
1. Titre accrocheur
2. Contenu éducatif structuré en markdown avec:
   - Histoire et signification culturelle
   - Techniques traditionnelles
   - Designers contemporains
   - Conseils stylistiques
3. 4 concepts clés à retenir (liste à puces)
4. 5 questions de quiz avec:
   - Question
   - 4 options
   - Index de la bonne réponse (0-3)
   - Explication détaillée
   - Difficulté progressive

Format de sortie JSON strict:
{
  "id": "module_${topic.toLowerCase()}_$difficulty",
  "title": "Titre du module",
  "category": "$topic",
  "difficulty": $difficulty,
  "content": "Contenu markdown ici...",
  "keyConcepts": ["Concept 1", "Concept 2", ...],
  "quizQuestions": [
    {
      "id": "q1",
      "question": "Texte de la question",
      "options": ["Option1", "Option2", "Option3", "Option4"],
      "correctAnswerIndex": 0,
      "explanation": "Explication de la réponse"
    },
    ... // 4 questions supplémentaires
  ],
  "geminiPrompt": "Prompt original"
}
""";

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonMap = json.decode(cleanJson) as Map<String, dynamic>;

      return LearningModule.fromJson(jsonMap);
    } catch (e) {
      print('Erreur de génération Gemini: $e');
      return _createFallbackModule(topic, difficulty);
    }
  }

  LearningModule _createFallbackModule(String topic, int difficulty) {
    return LearningModule(
      id: 'fallback_${topic}_$difficulty',
      title: 'Découverte du $topic',
      category: topic,
      difficulty: difficulty,
      content: """
## $topic: Héritage et Modernité

Le $topic est bien plus qu'un simple tissu - c'est une narration visuelle de notre histoire. 
Chaque motif raconte une histoire, chaque couleur évoque une émotion, chaque pli révèle une tradition.

**Signification culturelle:**
- Symbole d'identité et d'appartenance
- Utilisé lors des cérémonies importantes
- Transmission des valeurs ancestrales

**Designers contemporains:**
- Pathé'O (Côte d'Ivoire)
- Lisa Folawiyo (Nigeria)
- Sindiso Khumalo (Afrique du Sud)
""",
      keyConcepts: [
        'Signification culturelle',
        'Techniques traditionnelles',
        'Designers contemporains'
      ],
      quizQuestions: [
        QuizQuestion(
          id: 'q1',
          question: 'Que représente le $topic dans la culture africaine?',
          options: [
            'Un simple tissu',
            'Un symbole d\'identité',
            'Une tendance moderne',
            'Un produit d\'exportation'
          ],
          correctAnswerIndex: 1,
          explanation: 'Le $topic est un symbole fort d\'identité culturelle et d\'appartenance communautaire',
        ),
        QuizQuestion(
          id: 'q2',
          question: 'Quel designer est connu pour son travail avec le $topic?',
          options: [
            'Karl Lagerfeld',
            'Lisa Folawiyo',
            'Coco Chanel',
            'Giorgio Armani'
          ],
          correctAnswerIndex: 1,
          explanation: 'Lisa Folawiyo est une designer nigériane renommée pour ses créations contemporaines en $topic',
        )
      ],
      geminiPrompt: 'Module de secours',
    );
  }
}

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AIService _aiService = AIService();

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<UserProfile> getUserProfile() {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => UserProfile.fromFirestore(doc));
  }

  Future<bool> checkDailyStyle() async {
    if (currentUserId == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();

    if (!userDoc.exists) {
      await _initializeUser();
      return checkDailyStyle();
    }

    final profile = UserProfile.fromFirestore(userDoc);
    final lastCheck = profile.lastStyleCheck;

    if (lastCheck == null ||
        DateTime(lastCheck.year, lastCheck.month, lastCheck.day) != today) {

      bool shouldBreakStreak = false;
      if (lastCheck != null) {
        final daysSinceLastCheck = today.difference(
            DateTime(lastCheck.year, lastCheck.month, lastCheck.day)
        ).inDays;

        if (daysSinceLastCheck > 1) {
          shouldBreakStreak = true;
        }
      }

      final newStreak = shouldBreakStreak ? 1 : profile.currentStreak + 1;
      final newPoints = profile.totalPoints + 5;
      final newMaxStreak = newStreak > profile.maxStreak ? newStreak : profile.maxStreak;

      await _firestore.collection('users').doc(currentUserId).update({
        'currentStreak': newStreak,
        'totalPoints': newPoints,
        'lastStyleCheck': now,
        'maxStreak': newMaxStreak,
      });

      await _checkAndUnlockBadges(newStreak, profile.unlockedBadges);

      HapticFeedback.lightImpact();
      return true;
    }
    return false;
  }

  Future<void> _initializeUser() async {
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).set({
      'currentStreak': 0,
      'totalPoints': 0,
      'lastStyleCheck': null,
      'unlockedBadges': [],
      'maxStreak': 0,
      'learningProgress': {},
      'createdAt': DateTime.now(),
    });
  }

  Future<void> _checkAndUnlockBadges(int currentStreak, List<String> unlockedBadges) async {
    final achievements = Achievement.getAchievements();
    final newBadges = <String>[];

    for (final achievement in achievements) {
      if (currentStreak >= achievement.requiredStreak &&
          !unlockedBadges.contains(achievement.id)) {
        newBadges.add(achievement.id);
      }
    }

    if (newBadges.isNotEmpty) {
      await _firestore.collection('users').doc(currentUserId).update({
        'unlockedBadges': FieldValue.arrayUnion(newBadges),
      });
    }
  }

  Stream<DailyOutfit> getTodayOutfit() {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return _firestore
        .collection('dailyOutfits')
        .doc(todayString)
        .snapshots()
        .map((doc) => doc.exists ? DailyOutfit.fromFirestore(doc) : _generateDemoOutfit());
  }

  DailyOutfit _generateDemoOutfit() {
    return DailyOutfit(
      id: 'demo',
      title: 'Tenue du Jour - ${_getDayName()}',
      description: 'Inspirée du Faso Dan Fani + météo fraîche à Ouaga',
      imageUrl: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=600&fit=crop',
      weather: '22°C - Nuageux',
      occasion: 'Professionnel décontracté',
      colors: [
        const Color(0xFF8B4513),
        const Color(0xFFDAA520),
        const Color(0xFF2F4F4F),
      ],
      date: DateTime.now(),
      stylistName: 'Amina Traoré',
      stylistPhoto: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&h=200&fit=crop',
    );
  }

  String _getDayName() {
    final weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return weekdays[DateTime.now().weekday - 1];
  }

  Stream<WeeklyChallenge> getCurrentChallenge() {
    return _firestore
        .collection('weeklyChallenges')
        .where('endDate', isGreaterThan: DateTime.now())
        .orderBy('endDate')
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty
        ? WeeklyChallenge.fromFirestore(snapshot.docs.first)
        : _generateDemoChallenge());
  }

  WeeklyChallenge _generateDemoChallenge() {
    return WeeklyChallenge(
      id: 'demo',
      title: 'Semaine Afro Élégante 🌍',
      description: 'Propose ton look préféré associant tissu traditionnel et modernité',
      endDate: DateTime.now().add(const Duration(days: 3)),
      participants: 127,
      submissions: 43,
      prize: 'Tenue VIP personnalisée',
    );
  }

  Future<LearningModule> generateLearningModule(String category, int difficulty) async {
    return _aiService.generateLearningModule(category, difficulty);
  }

  Future<void> completeLearningModule(String moduleId, int score) async {
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).update({
      'learningProgress.$moduleId': FieldValue.arrayUnion([{
        'date': DateTime.now(),
        'score': score,
      }]),
      'totalPoints': FieldValue.increment(score),
    });
  }

  Future<bool> canTakeLearningToday() async {
    if (currentUserId == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    if (!userDoc.exists) return true;

    final profile = UserProfile.fromFirestore(userDoc);
    final lastLearning = profile.learningProgress.values.expand((e) => e).map((e) =>
    (e as Map)['date'] is Timestamp ? (e['date'] as Timestamp).toDate() : null).lastOrNull;

    return lastLearning == null ||
        DateTime(lastLearning.year, lastLearning.month, lastLearning.day) != today;
  }
}

// Écrans
class LearningScreen extends StatefulWidget {
  final String category;
  final int difficulty;

  const LearningScreen({
    Key? key,
    required this.category,
    required this.difficulty,
  }) : super(key: key);

  @override
  _LearningScreenState createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final GameService _gameService = GameService();
  late Future<LearningModule> _learningModule;
  int _currentPage = 0;
  bool _isLoading = true;
  bool _showQuiz = false;

  @override
  void initState() {
    super.initState();
    _learningModule = _gameService.generateLearningModule(widget.category, widget.difficulty);
    _learningModule.then((_) => setState(() => _isLoading = false));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LearningModule>(
      future: _learningModule,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorScreen();
        }

        final module = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(module.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.quiz),
                onPressed: () => setState(() => _showQuiz = true),
                tooltip: 'Passer au quiz',
              ),
            ],
          ),
          body: _showQuiz
              ? QuizScreen(
            module: module,
            onComplete: (score) async {
              await _gameService.completeLearningModule(module.id, score);
              Navigator.pop(context, score);
            },
          )
              : _buildLearningContent(module),
        );
      },
    );
  }

  Widget _buildLearningContent(LearningModule module) {
    return PageView(
      controller: PageController(viewportFraction: 0.95),
      onPageChanged: (index) => setState(() => _currentPage = index),
      children: [
        _buildContentPage(module),
        _buildKeyConceptsPage(module),
      ],
    );
  }

  Widget _buildContentPage(LearningModule module) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Text(
              'Niveau: ${['Débutant', 'Intermédiaire', 'Avancé'][module.difficulty - 1]}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ...module.content.split('\n\n').map((paragraph) {
            final isHeading = paragraph.startsWith('##');
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                paragraph.replaceAll('##', ''),
                style: TextStyle(
                  fontSize: isHeading ? 20 : 16,
                  fontWeight: isHeading ? FontWeight.bold : FontWeight.normal,
                  color: Colors.grey[800],
                  height: 1.6,
                ),
              ),
            );
          }).toList(),
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 40),
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showQuiz = true),
              icon: const Icon(Icons.quiz),
              label: const Text('Passer au Quiz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyConceptsPage(LearningModule module) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
          'Concepts Essentiels',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Retiens ces éléments clés pour maîtriser le ${module.category}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 30),
        ...module.keyConcepts.map((concept) {
      return Card(
        margin: const EdgeInsets.only(bottom: 15),
        elevation: 2,
        child: ListTile(
          leading: const Icon(Icons.circle, size: 12, color: Colors.blue),
          title: Text(
            concept,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: _buildConceptDetails(concept, module),
        ),
      );
    }).toList(),
    Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 40),
    child: ElevatedButton.icon(
    onPressed: () => setState(() => _showQuiz = true),
    icon: const Icon(Icons.quiz),
    label: const Text('Passer au Quiz'),
    style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    ),
    )],
    ),
    );
  }

  Widget _buildConceptDetails(String concept, LearningModule module) {
    final details = {
      'Signification culturelle': 'Explore la profondeur symbolique et les valeurs transmises',
      'Techniques traditionnelles': 'Découvre les méthodes ancestrales de création',
      'Designers contemporains': 'Rencontre les artisans qui réinventent la tradition',
    }[concept] ?? 'Concept clé à maîtriser';

    return Text(details);
  }

  void _textToSpeech(String text) {
    // Intégration TTS (à implémenter)
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: Text('Préparation du cours sur ${widget.category}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Notre styliste IA prépare votre cours...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Concepts en préparation:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                Chip(label: Text('Histoire')),
                Chip(label: Text('Motifs')),
                Chip(label: Text('Designers')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Notre styliste IA est indisponible',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 15),
            Text(
              'Veuillez réessayer plus tard',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final LearningModule module;
  final Function(int) onComplete;

  const QuizScreen({
    Key? key,
    required this.module,
    required this.onComplete,
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  int _score = 0;
  bool _quizCompleted = false;
  bool _showExplanation = false;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _feedbackAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _showFeedback(bool isCorrect) {
    _feedbackController.reset();
    _feedbackController.forward();
    HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    if (_quizCompleted) {
      return _buildResultsScreen();
    }

    final question = widget.module.quizQuestions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.module.title}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${_score}/${widget.module.quizQuestions.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ScaleTransition(
        scale: _feedbackAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / widget.module.quizQuestions.length,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),

              // En-tête de la question
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 10),
                    Text(
                      'Question ${_currentQuestionIndex + 1}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Texte de la question
              Text(
                question.question,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Options de réponse
              ...question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = _selectedAnswerIndex == index;
                final isCorrect = index == question.correctAnswerIndex;
                final showFeedback = _showExplanation && isSelected;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: showFeedback
                          ? (isCorrect ? Colors.green[50] : Colors.red[50])
                          : isSelected
                          ? Colors.blue[50]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: showFeedback
                            ? (isCorrect ? Colors.green : Colors.red)
                            : isSelected
                            ? Colors.blue
                            : Colors.grey[300]!,
                        width: showFeedback || isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: _showExplanation ? null : () => setState(() {
                        _selectedAnswerIndex = index;
                        if (!_showExplanation) {
                          _showFeedback(isCorrect);
                        }
                      }),
                      leading: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: showFeedback
                                ? (isCorrect ? Colors.green : Colors.red)
                                : isSelected
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                        child: Center(
                          child: showFeedback
                              ? Icon(
                            isCorrect ? Icons.check : Icons.close,
                            size: 16,
                            color: isCorrect ? Colors.green : Colors.red,
                          )
                              : null,
                        ),
                      ),
                      title: Text(option),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              }).toList(),

              const Spacer(),

              // Zone d'explication
              if (_showExplanation) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explication:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.explanation,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Bouton de navigation
              ElevatedButton(
                onPressed: _selectedAnswerIndex != null
                    ? _showExplanation ? _nextQuestion : _submitAnswer
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _showExplanation
                      ? _currentQuestionIndex < widget.module.quizQuestions.length - 1
                      ? 'Question Suivante'
                      : 'Terminer le Quiz'
                      : 'Valider la Réponse',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitAnswer() {
    final question = widget.module.quizQuestions[_currentQuestionIndex];
    final isCorrect = _selectedAnswerIndex == question.correctAnswerIndex;

    if (isCorrect) {
      setState(() => _score += 1);
    }

    setState(() => _showExplanation = true);
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < widget.module.quizQuestions.length - 1) {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _showExplanation = false;
      } else {
        _quizCompleted = true;
        widget.onComplete(_score);
      }
    });
  }

  Widget _buildResultsScreen() {
    final percentage = (_score / widget.module.quizQuestions.length * 100).round();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: _score / widget.module.quizQuestions.length,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[200],
                      color: _score == widget.module.quizQuestions.length
                          ? Colors.amber
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$_score/${widget.module.quizQuestions.length}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                _score == widget.module.quizQuestions.length
                    ? 'Maîtrise Parfaite! 🎉'
                    : _score > widget.module.quizQuestions.length / 2
                    ? 'Bonne Performance! 👍'
                    : 'Continue d\'apprendre! 💪',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tu as gagné $_score points',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('Retour à l\'accueil'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Écran principal
class HomeContentScreen extends StatefulWidget {
  @override
  _HomeContentScreenState createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen>
    with TickerProviderStateMixin {
  final GameService _gameService = GameService();
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showSuccessMessage = false;
  Timer? _successTimer;
  bool _isCheckingStyle = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyStyleOnStart();
    });
  }

  void _checkDailyStyleOnStart() async {
    setState(() => _isCheckingStyle = true);
    final checked = await _gameService.checkDailyStyle();
    if (checked) _showSuccess();
    setState(() => _isCheckingStyle = false);
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  void _showSuccess() {
    setState(() => _showSuccessMessage = true);
    _slideController.forward();
    HapticFeedback.heavyImpact();

    _successTimer = Timer(const Duration(seconds: 3), () {
      _slideController.reverse().then((_) {
        if (mounted) setState(() => _showSuccessMessage = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            _buildMainContent(),
            if (_showSuccessMessage) _buildSuccessMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStreakCard(),
              const SizedBox(height: 20),
              _buildDailyStyleCard(),
              const SizedBox(height: 20),
              _buildLearningCard(),
              const SizedBox(height: 20),
              _buildWeeklyChallengeCard(),
              const SizedBox(height: 20),
              _buildStatsCard(),
              const SizedBox(height: 20),
              _buildAchievementsCard(),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 2,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ElegantFaso',
              style: TextStyle(
                color: Colors.grey[900],
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: 'PlayfairDisplay',
              ),
            ),
            Text(
              'Ton style, chaque jour',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Badge(
            child: const Icon(Icons.notifications_outlined, color: Colors.black54),
            isLabelVisible: true,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return StreamBuilder<UserProfile>(
      stream: _gameService.getUserProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingCard();

        final profile = snapshot.data!;
        final nextAchievement = _getNextAchievement(profile.currentStreak);

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: profile.currentStreak > 0 ? _pulseAnimation.value : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange[500]!,
                      Colors.red[600]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'SÉRIE DE STYLE',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${profile.currentStreak} jours',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black26,
                                      offset: Offset(1, 1),
                                    )
                                  ],
                                ),
                              ),
                              Text(
                                '+5 pts/jour',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.currentStreak > 0
                                  ? "🔥 Tu es à ${profile.currentStreak} jours consécutifs de style !"
                                  : "Commence ta série de style aujourd'hui !",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (nextAchievement != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                "Encore ${nextAchievement.requiredStreak - profile.currentStreak} jour(s) pour :",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Text(
                                    '${nextAchievement.emoji} ${nextAchievement.name}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (nextAchievement.rewardDescription != null)
                                    Flexible(
                                      child: Text(
                                        '- ${nextAchievement.rewardDescription!}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDailyStyleCard() {
    return StreamBuilder<DailyOutfit>(
      stream: _gameService.getTodayOutfit(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingCard();

        final outfit = snapshot.data!;

        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(outfit.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            outfit.weather,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Text(
                        outfit.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outfit.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (outfit.stylistName != null) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: outfit.stylistPhoto != null
                                ? NetworkImage(outfit.stylistPhoto!)
                                : null,
                            backgroundColor: Colors.grey[200],
                            child: outfit.stylistPhoto == null
                                ? const Icon(Icons.person, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Styliste: ${outfit.stylistName!}',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                    ],
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.blue[100]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            outfit.occasion,
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ...outfit.colors.map((color) => Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.4),
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<UserProfile>(
                            stream: _gameService.getUserProfile(),
                            builder: (context, profileSnapshot) {
                              if (!profileSnapshot.hasData) {
                                return const SizedBox();
                              }

                              final profile = profileSnapshot.data!;
                              final today = DateTime.now();
                              final lastCheck = profile.lastStyleCheck;

                              final alreadyChecked = lastCheck != null &&
                                  lastCheck.year == today.year &&
                                  lastCheck.month == today.month &&
                                  lastCheck.day == today.day;

                              return ElevatedButton.icon(
                                onPressed: alreadyChecked || _isCheckingStyle
                                    ? null
                                    : () async {
                                  final checked = await _gameService.checkDailyStyle();
                                  if (checked) _showSuccess();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: alreadyChecked
                                      ? Colors.green[600]
                                      : Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                                icon: alreadyChecked
                                    ? const Icon(Icons.check_circle, size: 20)
                                    : const Icon(Icons.style, size: 20),
                                label: alreadyChecked
                                    ? const Text('DÉJÀ CONSULTÉ (+5 pts)')
                                    : const Text('CONSULTER LA TENUE'),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.share),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.grey[800],
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLearningCard() {
    return StreamBuilder<bool>(
      stream: _gameService.getUserProfile().asyncMap((profile) async {
        return await _gameService.canTakeLearningToday();
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingCard();

        final canLearnToday = snapshot.data!;
        final difficultyLevels = [
          {'level': 1, 'label': 'Débutant', 'points': '+1 pt/question', 'color': Colors.green},
          {'level': 2, 'label': 'Intermédiaire', 'points': '+1 pt/question', 'color': Colors.orange},
          {'level': 3, 'label': 'Avancé', 'points': '+1 pt/question', 'color': Colors.red},
        ];

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school, color: Colors.grey[700], size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'APPRENTISSAGE STYLE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Découvre les secrets de la mode africaine avec notre coach IA',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                if (canLearnToday) ...[
                  const Text(
                    'Choisis ton thème du jour:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: difficultyLevels.map((level) {
                      return ActionChip(
                        onPressed: () => _startLearning(level['level'] as int),
                        label: Text(level['label'] as String),
                        avatar: CircleAvatar(
                          backgroundColor: (level['color'] as Color).withOpacity(0.2),
                          child: Text(
                            '${level['level']}',
                            style: TextStyle(
                              color: level['color'] as Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                        backgroundColor: Colors.grey[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green[100]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tu as déjà complété ton apprentissage aujourd\'hui. Reviens demain!',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _startLearning(int difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningScreen(
          category: 'Style Africain',
          difficulty: difficulty,
        ),
      ),
    );
  }

  Widget _buildWeeklyChallengeCard() {
    return StreamBuilder<WeeklyChallenge>(
      stream: _gameService.getCurrentChallenge(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingCard();

        final challenge = snapshot.data!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple[600]!,
                Colors.pink[700]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DÉFI HEBDOMADAIRE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  challenge.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  challenge.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildChallengeStats(
                        '${challenge.daysLeft}',
                        'JOURS RESTANTS',
                        Icons.timer,
                      ),
                      _buildChallengeStats(
                        '${challenge.participants}',
                        'PARTICIPANTS',
                        Icons.people,
                      ),
                      _buildChallengeStats(
                        '${challenge.submissions}',
                        'CRÉATIONS',
                        Icons.brush,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('PARTICIPER AU DÉFI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.purple[800],
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Prix: ${challenge.prize}',
                    style: TextStyle(
                      color: Colors.amber[200],
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChallengeStats(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return StreamBuilder<UserProfile>(
      stream: _gameService.getUserProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingCard();

        final profile = snapshot.data!;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: Colors.grey[700],
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'TES STATISTIQUES',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        Icons.stars,
                        '${profile.totalPoints}',
                        'POINTS TOTAUX',
                        Colors.amber[700]!,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: _buildStatItem(
                        Icons.local_fire_department,
                        '${profile.maxStreak}',
                        'MEILLEURE SÉRIE',
                        Colors.orange[700]!,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: _buildStatItem(
                        Icons.military_tech,
                        '${profile.unlockedBadges.length}',
                        'BADGES',
                        Colors.blue[700]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsCard() {
    return StreamBuilder<UserProfile>(
      stream: _gameService.getUserProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingCard();

        final profile = snapshot.data!;
        final achievements = Achievement.getAchievements();

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: Colors.grey[700],
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'TES RÉCOMPENSES',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...achievements.map((achievement) {
                  final isUnlocked = profile.unlockedBadges.contains(achievement.id);
                  final canUnlock = profile.currentStreak >= achievement.requiredStreak;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? Colors.green[50]
                          : canUnlock
                          ? Colors.blue[50]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnlocked
                            ? Colors.green[200]!
                            : canUnlock
                            ? Colors.blue[200]!
                            : Colors.grey[200]!,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isUnlocked
                                ? Colors.green[100]
                                : canUnlock
                                ? Colors.blue[100]
                                : Colors.grey[100],
                            border: Border.all(
                              color: isUnlocked
                                  ? Colors.green[300]!
                                  : canUnlock
                                  ? Colors.blue[300]!
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              achievement.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
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
                                    achievement.name,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isUnlocked
                                          ? Colors.green[900]
                                          : canUnlock
                                          ? Colors.blue[900]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  if (isUnlocked) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.verified,
                                      color: Colors.green[700],
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                achievement.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUnlocked
                                          ? Colors.green[100]
                                          : canUnlock
                                          ? Colors.blue[100]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${achievement.requiredStreak} jours',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isUnlocked
                                            ? Colors.green[800]
                                            : canUnlock
                                            ? Colors.blue[800]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '+${achievement.points} pts',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (achievement.rewardDescription != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.card_giftcard,
                                      size: 16,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        achievement.rewardDescription!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Chargement des données...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green[500]!,
                  Colors.green[700]!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Félicitations !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(text: 'Style consulté ! '),
                            TextSpan(
                              text: '+5 points',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: ' ajoutés à ton compte.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Achievement? _getNextAchievement(int currentStreak) {
    final achievements = Achievement.getAchievements();
    for (final achievement in achievements) {
      if (currentStreak < achievement.requiredStreak) {
        return achievement;
      }
    }
    return null;
  }
}

void main() {
  runApp(MaterialApp(
    title: 'ElegantFaso',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      fontFamily: 'Roboto',
    ),
    home: HomeContentScreen(),
  ));
}