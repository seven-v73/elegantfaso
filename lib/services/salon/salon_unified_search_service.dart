import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/salon/salon_context.dart';
import '../../models/salon/salon_item.dart';
import '../../models/salon/salon_section.dart';
import 'salon_boost_service.dart';

class SalonUnifiedSearchService {
  SalonUnifiedSearchService({
    FirebaseFirestore? firestore,
    SalonBoostService? boostService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _boostService = boostService ?? SalonBoostService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final SalonBoostService _boostService;
  final Map<String, Future<List<SalonSection>>> _cache = {};

  Future<List<SalonSection>> search(SalonContext context) async {
    final key = _cacheKey(context);
    return _cache.putIfAbsent(key, () => _searchFresh(context));
  }

  Future<List<SalonSection>> _searchFresh(SalonContext context) async {
    final query = context.displayQuery.toLowerCase();
    final results = await Future.wait([
      _firestore.collection('products').limit(60).get(),
      _firestore.collection('creations').limit(60).get(),
      _firestore.collection('users').limit(90).get(),
      _firestore.collection('events').limit(60).get(),
      _firestore.collection('inspirations').limit(60).get(),
      _firestore.collection('inspiration_articles').limit(30).get(),
      _boostService.loadActiveBoostIndex(),
    ]);
    final productDocs = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final creationDocs = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final userDocs = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final eventDocs = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final inspirationDocs = results[4] as QuerySnapshot<Map<String, dynamic>>;
    final articleDocs = results[5] as QuerySnapshot<Map<String, dynamic>>;
    final boosts = results[6] as SalonBoostIndex;

    final products =
        productDocs.docs
            .where((doc) => _isPublicListing(doc.data()))
            .map(SalonItem.product)
            .where((item) => _matches(item, query))
            .where((item) => _matchesScope(item, context))
            .toList()
          ..sort((a, b) => _rank(a, b, boosts));
    final visibleProducts = products.take(12).toList();
    final creations =
        creationDocs.docs
            .where((doc) => _isPublicListing(doc.data()))
            .map(SalonItem.creation)
            .where((item) => _matches(item, query))
            .where((item) => _matchesScope(item, context))
            .toList()
          ..sort((a, b) => _rank(a, b, boosts));
    final visibleCreations = creations.take(12).toList();
    final talents =
        userDocs.docs
            .where((doc) => !_isAdminUser(doc.data()))
            .expand(_talentItemsFor)
            .where(_isPublicTalent)
            .where((item) => _matches(item, query))
            .where((item) => _matchesScope(item, context))
            .toList()
          ..sort((a, b) => _rank(a, b, boosts));
    final visibleTalents = talents.take(12).toList();
    final events =
        eventDocs.docs
            .map(SalonItem.event)
            .where((item) => _matches(item, query))
            .where((item) => _matchesScope(item, context))
            .toList()
          ..sort((a, b) => _rank(a, b, boosts));
    final visibleEvents = events.take(10).toList();
    final inspirations =
        inspirationDocs.docs
            .map(SalonItem.inspiration)
            .where((item) => _matches(item, query))
            .where((item) => _matchesScope(item, context))
            .toList()
          ..sort((a, b) => _rank(a, b, boosts));
    final visibleInspirations = inspirations.take(12).toList();
    final articles =
        articleDocs.docs
            .map(SalonItem.article)
            .where((item) => _matches(item, query))
            .where((item) => _matchesScope(item, context))
            .toList()
          ..sort((a, b) => _rank(a, b, boosts));
    final visibleArticles = articles.take(8).toList();

    final sections =
        [
          SalonSection(
            title: 'Produits',
            subtitle: 'À acheter',
            items: visibleProducts,
          ),
          SalonSection(
            title: 'Créations',
            subtitle: 'Ateliers',
            items: visibleCreations,
          ),
          SalonSection(
            title: 'Boutiques & ateliers',
            subtitle: 'Vitrines pro',
            items: visibleTalents,
          ),
          SalonSection(
            title: 'Inspirations',
            subtitle: 'Idées visuelles',
            items: visibleInspirations,
          ),
          SalonSection(
            title: 'Événements',
            subtitle: 'Agenda',
            items: visibleEvents,
          ),
          SalonSection(
            title: 'Articles',
            subtitle: 'Lectures',
            items: visibleArticles,
          ),
        ].where((section) => !section.isEmpty).toList();

    final highlights =
        sections.expand((section) => section.items).toList()
          ..sort((a, b) => _rank(a, b, boosts));
    if (highlights.isNotEmpty && query.trim().isNotEmpty) {
      return [
        SalonSection(
          title: 'Meilleurs choix',
          subtitle: 'À ouvrir en premier',
          items: highlights.take(6).toList(),
        ),
        ...sections,
      ];
    }
    return sections;
  }

  String _cacheKey(SalonContext context) {
    return [
      context.displayQuery.trim().toLowerCase(),
      context.scope.name,
      context.city.trim().toLowerCase(),
      context.country.trim().toLowerCase(),
    ].join('|');
  }

  Future<List<SalonItem>> loadRecommendations(SalonContext context) async {
    final sections = await search(context);
    final items = sections.expand((section) => section.items).toList();
    items.sort((a, b) {
      final aScore = _score(a);
      final bScore = _score(b);
      if (aScore != bScore) return bScore.compareTo(aScore);
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return items.take(18).toList();
  }

  bool _matches(SalonItem item, String query) {
    final clean = _normalize(query);
    if (clean.trim().isEmpty) return true;
    final text = _normalize(item.searchableText);
    final terms =
        clean
            .split(RegExp(r'\s+'))
            .map((term) => term.trim())
            .where((term) => term.length > 1)
            .expand(_expandSearchTerm)
            .toSet();
    if (terms.isEmpty) return true;
    return terms.any((term) => text.contains(term) || _typeMatches(item, term));
  }

  Iterable<String> _expandSearchTerm(String term) sync* {
    yield term;
    switch (term) {
      case 'shop':
      case 'shops':
        yield 'boutique';
        yield 'produit';
      case 'boutique':
      case 'boutiques':
        yield 'shop';
        yield 'produit';
      case 'talent':
      case 'talents':
      case 'pro':
      case 'pros':
      case 'professionnel':
      case 'professionnels':
        yield 'boutique';
        yield 'createur';
        yield 'creator';
        yield 'atelier';
      case 'createur':
      case 'createurs':
      case 'creator':
      case 'creators':
      case 'atelier':
      case 'ateliers':
        yield 'creation';
        yield 'sur mesure';
      case 'produit':
      case 'produits':
      case 'product':
      case 'products':
        yield 'shop';
        yield 'boutique';
      case 'idee':
      case 'idees':
      case 'inspiration':
      case 'inspirations':
        yield 'style';
      case 'event':
      case 'events':
      case 'evenement':
      case 'evenements':
        yield 'agenda';
    }
  }

  bool _typeMatches(SalonItem item, String term) {
    final role = _normalize(item.data['salonRole']?.toString() ?? '');
    if ((term == 'produit' || term == 'product' || term == 'shop') &&
        item.type == SalonItemType.product) {
      return true;
    }
    if ((term == 'creation' || term == 'atelier' || term == 'sur mesure') &&
        item.type == SalonItemType.creation) {
      return true;
    }
    if ((term == 'boutique' || term == 'shop') &&
        item.type == SalonItemType.talent &&
        role.contains('boutique')) {
      return true;
    }
    if ((term == 'createur' ||
            term == 'creator' ||
            term == 'atelier' ||
            term == 'talent' ||
            term == 'pro') &&
        item.type == SalonItemType.talent &&
        role.contains('createur')) {
      return true;
    }
    if ((term == 'talent' || term == 'pro') &&
        item.type == SalonItemType.talent) {
      return true;
    }
    if ((term == 'idee' || term == 'inspiration' || term == 'style') &&
        (item.type == SalonItemType.inspiration ||
            item.type == SalonItemType.article ||
            item.type == SalonItemType.creation)) {
      return true;
    }
    if ((term == 'event' || term == 'evenement' || term == 'agenda') &&
        item.type == SalonItemType.event) {
      return true;
    }
    return false;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c');
  }

  bool _matchesScope(SalonItem item, SalonContext context) {
    if (context.scope == SalonDiscoveryScope.world) return true;

    final city = context.city.trim().toLowerCase();
    final country = context.country.trim().toLowerCase();
    final itemCity = item.city.trim().toLowerCase();
    final itemCountry = item.country.trim().toLowerCase();

    if (context.scope == SalonDiscoveryScope.nearby && city.isNotEmpty) {
      return itemCity.contains(city) || item.searchableText.contains(city);
    }
    if (context.scope == SalonDiscoveryScope.country && country.isNotEmpty) {
      return itemCountry.contains(country) ||
          item.searchableText.contains(country);
    }

    // If the user has not provided a city/country yet, keep results broad.
    return true;
  }

  bool _isPublicTalent(SalonItem item) {
    final text = item.searchableText;
    return text.contains('mode') ||
        text.contains('atelier') ||
        text.contains('boutique') ||
        text.contains('shop') ||
        text.contains('createur') ||
        text.contains('créateur') ||
        text.contains('creator') ||
        text.contains('coiff') ||
        text.contains('couture') ||
        text.contains('tailleur') ||
        text.contains('chauss') ||
        text.contains('styliste') ||
        text.contains('maquill');
  }

  Iterable<SalonItem> _talentItemsFor(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final roles = <String>{};
    final roleFlags = data['roleFlags'];
    if (roleFlags is Map) {
      if (roleFlags['isShop'] == true || roleFlags['isBoutique'] == true) {
        roles.add('boutique');
      }
      if (roleFlags['isCreator'] == true || roleFlags['isCreateur'] == true) {
        roles.add('createur');
      }
    }

    void addTextRole(Object? value) {
      final text = value?.toString().toLowerCase() ?? '';
      if (text.contains('boutique') || text.contains('shop')) {
        roles.add('boutique');
      }
      if (text.contains('createur') ||
          text.contains('créateur') ||
          text.contains('creator') ||
          text.contains('atelier')) {
        roles.add('createur');
      }
    }

    addTextRole(data['role']);
    addTextRole(data['activeRole']);
    addTextRole(data['publicRole']);
    addTextRole(data['roles']);

    if (_hasText(data, const ['boutiqueName', 'shopName']) ||
        data['shopProfile'] is Map) {
      roles.add('boutique');
    }
    if (_hasText(data, const ['creatorName', 'atelierName']) ||
        data['creatorProfile'] is Map) {
      roles.add('createur');
    }

    if (roles.isEmpty && _looksLikePublicTalent(data)) {
      return [SalonItem.talent(doc)];
    }
    return roles.map((role) => SalonItem.talentRole(doc, role: role));
  }

  bool _looksLikePublicTalent(Map<String, dynamic> data) {
    final text =
        '${data['speciality']} ${data['specialty']} ${data['profession']} ${data['category']} ${data['bio']} ${data['skills']} ${data['tags']}'
            .toLowerCase();
    return text.contains('mode') ||
        text.contains('coiff') ||
        text.contains('couture') ||
        text.contains('tailleur') ||
        text.contains('styliste') ||
        text.contains('maquill') ||
        text.contains('chauss');
  }

  bool _hasText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return true;
    }
    return false;
  }

  bool _isAdminUser(Map<String, dynamic> data) {
    final roleFlags = data['roleFlags'];
    final text =
        '${data['role']} ${data['activeRole']} ${data['publicRole']} ${data['roles']}'
            .toLowerCase();
    return data['admin'] == true ||
        data['isAdmin'] == true ||
        text.split(RegExp(r'\s+')).contains('admin') ||
        (roleFlags is Map && roleFlags['isAdmin'] == true);
  }

  bool _isPublicListing(Map<String, dynamic> data) {
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

  int _score(SalonItem item) {
    var score = 0;
    if (item.hasImage) score += 15;
    if (item.verified) score += 20;
    if (item.isLocal) score += 8;
    if (item.price != null && item.price! > 0) score += 8;
    score += item.tags.length * 2;
    return score;
  }

  int _rank(SalonItem a, SalonItem b, SalonBoostIndex boosts) {
    final aScore =
        _score(a) +
        boosts.boostScore(id: a.id, ownerId: a.ownerId, data: a.data);
    final bScore =
        _score(b) +
        boosts.boostScore(id: b.id, ownerId: b.ownerId, data: b.data);
    if (aScore != bScore) return bScore.compareTo(aScore);
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }
}
