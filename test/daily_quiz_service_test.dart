import 'package:elegantfaso/models/client/gamification/quiz_question_model.dart';
import 'package:elegantfaso/services/client/daily_quiz_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyQuizService', () {
    test('shuffles answers without losing the correct option', () {
      const question = QuizQuestionModel(
        question: 'Quelle matière respire mieux ?',
        options: ['Coton léger', 'Vinyle épais', 'Laine lourde', 'Simili cuir'],
        correctAnswer: 0,
        explanation: 'Le coton léger respire mieux.',
        category: 'Matières',
        difficulty: 1,
      );

      final shuffled = DailyQuizService.shuffleQuestionOptions(
        question,
        '2026-05-04-user-matieres',
      );

      expect(shuffled.options, contains('Coton léger'));
      expect(shuffled.options[shuffled.correctAnswer], 'Coton léger');
      expect(shuffled.options.toSet(), question.options.toSet());
    });

    test('uses a stable order for the same seed', () {
      const question = QuizQuestionModel(
        question: 'Quel accessoire équilibre une tenue forte ?',
        options: [
          'Bijou sobre',
          'Quatre colliers',
          'Sac sans lien',
          'Chaussures abîmées',
        ],
        correctAnswer: 0,
        explanation: 'Le bijou sobre garde l’équilibre.',
        category: 'Accessoires',
        difficulty: 1,
      );

      final first = DailyQuizService.shuffleQuestionOptions(
        question,
        'seed-accessoires',
      );
      final second = DailyQuizService.shuffleQuestionOptions(
        question,
        'seed-accessoires',
      );

      expect(second.options, first.options);
      expect(second.correctAnswer, first.correctAnswer);
    });
  });
}
