import 'daily_challenge_model.dart';
import 'client_visibility_tier.dart';
import 'style_badge_model.dart';

class StylePointBucket {
  final String id;
  final String label;
  final String description;
  final int points;

  const StylePointBucket({
    required this.id,
    required this.label,
    required this.description,
    required this.points,
  });
}

class StyleProgressModel {
  final int points;
  final int lifetimePoints;
  final int streak;
  final int nextLevelPoints;
  final bool quizCompletedToday;
  final String dailyTheme;
  final String dailyPrompt;
  final String ritualLabel;
  final String focusLabel;
  final String styleInsight;
  final String nextStyleAction;
  final String styleDirection;
  final List<String> recentThemes;
  final List<String> completedTodayIds;
  final List<StylePointBucket> pointBuckets;
  final List<DailyChallengeModel> challenges;
  final List<StyleBadgeModel> badges;
  final ClientVisibilityTier visibilityTier;

  const StyleProgressModel({
    required this.points,
    required this.lifetimePoints,
    required this.streak,
    required this.nextLevelPoints,
    required this.quizCompletedToday,
    required this.dailyTheme,
    required this.dailyPrompt,
    required this.ritualLabel,
    required this.focusLabel,
    required this.styleInsight,
    required this.nextStyleAction,
    required this.styleDirection,
    this.recentThemes = const [],
    this.completedTodayIds = const [],
    required this.pointBuckets,
    required this.challenges,
    required this.badges,
    required this.visibilityTier,
  });

  String get levelLabel => visibilityTier.label;

  double get progressToNextLevel {
    return visibilityTier.progressFor(lifetimePoints);
  }

  int get pointsToNextLevel => visibilityTier.pointsToNext(lifetimePoints);

  int get visibilityPercent =>
      ((visibilityTier.visibilityBoost - 1) * 100).round();
}
