import 'package:elegantfaso/core/account_roles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountRoles', () {
    test('normalise les roles au format liste', () {
      final roles = AccountRoles.normalize({
        'roles': ['client', 'boutique', 'createur'],
      });

      expect(roles, containsAll(['client', 'boutique', 'createur']));
    });

    test('normalise les roles au format map Firestore', () {
      final roles = AccountRoles.normalize({
        'roles': {'client': true, 'boutique': true, 'creator': true},
      });

      expect(roles, containsAll(['client', 'boutique', 'createur']));
    });

    test('normalise les roles depuis roleFlags et onboarding', () {
      final roles = AccountRoles.normalize({
        'roleFlags': {'isShop': true},
        'businessOnboarding': {
          'createur': {'status': 'active'},
        },
      });

      expect(roles, containsAll(['client', 'boutique', 'createur']));
    });
  });
}
