import 'package:elegantfaso/models/salon/salon_action.dart';
import 'package:elegantfaso/models/salon/salon_item.dart';
import 'package:elegantfaso/services/salon/salon_recently_viewed_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('mémorise les contenus récents sans doublons', () async {
    final service = SalonRecentlyViewedService();
    final first = _item('1', 'Robe fluide');
    final second = _item('2', 'Coiffeur mariage');

    await service.remember(first);
    await service.remember(second);
    await service.remember(first);

    final items = await service.load();

    expect(items, hasLength(2));
    expect(items.first.id, '1');
    expect(items.first.title, 'Robe fluide');
    expect(items.last.id, '2');
  });
}

SalonItem _item(String id, String title) {
  return SalonItem(
    id: id,
    type: SalonItemType.inspiration,
    title: title,
    subtitle: 'Inspiration mondiale',
    imageUrl: '',
    ownerId: 'owner',
    city: 'Abidjan',
    price: null,
    tags: const ['style'],
    actions: const [
      SalonAction(
        type: SalonActionType.save,
        label: 'Sauvegarder',
        icon: Icons.bookmark_border_rounded,
      ),
    ],
    data: const {'country': 'Côte d’Ivoire'},
  );
}
