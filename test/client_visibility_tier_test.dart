import 'package:elegantfaso/models/client/gamification/client_visibility_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('attribue les niveaux de visibilité selon les points cumulés', () {
    expect(ClientVisibilityTiers.fromPoints(0).id, 'explorer');
    expect(ClientVisibilityTiers.fromPoints(600).id, 'curator');
    expect(ClientVisibilityTiers.fromPoints(1200).id, 'trusted');
    expect(ClientVisibilityTiers.fromPoints(2500).id, 'ambassador');
  });

  test('calcule la progression vers le niveau suivant', () {
    final tier = ClientVisibilityTiers.curator;

    expect(tier.progressFor(600), 0);
    expect(tier.progressFor(900), 0.5);
    expect(tier.pointsToNext(900), 300);
  });
}
