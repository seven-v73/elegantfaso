import 'package:elegantfaso/services/client/client_gamification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientGamificationService', () {
    test('keeps the streak unchanged when the same day is rewarded again', () {
      expect(
        ClientGamificationService.nextStreakFor(
          today: '2026-05-04',
          lastDate: '2026-05-04',
          current: 5,
        ),
        5,
      );
    });

    test('increments the streak when yesterday was rewarded', () {
      expect(
        ClientGamificationService.nextStreakFor(
          today: '2026-05-04',
          lastDate: '2026-05-03',
          current: 5,
        ),
        6,
      );
    });

    test('resets the streak after a gap', () {
      expect(
        ClientGamificationService.nextStreakFor(
          today: '2026-05-04',
          lastDate: '2026-05-01',
          current: 5,
        ),
        1,
      );
    });

    test('builds a stable reward id for daily idempotency', () {
      expect(
        ClientGamificationService.rewardIdFor(
          type: 'daily quiz',
          date: '2026-05-04',
        ),
        '2026-05-04_daily_quiz',
      );
    });
  });
}
