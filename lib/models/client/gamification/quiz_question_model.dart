class QuizQuestionModel {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String category;
  final int difficulty;

  const QuizQuestionModel({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.category,
    required this.difficulty,
  });

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    final options =
        (map['options'] as List<dynamic>?)
            ?.map((option) => option.toString())
            .take(4)
            .toList() ??
        const ['Option 1', 'Option 2', 'Option 3', 'Option 4'];

    final correctAnswer = (map['correctAnswer'] as num?)?.toInt() ?? 0;

    return QuizQuestionModel(
      question: map['question']?.toString() ?? 'Question de style',
      options: options,
      correctAnswer: correctAnswer.clamp(0, 3),
      explanation:
          map['explanation']?.toString() ??
          'Cette réponse aide à mieux choisir une tenue.',
      category: map['category']?.toString() ?? 'Mode africaine',
      difficulty: ((map['difficulty'] as num?)?.toInt() ?? 1).clamp(1, 3),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options.take(4).toList(),
      'correctAnswer': correctAnswer.clamp(0, 3),
      'explanation': explanation,
      'category': category,
      'difficulty': difficulty.clamp(1, 3),
    };
  }
}
