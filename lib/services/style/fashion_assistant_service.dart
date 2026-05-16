import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../models/measurements/measurement_profile.dart';
import '../../models/style/fashion_assistant_models.dart';
import '../../models/wardrobe/wardrobe_item.dart';
import '../ai/gemini_client.dart';
import '../ai/openai_client.dart';
import '../preferences/currency_service.dart';

class FashionAssistantService {
  FashionAssistantService({FirebaseFirestore? firestore, http.Client? client})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _client = client ?? http.Client(),
      _geminiClient = GeminiClient(client: client),
      _openAiClient = OpenAiClient(client: client);

  final FirebaseFirestore _firestore;
  final http.Client _client;
  final GeminiClient _geminiClient;
  final OpenAiClient _openAiClient;
  static const Duration _contextCacheTtl = Duration(minutes: 4);
  static final Map<String, _StyleContextCacheEntry> _contextCache = {};

  bool get hasGeminiKey => _geminiClient.isConfigured;
  bool get hasOpenAiKey => _openAiClient.isConfigured;
  bool get hasStabilityKey =>
      (dotenv.env['STABILITY_API_KEY'] ?? '').isNotEmpty;
  bool get hasImageGeneration =>
      hasStabilityKey ||
      (hasOpenAiKey &&
          (dotenv.env['STYLE_IMAGE_PROVIDER'] ?? 'openai')
                  .trim()
                  .toLowerCase() ==
              'openai');

  Future<StyleUserContext> loadUserContext(String userId) async {
    final cached = _contextCache[userId];
    if (cached != null && cached.isFresh) return cached.value;

    final userRef = _firestore.collection('users').doc(userId);
    final userDocFuture = userRef.get();
    final wardrobeFuture =
        userRef
            .collection('wardrobe')
            .orderBy('createdAt', descending: true)
            .limit(40)
            .get();
    final measurementFuture =
        userRef.collection('measurements').doc('profile').get();
    final latestFuture =
        userRef
            .collection('style_consultations')
            .orderBy('createdAt', descending: true)
            .limit(8)
            .get();

    final results = await Future.wait([
      userDocFuture,
      wardrobeFuture,
      measurementFuture,
      latestFuture,
    ]);
    final userDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final wardrobeSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final measurementDoc = results[2] as DocumentSnapshot<Map<String, dynamic>>;
    final latestSnapshot = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final userData = userDoc.data() ?? {};
    final location = _styleLocationFrom(userData);
    final wardrobe =
        wardrobeSnapshot.docs
            .map(WardrobeItem.fromFirestore)
            .where((item) => !item.isArchived)
            .toList();

    final measurements =
        measurementDoc.exists
            ? MeasurementProfile.fromFirestore(measurementDoc)
            : null;

    final looks = latestSnapshot.docs.map(GeneratedLook.fromFirestore).toList();

    final context = StyleUserContext(
      country:
          location.country.isNotEmpty
              ? location.country
              : location.label.isNotEmpty
              ? location.label
              : 'Monde',
      region:
          location.region.isNotEmpty
              ? location.region
              : location.label.isNotEmpty
              ? location.label
              : 'Votre zone',
      currency: CurrencyService.currencyFromUserData(userData),
      styleProfile:
          userData['styleProfile']?.toString() ??
          userData['preferredStyle']?.toString() ??
          'Style personnel',
      wardrobe: wardrobe,
      measurements: measurements,
      latestLook: looks.isEmpty ? null : looks.first,
    );
    _contextCache[userId] = _StyleContextCacheEntry(context);
    return context;
  }

  void clearUserContextCache(String userId) {
    _contextCache.remove(userId);
  }

  _StyleLocation _styleLocationFrom(Map<String, dynamic> userData) {
    final shopProfile =
        userData['shopProfile'] is Map
            ? Map<String, dynamic>.from(userData['shopProfile'] as Map)
            : const <String, dynamic>{};
    final creatorProfile =
        userData['creatorProfile'] is Map
            ? Map<String, dynamic>.from(userData['creatorProfile'] as Map)
            : const <String, dynamic>{};

    final region = _firstNonEmpty([
      userData['region'],
      userData['city'],
      userData['ville'],
      userData['zone'],
    ]);
    final country = _firstNonEmpty([userData['country'], userData['pays']]);
    final label = _firstNonEmpty([
      userData['location'],
      userData['address'],
      userData['boutiqueAddress'],
      shopProfile['address'],
      shopProfile['location'],
      creatorProfile['location'],
    ]);

    return _StyleLocation(region: region, country: country, label: label);
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return value.toString();
    }
    return '';
  }

  Stream<List<GeneratedLook>> watchHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('style_consultations')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          final looks = snapshot.docs.map(GeneratedLook.fromFirestore).toList();
          return looks;
        });
  }

  Future<GeneratedLook> generateLook(
    StyleContext context, {
    required void Function(String stage) onStage,
    String variant = 'balanced',
  }) async {
    onStage('Analyse du contexte');
    final palette = buildPalette(context);
    final budget = buildBudget(context);
    final score = recommendationScore(context);

    onStage('Lecture garde-robe et mensurations');
    await Future<void>.delayed(const Duration(milliseconds: 150));

    onStage('Préparation du conseil');
    final consultation = await _generateConsultation(
      context,
      palette: palette,
      budget: budget,
      score: score,
      variant: variant,
    );

    Uint8List? imageBytes;
    if (hasImageGeneration) {
      onStage('Image');
      imageBytes = await _generateImage(context, palette);
    }

    return GeneratedLook(
      id: '',
      title: _titleFor(context, variant),
      prompt: context.prompt,
      consultation: consultation,
      palette: palette,
      budget: budget,
      shoppingList: _shoppingList(context),
      culturalTips: _culturalTips(context),
      score: score,
      currency: context.currency,
      country: context.country,
      region: context.region,
      imageStyle: context.imageStyle,
      imageBytes: imageBytes,
    );
  }

  Future<String> saveLook(String userId, GeneratedLook look) async {
    final ref = await _firestore
        .collection('users')
        .doc(userId)
        .collection('style_consultations')
        .add(look.toFirestore(includeCreatedAt: true));
    return ref.id;
  }

  Future<void> toggleFavorite(String userId, GeneratedLook look) {
    if (look.id.isEmpty) return Future<void>.value();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('style_consultations')
        .doc(look.id)
        .set({
          'favorite': !look.favorite,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  List<ColorPalette> buildPalette(StyleContext context) {
    final names =
        context.occasion.colors.isNotEmpty
            ? context.occasion.colors
            : context.season.colors;
    return names.map((name) {
      final value = _colorValues[name] ?? 0xFF0F766E;
      return ColorPalette(name: name, value: value, meaning: _meaning(name));
    }).toList();
  }

  List<BudgetEstimate> buildBudget(StyleContext context) {
    final min = context.occasion.minBudget;
    final max = context.occasion.maxBudget;
    final base = min + ((max - min) * 0.58).round();
    return [
      BudgetEstimate(
        label: 'Pièce principale',
        amount: (base * 0.42).round(),
        details: 'Tissu, coupe et finitions majeures',
      ),
      BudgetEstimate(
        label: 'Couture / ajustement',
        amount: (base * 0.28).round(),
        details: 'Main d’œuvre, retouches, confort',
      ),
      BudgetEstimate(
        label: 'Accessoires',
        amount: (base * 0.18).round(),
        details: 'Chaussures, sac, bijoux, foulard',
      ),
      BudgetEstimate(
        label: 'Marge confort',
        amount: (base * 0.12).round(),
        details: 'Transport, urgence, amélioration qualité',
      ),
      BudgetEstimate(
        label: 'Total estimé',
        amount: base,
        details: context.currency,
      ),
    ];
  }

  int recommendationScore(StyleContext context) {
    var score = 52;
    if (context.prompt.trim().length > 20) score += 10;
    if (context.useWardrobe && context.wardrobe.isNotEmpty) score += 14;
    if (context.useMeasurements &&
        (context.measurements?.completionRate ?? 0) >= 0.5) {
      score += 14;
    }
    if (context.region.trim().isNotEmpty && context.region != 'Votre zone') {
      score += 5;
    }
    if (context.cultureMode != 'global') score += 5;
    return score.clamp(0, 98);
  }

  Future<String> _generateConsultation(
    StyleContext context, {
    required List<ColorPalette> palette,
    required List<BudgetEstimate> budget,
    required int score,
    required String variant,
  }) async {
    if (!hasGeminiKey && !hasOpenAiKey) {
      return _offlineConsultation(context, palette, budget, score);
    }

    final prompt = _buildPrompt(context, palette, budget, score, variant);
    final provider =
        (dotenv.env['AI_TEXT_PROVIDER'] ?? '').trim().toLowerCase();

    if (provider == 'openai' && hasOpenAiKey) {
      try {
        return await _openAiClient.generateText(
          prompt: prompt,
          temperature: 0.72,
          topP: 0.92,
          maxOutputTokens: 1800,
        );
      } catch (_) {
        if (!hasGeminiKey) {
          return _offlineConsultation(context, palette, budget, score);
        }
      }
    }

    try {
      return await _geminiClient.generateText(
        prompt: prompt,
        temperature: 0.72,
        topK: 35,
        topP: 0.92,
        maxOutputTokens: 1800,
      );
    } catch (_) {
      if (!hasOpenAiKey) {
        return _offlineConsultation(context, palette, budget, score);
      }
    }

    try {
      return await _openAiClient.generateText(
        prompt: prompt,
        temperature: 0.72,
        topP: 0.92,
        maxOutputTokens: 1800,
      );
    } catch (_) {
      return _offlineConsultation(context, palette, budget, score);
    }
  }

  Future<Uint8List?> _generateImage(
    StyleContext context,
    List<ColorPalette> palette,
  ) async {
    final provider =
        (dotenv.env['STYLE_IMAGE_PROVIDER'] ?? 'openai').trim().toLowerCase();
    if (provider == 'openai' && hasOpenAiKey) {
      final image = await _generateOpenAiImage(context, palette);
      if (image != null) return image;
    }
    if (hasStabilityKey) {
      return _generateStabilityImage(context, palette);
    }
    if (hasOpenAiKey) {
      return _generateOpenAiImage(context, palette);
    }
    return null;
  }

  Future<Uint8List?> _generateOpenAiImage(
    StyleContext context,
    List<ColorPalette> palette,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) return null;

    final model =
        dotenv.env['OPENAI_IMAGE_MODEL']?.trim().isNotEmpty == true
            ? dotenv.env['OPENAI_IMAGE_MODEL']!.trim()
            : 'gpt-image-1';
    final quality =
        dotenv.env['OPENAI_IMAGE_QUALITY']?.trim().isNotEmpty == true
            ? dotenv.env['OPENAI_IMAGE_QUALITY']!.trim()
            : 'medium';

    try {
      final response = await _client
          .post(
            Uri.parse('https://api.openai.com/v1/images/generations'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'prompt': _buildImagePrompt(context, palette),
              'size': '1024x1024',
              'quality': quality,
              'n': 1,
            }),
          )
          .timeout(const Duration(seconds: 65));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final images = data['data'] as List?;
      if (images == null || images.isEmpty) return null;
      final first = images.first;
      if (first is! Map<String, dynamic>) return null;
      final b64 = first['b64_json']?.toString();
      if (b64 == null || b64.isEmpty) return null;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _generateStabilityImage(
    StyleContext context,
    List<ColorPalette> palette,
  ) async {
    final apiKey = dotenv.env['STABILITY_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    final prompt = _buildImagePrompt(context, palette);

    try {
      final response = await _client
          .post(
            Uri.parse(
              'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image',
            ),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'text_prompts': [
                {'text': prompt, 'weight': 1.0},
                {
                  'text':
                      'blurry, low quality, distorted anatomy, watermark, text, logo, nsfw',
                  'weight': -1.0,
                },
              ],
              'cfg_scale': 8,
              'height': 1024,
              'width': 1024,
              'samples': 1,
              'steps': 32,
              'style_preset': 'photographic',
            }),
          )
          .timeout(const Duration(seconds: 55));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final artifacts = data['artifacts'] as List?;
      if (artifacts == null || artifacts.isEmpty) return null;
      final base64Image = artifacts.first['base64']?.toString();
      if (base64Image == null) return null;
      return base64Decode(base64Image);
    } catch (_) {
      return null;
    }
  }

  String _buildImagePrompt(StyleContext context, List<ColorPalette> palette) {
    final wardrobeHint =
        context.useWardrobe && context.wardrobe.isNotEmpty
            ? 'Inspired by wardrobe pieces: ${context.wardrobe.take(5).map((item) => '${item.name} ${item.category} ${item.color}').join(', ')}.'
            : 'Create a practical outfit concept from scratch.';
    return [
      'Premium mobile-first fashion look concept for ElegantStyle.',
      'Target: ${context.gender}, occasion: ${context.occasion.name}, visual style: ${context.imageStyle}.',
      'Location context: ${context.region}, ${context.country}; climate: ${context.climate}.',
      'Palette: ${palette.map((item) => item.name).join(', ')}.',
      'Culture mode: ${context.cultureMode}; respectful modern styling, inclusive body-neutral presentation.',
      wardrobeHint,
      'Show a complete outfit with clear garment details, natural proportions, elegant lighting, no brand logos, no readable text, no watermark.',
    ].join(' ');
  }

  String _buildPrompt(
    StyleContext context,
    List<ColorPalette> palette,
    List<BudgetEstimate> budget,
    int score,
    String variant,
  ) {
    final wardrobeNames = context.wardrobe
        .take(10)
        .map((item) {
          return '${item.name} (${item.category}, ${item.color})';
        })
        .join(', ');
    final measurements = context.measurements;

    return '''
Tu es un conseiller style pour ElegantStyle.
Réponds en français, avec un ton clair, chaleureux et professionnel.
Évite de limiter la recommandation au Burkina : adapte-toi à la zone utilisateur.

Contexte utilisateur:
- Demande: ${context.prompt}
- Variante: $variant
- Genre/style cible: ${context.gender}
- Pays: ${context.country}
- Région/ville: ${context.region}
- Climat: ${context.climate}
- Mode culturel: ${context.cultureMode}
- Saison: ${context.season.name} (${context.season.description})
- Occasion: ${context.occasion.name} (${context.occasion.description})
- Devise: ${context.currency}
- Score contexte: $score/100
- Garde-robe disponible: ${context.useWardrobe ? wardrobeNames : 'non utilisée'}
- Mensurations: ${context.useMeasurements ? '${((measurements?.completionRate ?? 0) * 100).round()}% complètes, morphologie ${measurements?.bodyProfile ?? 'non renseignée'}' : 'non utilisées'}
- Palette: ${palette.map((item) => '${item.name}: ${item.meaning}').join('; ')}
- Budget: ${budget.map((item) => '${item.label}: ${item.amount} ${context.currency}').join('; ')}

Structure obligatoire:
1. LOOK
2. COULEURS
3. BUDGET
4. CONSEILS CULTURELS ET CLIMAT
5. À ACHETER / À UTILISER DE LA GARDE-ROBE
6. AJUSTEMENT ET CONFORT

Sois concret, ergonomique, actionnable, et donne des alternatives modernes/traditionnelles/économiques selon la variante.
''';
  }

  String _offlineConsultation(
    StyleContext context,
    List<ColorPalette> palette,
    List<BudgetEstimate> budget,
    int score,
  ) {
    final wardrobeLine =
        context.useWardrobe && context.wardrobe.isNotEmpty
            ? 'Commencez avec ${context.wardrobe.take(3).map((e) => e.name).join(', ')} puis complétez avec une pièce forte.'
            : 'Ajoutez quelques pièces dans votre garde-robe pour obtenir des propositions encore plus précises.';
    return '''
LOOK
Pour ${context.occasion.name.toLowerCase()}, je recommande une silhouette équilibrée, adaptée à ${context.region}, avec une pièce principale nette, une base confortable et un accessoire qui donne du caractère.

COULEURS
Palette conseillée : ${palette.map((item) => item.name).join(', ')}. Utilisez une couleur dominante, une couleur de liaison et une touche accent pour garder une lecture élégante.

BUDGET
Budget estimé : ${budget.last.amount} ${context.currency}. Priorisez la pièce principale et les retouches, puis gardez une marge pour les accessoires.

CONSEILS CULTURELS ET CLIMAT
Mode culturel : ${context.cultureMode}. Climat : ${context.climate}. Privilégiez des matières respirantes si la zone est chaude, et ajoutez une couche légère si la soirée peut être fraîche.

À ACHETER / À UTILISER DE LA GARDE-ROBE
$wardrobeLine

AJUSTEMENT ET CONFORT
Score de recommandation : $score/100. ${context.useMeasurements ? 'Les mensurations peuvent guider les longueurs et l’aisance.' : 'Activez les mensurations pour améliorer les conseils d’ajustement.'}
''';
  }

  String _titleFor(StyleContext context, String variant) {
    final variantLabel = switch (variant) {
      'modern' => 'moderne',
      'traditional' => 'culturel',
      'budget' => 'économique',
      'colorful' => 'coloré',
      _ => 'personnalisé',
    };
    return 'Look ${context.occasion.name} $variantLabel';
  }

  List<String> _shoppingList(StyleContext context) {
    return [
      'Pièce principale adaptée à ${context.occasion.name}',
      'Chaussures confortables pour ${context.region}',
      'Accessoire de rappel couleur',
      if (context.wardrobe.isEmpty)
        'Première base neutre pour votre garde-robe',
    ];
  }

  List<String> _culturalTips(StyleContext context) {
    return [
      'Adaptez les couleurs au niveau de formalité de ${context.occasion.name}.',
      'Respectez les codes locaux de ${context.region} tout en gardant votre style.',
      'Choisissez des matières compatibles avec le climat ${context.climate}.',
    ];
  }

  static const Map<String, int> _colorValues = {
    'Teal': 0xFF0F766E,
    'Ivory': 0xFFFFFFF0,
    'Gold': 0xFFF59E0B,
    'Rose': 0xFFE11D48,
    'Indigo': 0xFF4F46E5,
    'Charcoal': 0xFF1F2933,
    'Sand': 0xFFD6B98C,
    'Olive': 0xFF6B8E23,
    'Sky': 0xFF38BDF8,
    'Terracotta': 0xFFCC5500,
  };

  String _meaning(String name) {
    return switch (name) {
      'Teal' => 'équilibre moderne et fraîcheur',
      'Ivory' => 'pureté, lumière et élégance',
      'Gold' => 'prestige et chaleur',
      'Rose' => 'présence et énergie',
      'Indigo' => 'profondeur et sophistication',
      'Charcoal' => 'sobriété professionnelle',
      'Sand' => 'neutralité douce',
      'Olive' => 'naturel et stabilité',
      'Sky' => 'légèreté et clarté',
      'Terracotta' => 'ancrage et caractère',
      _ => 'harmonie visuelle',
    };
  }
}

class _StyleLocation {
  const _StyleLocation({
    required this.region,
    required this.country,
    required this.label,
  });

  final String region;
  final String country;
  final String label;
}

const styleSeasons = [
  StyleSeason(
    id: 'tropical',
    name: 'Tropical',
    climate: 'chaud humide',
    description: 'Chaleur, humidité et besoin de respirabilité',
    colors: ['Teal', 'Ivory', 'Sky', 'Olive'],
    fabrics: ['coton léger', 'lin', 'viscose'],
  ),
  StyleSeason(
    id: 'dry',
    name: 'Sec',
    climate: 'chaud sec',
    description: 'Lumière forte, air sec, soirées parfois fraîches',
    colors: ['Terracotta', 'Sand', 'Gold', 'Ivory'],
    fabrics: ['coton', 'lin épais', 'textile artisanal'],
  ),
  StyleSeason(
    id: 'rain',
    name: 'Pluie',
    climate: 'pluvieux',
    description: 'Humidité, déplacements et protection légère',
    colors: ['Indigo', 'Teal', 'Charcoal', 'Olive'],
    fabrics: ['matières faciles à sécher', 'coton serré'],
  ),
  StyleSeason(
    id: 'winter',
    name: 'Hiver',
    climate: 'froid',
    description: 'Superpositions, chaleur et textures',
    colors: ['Charcoal', 'Indigo', 'Gold', 'Rose'],
    fabrics: ['laine', 'denim', 'maille'],
  ),
  StyleSeason(
    id: 'summer',
    name: 'Été',
    climate: 'chaud',
    description: 'Légèreté, protection solaire et couleurs fraîches',
    colors: ['Ivory', 'Sky', 'Teal', 'Gold'],
    fabrics: ['lin', 'coton léger', 'popeline'],
  ),
  StyleSeason(
    id: 'mid',
    name: 'Mi-saison',
    climate: 'variable',
    description: 'Flexibilité entre journée et soirée',
    colors: ['Sand', 'Teal', 'Charcoal', 'Rose'],
    fabrics: ['coton', 'twill', 'maille légère'],
  ),
];

const styleOccasions = [
  StyleOccasion(
    id: 'daily',
    name: 'Quotidien',
    description: 'Tenue pratique, confortable et soignée',
    minBudget: 40,
    maxBudget: 160,
    colors: ['Teal', 'Ivory', 'Sand'],
  ),
  StyleOccasion(
    id: 'work',
    name: 'Bureau',
    description: 'Style professionnel moderne',
    minBudget: 80,
    maxBudget: 260,
    colors: ['Charcoal', 'Ivory', 'Teal'],
  ),
  StyleOccasion(
    id: 'ceremony',
    name: 'Cérémonie',
    description: 'Élégance, respect des codes et présence',
    minBudget: 140,
    maxBudget: 520,
    colors: ['Gold', 'Rose', 'Ivory', 'Indigo'],
  ),
  StyleOccasion(
    id: 'wedding',
    name: 'Mariage',
    description: 'Look habillé, joyeux et photogénique',
    minBudget: 180,
    maxBudget: 850,
    colors: ['Gold', 'Rose', 'Ivory', 'Teal'],
  ),
  StyleOccasion(
    id: 'casual',
    name: 'Sortie',
    description: 'Décontracté, expressif et confortable',
    minBudget: 60,
    maxBudget: 220,
    colors: ['Sky', 'Teal', 'Sand', 'Rose'],
  ),
];

class _StyleContextCacheEntry {
  _StyleContextCacheEntry(this.value) : createdAt = DateTime.now();

  final StyleUserContext value;
  final DateTime createdAt;

  bool get isFresh =>
      DateTime.now().difference(createdAt) <
      FashionAssistantService._contextCacheTtl;
}
