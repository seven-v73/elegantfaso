import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../../services/ai/gemini_client.dart';
import '../../../../../services/ai/openai_client.dart';
import '../../../../../services/preferences/currency_service.dart';
import 'serp_api_service.dart';

class GeminiApiService {
  final GeminiClient _geminiClient = GeminiClient();
  final OpenAiClient _openAiClient = OpenAiClient();
  final SerpApiService _serpApiService = SerpApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache pour les données utilisateur
  Map<String, dynamic>? _cachedUserData;
  String? _cachedUserId;
  String? _cachedLiveContext;
  DateTime? _cachedLiveContextAt;

  static const Duration _liveContextTtl = Duration(minutes: 4);
  static const Duration _contextQueryTimeout = Duration(seconds: 3);

  // Analyseur d'émotions
  final Map<String, List<String>> _emotionKeywords = {
    'joie': [
      'heureux',
      'content',
      'génial',
      'super',
      'parfait',
      'merveilleux',
      'fantastique',
      'excellent',
      '😊',
      '😄',
      '🥳',
      '❤️',
    ],
    'excitation': [
      'excité',
      'motivé',
      'énergique',
      'dynamique',
      'enthousiaste',
      'impatient',
      'wow',
      'incroyable',
      '🔥',
      '⚡',
      '🚀',
    ],
    'stress': [
      'stressé',
      'anxieux',
      'inquiet',
      'nerveux',
      'tendu',
      'préoccupé',
      'problème',
      'difficile',
      'urgent',
      '😰',
      '😓',
    ],
    'tristesse': [
      'triste',
      'mélancolique',
      'déçu',
      'malheureux',
      'déprimé',
      'nostalgique',
      'pas moral',
      '😢',
      '😔',
      '💔',
    ],
    'colère': [
      'énervé',
      'frustré',
      'agacé',
      'furieux',
      'irrité',
      'fâché',
      'pas content',
      'ras le bol',
      '😠',
      '😡',
    ],
    'confiance': [
      'confiant',
      'sûr',
      'déterminé',
      'prêt',
      'capable',
      'fort',
      'puissant',
      'winner',
      '💪',
      '👑',
    ],
    'doute': [
      'incertain',
      'hésitant',
      'pas sûr',
      'confus',
      'perdu',
      'complexe',
      'peut-être',
      'je sais pas',
      '🤔',
      '😕',
    ],
    'fatigue': [
      'fatigué',
      'épuisé',
      'crevé',
      'las',
      'usé',
      'burn out',
      'à bout',
      'mou',
      '😴',
      '😪',
    ],
    'curiosité': [
      'curieux',
      'intéressé',
      'découvrir',
      'apprendre',
      'explorer',
      'nouveau',
      'comment',
      'pourquoi',
      '🤓',
      '🧐',
    ],
    'amour': [
      'amour',
      'amoureux',
      'crush',
      'relation',
      'couple',
      'romantique',
      'séduire',
      'plaire',
      '💕',
      '💖',
    ],
  };

  // Contextes situationnels
  final Map<String, List<String>> _situationKeywords = {
    'travail': [
      'bureau',
      'boulot',
      'travail',
      'collègue',
      'patron',
      'réunion',
      'entretien',
      'professionnel',
      'carrière',
    ],
    'études': [
      'école',
      'université',
      'exam',
      'cours',
      'étudiant',
      'diplôme',
      'thèse',
      'mémoire',
      'formation',
    ],
    'sortie': [
      'sortir',
      'fête',
      'soirée',
      'restaurant',
      'cinéma',
      'concert',
      'dancing',
      'amis',
      'rendez-vous',
    ],
    'famille': [
      'famille',
      'parents',
      'maman',
      'papa',
      'frère',
      'sœur',
      'enfant',
      'mariage',
      'baptême',
      'funérailles',
    ],
    'sport': [
      'sport',
      'fitness',
      'gym',
      'course',
      'match',
      'entraînement',
      'musculation',
      'yoga',
      'danse',
    ],
    'voyage': [
      'voyage',
      'vacances',
      'partir',
      'destination',
      'avion',
      'hôtel',
      'tourisme',
      'découverte',
    ],
    'maison': [
      'maison',
      'chez moi',
      'repos',
      'détente',
      'cocooning',
      'confort',
      'famille',
      'weekend',
    ],
    'célébration': [
      'anniversaire',
      'fête',
      'célébration',
      'événement',
      'spécial',
      'important',
      'mémorable',
    ],
  };

  Future<String> _buildSystemInstruction(Map<String, dynamic> userData) async {
    final String userName = _firstString(userData, const [
      'name',
      'displayName',
      'clientName',
    ], 'mon ami(e)');
    final String userGender = _firstString(userData, const ['gender'], '');
    final String userAge = userData['age']?.toString() ?? '';
    final locationSnapshot = _buildLocationSnapshot(userData);
    final String userLocation = locationSnapshot.summary;
    final String userStyle = _firstString(userData, const [
      'preferredStyle',
      'styleProfile',
    ], '');
    final String userBudget = _firstString(userData, const ['budget'], '');
    final List<String> userInterests = List<String>.from(
      userData['interests'] ?? [],
    );
    final Map<String, dynamic> userPreferences = userData['preferences'] ?? {};
    // final int userPoints = userData['totalPoints'] ?? 0;
    final String userRole = userData['role'] ?? 'client';
    // final List<String> unlockedBadges = List<String>.from(userData['unlockedBadges'] ?? []);

    // Récupérer l'historique émotionnel et les interactions
    final emotionalHistory = await _getEmotionalHistory();
    final lastInteraction = await _getLastInteraction();
    final conversationInsights = await _getConversationInsights();
    final personalityProfile = await _getPersonalityProfile();

    // Construire la salutation personnalisée
    String personalizedGreeting = _buildPersonalizedGreeting(
      userName,
      userGender,
      userAge,
    );

    // Construire le contexte utilisateur
    String userContext = _buildUserContext(userData);
    final styleSnapshot = await _getStyleSnapshot();
    final livePlatformContext = await _buildLivePlatformContext(userData);

    return """Tu es le conseiller style d'ElegantStyle.
Tu aides les utilisateurs à découvrir, organiser, essayer et acheter des looks avec une approche ouverte, inclusive et professionnelle.
Tu peux valoriser les traditions, textiles, cultures locales et savoir-faire artisanaux, mais tu ne limites jamais tes réponses à un seul pays.
Tu ne prétends pas être une vraie personne, une amie intime ou avoir des souvenirs personnels inventés. Tu es chaleureuse, présente, précise et respectueuse.

INFORMATIONS UTILISATEUR CONNECTÉ :
- Nom : $userName
- Salutation personnalisée : $personalizedGreeting
- Localisation : $userLocation
- Contexte géographique exploitable : ${locationSnapshot.promptContext}
- Style préféré : ${userStyle.isNotEmpty ? userStyle : 'À découvrir ensemble'}
- Budget approximatif : ${userBudget.isNotEmpty ? userBudget : 'On va voir ça'}
- Espace actif : $userRole
- Centres d'intérêt : ${userInterests.isEmpty ? 'À découvrir ensemble' : userInterests.join(', ')}
- Préférences enregistrées : ${userPreferences.isEmpty ? 'Aucune préférence explicite' : userPreferences.entries.map((entry) => '${entry.key}: ${entry.value}').join(', ')}


INTELLIGENCE ÉMOTIONNELLE ÉVOLUTIVE :
- Historique émotionnel récent : ${emotionalHistory['recent_emotions']}
- Patterns émotionnels : ${emotionalHistory['patterns']}
- État émotionnel actuel estimé : ${emotionalHistory['current_state']}
- Déclencheurs émotionnels identifiés : ${emotionalHistory['triggers']}

MÉMOIRE RELATIONNELLE PROFONDE :
- Dernière interaction : ${lastInteraction['summary']}
- Sujets préférés : ${conversationInsights['favorite_topics']}
- Style de communication : ${conversationInsights['communication_style']}
- Évolution des goûts : ${conversationInsights['taste_evolution']}
- Moments mémorables : ${conversationInsights['memorable_moments']}

PROFIL PSYCHOLOGIQUE ÉVOLUTIF :
- Traits de personnalité détectés : ${personalityProfile['traits']}
- Préférences comportementales : ${personalityProfile['behavioral_preferences']}
- Cycles d'humeur identifiés : ${personalityProfile['mood_cycles']}
- Besoins émotionnels principaux : ${personalityProfile['emotional_needs']}
- Évolution personnelle observée : ${personalityProfile['personal_growth']}

CONTEXTE UTILISATEUR PERSONNALISÉ :
$userContext

CONTEXTE STYLE RÉEL :
$styleSnapshot

CONTEXTE VIVANT DE LA PLATEFORME :
$livePlatformContext

MISSION IRIS :
- Iris ne remplace pas la communauté : elle aide à formuler, résumer et connecter aux bonnes personnes.
- Quand c’est pertinent, propose une action concrète : demander un avis à la communauté, consulter une discussion proche, chercher dans le Salon, contacter un créateur ou une boutique certifiée, sauvegarder une idée, essayer avec la garde-robe.
- Les recommandations pros doivent rester utiles et transparentes : parle de pistes disponibles ou proches, jamais comme une publicité forcée.
- Si le contexte réel est insuffisant, dis-le simplement et propose une recherche Salon, une question communautaire ou une recherche web.

RÈGLES DE CONSEIL :
1. Réponds en français clair, chaleureux et utile.
2. Donne des conseils actionnables : tenue, couleurs, matières, coupe, budget, confort, achat/contact si pertinent.
3. Adapte-toi au monde entier : local, pays, diaspora ou global selon la demande.
4. Valorise tradition et modernité sans exotiser ni enfermer l’utilisateur dans un seul style.
5. Si la demande touche au Salon, propose naturellement : sauvegarder, essayer, chercher similaire, contacter un talent ou acheter.
6. Si l’information manque, pose une seule question courte ou propose une option par défaut.
7. N’invente pas de données personnelles, de créateurs précis ou de prix exacts si tu ne les as pas.
8. Utilise l’historique seulement comme contexte discret, jamais comme surveillance.
9. Réponse courte par défaut : 120 à 180 mots, avec structure légère si utile.
10. Si recherche web fournie, distingue ce qui vient du web et reste prudent.""";
  }

  String _buildPersonalizedGreeting(
    String userName,
    String userGender,
    String userAge,
  ) {
    if (userName == 'Salut') return 'Salut';
    final normalizedName = userName.trim().isEmpty ? 'vous' : userName.trim();
    int? age = int.tryParse(userAge);

    if (userGender.toLowerCase().contains('femme') ||
        userGender.toLowerCase().contains('fille')) {
      if (age != null && age < 25) {
        return 'Salut $normalizedName';
      } else if (age != null && age > 45) {
        return 'Bonjour $normalizedName';
      } else {
        return 'Bonjour $normalizedName';
      }
    } else if (userGender.toLowerCase().contains('homme') ||
        userGender.toLowerCase().contains('garçon')) {
      if (age != null && age < 25) {
        return 'Salut $normalizedName';
      } else if (age != null && age > 45) {
        return 'Bonjour $normalizedName';
      } else {
        return 'Bonjour $normalizedName';
      }
    }

    return 'Bonjour $normalizedName';
  }

  String _buildUserContext(Map<String, dynamic> userData) {
    final StringBuffer context = StringBuffer();
    final locationSnapshot = _buildLocationSnapshot(userData);

    // Contexte stylistique
    if (userData['preferredStyle']?.isNotEmpty == true) {
      context.writeln('• Style préféré : ${userData['preferredStyle']}');
    }

    // Contexte budgétaire
    if (userData['budget']?.isNotEmpty == true) {
      context.writeln(
        '• Budget : ${userData['budget']} - adapte toujours tes conseils à ce budget',
      );
    }

    // Contexte d'intérêts
    final List<String> interests = List<String>.from(
      userData['interests'] ?? [],
    );
    if (interests.isNotEmpty) {
      context.writeln(
        '• Centres d\'intérêt : ${interests.join(', ')} - utilise ces infos pour contextualiser tes conseils',
      );
    }

    // Contexte de progression
    // final int points = userData['totalPoints'] ?? 0;
    // if (points > 0) {
    //   context.writeln('• Points visibilité : $points - mentionne sa progression et encourage-le');
    // }

    // Contexte des préférences
    // final Map<String, dynamic> preferences = userData['preferences'] ?? {};
    // if (preferences.isNotEmpty) {
    //   context.writeln('• Préférences : ${preferences.toString()} - respecte ces préférences');
    // }

    if (locationSnapshot.hasLocation) {
      context.writeln(
        '• Localisation : ${locationSnapshot.promptContext} - adapte les conseils au climat probable, aux matières faciles à porter, au contexte culturel local et aux options du Salon près de cette zone quand c’est pertinent.',
      );
    } else {
      context.writeln(
        '• Localisation : non définie - propose des conseils adaptables à plusieurs climats.',
      );
    }

    return context.toString();
  }

  Future<String> _buildLivePlatformContext(
    Map<String, dynamic> userData,
  ) async {
    final cached = _cachedLiveContext;
    final cachedAt = _cachedLiveContextAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _liveContextTtl) {
      return cached;
    }

    try {
      final location = _buildLocationSnapshot(userData);
      final results = await Future.wait<String>([
        _getCommunitySnapshot(),
        _getSalonMarketplaceSnapshot(location),
        _getStyleGuidesSnapshot(),
      ]).timeout(const Duration(seconds: 5));

      final context = results
          .where((value) => value.trim().isNotEmpty)
          .join('\n');
      _cachedLiveContext =
          context.isEmpty
              ? '- Aucun signal live exploitable pour le moment.'
              : context;
      _cachedLiveContextAt = DateTime.now();
      return _cachedLiveContext!;
    } catch (e) {
      debugPrint('Contexte vivant Iris indisponible: $e');
      return '- Contexte live indisponible. Utilise les conseils généraux, la garde-robe et propose une action Salon/communauté.';
    }
  }

  Future<String> _getCommunitySnapshot() async {
    try {
      final snapshot = await _firestore
          .collection('community_questions')
          .limit(10)
          .get()
          .timeout(_contextQueryTimeout);

      final questions =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                final question = _firstString(data, const [
                  'question',
                  'title',
                  'content',
                ], '');
                final category = _firstString(data, const [
                  'category',
                ], 'Style');
                final answers = (data['answersCount'] as num?)?.toInt() ?? 0;
                if (question.isEmpty) return '';
                return '$category: $question ($answers réponse(s))';
              })
              .where((value) => value.isNotEmpty)
              .take(5)
              .toList();

      if (questions.isEmpty) {
        return '- Communauté: aucune discussion récente exploitable.';
      }
      return '- Discussions communauté récentes: ${questions.join(' | ')}.';
    } catch (e) {
      debugPrint('Iris communauté indisponible: $e');
      return '- Communauté: non chargée.';
    }
  }

  Future<String> _getSalonMarketplaceSnapshot(
    _IrisLocationSnapshot location,
  ) async {
    try {
      final results = await Future.wait([
        _firestore.collection('products').limit(8).get(),
        _firestore.collection('creations').limit(8).get(),
        _firestore.collection('boutiques').limit(6).get(),
      ]).timeout(const Duration(seconds: 4));

      final products =
          results[0].docs
              .map(
                (doc) => _summarizeCommerceDoc(doc.data(), fallback: 'Produit'),
              )
              .where((value) => value.isNotEmpty)
              .take(4)
              .toList();
      final creations =
          results[1].docs
              .map(
                (doc) =>
                    _summarizeCommerceDoc(doc.data(), fallback: 'Création'),
              )
              .where((value) => value.isNotEmpty)
              .take(4)
              .toList();
      final boutiques =
          results[2].docs
              .map((doc) {
                final data = doc.data();
                final name = _firstString(data, const [
                  'boutiqueName',
                  'name',
                  'displayName',
                ], '');
                final city = _firstString(data, const ['city', 'ville'], '');
                if (name.isEmpty) return '';
                return city.isEmpty ? name : '$name ($city)';
              })
              .where((value) => value.isNotEmpty)
              .take(3)
              .toList();

      return [
        '- Zone client: ${location.summary}.',
        if (products.isNotEmpty)
          '- Produits Salon disponibles: ${products.join(' | ')}.',
        if (creations.isNotEmpty)
          '- Créations/portfolio disponibles: ${creations.join(' | ')}.',
        if (boutiques.isNotEmpty)
          '- Boutiques à proposer si pertinent: ${boutiques.join(' | ')}.',
      ].join('\n');
    } catch (e) {
      debugPrint('Iris Salon indisponible: $e');
      return '- Salon: non chargé. Propose une recherche Salon plutôt que des noms précis.';
    }
  }

  Future<String> _getStyleGuidesSnapshot() async {
    try {
      final snapshot = await _firestore
          .collection('style_guides')
          .where('published', isEqualTo: true)
          .limit(6)
          .get()
          .timeout(_contextQueryTimeout);

      final guides =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                final title = _firstString(data, const ['title'], '');
                final category = _firstString(data, const [
                  'category',
                ], 'Guide');
                if (title.isEmpty) return '';
                return '$category: $title';
              })
              .where((value) => value.isNotEmpty)
              .take(4)
              .toList();
      if (guides.isEmpty) return '- Guides Style: aucun guide publié chargé.';
      return '- Guides Style natifs: ${guides.join(' | ')}.';
    } catch (e) {
      debugPrint('Iris guides indisponibles: $e');
      return '- Guides Style: non chargés.';
    }
  }

  String _summarizeCommerceDoc(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final title = _firstString(data, const [
      'title',
      'name',
      'productName',
      'creationName',
    ], fallback);
    final category = _firstString(data, const ['category', 'type'], '');
    final city = _firstString(data, const ['city', 'ville', 'location'], '');
    final priceValue = data['price'] ?? data['basePrice'] ?? data['minPrice'];
    final price =
        priceValue is num
            ? CurrencyService.format(
              priceValue,
              code: data['currency']?.toString(),
            )
            : priceValue?.toString().trim() ?? '';
    final parts = [
      title,
      if (category.isNotEmpty) category,
      if (price.isNotEmpty) price,
      if (city.isNotEmpty) city,
    ];
    return parts.join(' / ');
  }

  _IrisLocationSnapshot _buildLocationSnapshot(Map<String, dynamic> userData) {
    final shopProfile =
        userData['shopProfile'] is Map
            ? Map<String, dynamic>.from(userData['shopProfile'] as Map)
            : const <String, dynamic>{};
    final creatorProfile =
        userData['creatorProfile'] is Map
            ? Map<String, dynamic>.from(userData['creatorProfile'] as Map)
            : const <String, dynamic>{};

    final city = _firstString(userData, const [
      'city',
      'ville',
      'region',
      'zone',
    ], '');
    final country = _firstString(userData, const ['country', 'pays'], '');
    final address = _firstNonEmpty([
      userData['address'],
      userData['location'],
      userData['boutiqueAddress'],
      shopProfile['address'],
      shopProfile['location'],
      creatorProfile['location'],
    ]);

    final latitude = _firstDouble([
      userData['latitude'],
      userData['lat'],
      userData['geo'] is Map ? userData['geo']['latitude'] : null,
      userData['location'] is Map ? userData['location']['latitude'] : null,
      shopProfile['latitude'],
      creatorProfile['latitude'],
    ]);
    final longitude = _firstDouble([
      userData['longitude'],
      userData['lng'],
      userData['lon'],
      userData['geo'] is Map ? userData['geo']['longitude'] : null,
      userData['location'] is Map ? userData['location']['longitude'] : null,
      shopProfile['longitude'],
      creatorProfile['longitude'],
    ]);

    final labelParts =
        [
          address,
          city,
          country,
        ].where((value) => value.trim().isNotEmpty).toSet().toList();
    final summary = labelParts.isEmpty ? 'votre zone' : labelParts.join(', ');
    final coordinates =
        latitude != null && longitude != null
            ? 'coordonnées ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}'
            : 'coordonnées non définies';

    return _IrisLocationSnapshot(
      summary: summary,
      promptContext:
          labelParts.isEmpty
              ? 'Aucune localisation enregistrée.'
              : '${labelParts.join(', ')} ($coordinates).',
      hasLocation:
          labelParts.isNotEmpty || (latitude != null && longitude != null),
    );
  }

  String _firstString(
    Map<String, dynamic> data,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return value.toString();
    }
    return fallback;
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  double? _firstDouble(List<dynamic> values) {
    for (final value in values) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Future<String> _getStyleSnapshot() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return '- Utilisateur non connecté.';

      final wardrobeSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('wardrobe')
              .limit(8)
              .get();
      final wardrobeNames =
          wardrobeSnapshot.docs
              .map((doc) {
                final data = doc.data();
                final name = data['name']?.toString() ?? '';
                final category = data['category']?.toString() ?? '';
                final color = data['color']?.toString() ?? '';
                return [
                  name,
                  category,
                  color,
                ].where((value) => value.trim().isNotEmpty).join(' / ');
              })
              .where((value) => value.trim().isNotEmpty)
              .take(6)
              .toList();

      final measurementDoc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('measurements')
              .doc('profile')
              .get();
      final measurementData = measurementDoc.data() ?? {};
      final completion =
          ((measurementData['completionRate'] as num?)?.toDouble() ?? 0) * 100;
      final bodyProfile =
          measurementData['bodyProfile']?.toString() ??
          measurementData['morphology']?.toString() ??
          '';

      final consultations =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('style_consultations')
              .limit(3)
              .get();
      final lastLooks =
          consultations.docs
              .map((doc) => doc.data()['title']?.toString() ?? '')
              .where((value) => value.trim().isNotEmpty)
              .toList();

      return [
        '- Garde-robe: ${wardrobeSnapshot.docs.length} pièce(s). ${wardrobeNames.isEmpty ? 'Aucune pièce lisible.' : wardrobeNames.join('; ')}',
        '- Mensurations: ${completion.round()}% complètes${bodyProfile.isNotEmpty ? ', morphologie $bodyProfile' : ''}.',
        '- Dernières idées de tenues: ${lastLooks.isEmpty ? 'aucune' : lastLooks.join('; ')}.',
      ].join('\n');
    } catch (e) {
      debugPrint('Erreur contexte style: $e');
      return '- Contexte style indisponible pour le moment.';
    }
  }

  // Analyse des émotions dans le message
  // Remplacer la méthode privée existante
  Map<String, dynamic> analyzeEmotions(String message) {
    final lowerMessage = message.toLowerCase();
    final detectedEmotions = <String, double>{};
    final context = <String>[];

    // Analyser les émotions
    _emotionKeywords.forEach((emotion, keywords) {
      double score = 0;
      for (String keyword in keywords) {
        if (lowerMessage.contains(keyword.toLowerCase())) {
          score += 1;
        }
      }
      if (score > 0) {
        detectedEmotions[emotion] = score;
      }
    });

    // Analyser le contexte situationnel
    _situationKeywords.forEach((situation, keywords) {
      for (String keyword in keywords) {
        if (lowerMessage.contains(keyword.toLowerCase())) {
          context.add(situation);
          break;
        }
      }
    });

    // Déterminer l'émotion dominante
    String dominantEmotion = 'neutre';
    double maxScore = 0;
    detectedEmotions.forEach((emotion, score) {
      if (score > maxScore) {
        maxScore = score;
        dominantEmotion = emotion;
      }
    });

    return {
      'dominant_emotion': dominantEmotion,
      'emotion_scores': detectedEmotions,
      'context': context,
      'intensity': maxScore,
      'message_length': message.length,
      'has_question': message.contains('?'),
      'has_exclamation': message.contains('!'),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Enregistrer l'analyse émotionnelle
  Future<void> _saveEmotionalAnalysis(
    Map<String, dynamic> emotionalData,
  ) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Enregistrer dans la collection des émotions
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('emotional_history')
            .add(emotionalData);

        // Mettre à jour le profil émotionnel de l'utilisateur
        await _updateEmotionalProfile(emotionalData);
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement émotionnel: $e');
    }
  }

  // Mettre à jour le profil émotionnel
  Future<void> _updateEmotionalProfile(
    Map<String, dynamic> emotionalData,
  ) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final userRef = _firestore.collection('users').doc(user.uid);

        // Récupérer le profil émotionnel actuel
        final doc = await userRef.get();
        final currentProfile = doc.data()?['emotional_profile'] ?? {};

        // Mettre à jour les statistiques émotionnelles
        final String dominantEmotion = emotionalData['dominant_emotion'];
        final currentCount =
            currentProfile['emotion_counts']?[dominantEmotion] ?? 0;

        final updatedProfile = {
          'last_emotion': dominantEmotion,
          'last_context': emotionalData['context'],
          'last_intensity': emotionalData['intensity'],
          'emotion_counts': {
            ...currentProfile['emotion_counts'] ?? {},
            dominantEmotion: currentCount + 1,
          },
          'total_interactions': (currentProfile['total_interactions'] ?? 0) + 1,
          'last_updated': FieldValue.serverTimestamp(),
        };

        await userRef.update({'emotional_profile': updatedProfile});
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du profil émotionnel: $e');
    }
  }

  // Récupérer l'historique émotionnel
  Future<Map<String, dynamic>> _getEmotionalHistory() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return _getDefaultEmotionalHistory();

      // Récupérer les 10 dernières interactions émotionnelles
      final recentQuery =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('emotional_history')
              .orderBy('timestamp', descending: true)
              .limit(10)
              .get();

      final recentEmotions =
          recentQuery.docs.map((doc) {
            final data = doc.data();
            return '${data['dominant_emotion']} (${data['intensity']})';
          }).toList();

      // Récupérer le profil émotionnel
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final emotionalProfile = userDoc.data()?['emotional_profile'] ?? {};

      // Analyser les patterns
      final emotionCounts = Map<String, dynamic>.from(
        emotionalProfile['emotion_counts'] is Map
            ? emotionalProfile['emotion_counts'] as Map
            : const {},
      );
      final sortedEmotions =
          emotionCounts.entries.toList()..sort((a, b) {
            final aValue = (a.value as num?)?.toDouble() ?? 0;
            final bValue = (b.value as num?)?.toDouble() ?? 0;
            return bValue.compareTo(aValue);
          });

      return {
        'recent_emotions': recentEmotions.join(', '),
        'patterns': sortedEmotions
            .take(3)
            .map((e) => '${e.key} (${e.value}x)')
            .join(', '),
        'current_state': emotionalProfile['last_emotion'] ?? 'neutre',
        'triggers': emotionalProfile['last_context'] ?? [],
      };
    } catch (e) {
      debugPrint(
        'Erreur lors de la récupération de l\'historique émotionnel: $e',
      );
      return _getDefaultEmotionalHistory();
    }
  }

  Map<String, dynamic> _getDefaultEmotionalHistory() {
    return {
      'recent_emotions': 'Première interaction',
      'patterns': 'En cours d\'apprentissage',
      'current_state': 'neutre',
      'triggers': [],
    };
  }

  // Récupérer la dernière interaction
  Future<Map<String, dynamic>> _getLastInteraction() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return _getDefaultLastInteraction();

      final lastInteractionQuery =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('interactions')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      if (lastInteractionQuery.docs.isNotEmpty) {
        final lastInteraction = lastInteractionQuery.docs.first.data();
        return {
          'summary': lastInteraction['summary'] ?? 'Pas d\'interaction récente',
          'topics': lastInteraction['topics'] ?? [],
          'timestamp': lastInteraction['timestamp'],
        };
      }

      return _getDefaultLastInteraction();
    } catch (e) {
      debugPrint(
        'Erreur lors de la récupération de la dernière interaction: $e',
      );
      return _getDefaultLastInteraction();
    }
  }

  Map<String, dynamic> _getDefaultLastInteraction() {
    return {
      'summary': 'Première rencontre - découverte mutuelle',
      'topics': ['présentation', 'style', 'préférences'],
      'timestamp': DateTime.now(),
    };
  }

  // Récupérer les insights de conversation
  Future<Map<String, dynamic>> _getConversationInsights() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return _getDefaultConversationInsights();

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final conversationData = userDoc.data()?['conversation_insights'] ?? {};

      return {
        'favorite_topics':
            conversationData['favorite_topics'] ?? ['Style', 'Tendances'],
        'communication_style':
            conversationData['communication_style'] ?? 'Décontracté et amical',
        'taste_evolution':
            conversationData['taste_evolution'] ?? 'En cours d\'observation',
        'memorable_moments': conversationData['memorable_moments'] ?? [],
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des insights: $e');
      return _getDefaultConversationInsights();
    }
  }

  Map<String, dynamic> _getDefaultConversationInsights() {
    return {
      'favorite_topics': ['Style', 'Tendances'],
      'communication_style': 'Décontracté et amical',
      'taste_evolution': 'En cours d\'observation',
      'memorable_moments': [],
    };
  }

  // Récupérer le profil de personnalité
  Future<Map<String, dynamic>> _getPersonalityProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return _getDefaultPersonalityProfile();

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final personalityData = userDoc.data()?['personality_profile'] ?? {};

      return {
        'traits': personalityData['traits'] ?? 'En cours d\'analyse',
        'behavioral_preferences':
            personalityData['behavioral_preferences'] ?? [],
        'mood_cycles':
            personalityData['mood_cycles'] ?? 'Patterns en observation',
        'emotional_needs': personalityData['emotional_needs'] ?? [],
        'personal_growth':
            personalityData['personal_growth'] ?? 'Évolution positive',
      };
    } catch (e) {
      debugPrint(
        'Erreur lors de la récupération du profil de personnalité: $e',
      );
      return _getDefaultPersonalityProfile();
    }
  }

  Map<String, dynamic> _getDefaultPersonalityProfile() {
    return {
      'traits': 'En cours d\'analyse',
      'behavioral_preferences': [],
      'mood_cycles': 'Patterns en observation',
      'emotional_needs': [],
      'personal_growth': 'Évolution positive',
    };
  }

  // Enregistrer une interaction
  Future<void> _saveInteraction(String userMessage, String aiResponse) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final interactionData = {
          'user_message': userMessage,
          'ai_response': aiResponse,
          'timestamp': FieldValue.serverTimestamp(),
          'summary': _generateInteractionSummary(userMessage, aiResponse),
          'topics': _extractTopics(userMessage),
          'response_length': aiResponse.length,
          'user_message_length': userMessage.length,
        };

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('interactions')
            .add(interactionData);

        // Mettre à jour les insights de conversation
        await _updateConversationInsights(interactionData);
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement de l\'interaction: $e');
    }
  }

  // Générer un résumé d'interaction
  String _generateInteractionSummary(String userMessage, String aiResponse) {
    final topics = _extractTopics(userMessage);
    final mainTopic =
        topics.isNotEmpty ? topics.first : 'conversation générale';

    if (userMessage.contains('?')) {
      return 'Question sur $mainTopic';
    } else if (userMessage.contains('!')) {
      return 'Exclamation concernant $mainTopic';
    } else {
      return 'Discussion sur $mainTopic';
    }
  }

  // Extraire les sujets d'une conversation
  List<String> _extractTopics(String message) {
    final topics = <String>[];
    final lowerMessage = message.toLowerCase();

    final topicKeywords = {
      'style': ['style', 'look', 'tenue', 'vêtement', 'mode'],
      'couleur': ['couleur', 'teinte', 'nuance', 'ton', 'coloris'],
      'tendance': ['tendance', 'trend', 'fashion', 'actualité', 'nouveau'],
      'événement': ['événement', 'sortie', 'fête', 'occasion', 'célébration'],
      'budget': ['budget', 'prix', 'coût', 'argent', 'économie'],
      'traditionnel': [
        'traditionnel',
        'culturel',
        'africain',
        'wax',
        'bogolan',
        'kente',
        'kimono',
        'sari',
        'broderie',
        'tissage',
      ],
      'moderne': ['moderne', 'contemporain', 'actuel', 'récent'],
      'conseil': ['conseil', 'aide', 'suggestion', 'recommandation'],
    };

    topicKeywords.forEach((topic, keywords) {
      for (String keyword in keywords) {
        if (lowerMessage.contains(keyword)) {
          topics.add(topic);
          break;
        }
      }
    });

    return topics.isEmpty ? ['général'] : topics;
  }

  // Mettre à jour les insights de conversation
  Future<void> _updateConversationInsights(
    Map<String, dynamic> interactionData,
  ) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final userRef = _firestore.collection('users').doc(user.uid);
        final doc = await userRef.get();
        final currentInsights = doc.data()?['conversation_insights'] ?? {};

        // Mettre à jour les sujets favoris
        final List<String> currentTopics = List<String>.from(
          currentInsights['favorite_topics'] ?? [],
        );
        final List<String> newTopics = List<String>.from(
          interactionData['topics'] ?? [],
        );

        for (String topic in newTopics) {
          if (!currentTopics.contains(topic)) {
            currentTopics.add(topic);
          }
        }

        // Analyser le style de communication
        String communicationStyle = _analyzeCommunicationStyle(interactionData);

        // Mettre à jour les moments mémorables
        final List<String> memorableMoments = List<String>.from(
          currentInsights['memorable_moments'] ?? [],
        );
        if (_isMemorableInteraction(interactionData)) {
          memorableMoments.add(
            '${interactionData['summary']} - ${DateTime.now().toString().split(' ')[0]}',
          );
          if (memorableMoments.length > 10) {
            memorableMoments.removeAt(0); // Garder seulement les 10 derniers
          }
        }

        final updatedInsights = {
          'favorite_topics': currentTopics.take(10).toList(),
          'communication_style': communicationStyle,
          'taste_evolution':
              currentInsights['taste_evolution'] ?? 'En cours d\'observation',
          'memorable_moments': memorableMoments,
          'last_updated': FieldValue.serverTimestamp(),
        };

        await userRef.update({'conversation_insights': updatedInsights});
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des insights: $e');
    }
  }

  // Analyser le style de communication
  String _analyzeCommunicationStyle(Map<String, dynamic> interactionData) {
    final String userMessage = interactionData['user_message'] ?? '';
    final int messageLength = userMessage.length;

    if (messageLength < 50) {
      return 'Concis et direct';
    } else if (messageLength < 150) {
      return 'Équilibré et décontracté';
    } else {
      return 'Détaillé et expressif';
    }
  }

  // Déterminer si une interaction est mémorable
  bool _isMemorableInteraction(Map<String, dynamic> interactionData) {
    final String userMessage = interactionData['user_message'] ?? '';
    final int responseLength = interactionData['response_length'] ?? 0;

    // Interaction mémorable si:
    // - Long message de l'utilisateur (>200 caractères)
    // - Réponse détaillée (>500 caractères)
    // - Contient des mots-clés spéciaux
    final memorableKeywords = [
      'merci',
      'parfait',
      'génial',
      'super',
      'j\'adore',
      'magnifique',
    ];

    return userMessage.length > 200 ||
        responseLength > 500 ||
        memorableKeywords.any(
          (keyword) => userMessage.toLowerCase().contains(keyword),
        );
  }

  // Mettre à jour le profil de personnalité
  Future<void> _updatePersonalityProfile(
    Map<String, dynamic> emotionalData,
  ) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final userRef = _firestore.collection('users').doc(user.uid);
        final doc = await userRef.get();
        final currentProfile = doc.data()?['personality_profile'] ?? {};

        // Analyser les traits de personnalité basés sur les émotions
        final traits = _analyzePersonalityTraits(emotionalData);

        // Identifier les besoins émotionnels
        final emotionalNeeds = _identifyEmotionalNeeds(emotionalData);

        // Détecter les cycles d'humeur
        final moodCycles = await _detectMoodCycles(user.uid);

        final updatedProfile = {
          'traits': traits,
          'behavioral_preferences':
              currentProfile['behavioral_preferences'] ?? [],
          'mood_cycles': moodCycles,
          'emotional_needs': emotionalNeeds,
          'personal_growth': _assessPersonalGrowth(currentProfile),
          'last_updated': FieldValue.serverTimestamp(),
        };

        await userRef.update({'personality_profile': updatedProfile});
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du profil de personnalité: $e');
    }
  }

  // Analyser les traits de personnalité
  String _analyzePersonalityTraits(Map<String, dynamic> emotionalData) {
    final String dominantEmotion =
        emotionalData['dominant_emotion'] ?? 'neutre';
    final double intensity = emotionalData['intensity'] ?? 0.0;

    if (dominantEmotion == 'joie' && intensity > 2) {
      return 'Optimiste et enthousiaste';
    } else if (dominantEmotion == 'curiosité') {
      return 'Curieux et ouvert d\'esprit';
    } else if (dominantEmotion == 'confiance') {
      return 'Confiant et déterminé';
    } else if (dominantEmotion == 'stress') {
      return 'Perfectionniste et soucieux du détail';
    } else {
      return 'Équilibré et réfléchi';
    }
  }

  // Identifier les besoins émotionnels
  List<String> _identifyEmotionalNeeds(Map<String, dynamic> emotionalData) {
    final String dominantEmotion =
        emotionalData['dominant_emotion'] ?? 'neutre';
    final List<String> context = List<String>.from(
      emotionalData['context'] ?? [],
    );

    final needs = <String>[];

    if (dominantEmotion == 'stress') {
      needs.addAll([
        'Réassurance',
        'Solutions pratiques',
        'Soutien émotionnel',
      ]);
    } else if (dominantEmotion == 'joie') {
      needs.addAll([
        'Célébration',
        'Partage d\'enthousiasme',
        'Nouvelles expériences',
      ]);
    } else if (dominantEmotion == 'tristesse') {
      needs.addAll(['Écoute active', 'Empathie', 'Réconfort']);
    } else if (dominantEmotion == 'curiosité') {
      needs.addAll(['Information', 'Exploration', 'Apprentissage']);
    }

    // Ajouter des besoins basés sur le contexte
    if (context.contains('travail')) {
      needs.add('Confiance professionnelle');
    } else if (context.contains('sortie')) {
      needs.add('Aide pour se sentir belle');
    }

    return needs.take(5).toList();
  }

  // Détecter les cycles d'humeur
  Future<String> _detectMoodCycles(String userId) async {
    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(Duration(days: 7));

      final recentEmotions =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('emotional_history')
              .where('timestamp', isGreaterThan: lastWeek.toIso8601String())
              .orderBy('timestamp')
              .get();

      if (recentEmotions.docs.length < 3) {
        return 'Données insuffisantes pour détecter les cycles';
      }

      // Analyser les patterns émotionnels
      final emotions =
          recentEmotions.docs
              .map((doc) => doc.data()['dominant_emotion'])
              .toList();
      final Map<String, int> emotionCounts = {};

      for (String emotion in emotions) {
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }

      // Détecter les cycles
      if (emotionCounts['joie'] != null &&
          emotionCounts['joie']! > emotions.length * 0.6) {
        return 'Période très positive';
      } else if (emotionCounts['stress'] != null &&
          emotionCounts['stress']! > emotions.length * 0.4) {
        return 'Période de stress élevé';
      } else {
        return 'Humeur stable et équilibrée';
      }
    } catch (e) {
      debugPrint('Erreur lors de la détection des cycles d\'humeur: $e');
      return 'Analyse en cours';
    }
  }

  // Évaluer la croissance personnelle
  String _assessPersonalGrowth(Map<String, dynamic> currentProfile) {
    final lastUpdate = currentProfile['last_updated'];
    if (lastUpdate == null) {
      return 'Début du parcours de développement';
    }

    // Analyser l'évolution basée sur les données historiques
    final currentTraits = currentProfile['traits'] ?? '';
    if (currentTraits.contains('Confiant')) {
      return 'Développement de la confiance en soi';
    } else if (currentTraits.contains('Curieux')) {
      return 'Exploration et ouverture croissantes';
    } else {
      return 'Évolution positive continue';
    }
  }

  // Récupérer les données utilisateur avec cache
  Future<Map<String, dynamic>> _getUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return {};

      // Vérifier le cache
      if (_cachedUserData != null && _cachedUserId == user.uid) {
        return _cachedUserData!;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _cachedUserData = doc.data() ?? <String, dynamic>{};
        _cachedUserId = user.uid;
        return _cachedUserData!;
      }

      return {};
    } catch (e) {
      debugPrint('Erreur lors de la récupération des données utilisateur: $e');
      return {};
    }
  }

  // Invalider le cache utilisateur
  void _invalidateUserCache() {
    _cachedUserData = null;
    _cachedUserId = null;
    _cachedLiveContext = null;
    _cachedLiveContextAt = null;
  }

  // Méthode principale pour générer du contenu
  Future<String> generateContent(String prompt) async {
    final emotionalData = analyzeEmotions(prompt);

    try {
      // Récupérer les données utilisateur
      final userData = await _getUserData();

      // Sauvegarder l'analyse émotionnelle
      await _saveEmotionalAnalysis(emotionalData);

      // Construire l'instruction système avec toutes les données
      final systemInstruction = await _buildSystemInstruction(userData);

      final geminiPrompt = '''
CONTEXTE ÉMOTIONNEL ACTUEL :
- Émotion dominante détectée : ${emotionalData['dominant_emotion']}
- Intensité émotionnelle : ${emotionalData['intensity']}
- Contexte situationnel : ${emotionalData['context'].join(', ')}

MESSAGE UTILISATEUR : $prompt

INSTRUCTIONS SPÉCIFIQUES :
1. Réponds en tant que conseiller style ElegantStyle
2. Adapte ton ton à l'état émotionnel détecté
3. Intègre naturellement le contexte récent si utile
4. Propose des solutions mode personnalisées
5. Reste ouvert, inclusif, tradition + modernité
6. Maintiens une approche empathique et professionnelle
7. Évite les listes à puces, privilégie un style conversationnel naturel
8. Limite ta réponse à 150-200 mots pour rester engageante''';

      final generatedText = await _generateWithPreferredAi(
        systemInstruction: systemInstruction,
        prompt: geminiPrompt,
        temperature: 0.78,
        topP: 0.94,
        maxOutputTokens: 1000,
      );

      await _saveInteraction(prompt, generatedText);
      await _updatePersonalityProfile(emotionalData);

      return generatedText;
    } on GeminiClientException catch (e) {
      debugPrint('Iris Gemini indisponible: ${e.message}');
      await _saveEmotionalAnalysis(emotionalData);
      return _getOfflineStyleResponse(prompt, emotionalData);
    } catch (e) {
      debugPrint('Erreur lors de la génération de contenu: $e');
      return _getOfflineStyleResponse(prompt, emotionalData);
    }
  }

  Future<String> _generateWithPreferredAi({
    required String systemInstruction,
    required String prompt,
    required double temperature,
    required double topP,
    required int maxOutputTokens,
  }) async {
    final provider =
        (dotenv.env['AI_TEXT_PROVIDER'] ?? '').trim().toLowerCase();

    if (provider == 'openai' && _openAiClient.isConfigured) {
      try {
        return await _openAiClient.generateText(
          systemInstruction: systemInstruction,
          prompt: prompt,
          temperature: temperature,
          topP: topP,
          maxOutputTokens: maxOutputTokens,
        );
      } on OpenAiClientException catch (e) {
        debugPrint('OpenAI indisponible, bascule Gemini: ${e.message}');
      }
    }

    try {
      return await _geminiClient.generateText(
        systemInstruction: systemInstruction,
        prompt: prompt,
        temperature: temperature,
        topK: 40,
        topP: topP,
        maxOutputTokens: maxOutputTokens,
      );
    } on GeminiClientException catch (e) {
      if (!_openAiClient.isConfigured) rethrow;
      debugPrint('Gemini indisponible, bascule OpenAI: ${e.message}');
    }

    return _openAiClient.generateText(
      systemInstruction: systemInstruction,
      prompt: prompt,
      temperature: temperature,
      topP: topP,
      maxOutputTokens: maxOutputTokens,
    );
  }

  Future<String> generateChatContent({
    required String prompt,
    String conversationContext = '',
    bool useWebSearch = false,
  }) async {
    var enrichedPrompt = prompt;

    if (conversationContext.trim().isNotEmpty) {
      enrichedPrompt = '''
Contexte récent de la conversation avec l'utilisateur :
$conversationContext

Nouveau message utilisateur :
$prompt''';
    }

    if (useWebSearch) {
      final webContext = await searchFashionInfo(prompt);
      enrichedPrompt = '''
$enrichedPrompt

Informations web récentes à utiliser si elles sont pertinentes :
$webContext

Réponds naturellement, cite les liens utiles s'ils existent, et indique clairement quand une information vient du web.''';
    }

    return generateContent(enrichedPrompt);
  }

  String _getOfflineStyleResponse(
    String prompt,
    Map<String, dynamic> emotionalData,
  ) {
    final lowerPrompt = prompt.toLowerCase();
    final emotion = emotionalData['dominant_emotion']?.toString() ?? 'neutre';
    final reassuringIntro =
        emotion == 'stress' || emotion == 'doute'
            ? 'Je peux déjà vous orienter simplement.'
            : 'Je peux déjà vous proposer une base élégante.';

    if (_containsAny(lowerPrompt, [
      'mariage',
      'cérémonie',
      'baptême',
      'gala',
    ])) {
      return '$reassuringIntro Pour une occasion habillée, partez sur une silhouette nette : une pièce forte bien coupée, une couleur principale élégante, puis deux accents maximum avec les chaussures et les accessoires. Si vous aimez le mélange tradition et modernité, associez un textile culturel ou artisanal à une coupe contemporaine. Gardez le confort en tête : l’allure premium vient surtout d’un bon tombé et de finitions propres.';
    }

    if (_containsAny(lowerPrompt, [
      'bureau',
      'travail',
      'réunion',
      'entretien',
    ])) {
      return '$reassuringIntro Pour un look professionnel, choisissez une base sobre et structurée : pantalon droit, jupe midi, chemise, veste légère ou ensemble coordonné. Ajoutez une touche personnelle avec une texture, un imprimé discret ou un accessoire de caractère. L’objectif est d’avoir une tenue facile à porter, crédible et mémorable sans être trop chargée.';
    }

    if (_containsAny(lowerPrompt, ['couleur', 'couleurs', 'teint', 'peau'])) {
      return '$reassuringIntro Commencez par identifier les couleurs qui illuminent votre visage : si les tons chauds vous vont bien, testez terracotta, ivoire, doré, vert olive ou chocolat. Si les tons froids vous flattent plus, essayez bleu profond, gris perle, rose poudré, blanc net ou bordeaux froid. Le plus sûr reste de placer la couleur forte près du visage et de garder le reste plus calme.';
    }

    if (_containsAny(lowerPrompt, [
      'morphologie',
      'silhouette',
      'taille',
      'forme',
    ])) {
      return '$reassuringIntro Pour valoriser une silhouette, cherchez l’équilibre plutôt que la règle stricte. Marquez la zone que vous aimez, choisissez une coupe qui suit le corps sans le serrer, et gardez une proportion claire entre haut et bas. Une taille légèrement structurée, une longueur bien choisie et des matières qui tiennent bien font souvent plus que beaucoup d’accessoires.';
    }

    if (_containsAny(lowerPrompt, [
      'pagne',
      'wax',
      'faso dan fani',
      'tradition',
      'traditionnel',
    ])) {
      return '$reassuringIntro Pour moderniser une pièce traditionnelle, laissez-la être le point focal. Associez-la à une coupe contemporaine, des chaussures sobres et des accessoires minimalistes. Un pagne, un tissage ou un motif fort fonctionne très bien avec une chemise blanche, un blazer net, une jupe simple ou un pantalon bien coupé.';
    }

    return '$reassuringIntro Donnez-moi l’occasion, votre style préféré, les couleurs que vous aimez et votre budget, et je pourrai affiner. En attendant, partez sur une tenue équilibrée : une pièce principale forte, une coupe confortable, des accessoires simples et une palette de deux ou trois couleurs maximum. C’est la base la plus sûre pour un rendu élégant et facile à personnaliser.';
  }

  bool _containsAny(String value, List<String> keywords) {
    return keywords.any(value.contains);
  }

  // Méthode pour rechercher des informations mode
  Future<String> searchFashionInfo(String query) async {
    try {
      // Use existing method name - check your SerpApiService class
      final searchResults = await _serpApiService.hybridSearch(
        'fashion style trends $query',
      );

      // Check if there's an error in the results
      if (searchResults.containsKey('error')) {
        return searchResults['error'] as String;
      }

      // Check if the search was successful
      if (searchResults['success'] == true) {
        // Extract the actual content from the results
        // Adjust these keys based on what your hybridSearch actually returns
        if (searchResults.containsKey('results')) {
          return _processFashionResults(searchResults['results']);
        } else if (searchResults.containsKey('data')) {
          return _processFashionResults(searchResults['data']);
        } else if (searchResults.containsKey('content')) {
          return searchResults['content'].toString();
        }
      }

      // If no specific content found, return a generic message
      return 'Aucune information mode trouvée pour cette recherche.';
    } catch (e) {
      debugPrint('Erreur lors de la recherche mode: $e');
      return 'Désolée, je ne peux pas accéder aux informations de recherche en ce moment.';
    }
  }

  // Helper method to process fashion results
  String _processFashionResults(dynamic results) {
    try {
      if (results is List) {
        // If results is a list of items
        String fashionInfo = '';
        for (var item in results.take(5)) {
          if (item is Map<String, dynamic>) {
            final title = item['title'] ?? '';
            final snippet = item['snippet'] ?? item['description'] ?? '';

            if (title.isNotEmpty && snippet.isNotEmpty) {
              fashionInfo += '• $title\n$snippet\n\n';
            }
          }
        }
        return fashionInfo.isNotEmpty
            ? fashionInfo
            : 'Aucune information mode pertinente trouvée.';
      } else if (results is Map<String, dynamic>) {
        // If results is a single map object
        final title = results['title'] ?? '';
        final content =
            results['content'] ??
            results['snippet'] ??
            results['description'] ??
            '';

        if (title.isNotEmpty && content.isNotEmpty) {
          return '• $title\n$content';
        }
      } else if (results is String) {
        // If results is already a string
        return results;
      }

      return 'Format de résultats non reconnu.';
    } catch (e) {
      debugPrint('Erreur lors du traitement des résultats: $e');
      return 'Erreur lors du traitement des informations mode.';
    }
  }

  // Alternative simpler version if you just want the raw content
  Future<String> searchFashionInfoSimple(String query) async {
    try {
      final searchResults = await _serpApiService.hybridSearch(
        'fashion style trends $query',
      );

      // Convert the entire result to a formatted string
      if (searchResults.containsKey('error')) {
        return searchResults['error'] as String;
      }

      // Return a formatted version of the results
      return searchResults.toString();
    } catch (e) {
      debugPrint('Erreur lors de la recherche mode: $e');
      return 'Désolée, je ne peux pas accéder aux informations de recherche en ce moment.';
    }
  }

  // Méthode pour réinitialiser le cache et les données
  void resetCache() {
    _invalidateUserCache();
  }

  // Méthode pour obtenir des statistiques utilisateur
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final userData = await _getUserData();
      final emotionalHistory = await _getEmotionalHistory();
      final conversationInsights = await _getConversationInsights();

      return {
        'user_data': userData,
        'emotional_history': emotionalHistory,
        'conversation_insights': conversationInsights,
        'cache_status': _cachedUserData != null ? 'cached' : 'not_cached',
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des statistiques: $e');
      return {};
    }
  }
}

class _IrisLocationSnapshot {
  const _IrisLocationSnapshot({
    required this.summary,
    required this.promptContext,
    required this.hasLocation,
  });

  final String summary;
  final String promptContext;
  final bool hasLocation;
}
