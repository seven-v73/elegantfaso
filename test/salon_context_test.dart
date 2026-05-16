import 'package:elegantfaso/models/salon/salon_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalonContext', () {
    test('detecte le type et l’occasion depuis une recherche utilisateur', () {
      final context = SalonContext.fromQuery(
        'coiffure mariage Dakar',
        source: 'test',
      );

      expect(context.type, 'coiffure');
      expect(context.occasion, 'mariage');
      expect(context.source, 'test');
      expect(context.displayQuery, contains('coiffure mariage Dakar'));
    });

    test(
      'porte une portée mondiale, pays ou proximité sans perdre la requête',
      () {
        final context = SalonContext.fromQuery(
          'tenue bureau',
        ).copyWith(scope: SalonDiscoveryScope.country, country: 'Sénégal');

        expect(context.scope, SalonDiscoveryScope.country);
        expect(context.country, 'Sénégal');
        expect(context.displayQuery, contains('tenue bureau'));
        expect(context.displayQuery, contains('Sénégal'));
      },
    );

    test('considère ville et pays comme contexte exploitable', () {
      const context = SalonContext(
        city: 'Abidjan',
        country: 'Côte d’Ivoire',
        scope: SalonDiscoveryScope.nearby,
      );

      expect(context.isEmpty, isFalse);
      expect(context.displayQuery, 'Abidjan Côte d’Ivoire');
    });
  });
}
