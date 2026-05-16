import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/inspiration/external_look.dart';
import '../../models/salon/salon_item.dart';
import '../inspiration/inspiration_wishlist_service.dart';

class SalonActionService {
  SalonActionService({InspirationWishlistService? wishlistService})
    : _wishlistService = wishlistService ?? InspirationWishlistService();

  final InspirationWishlistService _wishlistService;

  Future<void> save(SalonItem item) {
    return _wishlistService.save(
      ExternalLook(
        id: ExternalLook.idFromImage(
          '${item.type.name}_${item.id}_${item.imageUrl}',
        ),
        title: item.title,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        source: item.typeLabel,
        tags: [item.typeLabel, ...item.tags],
      ),
    );
  }

  Future<void> share(SalonItem item) {
    return SharePlus.instance.share(
      ShareParams(
        text:
            '${item.title}\n${item.subtitle}'
            '${item.city.isEmpty ? '' : '\n${item.city}'}'
            '${item.url.isEmpty ? '' : '\n${item.url}'}',
      ),
    );
  }

  Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) return false;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return true;
  }

  Future<bool> contact(SalonItem item) async {
    final raw = (item.data['phone'] ?? item.data['whatsapp'] ?? '').toString();
    final phone = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) return false;
    return openUrl(
      'https://wa.me/$phone?text=${Uri.encodeComponent('Bonjour, je suis intéressé par ${item.title}.')}',
    );
  }
}
