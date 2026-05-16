import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/account_roles.dart';
import '../../models/inspiration/style_guide.dart';
import '../profile/public_profile_service.dart';

class StyleGuideService {
  StyleGuideService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PublicProfileService? profileService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _profileService =
           profileService ??
           PublicProfileService(firestore: firestore, auth: auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PublicProfileService _profileService;

  CollectionReference<Map<String, dynamic>> get _guides =>
      _firestore.collection('style_guides');

  Future<List<StyleGuide>> loadGuides({
    String query = '',
    int limit = 20,
  }) async {
    final dynamicGuides = await _loadDynamicGuides(limit: 12);
    final editorialGuides = <StyleGuide>[];
    try {
      final snapshot =
          await _guides
              .where('status', isEqualTo: 'published')
              .where('visibility', isEqualTo: 'salon')
              .limit(limit)
              .get();
      editorialGuides.addAll(snapshot.docs.map(StyleGuide.fromDoc));
    } catch (_) {
      // Les guides natifs doivent rester disponibles même sans index Firestore.
    }

    final combined = _uniqueGuides([
      ...dynamicGuides,
      ...editorialGuides,
      ...fallbackGuides,
    ]);
    final filtered = _filter(combined, query);
    final result = filtered.isEmpty ? combined : filtered;
    result.sort(_guideSort);
    return result.take(limit).toList();
  }

  Future<String> publishProGuide({
    required String role,
    required String title,
    required String subtitle,
    required String category,
    required List<String> steps,
    String imageUrl = '',
    String videoUrl = '',
  }) async {
    if (!AccountRoles.businessRoles.contains(role)) {
      throw StateError('Les guides sont réservés aux comptes pros.');
    }
    final user = _auth.currentUser;
    if (user == null) throw StateError('Connectez-vous pour publier.');
    final profile = await _profileService.load(user.uid);
    final doc = _guides.doc();
    final guide = StyleGuide(
      id: doc.id,
      title: title.trim(),
      subtitle: subtitle.trim(),
      category: category.trim().isEmpty ? 'Style' : category.trim(),
      steps:
          steps
              .map((step) => step.trim())
              .where((step) => step.isNotEmpty)
              .toList(),
      imageUrl: imageUrl.trim(),
      videoUrl: videoUrl.trim(),
      authorId: user.uid,
      authorName: profile?.displayName ?? user.displayName ?? 'Compte certifié',
      authorRole: role,
      tags: [role, category.trim()],
      featured: false,
    );
    await doc.set({
      ...guide.toFirestore(status: 'published', visibility: 'salon'),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  List<StyleGuide> _filter(List<StyleGuide> guides, String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return guides;
    return guides.where((guide) {
      final text =
          '${guide.title} ${guide.subtitle} ${guide.category} '
                  '${guide.steps.join(' ')} ${guide.tags.join(' ')}'
              .toLowerCase();
      return text.contains(clean) ||
          clean.split(RegExp(r'\s+')).any((word) => text.contains(word));
    }).toList();
  }

  Future<List<StyleGuide>> _loadDynamicGuides({required int limit}) async {
    final guides = <StyleGuide>[];
    await Future.wait([
      _appendProductGuides(guides, limit: 6),
      _appendCreationGuides(guides, limit: 6),
      _appendEventGuides(guides, limit: 4),
    ]).catchError((_) => <void>[]);
    guides.sort(_guideSort);
    return guides.take(limit).toList();
  }

  Future<void> _appendProductGuides(
    List<StyleGuide> guides, {
    required int limit,
  }) async {
    try {
      final snapshot = await _firestore.collection('products').limit(36).get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!_isPublicContent(data)) continue;
        final title = _first(data, const ['title', 'name'], 'Pièce du Salon');
        final category = _first(data, const ['category', 'type'], 'Shopping');
        final imageUrl = _itemImage(data);
        guides.add(
          StyleGuide(
            id: 'dynamic_product_${doc.id}',
            title: 'Look avec $title',
            subtitle: 'Une pièce du Salon à associer simplement.',
            category: category,
            imageUrl: imageUrl,
            authorId: _first(data, const ['sellerId', 'boutiqueId'], ''),
            authorName: _first(data, const [
              'sellerName',
              'boutiqueName',
            ], 'Boutique du Salon'),
            authorRole: 'boutique',
            linkedProducts: [doc.id],
            tags: _tags(data, extra: [category, title, 'produit']),
            featured: _isFresh(data),
            steps: [
              'Garde cette pièce comme point fort.',
              'Ajoute une couleur calme autour.',
              'Finalise avec un talent ou une boutique proche.',
            ],
          ),
        );
        if (guides.length >= limit) break;
      }
    } catch (_) {
      // Les guides éditoriaux prennent le relais si les produits sont indisponibles.
    }
  }

  Future<void> _appendCreationGuides(
    List<StyleGuide> guides, {
    required int limit,
  }) async {
    try {
      final snapshot = await _firestore.collection('creations').limit(36).get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!_isPublicContent(data)) continue;
        final title = _first(data, const ['title', 'name'], 'Création');
        final category = _first(data, const ['category', 'style'], 'Création');
        final imageUrl = _itemImage(data);
        guides.add(
          StyleGuide(
            id: 'dynamic_creation_${doc.id}',
            title: 'Idée autour de $title',
            subtitle: 'Une création récente pour guider le look.',
            category: category,
            imageUrl: imageUrl,
            authorId: _first(data, const [
              'createurId',
              'creatorId',
              'ownerId',
              'sellerId',
            ], ''),
            authorName: _first(data, const [
              'creatorName',
              'createurName',
              'authorName',
            ], 'Créateur du Salon'),
            authorRole: 'createur',
            linkedCreations: [doc.id],
            tags: _tags(data, extra: [category, title, 'création']),
            featured: _isFresh(data),
            steps: [
              'Observe la coupe avant les accessoires.',
              'Reprends une seule couleur forte.',
              'Contacte un créateur pour l’adapter.',
            ],
          ),
        );
        if (guides.length >= limit) break;
      }
    } catch (_) {
      // Les guides éditoriaux prennent le relais si les créations sont indisponibles.
    }
  }

  Future<void> _appendEventGuides(
    List<StyleGuide> guides, {
    required int limit,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('events')
              .orderBy('startAt', descending: false)
              .limit(24)
              .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!_isPublicContent(data)) continue;
        final startAt = _date(data['startAt'] ?? data['date']);
        if (startAt != null &&
            startAt.isBefore(
              DateTime.now().subtract(const Duration(days: 1)),
            )) {
          continue;
        }
        final title = _first(data, const ['title', 'name'], 'Événement');
        final category = _first(data, const ['type', 'category'], 'Agenda');
        guides.add(
          StyleGuide(
            id: 'dynamic_event_${doc.id}',
            title: 'Look pour $title',
            subtitle: 'Un événement à venir, une tenue à préparer.',
            category: category,
            imageUrl: _itemImage(data),
            authorId: _first(data, const ['organizerId', 'ownerId'], ''),
            authorName: _first(data, const [
              'organizerName',
              'hostName',
            ], 'Agenda Salon'),
            authorRole: 'editorial',
            tags: _tags(data, extra: [category, title, 'événement']),
            featured: true,
            steps: [
              'Adapte la tenue au lieu et à l’heure.',
              'Garde une pièce confortable.',
              'Repère un talent proche pour les détails.',
            ],
          ),
        );
        if (guides.length >= limit) break;
      }
    } catch (_) {
      // Les événements sont facultatifs pour les Conseils Style.
    }
  }

  List<StyleGuide> _uniqueGuides(List<StyleGuide> guides) {
    final seen = <String>{};
    final unique = <StyleGuide>[];
    for (final guide in guides) {
      final key = guide.id.isNotEmpty ? guide.id : guide.title.toLowerCase();
      if (seen.add(key)) unique.add(guide);
    }
    return unique;
  }

  int _guideSort(StyleGuide a, StyleGuide b) {
    final aScore = _guideScore(a);
    final bScore = _guideScore(b);
    return bScore.compareTo(aScore);
  }

  int _guideScore(StyleGuide guide) {
    var score = 0;
    if (guide.featured) score += 80;
    if (guide.isProGuide) score += 35;
    if (guide.imageUrl.isNotEmpty) score += 25;
    if (guide.linkedProducts.isNotEmpty || guide.linkedCreations.isNotEmpty) {
      score += 35;
    }
    score += guide.tags.length.clamp(0, 8);
    return score;
  }

  bool _isPublicContent(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';
    final visibility = data['visibility']?.toString().toLowerCase() ?? '';
    final moderation = data['moderationStatus']?.toString().toLowerCase() ?? '';
    if (data['deleted'] == true || data['isDeleted'] == true) return false;
    if (data['isPublic'] == false || data['public'] == false) return false;
    if (status == 'draft' || status == 'hidden' || status == 'archived') {
      return false;
    }
    if (visibility == 'private' || visibility == 'hidden') return false;
    if (moderation == 'rejected' || moderation == 'blocked') return false;
    return true;
  }

  bool _isFresh(Map<String, dynamic> data) {
    final date = _date(data['createdAt'] ?? data['updatedAt']);
    if (date == null) return false;
    return date.isAfter(DateTime.now().subtract(const Duration(days: 14)));
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _itemImage(Map<String, dynamic> data) {
    return _firstImage([
      _itemMedia(data['media']),
      data['imageUrls'],
      data['images'],
      data['coverImage'],
      data['posterUrl'],
      data['thumbnailUrl'],
      data['imageUrl'],
    ]);
  }

  Object? _itemMedia(Object? media) {
    if (media is! Map) return media;
    return [
      media['cover'],
      media['main'],
      media['primary'],
      media['product'],
      media['creation'],
      media['gallery'],
      media['images'],
      media['imageUrls'],
      media['coverUrl'],
      media['imageUrl'],
      media['coverImage'],
      media['thumbnailUrl'],
      media['optimizedUrl'],
      media['secureUrl'],
    ];
  }

  String _firstImage(List<Object?> values) {
    for (final value in values) {
      final image = _cleanImage(value);
      if (image.isNotEmpty) return image;
    }
    return '';
  }

  String _cleanImage(Object? value) {
    if (value == null) return '';
    if (value is Iterable) {
      for (final item in value) {
        final image = _cleanImage(item);
        if (image.isNotEmpty) return image;
      }
      return '';
    }
    if (value is Map) {
      for (final key in const [
        'optimizedUrl',
        'thumbnailUrl',
        'secureUrl',
        'coverUrl',
        'imageUrl',
        'url',
        'coverImage',
      ]) {
        final image = _cleanImage(value[key]);
        if (image.isNotEmpty) return image;
      }
      return '';
    }
    final image = value.toString().trim();
    final isNetwork =
        image.startsWith('http://') || image.startsWith('https://');
    return isNetwork && !_looksLikeProfileImage(image) ? image : '';
  }

  bool _looksLikeProfileImage(String url) {
    final value = url.toLowerCase();
    return value.contains('/profiles/') ||
        value.contains('/profile_') ||
        value.contains('/avatar_') ||
        value.contains('/shops/') && value.contains('/logo_') ||
        value.contains('/createur/') && value.contains('/profile_') ||
        value.contains('/users/') && value.contains('/avatar_');
  }

  String _first(Map<String, dynamic> data, List<String> keys, String fallback) {
    for (final key in keys) {
      final value = _valueAt(data, key)?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  Object? _valueAt(Map<String, dynamic> data, String path) {
    Object? current = data;
    for (final part in path.split('.')) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  List<String> _tags(
    Map<String, dynamic> data, {
    List<String> extra = const [],
  }) {
    final values = <String>{};
    void add(Object? value) {
      if (value == null) return;
      if (value is Iterable) {
        for (final item in value) {
          add(item);
        }
        return;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty && text.length <= 36) values.add(text);
    }

    add(data['tags']);
    add(data['category']);
    add(data['type']);
    add(data['style']);
    add(data['occasion']);
    add(extra);
    return values.take(8).toList();
  }

  static const fallbackGuides = [
    StyleGuide(
      id: 'guide_accessoires_signature',
      title: 'Signer une tenue avec un accessoire',
      subtitle: 'Un détail fort suffit pour rendre un look mémorable.',
      category: 'Accessoires',
      authorName: 'Guide ElegantStyle',
      imageUrl:
          'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?auto=format&fit=crop&w=900&q=80',
      steps: [
        'Choisis une base simple: chemise, robe unie ou ensemble sobre.',
        'Ajoute un seul accessoire fort: collier, foulard, sac ou bijou.',
        'Répète une couleur de l’accessoire dans les chaussures ou le sac.',
      ],
      tags: ['accessoires', 'bijoux', 'foulard'],
    ),
    StyleGuide(
      id: 'guide_ceremonie_equilibre',
      title: 'Équilibrer une tenue de cérémonie',
      subtitle: 'Tradition, élégance et confort sans surcharge.',
      category: 'Cérémonie',
      authorName: 'Guide ElegantStyle',
      imageUrl:
          'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=900&q=80',
      steps: [
        'Garde une pièce dominante: tissu, coupe ou accessoire.',
        'Calme le reste avec deux couleurs maximum.',
        'Vérifie la mobilité: marcher, s’asseoir, danser, saluer.',
      ],
      tags: ['mariage', 'cérémonie', 'tenue'],
      featured: true,
    ),
    StyleGuide(
      id: 'guide_matiere_chaleur',
      title: 'Choisir une matière quand il fait chaud',
      subtitle: 'Respirer, bouger et rester net toute la journée.',
      category: 'Matières',
      authorName: 'Guide ElegantStyle',
      imageUrl:
          'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?auto=format&fit=crop&w=900&q=80',
      steps: [
        'Privilégie coton, lin, viscose légère ou tissage aéré.',
        'Évite les doublures lourdes si la journée est longue.',
        'Choisis une coupe qui laisse circuler l’air.',
      ],
      tags: ['matières', 'été', 'confort'],
    ),
    StyleGuide(
      id: 'guide_chaussures_tenue',
      title: 'Associer chaussures et tenue',
      subtitle: 'La chaussure doit soutenir le look, pas le compliquer.',
      category: 'Chaussures',
      authorName: 'Guide ElegantStyle',
      imageUrl:
          'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=900&q=80',
      steps: [
        'Pour une tenue expressive, choisis une chaussure plus calme.',
        'Pour une base sobre, autorise une chaussure plus travaillée.',
        'Adapte la hauteur au trajet réel de la journée.',
      ],
      tags: ['chaussures', 'tenue', 'confort'],
    ),
  ];
}
