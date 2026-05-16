import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../design/app_icons.dart';
import '../../models/client/client_dashboard_summary.dart';
import '../../models/client/gamification/client_visibility_tier.dart';
import '../../models/client/gamification/daily_challenge_model.dart';
import '../../models/client/gamification/style_badge_model.dart';
import '../../models/client/gamification/style_progress_model.dart';

class ClientGamificationService {
  ClientGamificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<StyleProgressModel> watchProgress({
    required String userId,
    required ClientDashboardSummary summary,
  }) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data() ?? const {};
      final gamification = Map<String, dynamic>.from(
        data['gamification'] as Map? ?? const {},
      );
      final today = _todayKey();
      final lastActivityDate = gamification['lastActivityDate']?.toString();
      final completedToday =
          lastActivityDate == today
              ? List<String>.from(
                gamification['completedChallengesToday'] ?? const [],
              )
              : <String>[];
      final points = (gamification['points'] as num?)?.toInt() ?? 0;
      final lifetimePoints =
          (gamification['lifetimePoints'] as num?)?.toInt() ?? points;
      final pointBuckets = _pointBucketsFrom(gamification);
      final storedStyleStreak =
          (gamification['styleStreak'] as num?)?.toInt() ??
          (gamification['streak'] as num?)?.toInt() ??
          0;
      final streak =
          lastActivityDate == today
              ? storedStyleStreak
              : _isYesterday(lastActivityDate)
              ? storedStyleStreak
              : 0;
      final quizStreak = (gamification['quizStreak'] as num?)?.toInt() ?? 0;
      final quizCompleted =
          data['quizStats'] is Map &&
          (data['quizStats']['lastQuizDate']?.toString() == today);
      final styleSignals = Map<String, dynamic>.from(
        data['styleSignals'] as Map? ?? const {},
      );
      final visibilityTier = ClientVisibilityTiers.fromPoints(lifetimePoints);
      final dailyTheme = _dailyThemeFor(today);

      return StyleProgressModel(
        points: points,
        lifetimePoints: lifetimePoints,
        streak: streak,
        nextLevelPoints: visibilityTier.nextPoints,
        quizCompletedToday: quizCompleted,
        dailyTheme: dailyTheme,
        dailyPrompt: _dailyPromptFor(
          theme: dailyTheme,
          summary: summary,
          quizCompleted: quizCompleted,
        ),
        ritualLabel: _ritualLabelFor(
          quizCompleted: quizCompleted,
          completedToday: completedToday,
        ),
        focusLabel: _focusLabelFor(pointBuckets),
        styleInsight: _styleInsightFor(styleSignals, dailyTheme),
        nextStyleAction: _nextStyleActionFor(styleSignals, summary),
        styleDirection: _styleDirectionFor(pointBuckets, styleSignals),
        recentThemes: _recentThemesFrom(styleSignals, dailyTheme),
        completedTodayIds: completedToday,
        pointBuckets: pointBuckets,
        challenges: _buildChallenges(
          summary,
          completedToday,
          quizCompleted: quizCompleted,
        ),
        badges: _buildBadges(
          summary,
          lifetimePoints,
          quizCompleted,
          pointBuckets,
          quizStreak,
        ),
        visibilityTier: visibilityTier,
      );
    });
  }

  Future<int> completeChallenge({
    required String userId,
    required DailyChallengeModel challenge,
  }) async {
    if (challenge.completed) return 0;
    final today = _todayKey();
    final ref = _firestore.collection('users').doc(userId);
    final rewardRef = ref
        .collection('style_rewards')
        .doc(rewardIdFor(type: 'challenge_${challenge.id}', date: today));
    return _firestore.runTransaction<int>((transaction) async {
      final rewardSnapshot = await transaction.get(rewardRef);
      if (rewardSnapshot.exists) return 0;

      final snapshot = await transaction.get(ref);
      final data = snapshot.data() ?? const {};
      final gamification = Map<String, dynamic>.from(
        data['gamification'] as Map? ?? const {},
      );
      final lastActivityDate = gamification['lastActivityDate']?.toString();
      final currentStyleStreak =
          (gamification['styleStreak'] as num?)?.toInt() ??
          (gamification['streak'] as num?)?.toInt() ??
          0;
      final styleStreak = nextStreakFor(
        today: today,
        lastDate: lastActivityDate,
        current: currentStyleStreak,
      );
      final completedToday =
          lastActivityDate == today
              ? FieldValue.arrayUnion([challenge.id])
              : [challenge.id];

      transaction.set(ref, {
        'gamification': {
          'points': FieldValue.increment(challenge.points),
          'lifetimePoints': FieldValue.increment(challenge.points),
          'pointBuckets.${challenge.pointCategory}': FieldValue.increment(
            challenge.points,
          ),
          'streak': styleStreak,
          'styleStreak': styleStreak,
          'lastActivityDate': today,
          'completedChallengesToday': completedToday,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      transaction.set(rewardRef, {
        'userId': userId,
        'type': 'challenge',
        'challengeId': challenge.id,
        'pointCategory': challenge.pointCategory,
        'points': challenge.points,
        'date': today,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        ref.collection('visibility_activity').doc('${today}_${challenge.id}'),
        {
          'type': 'challenge',
          'challengeId': challenge.id,
          'pointCategory': challenge.pointCategory,
          'title': challenge.title,
          'points': challenge.points,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return challenge.points;
    });
  }

  Future<int> awardQuizPoints({
    required String userId,
    required int points,
    required String quizDate,
  }) async {
    if (points <= 0) return 0;
    final ref = _firestore.collection('users').doc(userId);
    final rewardRef = ref
        .collection('style_rewards')
        .doc(rewardIdFor(type: 'daily_quiz', date: quizDate));
    return _firestore.runTransaction<int>((transaction) async {
      final rewardSnapshot = await transaction.get(rewardRef);
      if (rewardSnapshot.exists) return 0;

      final snapshot = await transaction.get(ref);
      final data = snapshot.data() ?? const {};
      final gamification = Map<String, dynamic>.from(
        data['gamification'] as Map? ?? const {},
      );
      final lastActivityDate = gamification['lastActivityDate']?.toString();
      final lastQuizDate =
          gamification['lastQuizDate']?.toString() ??
          (data['quizStats'] is Map
              ? data['quizStats']['previousQuizDate']?.toString()
              : null);
      final currentStyleStreak =
          (gamification['styleStreak'] as num?)?.toInt() ??
          (gamification['streak'] as num?)?.toInt() ??
          0;
      final currentQuizStreak =
          (gamification['quizStreak'] as num?)?.toInt() ??
          (data['quizStats'] is Map
              ? (data['quizStats']['streak'] as num?)?.toInt()
              : null) ??
          0;
      final styleStreak = nextStreakFor(
        today: quizDate,
        lastDate: lastActivityDate,
        current: currentStyleStreak,
      );
      final quizStreak = nextStreakFor(
        today: quizDate,
        lastDate: lastQuizDate,
        current: currentQuizStreak,
      );
      final completedToday =
          lastActivityDate == quizDate
              ? FieldValue.arrayUnion(['daily_quiz'])
              : ['daily_quiz'];

      transaction.set(ref, {
        'gamification': {
          'points': FieldValue.increment(points),
          'lifetimePoints': FieldValue.increment(points),
          'pointBuckets.style': FieldValue.increment(points),
          'lastActivityDate': quizDate,
          'lastQuizDate': quizDate,
          'streak': styleStreak,
          'styleStreak': styleStreak,
          'quizStreak': quizStreak,
          'completedChallengesToday': completedToday,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      transaction.set(rewardRef, {
        'userId': userId,
        'type': 'daily_quiz',
        'pointCategory': 'style',
        'points': points,
        'date': quizDate,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        ref.collection('visibility_activity').doc('${quizDate}_daily_quiz'),
        {
          'type': 'quiz',
          'challengeId': 'daily_quiz',
          'pointCategory': 'style',
          'title': 'Quiz style du jour',
          'points': points,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return points;
    });
  }

  Future<ClientVisibilityTier> loadVisibilityTier(String? userId) async {
    if (userId == null || userId.isEmpty) return ClientVisibilityTiers.explorer;
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data() ?? const {};
    final gamification = data['gamification'];
    if (gamification is! Map) return ClientVisibilityTiers.explorer;
    final lifetimePoints =
        (gamification['lifetimePoints'] as num?)?.toInt() ??
        (gamification['points'] as num?)?.toInt() ??
        0;
    return ClientVisibilityTiers.fromPoints(lifetimePoints);
  }

  static ClientVisibilityTier visibilityTierForPoints(int points) {
    return ClientVisibilityTiers.fromPoints(points);
  }

  List<DailyChallengeModel> _buildChallenges(
    ClientDashboardSummary summary,
    List<String> completedToday, {
    required bool quizCompleted,
  }) {
    final challenges = <DailyChallengeModel>[
      DailyChallengeModel(
        id: 'daily_quiz',
        title: 'Réveil Style',
        subtitle: '3 minutes pour apprendre un détail qui change un look',
        intent: 'quiz',
        pointCategory: 'style',
        points: 70,
        icon: Icons.quiz_rounded,
        completed: quizCompleted || completedToday.contains('daily_quiz'),
        actionLabel: quizCompleted ? 'Revoir' : 'Jouer',
        proofHint: 'Récompense une seule fois par jour',
      ),
      DailyChallengeModel(
        id: 'save_inspiration',
        title: 'Trouver ton détail du jour',
        subtitle: 'Garde une inspiration qui peut servir à ton prochain look',
        intent: 'salon',
        pointCategory: 'discovery',
        points: 35,
        icon: AppIcons.save,
        completed:
            summary.wishlistCount > 0 ||
            completedToday.contains('save_inspiration'),
        actionLabel: 'Explorer',
      ),
      DailyChallengeModel(
        id: 'ask_style_advice',
        title: 'Transformer une hésitation',
        subtitle: 'Demande un avis à Iris pour rendre une idée portable',
        intent: 'style',
        pointCategory: 'style',
        points: 25,
        icon: AppIcons.style,
        completed:
            completedToday.contains('ask_style_advice') ||
            completedToday.contains('ask_iris'),
        actionLabel: 'Demander',
      ),
    ];

    if (summary.wardrobeCount < 5) {
      challenges.add(
        DailyChallengeModel(
          id: 'add_wardrobe',
          title: 'Faire entrer une pièce',
          subtitle: 'Ta garde-robe devient plus intelligente à chaque ajout',
          intent: 'wardrobe',
          pointCategory: 'trust',
          points: 40,
          icon: AppIcons.wardrobe,
          completed: completedToday.contains('add_wardrobe'),
          actionLabel: 'Ajouter',
        ),
      );
    } else if (summary.measurementCompletion < 0.85) {
      challenges.add(
        DailyChallengeModel(
          id: 'complete_measurements',
          title: 'Ajuster ton profil coupe',
          subtitle: 'Quelques mesures pour mieux commander et essayer',
          intent: 'measurements',
          pointCategory: 'trust',
          points: 45,
          icon: AppIcons.measurements,
          completed: completedToday.contains('complete_measurements'),
          actionLabel: 'Compléter',
        ),
      );
    } else {
      challenges.add(
        DailyChallengeModel(
          id: 'try_on',
          title: 'Tester une silhouette',
          subtitle: 'Essaie une pièce avant de contacter ou commander',
          intent: 'try_on',
          pointCategory: 'style',
          points: 30,
          icon: Icons.view_in_ar_rounded,
          completed: completedToday.contains('try_on'),
          actionLabel: 'Essayer',
        ),
      );
    }

    final socialChallenge =
        summary.unreadMessagesCount > 0
            ? DailyChallengeModel(
              id: 'kind_exchange',
              title: 'Répondre avec attention',
              subtitle: 'Une bonne réponse crée de la confiance',
              intent: 'messages',
              pointCategory: 'community',
              points: 35,
              icon: AppIcons.messages,
              completed: completedToday.contains('kind_exchange'),
              actionLabel: 'Répondre',
            )
            : DailyChallengeModel(
              id: 'ask_community_style',
              title: 'Ouvrir une discussion',
              subtitle: 'Demande un avis ou aide quelqu’un sur son look',
              intent: 'community',
              pointCategory: 'community',
              points: 35,
              icon: Icons.forum_rounded,
              completed: completedToday.contains('ask_community_style'),
              actionLabel: 'Échanger',
            );

    return [...challenges.take(3), socialChallenge];
  }

  List<StyleBadgeModel> _buildBadges(
    ClientDashboardSummary summary,
    int lifetimePoints,
    bool quizCompleted,
    List<StylePointBucket> pointBuckets,
    int quizStreak,
  ) {
    return [
      StyleBadgeModel(
        id: 'first_piece',
        label: 'Première pièce',
        description: 'Une pièce ajoutée à la garde-robe',
        icon: AppIcons.wardrobe,
        unlocked: summary.wardrobeCount > 0,
      ),
      StyleBadgeModel(
        id: 'curator',
        label: 'Curateur',
        description: '5 souhaits ou favoris sauvegardés',
        icon: AppIcons.favorites,
        unlocked: summary.wishlistCount >= 5,
      ),
      StyleBadgeModel(
        id: 'precise_fit',
        label: 'Tailles prêtes',
        description: 'Mensurations complètes',
        icon: AppIcons.measurements,
        unlocked: summary.measurementCompletion >= 0.85,
      ),
      StyleBadgeModel(
        id: 'daily_mindset',
        label: 'Rituel style',
        description: 'Quiz du jour terminé',
        icon: AppIcons.today,
        unlocked: quizCompleted,
      ),
      StyleBadgeModel(
        id: 'regular_learner',
        label: 'Régulier',
        description: '7 jours de quiz dans ton rythme style',
        icon: Icons.local_fire_department_rounded,
        unlocked: quizStreak >= 7,
      ),
      StyleBadgeModel(
        id: 'stylist_eye',
        label: 'Œil de styliste',
        description: 'Tu progresses dans les quiz et les choix de style',
        icon: Icons.visibility_rounded,
        unlocked: lifetimePoints >= 300,
      ),
      StyleBadgeModel(
        id: 'kind_guide',
        label: 'Guide bienveillant',
        description: 'Tu participes à des échanges utiles et respectueux',
        icon: Icons.volunteer_activism_rounded,
        unlocked:
            _bucketValue(pointBuckets: pointBuckets, id: 'community') >= 300,
      ),
      StyleBadgeModel(
        id: 'visibility_curator',
        label: 'Curateur',
        description: '600 points: visibilité légère pour tes pièces',
        icon: AppIcons.award,
        unlocked: lifetimePoints >= 600,
      ),
      StyleBadgeModel(
        id: 'trusted_client',
        label: 'Confiance',
        description: '1200 points: tes annonces sont mieux recommandées',
        icon: Icons.verified_user_rounded,
        unlocked: lifetimePoints >= 1200,
      ),
      StyleBadgeModel(
        id: 'circular_ambassador',
        label: 'Ambassadeur',
        description: '2500 points: priorité communauté dans le Vide-dressing',
        icon: Icons.recycling_rounded,
        unlocked: lifetimePoints >= 2500,
      ),
    ];
  }

  List<StylePointBucket> _pointBucketsFrom(Map<String, dynamic> gamification) {
    final raw = gamification['pointBuckets'];
    final map = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    int value(String key) => (map[key] as num?)?.toInt() ?? 0;
    return [
      StylePointBucket(
        id: 'style',
        label: 'Style',
        description: 'Quiz, essayage, Iris et garde-robe',
        points: value('style'),
      ),
      StylePointBucket(
        id: 'discovery',
        label: 'Découverte',
        description: 'Salon, talents, stories et inspirations',
        points: value('discovery'),
      ),
      StylePointBucket(
        id: 'community',
        label: 'Communauté',
        description: 'Échanges, conseils et entraide',
        points: value('community'),
      ),
      StylePointBucket(
        id: 'trust',
        label: 'Confiance',
        description: 'Profil, avis, garde-robe et ventes fiables',
        points: value('trust'),
      ),
    ];
  }

  String _focusLabelFor(List<StylePointBucket> buckets) {
    final sorted = [...buckets]..sort((a, b) => b.points.compareTo(a.points));
    final top = sorted.first;
    if (top.points == 0) return 'Commence ton parcours par le quiz du jour';
    return 'Ta force actuelle : ${top.label.toLowerCase()}';
  }

  String _styleInsightFor(Map<String, dynamic> signals, String theme) {
    final learned = signals['lastLearned']?.toString().trim();
    if (learned != null && learned.isNotEmpty) {
      return learned;
    }
    final tip = signals['lastTip']?.toString().trim();
    if (tip != null && tip.isNotEmpty) {
      return tip;
    }
    return '$theme: observe ce que tu choisis naturellement.';
  }

  String _nextStyleActionFor(
    Map<String, dynamic> signals,
    ClientDashboardSummary summary,
  ) {
    final action = signals['lastAction']?.toString().trim();
    if (action != null && action.isNotEmpty) return action;
    if (summary.wardrobeCount < 5) {
      return 'Ajoute une pièce réelle pour révéler tes habitudes.';
    }
    if (summary.savedItems.isNotEmpty) {
      return 'Repars d’une inspiration sauvegardée et compose un look.';
    }
    return 'Explore sans acheter : sauvegarde ce qui te parle.';
  }

  List<String> _recentThemesFrom(
    Map<String, dynamic> signals,
    String dailyTheme,
  ) {
    final raw = signals['recentThemes'];
    final themes =
        raw is List
            ? raw
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toSet()
                .toList()
            : <String>[];
    if (themes.isEmpty) return [dailyTheme];
    return themes.reversed.take(5).toList();
  }

  String _styleDirectionFor(
    List<StylePointBucket> buckets,
    Map<String, dynamic> signals,
  ) {
    final sorted = [...buckets]..sort((a, b) => b.points.compareTo(a.points));
    final top = sorted.first;
    final second = sorted.length > 1 ? sorted[1] : top;
    final theme = signals['lastTheme']?.toString().trim();
    final themePart = theme == null || theme.isEmpty ? '' : ' autour de $theme';

    if (top.points == 0) {
      return 'Ton profil se forme avec tes premiers choix.';
    }
    if (top.id == 'style' && second.id == 'discovery') {
      return 'Tu construis un style curieux$themePart.';
    }
    if (top.id == 'style' && second.id == 'trust') {
      return 'Tu avances vers un style précis et portable$themePart.';
    }
    if (top.id == 'discovery') {
      return 'Tu découvres beaucoup : tes goûts se dessinent par comparaison.';
    }
    if (top.id == 'community') {
      return 'Ton style se construit avec les regards et les échanges.';
    }
    if (top.id == 'trust') {
      return 'Tu rends ton style plus fiable avec des bases concrètes.';
    }
    return 'Ton profil style devient plus clair à chaque action.';
  }

  String _dailyThemeFor(String date) {
    final weekday = DateTime.tryParse(date)?.weekday ?? DateTime.now().weekday;
    const themes = {
      DateTime.monday: 'Couleurs',
      DateTime.tuesday: 'Occasions',
      DateTime.wednesday: 'Silhouette',
      DateTime.thursday: 'Budget',
      DateTime.friday: 'Matières',
      DateTime.saturday: 'Beauté',
      DateTime.sunday: 'Résumé Style',
    };
    return themes[weekday] ?? 'Style personnel';
  }

  String _dailyPromptFor({
    required String theme,
    required ClientDashboardSummary summary,
    required bool quizCompleted,
  }) {
    if (!quizCompleted) {
      return '$theme: un choix court pour mieux te comprendre.';
    }
    if (summary.savedItems.isNotEmpty) {
      return '$theme: transforme une inspiration sauvegardée.';
    }
    if (summary.wardrobeCount < 5) {
      return '$theme: ajoute une pièce réelle pour affiner tes conseils.';
    }
    return '$theme: observe, essaie ou demande un avis.';
  }

  String _ritualLabelFor({
    required bool quizCompleted,
    required List<String> completedToday,
  }) {
    if (!quizCompleted) return 'À lancer';
    final extraActions =
        completedToday.where((id) => id != 'daily_quiz').toSet().length;
    if (extraActions >= 2) return 'Très vivant';
    if (extraActions == 1) return 'En mouvement';
    return 'Quiz terminé';
  }

  int _bucketValue({
    required List<StylePointBucket>? pointBuckets,
    required String id,
  }) {
    if (pointBuckets == null) return 0;
    return pointBuckets
        .firstWhere(
          (bucket) => bucket.id == id,
          orElse:
              () => const StylePointBucket(
                id: '',
                label: '',
                description: '',
                points: 0,
              ),
        )
        .points;
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String rewardIdFor({required String type, required String date}) {
    return '${date}_$type'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  static int nextStreakFor({
    required String today,
    required String? lastDate,
    required int current,
  }) {
    if (lastDate == today) return current;
    if (_isPreviousDay(lastDate, today)) return current + 1;
    return 1;
  }

  static bool _isYesterday(String? value) {
    if (value == null || value.isEmpty) return false;
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final key =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    return value == key;
  }

  static bool _isPreviousDay(String? value, String today) {
    if (value == null || value.isEmpty) return false;
    final todayDate = DateTime.tryParse(today);
    if (todayDate == null) return false;
    final previous = todayDate.subtract(const Duration(days: 1));
    final key =
        '${previous.year.toString().padLeft(4, '0')}-${previous.month.toString().padLeft(2, '0')}-${previous.day.toString().padLeft(2, '0')}';
    return value == key;
  }
}
