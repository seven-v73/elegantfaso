import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../models/client/gamification/daily_quiz_model.dart';
import '../../models/client/gamification/quiz_question_model.dart';

class DailyQuizContext {
  final String userId;
  final String level;
  final int points;
  final int streak;
  final String preferredStyle;
  final String gender;
  final String country;
  final String weatherSummary;
  final List<String> localEvents;
  final List<String> trendNotes;

  const DailyQuizContext({
    required this.userId,
    required this.level,
    required this.points,
    required this.streak,
    this.preferredStyle = 'élégant',
    this.gender = 'non précisé',
    this.country = 'International',
    this.weatherSummary = 'adapté à la zone de l’utilisateur',
    this.localEvents = const [],
    this.trendNotes = const [],
  });
}

class DailyQuizResult {
  final int score;
  final int totalQuestions;
  final int earnedPoints;
  final List<Map<String, dynamic>> missedQuestions;

  const DailyQuizResult({
    required this.score,
    required this.totalQuestions,
    required this.earnedPoints,
    required this.missedQuestions,
  });
}

class _StyleRitualStage {
  final String title;
  final String category;
  final String intent;
  final String tip;
  final String action;

  const _StyleRitualStage({
    required this.title,
    required this.category,
    required this.intent,
    required this.tip,
    required this.action,
  });
}

class DailyQuizService {
  DailyQuizService({FirebaseFirestore? firestore, http.Client? httpClient})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _httpClient = httpClient ?? http.Client();

  final FirebaseFirestore _firestore;
  final http.Client _httpClient;

  String? get _geminiApiKey => dotenv.env['GEMINI_API_KEY'];

  String get _geminiApiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_geminiApiKey';

  Future<DailyQuizModel> getOrCreateDailyQuiz({
    required String date,
    required DailyQuizContext context,
  }) async {
    final dayRef = _dayRef(context.userId, date);
    final existing = await dayRef.get();
    if (existing.exists && existing.data() != null) {
      final quiz = DailyQuizModel.fromMap(existing.data()!);
      if (quiz.questions.length >= 5) return quiz;
    }

    final recentQuestions = await _loadRecentQuestions(context.userId);
    final insights = await loadQuizInsights(context.userId);
    final quiz = await _generateAiQuiz(
      date: date,
      context: context,
      recentQuestions: recentQuestions,
      insights: insights,
    ).catchError((error, stackTrace) {
      debugPrint('Daily quiz AI fallback: $error');
      return _buildFallbackQuiz(
        date: date,
        context: context,
        recentQuestions: recentQuestions,
      );
    });

    await dayRef.set({
      ...quiz.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'source': quiz.questions.length >= 5 ? 'ai_or_local' : 'local',
    }, SetOptions(merge: true));
    await _rememberQuestions(context.userId, quiz.questions);
    return quiz;
  }

  Future<Map<String, dynamic>> loadQuizInsights(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('quiz_history')
              .doc(userId)
              .collection('daily_results')
              .orderBy('completedAt', descending: true)
              .limit(7)
              .get();

      if (snapshot.docs.isEmpty) {
        return {
          'weakCategories': 'aucune donnée',
          'averageScore': 'nouveau',
          'preferredDifficulty': 1,
        };
      }

      var scoreRatioTotal = 0.0;
      final missedCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final score = (data['score'] as num?)?.toDouble() ?? 0;
        final total = (data['totalQuestions'] as num?)?.toDouble() ?? 5;
        if (total > 0) scoreRatioTotal += score / total;

        for (final category
            in (data['missedCategories'] as List? ?? const [])) {
          final key = category.toString();
          missedCounts[key] = (missedCounts[key] ?? 0) + 1;
        }
      }

      final averageScore = scoreRatioTotal / snapshot.docs.length;
      final weakCategories =
          missedCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'weakCategories':
            weakCategories.isEmpty
                ? 'aucune faiblesse claire'
                : weakCategories.take(3).map((entry) => entry.key).join(', '),
        'averageScore': '${(averageScore * 100).round()}%',
        'preferredDifficulty':
            averageScore >= 0.85
                ? 3
                : averageScore >= 0.6
                ? 2
                : 1,
      };
    } catch (error) {
      debugPrint('Quiz insights unavailable: $error');
      return {
        'weakCategories': 'indisponible',
        'averageScore': 'indisponible',
        'preferredDifficulty': 1,
      };
    }
  }

  Future<void> completeQuiz({
    required String userId,
    required String date,
    required DailyQuizModel quiz,
    required DailyQuizResult result,
  }) async {
    final missedCategories =
        result.missedQuestions
            .map((question) => question['category']?.toString() ?? 'Style')
            .toSet()
            .toList();
    final perfectScore = result.score == result.totalQuestions;
    final rewardLabel = _rewardLabelFor(result.score, result.totalQuestions);
    final badgeLabel = _badgeLabelFor(result.score, result.totalQuestions);
    final learnedToday = _learnedSummary(
      quiz.questions,
      result.missedQuestions,
    );
    final completedQuiz = quiz.copyWith(
      progress: result.totalQuestions,
      completed: true,
      bonusUnlocked: perfectScore,
      rewardLabel: rewardLabel,
      badgeLabel: badgeLabel,
      learnedToday: learnedToday,
    );

    final batch = _firestore.batch();
    batch.set(_dayRef(userId, date), {
      ...completedQuiz.toMap(),
      'score': result.score,
      'earnedPoints': result.earnedPoints,
      'missedCategories': missedCategories,
      'missedQuestions': result.missedQuestions,
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(
      _firestore
          .collection('quiz_history')
          .doc(userId)
          .collection('daily_results')
          .doc(date),
      {
        'date': date,
        'score': result.score,
        'totalQuestions': result.totalQuestions,
        'earnedPoints': result.earnedPoints,
        'theme': quiz.subtitle,
        'missedCategories': missedCategories,
        'missedQuestions': result.missedQuestions,
        'styleTip': quiz.styleTip,
        'outfitSuggestion': quiz.outfitSuggestion,
        'learnedToday': learnedToday,
        'bonusUnlocked': perfectScore,
        'rewardLabel': rewardLabel,
        'badgeLabel': badgeLabel,
        'completedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final skillUpdates = <String, Object>{};
    for (final question in quiz.questions) {
      skillUpdates['quizStats.skillProgress.${question.category}'] =
          FieldValue.increment(1);
    }

    batch.update(_firestore.collection('users').doc(userId), {
      'quizStats.completedDays': FieldValue.increment(1),
      'quizStats.lastQuizDate': date,
      'quizStats.lastScore': result.score,
      'quizStats.lastTotal': result.totalQuestions,
      if (perfectScore) 'quizStats.perfectDays': FieldValue.increment(1),
      if (badgeLabel.isNotEmpty)
        'quizBadges': FieldValue.arrayUnion([badgeLabel]),
      'styleSignals.lastTheme': quiz.subtitle,
      'styleSignals.lastTip': quiz.styleTip,
      'styleSignals.lastAction': quiz.outfitSuggestion,
      'styleSignals.lastLearned': learnedToday,
      'styleSignals.lastScore': result.score,
      'styleSignals.updatedAt': FieldValue.serverTimestamp(),
      'styleSignals.recentThemes': FieldValue.arrayUnion([quiz.subtitle]),
      ...skillUpdates,
    });

    await batch.commit();
  }

  Future<DailyQuizModel> _generateAiQuiz({
    required String date,
    required DailyQuizContext context,
    required Set<String> recentQuestions,
    required Map<String, dynamic> insights,
  }) async {
    final apiKey = _geminiApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('GEMINI_API_KEY manquant');
    }

    final difficulty = _recommendedDifficulty(context, insights);
    final stage = _ritualStageForDate(date);
    final theme = stage.title;
    final prompt = '''
Génère 5 questions courtes pour un rituel Style mobile-first. Ce rituel sert de diagnostic léger, pas de jeu scolaire.
Contexte utilisateur :
- niveau : ${context.level}
- style préféré : ${context.preferredStyle}
- genre/style : ${context.gender}
- pays : ${context.country}
- thème du jour : $theme
- intention du jour : ${stage.intent}
- météo/saison : ${context.weatherSummary}
- série actuelle : ${context.streak} jours
- score moyen récent : ${insights['averageScore']}
- erreurs à renforcer : ${insights['weakCategories']}
- événements locaux : ${context.localEvents.isEmpty ? 'marchés créatifs, ateliers, mariages, cérémonies, fashion weeks locales' : context.localEvents.join(', ')}
- tendances validées : ${context.trendNotes.isEmpty ? 'textiles locaux, matières adaptées au climat, accessoires artisanaux' : context.trendNotes.join(', ')}
- questions récentes à éviter : ${recentQuestions.take(25).join(' | ')}

Règles :
- chaque question doit apprendre une préférence exploitable : couleur, occasion, silhouette, budget, matière, beauté ou audace
- question courte, vocabulaire humain, pas de ton IA
- 4 réponses maximum, très lisibles sur mobile
- chaque explication doit mener vers une action Salon possible : produit, créateur, inspiration, événement ou moodboard
Retour JSON strict, sans markdown :
{
  "title": "Rituel Style",
  "subtitle": "$theme",
  "points": 70,
  "difficulty": $difficulty,
  "styleTip": "astuce courte liée au thème",
  "outfitSuggestion": "prochaine action Salon en une phrase",
  "learnedToday": "résumé très court du signal style appris",
  "questions": [
    {
      "question": "texte",
      "options": ["A", "B", "C", "D"],
      "correctAnswer": 2,
      "explanation": "explication courte",
      "category": "couleurs|matières|morphologie|culture|entretien|accessoires",
      "difficulty": $difficulty
    }
  ]
}
''';

    final response = await _httpClient.post(
      Uri.parse(_geminiApiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.85, 'maxOutputTokens': 1600},
      }),
    );

    if (response.statusCode != 200) {
      throw StateError('Gemini ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        body['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString() ??
        '{}';
    final jsonText = _extractJson(text);
    final data = jsonDecode(jsonText) as Map<String, dynamic>;
    final quiz = _normalizeQuizMap(data, date, theme, difficulty);
    _assertFresh(quiz.questions, recentQuestions);
    return quiz;
  }

  DailyQuizModel _buildFallbackQuiz({
    required String date,
    required DailyQuizContext context,
    required Set<String> recentQuestions,
  }) {
    final stage = _ritualStageForDate(date);
    final theme = stage.title;
    final difficulty = _recommendedDifficulty(context, const {});
    final seed = '$date-${context.level}-${context.streak}';
    final bank = [
      ..._fallbackQuestionBank.where(
        (item) => item['category']?.toString() == stage.category,
      ),
      ..._fallbackQuestionBank.where(
        (item) => item['category']?.toString() != stage.category,
      ),
    ];
    final start = _stableIndex(seed, bank.length);
    final questions = <QuizQuestionModel>[];

    for (
      var offset = 0;
      questions.length < 5 && offset < bank.length * 2;
      offset++
    ) {
      final item = bank[(start + offset) % bank.length];
      final question = QuizQuestionModel.fromMap({
        ...item,
        'difficulty': math.min(3, math.max(1, difficulty)),
      });
      final shuffledQuestion = shuffleQuestionOptions(
        question,
        '$date-${context.userId}-${context.level}-${question.question}',
      );
      final normalized = shuffledQuestion.question.toLowerCase().trim();
      final alreadyPicked = questions.any(
        (picked) => picked.question.toLowerCase().trim() == normalized,
      );
      if (!alreadyPicked && !recentQuestions.contains(normalized)) {
        questions.add(shuffledQuestion);
      }
    }

    while (questions.length < 5) {
      final question = QuizQuestionModel.fromMap(
        _fallbackQuestionBank[questions.length],
      );
      questions.add(
        shuffleQuestionOptions(question, '$date-fallback-${questions.length}'),
      );
    }

    return DailyQuizModel(
      date: date,
      title: 'Rituel Style',
      subtitle: theme,
      progress: 0,
      target: 5,
      completed: false,
      points: 60 + difficulty * 5 + (context.streak >= 7 ? 10 : 0),
      difficulty: difficulty,
      styleTip: stage.tip,
      outfitSuggestion: stage.action,
      learnedToday: _learnedSummary(questions, const []),
      bonusUnlocked: false,
      rewardLabel: '',
      badgeLabel: '',
      questions: questions,
    );
  }

  DailyQuizModel _normalizeQuizMap(
    Map<String, dynamic> data,
    String date,
    String theme,
    int difficulty,
  ) {
    final questions =
        (data['questions'] as List<dynamic>?)
            ?.whereType<Map>()
            .map(
              (item) =>
                  QuizQuestionModel.fromMap(Map<String, dynamic>.from(item)),
            )
            .where((question) => question.options.length == 4)
            .take(5)
            .toList() ??
        <QuizQuestionModel>[];

    if (questions.length < 5) {
      throw StateError('Réponse IA incomplète');
    }
    final shuffledQuestions = [
      for (var index = 0; index < questions.length; index++)
        shuffleQuestionOptions(
          questions[index],
          '$date-$theme-ai-$index-${questions[index].question}',
        ),
    ];

    return DailyQuizModel(
      date: date,
      title: data['title']?.toString() ?? 'Parcours du jour',
      subtitle: data['subtitle']?.toString() ?? theme,
      progress: 0,
      target: 5,
      completed: false,
      points: (data['points'] as num?)?.toInt() ?? 70,
      difficulty: ((data['difficulty'] as num?)?.toInt() ?? difficulty).clamp(
        1,
        3,
      ),
      styleTip: data['styleTip']?.toString() ?? _styleTipForTheme(theme),
      outfitSuggestion:
          data['outfitSuggestion']?.toString() ??
          _outfitSuggestionForTheme(theme),
      learnedToday:
          data['learnedToday']?.toString() ??
          _learnedSummary(shuffledQuestions, const []),
      bonusUnlocked: false,
      rewardLabel: '',
      badgeLabel: '',
      questions: shuffledQuestions,
    );
  }

  Future<Set<String>> _loadRecentQuestions(String userId) async {
    final questions = <String>{};

    final usedDoc =
        await _firestore.collection('used_questions').doc(userId).get();
    final used = usedDoc.data()?['questions'];
    if (used is List) {
      questions.addAll(
        used.map((item) => item.toString().toLowerCase().trim()),
      );
    }

    final history =
        await _firestore
            .collection('quiz_history')
            .doc(userId)
            .collection('daily_results')
            .orderBy('completedAt', descending: true)
            .limit(10)
            .get();
    for (final doc in history.docs) {
      final missed = doc.data()['missedQuestions'];
      if (missed is List) {
        for (final item in missed.whereType<Map>()) {
          final question = item['question']?.toString().toLowerCase().trim();
          if (question != null && question.isNotEmpty) questions.add(question);
        }
      }
    }

    return questions;
  }

  Future<void> _rememberQuestions(
    String userId,
    List<QuizQuestionModel> questions,
  ) async {
    final ref = _firestore.collection('used_questions').doc(userId);
    final existing = await ref.get();
    final previous =
        (existing.data()?['questions'] as List<dynamic>?)
            ?.map((question) => question.toString())
            .where((question) => question.trim().isNotEmpty)
            .toList() ??
        <String>[];
    final merged = <String>[
      ...previous,
      ...questions.map((question) => question.question),
    ];
    final unique = LinkedHashSet<String>.from(merged).toList();
    final retained =
        unique.length > 120 ? unique.sublist(unique.length - 120) : unique;

    await ref.set({
      'questions': retained,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> _dayRef(String userId, String date) {
    return _firestore
        .collection('daily_quizzes')
        .doc(userId)
        .collection('days')
        .doc(date);
  }

  String themeForDate(String date) {
    return _ritualStageForDate(date).title;
  }

  _StyleRitualStage _ritualStageForDate(String date) {
    final weekday = DateTime.tryParse(date)?.weekday ?? DateTime.now().weekday;
    return _weeklyRitualStages[weekday] ??
        _weeklyRitualStages[DateTime.monday]!;
  }

  int _recommendedDifficulty(
    DailyQuizContext context,
    Map<String, dynamic> insights,
  ) {
    final historyDifficulty =
        (insights['preferredDifficulty'] as num?)?.toInt();
    if (historyDifficulty != null) return historyDifficulty.clamp(1, 3);
    if (context.streak >= 14 || context.points >= 2500) return 3;
    if (context.streak >= 5 || context.points >= 800) return 2;
    return 1;
  }

  void _assertFresh(
    List<QuizQuestionModel> questions,
    Set<String> recentQuestions,
  ) {
    final seen = <String>{};
    for (final question in questions) {
      final normalized = question.question.toLowerCase().trim();
      if (normalized.isEmpty ||
          seen.contains(normalized) ||
          recentQuestions.contains(normalized)) {
        throw StateError('Question répétée: ${question.question}');
      }
      seen.add(normalized);
    }
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end < start) throw FormatException('JSON introuvable');
    return text.substring(start, end + 1);
  }

  int _stableIndex(String seed, int length) {
    final value = seed.codeUnits.fold<int>(0, (total, unit) => total + unit);
    return length == 0 ? 0 : value % length;
  }

  static QuizQuestionModel shuffleQuestionOptions(
    QuizQuestionModel question,
    String seed,
  ) {
    final originalOptions = question.options.take(4).toList();
    if (originalOptions.length < 4) return question;

    final correctIndex = question.correctAnswer.clamp(
      0,
      originalOptions.length - 1,
    );
    final entries = [
      for (var index = 0; index < originalOptions.length; index++)
        MapEntry(index, originalOptions[index]),
    ];
    entries.shuffle(math.Random(_stableSeed(seed)));

    final options = entries.map((entry) => entry.value).toList();
    final newCorrectIndex = entries.indexWhere(
      (entry) => entry.key == correctIndex,
    );

    return QuizQuestionModel(
      question: question.question,
      options: options,
      correctAnswer: newCorrectIndex < 0 ? correctIndex : newCorrectIndex,
      explanation: question.explanation,
      category: question.category,
      difficulty: question.difficulty,
    );
  }

  static int _stableSeed(String seed) {
    var hash = 0x811c9dc5;
    for (final unit in seed.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  String _rewardLabelFor(int score, int total) {
    if (score == total) return 'Question bonus débloquée';
    if (score >= 3) return 'Mini récompense style';
    return 'Progression enregistrée';
  }

  String _badgeLabelFor(int score, int total) {
    if (score == total) return 'Oeil de styliste';
    if (score >= 4) return 'Style régulier';
    return '';
  }

  String _learnedSummary(
    List<QuizQuestionModel> questions,
    List<Map<String, dynamic>> missedQuestions,
  ) {
    final categories = questions
        .map((question) => question.category)
        .toSet()
        .take(3);
    if (missedQuestions.isEmpty) {
      return 'Aujourd’hui tu as consolidé : ${categories.join(', ')}.';
    }
    final weak = missedQuestions
        .map((question) => question['category']?.toString() ?? 'style')
        .toSet()
        .take(2)
        .join(', ');
    return 'Aujourd’hui tu as appris : ${categories.join(', ')}. À revoir : $weak.';
  }

  String _styleTipForTheme(String theme) {
    return _weeklyRitualStages.values
        .firstWhere(
          (stage) => stage.title == theme,
          orElse: () => _weeklyRitualStages[DateTime.monday]!,
        )
        .tip;
  }

  String _outfitSuggestionForTheme(String theme) {
    return _weeklyRitualStages.values
        .firstWhere(
          (stage) => stage.title == theme,
          orElse: () => _weeklyRitualStages[DateTime.monday]!,
        )
        .action;
  }

  static const Map<int, _StyleRitualStage> _weeklyRitualStages = {
    DateTime.monday: _StyleRitualStage(
      title: 'Couleurs',
      category: 'Couleurs',
      intent: 'identifier les palettes qui donnent envie de composer',
      tip: 'Choisis une couleur forte, puis garde deux tons calmes autour.',
      action: 'Explore des produits avec une palette proche dans le Salon.',
    ),
    DateTime.tuesday: _StyleRitualStage(
      title: 'Occasions',
      category: 'Occasion',
      intent: 'relier le style aux moments réels de la semaine',
      tip: 'Une bonne tenue commence par le moment où tu vas la porter.',
      action: 'Trouve un créateur adapté à ton prochain événement.',
    ),
    DateTime.wednesday: _StyleRitualStage(
      title: 'Silhouette',
      category: 'Morphologie',
      intent: 'comprendre les volumes qui mettent à l’aise',
      tip: 'Alterne volume et structure pour garder une silhouette lisible.',
      action: 'Compose un look avec une pièce forte et une base plus nette.',
    ),
    DateTime.thursday: _StyleRitualStage(
      title: 'Budget',
      category: 'Budget',
      intent: 'choisir entre achat, création sur mesure ou garde-robe',
      tip: 'Investis sur la coupe et complète avec des accessoires ciblés.',
      action: 'Compare produits prêts à acheter et ateliers sur mesure.',
    ),
    DateTime.friday: _StyleRitualStage(
      title: 'Matières',
      category: 'Matières',
      intent: 'repérer les textiles adaptés au climat et à l’usage',
      tip: 'La matière doit suivre la météo, le mouvement et l’entretien.',
      action: 'Sauvegarde les pièces dont la matière correspond à ta journée.',
    ),
    DateTime.saturday: _StyleRitualStage(
      title: 'Beauté',
      category: 'Beauté',
      intent: 'relier coiffure, peau, accessoires et tenue',
      tip: 'Un détail beauté peut remplacer plusieurs accessoires.',
      action: 'Cherche inspirations beauté et talents liés au look.',
    ),
    DateTime.sunday: _StyleRitualStage(
      title: 'Résumé Style',
      category: 'Synthèse',
      intent: 'transformer les réponses de la semaine en prochaine action',
      tip: 'Garde ce qui revient souvent : c’est ta direction style.',
      action: 'Mets à jour ton moodboard avec une palette et une intention.',
    ),
  };

  List<Map<String, dynamic>> get _fallbackQuestionBank => const [
    {
      'category': 'Couleurs',
      'question': 'Quelle palette te donne le plus envie aujourd’hui ?',
      'options': [
        'Neutres élégants',
        'Couleurs fortes',
        'Tons terre',
        'Pastels doux',
      ],
      'correctAnswer': 0,
      'explanation':
          'Les neutres sont une base facile à relier à des produits, accessoires et créations fortes du Salon.',
    },
    {
      'category': 'Couleurs',
      'question': 'Pour calmer une tenue très colorée, tu ajoutes quoi ?',
      'options': [
        'Une base sobre',
        'Trois motifs en plus',
        'Des couleurs sans lien',
        'Tous les accessoires forts',
      ],
      'correctAnswer': 0,
      'explanation':
          'Une base sobre garde la tenue lisible et aide à choisir les bons accessoires.',
    },
    {
      'category': 'Occasion',
      'question': 'Tu prépares un événement : premier réflexe utile ?',
      'options': [
        'Choisir le contexte',
        'Acheter au hasard',
        'Ignorer le lieu',
        'Changer tout au dernier moment',
      ],
      'correctAnswer': 0,
      'explanation':
          'Le contexte guide les produits, créateurs, lieux et inspirations à afficher.',
    },
    {
      'category': 'Occasion',
      'question': 'Pour un mariage, la meilleure base est souvent...',
      'options': [
        'Une intention claire',
        'Une tenue improvisée',
        'Des tailles incertaines',
        'Aucun essayage',
      ],
      'correctAnswer': 0,
      'explanation':
          'Une intention claire permet de chercher robes, accessoires, créateurs et inspirations cohérents.',
    },
    {
      'category': 'Morphologie',
      'question': 'Si une pièce est ample, qu’est-ce qui équilibre souvent ?',
      'options': [
        'Une ligne plus structurée',
        'Encore plus de volume partout',
        'Une longueur gênante',
        'Des finitions floues',
      ],
      'correctAnswer': 0,
      'explanation':
          'La structure donne une silhouette plus nette et facilite la composition d’un look.',
    },
    {
      'category': 'Budget',
      'question': 'Avec un budget serré, tu priorises quoi ?',
      'options': [
        'Une pièce forte compatible',
        'Plusieurs achats fragiles',
        'Des doublons inutiles',
        'Une taille approximative',
      ],
      'correctAnswer': 0,
      'explanation':
          'Une pièce compatible avec ta garde-robe se réutilise mieux et évite les achats dispersés.',
    },
    {
      'category': 'Budget',
      'question': 'Quand choisir plutôt un créateur ?',
      'options': [
        'Besoin d’ajustement précis',
        'Commande sans mesures',
        'Aucune idée de l’occasion',
        'Pas de délai',
      ],
      'correctAnswer': 0,
      'explanation':
          'Un créateur est précieux quand la coupe, les mesures ou l’occasion demandent du sur mesure.',
    },
    {
      'category': 'Matières',
      'question':
          'Aujourd’hui il fait chaud dans votre zone : quelle matière privilégier ?',
      'options': [
        'Coton léger',
        'Vinyle épais',
        'Laine lourde',
        'Simili cuir fermé',
      ],
      'correctAnswer': 0,
      'explanation':
          'Le coton léger respire mieux et reste adapté aux journées chaudes.',
    },
    {
      'category': 'Beauté',
      'question':
          'Si la tenue est chargée, le détail beauté le plus sûr est...',
      'options': [
        'Une finition nette',
        'Tout accentuer',
        'Ajouter sans regarder',
        'Changer de style au hasard',
      ],
      'correctAnswer': 0,
      'explanation':
          'Une finition nette relie coiffure, maquillage et tenue sans surcharger.',
    },
    {
      'category': 'Synthèse',
      'question': 'Après plusieurs choix, le meilleur signal à garder est...',
      'options': [
        'Ce qui revient souvent',
        'Ce qui contredit tout',
        'Le choix le moins porté',
        'Le hasard complet',
      ],
      'correctAnswer': 0,
      'explanation':
          'Les préférences répétées construisent un profil style utile pour le Salon et le moodboard.',
    },
    {
      'category': 'Accessoires',
      'question':
          'Pour une cérémonie avec un textile fort, quel accessoire équilibre mieux la tenue ?',
      'options': [
        'Bijou sobre',
        'Quatre colliers imposants',
        'Sac sans couleur liée',
        'Chaussures abîmées',
      ],
      'correctAnswer': 0,
      'explanation':
          'Un bijou sobre valorise le textile sans créer de surcharge.',
    },
    {
      'category': 'Bureau',
      'question':
          'Quelle option rend un textile expressif plus professionnel au bureau ?',
      'options': [
        'Coupe droite et repassée',
        'Motifs concurrents partout',
        'Ourlets négligés',
        'Accessoires trop brillants',
      ],
      'correctAnswer': 0,
      'explanation':
          'La coupe droite et les finitions propres donnent une présence plus professionnelle.',
    },
    {
      'category': 'Couleurs',
      'question': 'Quel réflexe harmonise vite une tenue colorée ?',
      'options': [
        'Répéter une couleur en rappel',
        'Ajouter trois couleurs au hasard',
        'Supprimer tous les neutres',
        'Changer chaque accessoire',
      ],
      'correctAnswer': 0,
      'explanation':
          'Un rappel de couleur relie les pièces et rend la silhouette plus lisible.',
    },
    {
      'category': 'Morphologie',
      'question':
          'Si le haut est ample, quel bas équilibre souvent mieux la silhouette ?',
      'options': [
        'Un bas droit ou ajusté',
        'Un bas encore plus volumineux',
        'Un bas sans ourlet',
        'Un bas trop long',
      ],
      'correctAnswer': 0,
      'explanation':
          'Alterner volume et structure aide à garder des proportions nettes.',
    },
    {
      'category': 'Culture',
      'question': 'Le SIAO valorise surtout quel univers ?',
      'options': [
        'L’artisanat africain',
        'Les sports nautiques',
        'La mécanique auto',
        'Les jeux vidéo',
      ],
      'correctAnswer': 0,
      'explanation':
          'Le SIAO met en avant les savoir-faire artisanaux africains.',
    },
    {
      'category': 'Entretien',
      'question': 'Quel geste protège mieux un textile teint naturellement ?',
      'options': [
        'Laver doucement à l’eau froide',
        'Frotter avec du sable',
        'Sécher longtemps en plein soleil',
        'Utiliser une eau très chaude',
      ],
      'correctAnswer': 0,
      'explanation':
          'Un lavage doux à froid préserve mieux les fibres et les couleurs.',
    },
    {
      'category': 'Sortie',
      'question': 'Pour une sortie, comment porter une pièce imprimée forte ?',
      'options': [
        'Avec une base simple',
        'Avec cinq motifs concurrents',
        'Avec des chaussures usées',
        'Sans vérifier la coupe',
      ],
      'correctAnswer': 0,
      'explanation':
          'Une base simple laisse la pièce forte attirer le regard de façon élégante.',
    },
    {
      'category': 'Accessoires',
      'question':
          'Quand la tenue est déjà très expressive, quel choix est le plus sûr ?',
      'options': [
        'Accessoires sobres',
        'Accumulation brillante',
        'Couleurs sans lien',
        'Sac trop chargé',
      ],
      'correctAnswer': 0,
      'explanation': 'Des accessoires sobres gardent l’équilibre visuel.',
    },
    {
      'category': 'Matières',
      'question':
          'Pourquoi une matière locale respirante est-elle utile en mode ?',
      'options': [
        'Il soutient une filière locale et respire bien',
        'Il interdit la teinture',
        'Il ne se coud pas',
        'Il remplace tous les accessoires',
      ],
      'correctAnswer': 0,
      'explanation':
          'Le coton local associe confort, identité et soutien aux savoir-faire.',
    },
  ];
}
