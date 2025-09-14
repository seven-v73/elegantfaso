import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    print("Fichier .env chargé avec succès");
  } catch (e) {
    print("Erreur lors du chargement du fichier .env: $e");
  }
  runApp(const FashionAssistantApp());
}

class FashionAssistantApp extends StatelessWidget {
  const FashionAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Iris - Styliste Burkinabé',
      theme: ThemeData(
        primarySwatch: _createMaterialColor(const Color(0xFF8B4513)),
        scaffoldBackgroundColor: const Color(0xFFFDF5E6),
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B4513),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2C1810),
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5D4037),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 6,
          shadowColor: const Color(0xFF8B4513).withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B4513),
          titleTextStyle: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const BurkinabeFashionAssistant(),
    );
  }

  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

class BurkinabeFashionAssistant extends StatefulWidget {
  const BurkinabeFashionAssistant({super.key});

  @override
  _BurkinabeFashionAssistantState createState() => _BurkinabeFashionAssistantState();
}

class _BurkinabeFashionAssistantState extends State<BurkinabeFashionAssistant>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  String _generatedOutfit = "";
  Uint8List? _imageData;
  bool _isLoading = false;
  bool _isGeneratingImage = false;
  bool _isGeneratingText = false;
  String _imageStyle = "flat_lay";
  String _selectedSeason = "harmattan";
  String _selectedOccasion = "quotidien";
  String _selectedGender = "femme";
  int _currentPageIndex = 0;
  List<Map<String, dynamic>> _colorHarmony = [];
  List<Map<String, dynamic>> _culturalAdvice = [];
  List<Map<String, dynamic>> _budgetEstimate = [];

  // Navigation
  late TabController _tabController;

  // Animations
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Couleurs traditionnelles burkinabé
  final Map<String, Color> _burkinabeColors = {
    'Terre de Sienne': const Color(0xFFA0522D),
    'Ocre Rouge': const Color(0xFFCC5500),
    'Jaune Sahel': const Color(0xFFFFB347),
    'Vert Karité': const Color(0xFF8FBC8F),
    'Rouge Traditionnel': const Color(0xFFDC143C),
    'Indigo Mossi': const Color(0xFF4B0082),
    'Blanc Coton': const Color(0xFFFFFFF0),
    'Brun Baobab': const Color(0xFF8B4513),
    'Bleu Touareg': const Color(0xFF5D8AA8),
    'Or Savannah': const Color(0xFFFFD700),
    'Mauve Désert': const Color(0xFF9966CC),
    'Vert Nil': const Color(0xFF7FFF00),
    'Noir': Colors.black,
    'Rose Pâle': const Color(0xFFFFD1DC),
  };

  // Saisons burkinabé
  final List<Map<String, dynamic>> _seasons = [
    {
      'id': 'harmattan',
      'name': 'Harmattan',
      'icon': '🌪️',
      'description': 'Saison sèche et venteuse',
      'colors': ['Terre de Sienne', 'Brun Baobab', 'Ocre Rouge', 'Or Savannah'],
      'fabrics': ['Coton épais', 'Faso Dan Fani'],
    },
    {
      'id': 'saison_seche',
      'name': 'Saison Sèche',
      'icon': '☀️',
      'description': 'Période chaude et sèche',
      'colors': ['Jaune Sahel', 'Blanc Coton', 'Vert Karité', 'Or Savannah'],
      'fabrics': ['Coton léger', 'Batik'],
    },
    {
      'id': 'hivernage',
      'name': 'Hivernage',
      'icon': '🌧️',
      'description': 'Saison des pluies',
      'colors': ['Vert Karité', 'Indigo Mossi', 'Rouge Traditionnel', 'Bleu Touareg'],
      'fabrics': ['Wax imperméable', 'Bogolan'],
    },
  ];

  // Occasions burkinabé
  final List<Map<String, dynamic>> _occasions = [
    {
      'id': 'quotidien',
      'name': 'Quotidien',
      'icon': '🏠',
      'description': 'Tenue de tous les jours',
      'budgetRange': [5000, 15000]
    },
    {
      'id': 'marche',
      'name': 'Marché',
      'icon': '🛍️',
      'description': 'Sortie au marché',
      'budgetRange': [8000, 20000]
    },
    {
      'id': 'ceremonie',
      'name': 'Cérémonie',
      'icon': '🎭',
      'description': 'Événement traditionnel',
      'budgetRange': [15000, 50000]
    },
    {
      'id': 'mariage',
      'name': 'Mariage',
      'icon': '💒',
      'description': 'Cérémonie nuptiale',
      'budgetRange': [25000, 100000]
    },
    {
      'id': 'funerailles',
      'name': 'Funérailles',
      'icon': '⚰️',
      'description': 'Cérémonie funéraire',
      'budgetRange': [10000, 40000],
      'colors': ['Noir', 'Brun Baobab', 'Blanc Coton', 'Bleu Touareg']
    },
    {
      'id': 'bapteme',
      'name': 'Baptême',
      'icon': '👶',
      'description': 'Cérémonie de baptême',
      'budgetRange': [15000, 45000],
      'colors': ['Blanc Coton', 'Or Savannah', 'Bleu Touareg', 'Rose Pâle']
    },
    {
      'id': 'dot',
      'name': 'Dot',
      'icon': '💍',
      'description': 'Cérémonie de dot',
      'budgetRange': [20000, 80000],
      'colors': ['Rouge Traditionnel', 'Or Savannah', 'Blanc Coton', 'Vert Karité']
    },
    {
      'id': 'fete_nationale',
      'name': 'Fête Nationale',
      'icon': '🇧🇫',
      'description': '11 Décembre',
      'budgetRange': [10000, 30000]
    },
    {
      'id': 'travail',
      'name': 'Travail',
      'icon': '💼',
      'description': 'Tenue professionnelle',
      'budgetRange': [10000, 35000]
    },
  ];

  // Genres
  final List<Map<String, dynamic>> _genders = [
    {
      'id': 'femme',
      'name': 'Femme',
      'icon': Icons.female,
      'color': const Color(0xFFDC143C)
    },
    {
      'id': 'homme',
      'name': 'Homme',
      'icon': Icons.male,
      'color': const Color(0xFF4B0082)
    },
    {
      'id': 'enfant',
      'name': 'Enfant',
      'icon': Icons.child_friendly,
      'color': const Color(0xFF8FBC8F)
    },
  ];

  // Styles de visualisation
  final List<Map<String, dynamic>> _imageStyles = [
    {
      "key": "flat_lay",
      "name": "Flat Lay",
      "icon": Icons.photo_camera,
      "color": const Color(0xFFA0522D),
      "description": "Vue aérienne traditionnelle"
    },
    {
      "key": "model",
      "name": "Modèle",
      "icon": Icons.person,
      "color": const Color(0xFFDC143C),
      "description": "Porté avec élégance"
    },
    {
      "key": "boutique",
      "name": "Boutique",
      "icon": Icons.store,
      "color": const Color(0xFF8FBC8F),
      "description": "Présentation marchande"
    },
    {
      "key": "lifestyle",
      "name": "Lifestyle",
      "icon": Icons.photo_filter,
      "color": const Color(0xFFFFB347),
      "description": "Contexte burkinabé"
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _generateColorHarmony();
    _loadCulturalAdvice();
  }

  void _handleTabSelection() {
    setState(() {
      _currentPageIndex = _tabController.index;
    });
  }

  void _generateColorHarmony() {
    final season = _seasons.firstWhere((s) => s['id'] == _selectedSeason);
    final occasion = _occasions.firstWhere((o) => o['id'] == _selectedOccasion);

    final colors = occasion['colors'] ?? season['colors'];

    _colorHarmony = (colors as List<String>).map((colorName) {
      return {
        'name': colorName,
        'color': _burkinabeColors[colorName] ?? _getFallbackColor(colorName),
        'meaning': _getColorMeaning(colorName),
      };
    }).toList();
  }

  Color _getFallbackColor(String colorName) {
    switch(colorName) {
      case 'Noir': return Colors.black;
      case 'Rose Pâle': return const Color(0xFFFFD1DC);
      default: return const Color(0xFF8B4513);
    }
  }

  String _getColorMeaning(String colorName) {
    switch (colorName) {
      case 'Terre de Sienne': return 'Stabilité et ancrage à la terre';
      case 'Ocre Rouge': return 'Énergie et vitalité africaine';
      case 'Jaune Sahel': return 'Lumière et prospérité';
      case 'Vert Karité': return 'Richesse naturelle du Burkina';
      case 'Rouge Traditionnel': return 'Force et courage ancestral';
      case 'Indigo Mossi': return 'Noblesse et spiritualité';
      case 'Blanc Coton': return 'Pureté et simplicité';
      case 'Brun Baobab': return 'Sagesse et longévité';
      case 'Bleu Touareg': return 'Protection et spiritualité';
      case 'Or Savannah': return 'Prestige et réussite';
      case 'Mauve Désert': return 'Créativité et originalité';
      case 'Vert Nil': return 'Renouveau et croissance';
      case 'Noir': return 'Respect et sobriété (funérailles)';
      case 'Rose Pâle': return 'Innocence et pureté (baptême)';
      default: return 'Couleur traditionnelle burkinabé';
    }
  }

  void _loadCulturalAdvice() {
    _culturalAdvice = [
      {
        'title': 'Respect des Traditions',
        'content': 'Le Faso Dan Fani est le tissu national du Burkina Faso, symbole de notre identité culturelle.',
        'icon': '🇧🇫',
      },
      {
        'title': 'Harmonie des Couleurs',
        'content': 'Les couleurs chaudes reflètent notre climat et notre terre généreuse.',
        'icon': '🎨',
      },
      {
        'title': 'Occasions Spéciales',
        'content': 'Chaque événement a ses codes vestimentaires dans la tradition burkinabé.',
        'icon': '🎭',
      },
      {
        'title': 'Accessoires Authentiques',
        'content': 'Les bijoux en bronze et les perles ajoutent une touche authentique.',
        'icon': '💎',
      },
      {
        'title': 'Funérailles',
        'content': 'Privilégiez les couleurs sobres comme le noir, brun ou blanc selon la région.',
        'icon': '⚰️',
      },
      {
        'title': 'Baptêmes',
        'content': 'Le blanc symbolise la pureté, accompagné de touches dorées ou bleues.',
        'icon': '👶',
      },
      {
        'title': 'Cérémonie de Dot',
        'content': 'Le rouge et l\'or dominent, symbolisant l\'amour et la prospérité.',
        'icon': '💍',
      },
    ];
  }

  void _generateBudgetEstimate() {
    final occasion = _occasions.firstWhere((o) => o['id'] == _selectedOccasion);
    final budgetRange = occasion['budgetRange'] as List<int>;
    final random = math.Random();

    final budget = budgetRange[0] + random.nextInt(budgetRange[1] - budgetRange[0]);

    _budgetEstimate = [
      {
        'item': 'Tissu principal',
        'price': (budget * 0.4).round(),
        'details': 'Faso Dan Fani ou Wax de qualité'
      },
      {
        'item': 'Tissu secondaire',
        'price': (budget * 0.2).round(),
        'details': 'Bogolan ou Batik pour accessoires'
      },
      {
        'item': 'Couture',
        'price': (budget * 0.25).round(),
        'details': 'Main d\'œuvre artisanale'
      },
      {
        'item': 'Accessoires',
        'price': (budget * 0.15).round(),
        'details': 'Bijoux, ceinture, chaussures'
      },
      {
        'item': 'TOTAL',
        'price': budget,
        'details': 'Fourchette: ${budgetRange[0]} - ${budgetRange[1]} FCFA'
      },
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<String?> generateOutfitDescription() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return "❌ Clé API Gemini manquante. Veuillez configurer votre fichier .env";
    }

    final selectedSeasonData = _seasons.firstWhere((s) => s['id'] == _selectedSeason);
    final selectedOccasionData = _occasions.firstWhere((o) => o['id'] == _selectedOccasion);
    final selectedGenderData = _genders.firstWhere((g) => g['id'] == _selectedGender);

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

    _generateBudgetEstimate();

    final prompt = """
Tu es Iris , styliste burkinabé pétillante et passionnée, reconnue internationalement pour ton charisme et ton talent exceptionnel ! Avec 15 ans d'expérience, tu rayonnes de joie et d'expertise. Tu es cette amie bienveillante qui transforme chaque consultation en moment magique, alliant tradition burkinabé et modernité avec un sourire contagieux et une énergie positive débordante.

🌟✨ BIENVENUE DANS TON UNIVERS STYLE PERSONNALISÉ ! ✨🌟

💫 TON PROFIL UNIQUE
• Genre : ${selectedGenderData['name']} 
• Qui tu es : "${_controller.text.trim()}"
• Ce qui te rend spécial(e) : [À découvrir dans ta description]

🌺 TON MOMENT SPÉCIAL
• Occasion magique : ${selectedOccasionData['name']} 
• Pourquoi c'est important : ${selectedOccasionData['description']}
• Saison parfaite : ${selectedSeasonData['name']} (${selectedSeasonData['description']})
• Tissus de rêve disponibles : ${selectedSeasonData['fabrics'].join(', ')}

💰 TON BUDGET INTELLIGENT
• Pour les plus beaux tissus : ${_budgetEstimate[0]['price']} FCFA
• Pour une couture parfaite : ${_budgetEstimate[2]['price']} FCFA  
• Pour des accessoires sublimes : ${_budgetEstimate[3]['price']} FCFA
• TON BUDGET TOTAL : ${_budgetEstimate[4]['price']} FCFA
• Gamme idéale pour l'occasion : ${selectedOccasionData['budgetRange'][0]} - ${selectedOccasionData['budgetRange'][1]} FCFA

🎨 TA PALETTE MAGIQUE
• Tes couleurs harmonieuses : ${_colorHarmony.map((c) => c['name']).join(', ')}
• [Chaque couleur raconte ton histoire !]

═══════════════════════════════════════════════════════════════════════════════════════════
                                  STRUCTURE DE CONSULTATION EXPERTE
═══════════════════════════════════════════════════════════════════════════════════════════

🌍✨ PLONGEONS DANS LA RICHESSE CULTURELLE ! ✨🌍

### 🌟 La magie de "${selectedOccasionData['name']}" dans notre beau Burkina
• Pourquoi cette occasion fait battre nos cœurs (traditions Mossi, Bobo, Gourmantché, Peul)
• Les secrets familiaux et sociaux qui rendent tout spécial
• Comment briller selon ton âge et ton statut avec élégance

### 💖 Spécialement pour toi, ${selectedGenderData['name']} extraordinaire
• Ce qu'on attend de toi avec fierté et respect
• Les nouvelles tendances que tu peux adopter sans crainte
• Les petites différences charmantes entre Ouaga, Bobo et nos provinces

## 👗💫 CRÉONS TON LOOK DE RÊVE ENSEMBLE ! 💫👗

### ✨ TA PIÈCE STAR (Pensée spécialement pour ${selectedGenderData['name']})
• Le modèle qui te fera briller : [Boubou de princesse, Grand Boubou royal, Complet élégant, Dashiki moderne, Robe enchanteresse]
• La coupe qui t'avantage : [Ajustée comme un gant, ample et gracieuse, droite et chic, évasée et dansante]
• La longueur parfaite : [Aux chevilles comme une déesse, mi-mollet raffinée, au genou moderne]
• Les détails qui font la différence : [Broderies dorées, empiècements précieux, boutons nacrés, fermetures invisibles]

### 🌺 TON ENSEMBLE HARMONIEUX
• Ton bas coordonné parfait : [Pagne assorti comme une reine, pantalon traditionnel confortable, jupe qui danse]
• Style qui te va comme un charme : [Taille haute flatteuse, plissé romantique, droit et moderne, évasé et léger]
• L'harmonie parfaite : [Motifs qui se parlent, couleurs qui s'aiment, proportions équilibrées]

### 🌤️ TON ATOUT SAISON
• Ta pièce secrète : [Veste sophistiquée, châle mystérieux, boléro coquet, gilet tendance]
• Parfaite pour ${selectedSeasonData['name']} : [Légère comme une plume, idéale mi-saison, protection solaire stylée]
• Ton confort assuré : [Respirante et douce, protectrice et belle, confortable toute la journée]

## 🎨💝 TA PALETTE COULEUR PERSONNALISÉE ! 💝🎨

### 🌈 Tes couleurs qui te font rayonner
• Ta couleur vedette : [Analyse magique de ${_colorHarmony.map((c) => c['name']).join(', ')}]
• Ce qu'elle dit de toi dans notre culture : [Signification pleine de fierté]
• L'effet wow garanti : [Comment tu vas impressionner tout le monde]

### ✨ Tes couleurs complices
• Tes compagnes de couleur : [2-3 tons qui t'adorent]
• Les motifs qui te chantent : [Géométriques rythmés, floraux poétiques, symboliques puissants]
• Parfaites pour ta beauté africaine : [Mise en valeur de ta splendeur naturelle]

## 🧵💖 SÉLECTION DE TISSUS AVEC AMOUR ! 💖🧵

### 🌟 Ton tissu coup de cœur
• Le tissu de tes rêves : [Faso Dan Fani prestigieux, Bogolan authentique, Wax vibrant, Batik artistique, Indigo mystérieux]
• Qualité divine : [Épaisseur câline, texture sensuelle, tombé parfait]
• D'où vient cette merveille : [Ouagadougou artisanal, Bobo traditionnel, Koudougou authentique, import de qualité]
• Combien il te faut : [Métrage précis pour ta tenue de rêve]

### 🎨 L'art de la création
• Comment c'est fait avec passion : [Indigo naturel magique, terre de barre ancestrale, teintures modernes sublimes]
• Motifs qui racontent ton histoire : [Technique utilisée, signification touchante]
• Finitions qui font la différence : [Broderies précieuses, applications délicates, surpiqûres parfaites]

### 💎 Prendre soin de ton trésor
• Comment le chouchouter : [Lavage doux, machine avec amour, produits respectueux]
• Comment le conserver : [Repassage expert, rangement parfait, protection optimale]
• Combien de temps il te rendra belle : [Avec tes soins attentionnés]

## 💎🌺 ACCESSOIRES QUI FAIT BRILLER ! 🌺💎

### ✨ Tes bijoux magiques
• Matières précieuses : [Bronze noble, argent éclatant, perles mystérieuses, cauris sacrés, or royal]
• Tes must-have : [Colliers envoûtants, bracelets dansants, boucles d'oreilles scintillantes, anneaux enchanteurs]
• Ce qu'ils disent de toi : [Signification culturelle profonde de chaque trésor]
• Parfaits avec ta tenue : [Proportions divines, couleurs harmonieuses, style cohérent]

### 🌺 Ta coiffure de déesse
• Style qui te va à merveille : [Tresses artistiques, chignon royal, foulard élégant, turban majestueux]
• Technique traditionnelle : [Méthode ancestrale, temps de réalisation, secrets de coiffeuse]
• Accessoires cheveux : [Perles colorées, fils brillants, bijoux de tête enchanteurs]
• Parfait pour ton visage : [Adaptation à ta beauté unique]

### 👠 Tes pieds et tes trésors
• Chaussures de princesse : [Babouches royales, sandales artisanales, escarpins élégants]
• Sac de rêve : [Tissé avec art, cuir noble, vannerie précieuse, perlé magique]
• Couleurs qui s'aiment : [Coordination parfaite avec ta tenue]
• Confort et style : [Adaptation à l'occasion et au climat, beauté et bien-être]

## 🎯💫 MES SECRETS POUR TOI ! 💫🎯

### 🌟 Te mettre en valeur, ${selectedGenderData['name']} magnifique
• Comment sublimer tes atouts : [Selon ta belle description personnelle]
• Ajuster les proportions avec style : [Conseils coupe et style sur-mesure]
• Ton confort avant tout : [Liberté de mouvement, bien-être assuré]

### 💰 Ton budget optimisé (${_budgetEstimate[4]['price']} FCFA) avec intelligence
• Où investir en priorité : [Conseils avisés pour tes dépenses]
• Alternatives malines : [Options moins coûteuses mais sublimes]
• Investissements durables : [Pièces à privilégier pour longtemps]
• Négocier avec le sourire : [Secrets pour bien s'entendre avec les artisans]

### 🏪 Tes adresses secrètes à Ouaga/Bobo
• Mes marchés chouchous : [Rood Woko magique, Sankaryare authentique, Grand Marché vivant]
• Mes artisans de confiance : [Couturiers talentueux, bijoutiers passionnés, cordonniers artistes]
• Quand y aller : [Meilleurs moments, jours de marché animés]
• Mes astuces transport : [Conseils pratiques de grande sœur]

## 📌💝 SECRETS DE COMPORTEMENT BURKINABÉ ! 💝📌

### 🌟 Comment rayonner à "${selectedOccasionData['name']}"
• Ton maintien de reine : [Élégance naturelle, dignité joyeuse, tradition vivante]
• Saluer avec grâce : [Selon l'âge, le statut, l'ethnie - mes petits secrets]
• Interactions sociales réussies : [Codes de politesse, respect mutuel]

### ⚠️ Ce qu'il faut éviter (mes conseils de grande sœur)
• Couleurs à éviter : [Selon l'occasion et le statut - je t'explique pourquoi]
• Styles qui ne conviennent pas : [Longueurs, coupes, motifs - sans jugement]
• Accessoires déconseillés : [Bijoux, coiffures, parfums - avec bienveillance]

### ✨ Ce que tes accessoires racontent
• Signification culturelle : [Chaque élément choisi avec amour]
• Messages que tu transmets : [Statut social, valeurs, appartenance - avec fierté]
• Respect joyeux des traditions : [Codes ancestraux honorés avec bonheur]

## 🌟💖 ADAPTATION SELON TON PROFIL ! 💖🌟

### 🎭 Selon ton âge avec style
• Jeunes cœurs : [Touches modernes acceptées avec enthousiasme]
• Adultes épanouis : [Équilibre parfait tradition/modernité]
• Sages respectés : [Respect chaleureux des codes traditionnels]

### 👑 Selon ton statut social avec élégance
• Étudiants/jeunes actifs : [Simplicité élégante et moderne]
• Professionnels établis : [Raffinement discret et sûr]
• Notables/autorités : [Prestige et tradition avec panache]

🌟✨ CRÉONS ENSEMBLE TA TRANSFORMATION MAGIQUE ! ✨🌟

## STYLE DE RÉPONSE MAGIQUE EXIGÉ ✨
• Ton de grande sœur bienveillante et experte, pleine de joie burkinabé authentique
• Utilise des expressions affectueuses ("ma chérie", "mon frère", "ma belle")
• Ponctue avec enthousiasme et émojis pour créer une connexion chaleureuse
• Raconte des petites anecdotes culturelles qui font sourire
• Donne des conseils comme des secrets d'amie proche
• Célèbre chaque choix avec fierté et encouragement

## PRÉSENTATION ENJOUÉE ET CAPTIVANTE 🌟
• Paragraphes courts et pétillants, faciles à lire
• Listes à puces colorées avec des détails croustillants
• Propose des alternatives avec enthousiasme ("Tu pourrais aussi...")
• Détails techniques expliqués avec simplicité et passion
• Termine par un message personnel chaleureux de Chantal avec une invitation amicale

## QUALITÉ CŒUR ET EXPERTISE 💖
• Consultation digne d'une styliste internationale ET d'une amie précieuse
• Respect joyeux et fier des codes culturels burkinabé
• Conseils pratiques donnés avec générosité et bienveillance
• Originalité moderne présentée avec confiance et sourire
• Expertise technique partagée avec simplicité et passion

CRÉÉ UNE CONSULTATION EXCEPTIONNELLE QUI DONNE ENVIE DE DANSER ET DE RAYONNER ! 
Que chaque mot transmette ta passion contagieuse pour la beauté africaine et ton amour sincère pour tes client(e)s ! 💫🌺
""";

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "contents": [
            {
              "parts": [{"text": prompt}]
            }
          ],
          "generationConfig": {
            "temperature": 0.85,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 2500,
          }
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['candidates'] != null &&
            decodedResponse['candidates'].isNotEmpty) {
          return decodedResponse['candidates'][0]['content']['parts'][0]['text'];
        }
      } else if (response.statusCode == 503) {
        await Future.delayed(const Duration(seconds: 3));
        return await _retryGenerateOutfitDescription();
      } else {
        print("Erreur API Gemini: ${response.statusCode} - ${response.body}");
        return "❌ Service temporairement indisponible. Veuillez réessayer.";
      }
    } on TimeoutException {
      return "❌ Temps d'attente dépassé. Veuillez réessayer.";
    } catch (e) {
      print("Erreur Gemini: $e");
      return "❌ Erreur de connexion: $e";
    }
    return null;
  }

  Future<String?> _retryGenerateOutfitDescription() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return "❌ Clé API manquante";

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "contents": [
            {
              "parts": [{"text": "Génère une description de tenue burkinabé pour ${_controller.text} (${_selectedGender}) pour ${_selectedOccasion} pendant ${_selectedSeason}"}]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "topK": 30,
            "topP": 0.9,
            "maxOutputTokens": 1200,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['candidates'] != null &&
            decodedResponse['candidates'].isNotEmpty) {
          return decodedResponse['candidates'][0]['content']['parts'][0]['text'];
        }
      }
    } catch (e) {
      print("Erreur retry Gemini: $e");
    }
    return null;
  }

  Future<Uint8List?> generateOutfitImage() async {
    final apiKey = dotenv.env['STABILITY_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print("Clé API Stability AI manquante");
      return null;
    }

    final selectedSeasonData = _seasons.firstWhere((s) => s['id'] == _selectedSeason);
    final selectedOccasionData = _occasions.firstWhere((o) => o['id'] == _selectedOccasion);
    final selectedGenderData = _genders.firstWhere((g) => g['id'] == _selectedGender);

    final imagePrompt = """
Traditional Burkinabe ${selectedGenderData['name']} outfit for ${selectedOccasionData['name']} 
Season: ${selectedSeasonData['name']} (${selectedSeasonData['description']})
Colors: ${_colorHarmony.map((c) => c['name']).join(', ')}
Style: ${_imageStyles.firstWhere((s) => s['key'] == _imageStyle)['name']}
Details: ${_controller.text.isEmpty ? 'Elegant traditional design' : _controller.text}
High quality, photorealistic, cultural authenticity
""";

    print("Prompt image: $imagePrompt");

    try {
      final response = await http.post(
        Uri.parse('https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          "text_prompts": [
            {
              "text": imagePrompt,
              "weight": 1.0
            },
            {
              "text": "blurry, low quality, distorted, ugly, bad anatomy, extra limbs, watermark, signature, text, logo, brand names, nsfw, inappropriate, western clothing, modern fashion, monochrome, single color dominance, oversaturated green, neon colors",
              "weight": -1.0
            }
          ],
          "cfg_scale": 9,
          "height": 1024,
          "width": 1024,
          "samples": 1,
          "steps": 40,
          "style_preset": "photographic"
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        final images = decodedResponse['artifacts'];

        if (images != null && images.isNotEmpty) {
          final base64Image = images[0]['base64'];
          return base64Decode(base64Image);
        }
      } else {
        print("""
🛑 Erreur Stability AI [${response.statusCode}]
Corps: ${response.body}
Prompt: $imagePrompt
""");
      }
    } on TimeoutException {
      print("Timeout génération image");
    } catch (e) {
      print("Erreur génération image: $e");
    }
    return null;
  }

  Future<void> generateOutfit() async {
    if (_controller.text.trim().isEmpty) {
      _showSnackBar('Décrivez votre besoin vestimentaire', const Color(0xFFFFB347));
      return;
    }

    setState(() {
      _isLoading = true;
      _isGeneratingImage = true;
      _isGeneratingText = true;
      _generatedOutfit = "";
      _imageData = null;
    });

    try {
      _fadeController.reset();

      // Génération description
      final description = await generateOutfitDescription();
      if (description != null && description.isNotEmpty) {
        setState(() {
          _generatedOutfit = description;
          _isGeneratingText = false;
        });
        _fadeController.forward();
      } else {
        setState(() {
          _generatedOutfit = "❌ Impossible de générer la description";
          _isGeneratingText = false;
        });
      }

      // Génération image en parallèle
      final imageData = await generateOutfitImage();
      setState(() {
        _imageData = imageData;
        _isGeneratingImage = false;
      });

    } catch (e) {
      setState(() {
        _generatedOutfit = "❌ Erreur: $e";
        _isGeneratingText = false;
        _isGeneratingImage = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white
            )
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iris, Ta styliste'),
        centerTitle: true,
        elevation: 6,
        shadowColor: const Color(0xFF8B4513).withOpacity(0.6),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber[200],
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined), text: 'Accueil'),
            Tab(icon: Icon(Icons.palette_outlined), text: 'Couleurs'),
            Tab(icon: Icon(Icons.school_outlined), text: 'Culture'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMainScreen(),
          _buildColorHarmonyScreen(),
          _buildCulturalAdviceScreen(),
        ],
      ),
    );
  }

  Widget _buildMainScreen() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 24),
                _buildGenderSelector(),
                const SizedBox(height: 24),
                _buildContextSelectors(),
                const SizedBox(height: 24),
                _buildInputSection(),
              ],
            ),
          ),
        ),
        if (_generatedOutfit.isNotEmpty || _isGeneratingText)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDescriptionSection(),
            ),
          ),
        if (_imageData != null || _isGeneratingImage)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: _buildImageSection(),
            ),
          ),
        if (_budgetEstimate.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: _buildBudgetSection(),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 8,
      shadowColor: const Color(0xFF8B4513).withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
          ),
          border: Border.all(
            color: const Color(0xFFE8DACF),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B4513), Color(0xFFD2691E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B4513).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural,
                        color: Color(0xFF8B4513),
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF8B4513).withOpacity(0.1),
                                const Color(0xFFD2691E).withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF8B4513).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Iris',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'PlayfairDisplay',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B4513),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.favorite, color: Color(0xFF8B4513), size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF5D4037),
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'Akwaba ! ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B4513),
                                ),
                              ),
                              TextSpan(
                                text: 'Je suis ta styliste personnelle. Dis-moi ce que tu recherches et je te proposerai des ',
                              ),
                              TextSpan(
                                text: 'styles authentiquement burkinabé',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFD2691E),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              TextSpan(text: ' ! ✨'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildExpertiseBadge('15 ans d\'expérience', Icons.star, const Color(0xFF8B4513)),
                  _buildExpertiseBadge('Mode traditionnelle', Icons.style, const Color(0xFFD2691E)),
                  _buildExpertiseBadge('Conseils sur mesure', Icons.person, const Color(0xFFA0522D)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpertiseBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Pour qui ?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _genders.length,
            itemBuilder: (context, index) {
              final gender = _genders[index];
              final isSelected = _selectedGender == gender['id'];

              return Container(
                width: 110,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = gender['id'];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [
                          (gender['color'] as Color).withOpacity(0.9),
                          (gender['color'] as Color).withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? (gender['color'] as Color) : const Color(0xFFE8DACF),
                        width: isSelected ? 2 : 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: (gender['color'] as Color).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          gender['icon'],
                          color: isSelected ? Colors.white : gender['color'],
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          gender['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContextSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Contexte',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Sélection de la saison
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Saison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: _seasons.length,
            itemBuilder: (context, index) {
              final season = _seasons[index];
              final isSelected = _selectedSeason == season['id'];

              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSeason = season['id'];
                      _generateColorHarmony();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [
                          const Color(0xFF8B4513).withOpacity(0.9),
                          const Color(0xFFD2691E).withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF8B4513) : const Color(0xFFE8DACF),
                        width: isSelected ? 2 : 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: const Color(0xFF8B4513).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            season['icon'],
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              season['name'],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF5D4037),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              season['description'],
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF7E6B5C),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Sélection de l'occasion
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Occasion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _occasions.length,
            itemBuilder: (context, index) {
              final occasion = _occasions[index];
              final isSelected = _selectedOccasion == occasion['id'];

              return Container(
                width: 130,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOccasion = occasion['id'];
                      _generateColorHarmony();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [
                          const Color(0xFFDC143C).withOpacity(0.9),
                          const Color(0xFFFF6347).withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFDC143C) : const Color(0xFFE8DACF),
                        width: isSelected ? 2 : 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: const Color(0xFFDC143C).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            occasion['icon'],
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            occasion['name'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF5D4037),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Votre demande',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ex: Je veux une tenue élégante pour un mariage traditionnel...',
              hintStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(18),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF5D4037),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Style de visualisation
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Style de visualisation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imageStyles.length,
            itemBuilder: (context, index) {
              final style = _imageStyles[index];
              final isSelected = _imageStyle == style['key'];

              return Container(
                width: 130,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _imageStyle = style['key'];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [
                          (style['color'] as Color).withOpacity(0.9),
                          (style['color'] as Color).withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? style['color'] : const Color(0xFFE8DACF),
                        width: isSelected ? 2 : 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: (style['color'] as Color).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          style['icon'],
                          color: isSelected ? Colors.white : style['color'],
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          style['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : style['color'],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Bouton de génération
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : generateOutfit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 8,
              shadowColor: const Color(0xFF8B4513).withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Iris réfléchit...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 28),
                SizedBox(width: 12),
                Text(
                  'Consulter Iris',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 12,
        shadowColor: const Color(0xFF8B4513).withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Consultation de Iris',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'PlayfairDisplay',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ),
                    if (_isGeneratingText)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE8DACF),
                      width: 1.5,
                    ),
                  ),
                  child: _isGeneratingText
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Iris analyse votre demande...',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ],
                    ),
                  )
                      : SelectableText(
                    _generatedOutfit,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5D4037),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 12,
      shadowColor: const Color(0xFF8B4513).withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC143C),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.photo_camera,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Visualisation',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                  ),
                  if (_isGeneratingImage)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC143C)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE8DACF),
                    width: 1.5,
                  ),
                ),
                child: _isGeneratingImage
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Création de votre visualisation...',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                )
                    : _imageData != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    _imageData!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 320,
                  ),
                )
                    : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Visualisation non disponible',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetSection() {
    return Card(
      elevation: 12,
      shadowColor: const Color(0xFF8B4513).withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B0082),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.attach_money,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Estimation Budget',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ..._budgetEstimate.map((item) {
                final isTotal = item['item'] == 'TOTAL';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['item'],
                          style: TextStyle(
                            fontSize: isTotal ? 18 : 16,
                            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                            color: isTotal ? const Color(0xFF8B4513) : const Color(0xFF5D4037),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${item['price']} FCFA',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: isTotal ? 18 : 16,
                            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                            color: isTotal ? const Color(0xFF8B4513) : const Color(0xFF5D4037),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              const Text(
                'Note: Ces prix sont indicatifs et peuvent varier selon les artisans et la qualité des matériaux.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF7E6B5C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorHarmonyScreen() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Harmonie des Couleurs',
                  style: TextStyle(
                    fontSize: 26,
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sélection adaptée à la saison et à l\'occasion',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildColorCard(_colorHarmony[index]),
              childCount: _colorHarmony.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildColorCombinationTips(),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Widget _buildColorCard(Map<String, dynamic> colorData) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: colorData['color'],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorData['color'].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      colorData['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      colorData['meaning'],
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF5D4037),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorCombinationTips() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5EDE0), Color(0xFFF0E6D6)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF8B4513),
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Conseils d\'harmonie',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '• Associez les couleurs chaudes pour refléter notre climat\n'
                    '• Utilisez les couleurs neutres comme base\n'
                    '• Ajoutez des touches de couleurs vives avec parcimonie\n'
                    '• Respectez les symboliques culturelles des couleurs\n'
                    '• Adaptez l\'intensité selon l\'occasion',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5D4037),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCulturalAdviceScreen() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conseils Culturels',
                  style: TextStyle(
                    fontSize: 26,
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sagesse traditionnelle et codes vestimentaires',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildAdviceCard(_culturalAdvice[index]),
              childCount: _culturalAdvice.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTissuGuide(),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Widget _buildAdviceCard(Map<String, dynamic> advice) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC143C),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      advice['icon'],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      advice['title'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                advice['content'],
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5D4037),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTissuGuide() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5EDE0), Color(0xFFF0E6D6)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.texture,
                    color: Color(0xFF8B4513),
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Guide des tissus traditionnels',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '🇧🇫 Faso Dan Fani : Tissu national tissé à la main\n'
                    '🎨 Bogolan : Tissu de boue traditionnel malien\n'
                    '🌺 Wax : Tissu imprimé aux motifs africains\n'
                    '🎭 Batik : Technique de teinture traditionnelle\n'
                    '🏺 Indigo : Teinture naturelle ancestrale',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5D4037),
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}