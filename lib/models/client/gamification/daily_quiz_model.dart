import 'quiz_question_model.dart';

class DailyQuizModel {
  final String date;
  final String title;
  final String subtitle;
  final int progress;
  final int target;
  final bool completed;
  final int points;
  final int difficulty;
  final String styleTip;
  final String outfitSuggestion;
  final String learnedToday;
  final bool bonusUnlocked;
  final String rewardLabel;
  final String badgeLabel;
  final List<QuizQuestionModel> questions;

  const DailyQuizModel({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.target,
    required this.completed,
    required this.points,
    required this.difficulty,
    required this.styleTip,
    required this.outfitSuggestion,
    required this.learnedToday,
    required this.bonusUnlocked,
    required this.rewardLabel,
    required this.badgeLabel,
    required this.questions,
  });

  factory DailyQuizModel.fromMap(Map<String, dynamic> map) {
    final questions =
        (map['questions'] as List<dynamic>?)
            ?.whereType<Map>()
            .map(
              (item) =>
                  QuizQuestionModel.fromMap(Map<String, dynamic>.from(item)),
            )
            .where((question) => question.options.length == 4)
            .take(5)
            .toList() ??
        <QuizQuestionModel>[];

    return DailyQuizModel(
      date: map['date']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Parcours du jour',
      subtitle: map['subtitle']?.toString() ?? 'Mode locale',
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      target: (map['target'] as num?)?.toInt() ?? 5,
      completed: _boolFrom(map['completed']),
      points: (map['points'] as num?)?.toInt() ?? 70,
      difficulty: ((map['difficulty'] as num?)?.toInt() ?? 1).clamp(1, 3),
      styleTip:
          map['styleTip']?.toString() ??
          'Choisis une pièce forte et construis le reste autour.',
      outfitSuggestion:
          map['outfitSuggestion']?.toString() ??
          'Base neutre, pièce locale bien coupée et accessoire discret.',
      learnedToday:
          map['learnedToday']?.toString() ??
          'matières, couleurs, coupe et accessoires sobres',
      bonusUnlocked: _boolFrom(map['bonusUnlocked']),
      rewardLabel: map['rewardLabel']?.toString() ?? '',
      badgeLabel: map['badgeLabel']?.toString() ?? '',
      questions: questions,
    );
  }

  static bool _boolFrom(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes' || text == 'oui') {
      return true;
    }
    if (text == 'false' || text == '0' || text == 'no' || text == 'non') {
      return false;
    }
    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'title': title,
      'subtitle': subtitle,
      'progress': progress,
      'target': target,
      'completed': completed,
      'points': points,
      'difficulty': difficulty,
      'styleTip': styleTip,
      'outfitSuggestion': outfitSuggestion,
      'learnedToday': learnedToday,
      'bonusUnlocked': bonusUnlocked,
      'rewardLabel': rewardLabel,
      'badgeLabel': badgeLabel,
      'questions': questions.map((question) => question.toMap()).toList(),
    };
  }

  DailyQuizModel copyWith({
    int? progress,
    bool? completed,
    bool? bonusUnlocked,
    String? rewardLabel,
    String? badgeLabel,
    String? learnedToday,
  }) {
    return DailyQuizModel(
      date: date,
      title: title,
      subtitle: subtitle,
      progress: progress ?? this.progress,
      target: target,
      completed: completed ?? this.completed,
      points: points,
      difficulty: difficulty,
      styleTip: styleTip,
      outfitSuggestion: outfitSuggestion,
      learnedToday: learnedToday ?? this.learnedToday,
      bonusUnlocked: bonusUnlocked ?? this.bonusUnlocked,
      rewardLabel: rewardLabel ?? this.rewardLabel,
      badgeLabel: badgeLabel ?? this.badgeLabel,
      questions: questions,
    );
  }
}
