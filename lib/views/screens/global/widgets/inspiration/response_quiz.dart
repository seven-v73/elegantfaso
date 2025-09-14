import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'style_quiz.dart';

class QuizResultsScreen extends StatefulWidget {
  final Map<String, int> userProfile;
  final List<Map<String, dynamic>> userAnswers; // Nouvelles réponses détaillées

  const QuizResultsScreen({
    super.key,
    required this.userProfile,
    required this.userAnswers,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _progressController;
  late AnimationController _cardController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  Map<String, dynamic>? _aiStyleProfile;
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _performAIAnalysis();
  }

  void _initAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _progressController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _performAIAnalysis() async {
    // Simulation d'analyse IA avancée
    await Future.delayed(const Duration(milliseconds: 2500));

    // Extraire les indices de réponses de la liste complète
    List<int> answerIndexes = widget.userAnswers
        .map((answer) => answer['selectedOption'] as int)
        .toList();

    // Générer le profil avec les indices extraits
    final aiProfile = _generateAIStyleProfile(widget.userProfile, answerIndexes);

    setState(() {
      _aiStyleProfile = aiProfile;
      _isAnalyzing = false;
    });

    _mainController.forward();
    _progressController.forward();
    _cardController.forward();

    HapticFeedback.mediumImpact();
  }

  Map<String, dynamic> _generateAIStyleProfile(Map<String, int> profile, List<int> answers) {
    // Analyse IA sophistiquée des patterns de réponses
    final analysisResult = _performDeepPatternAnalysis(profile, answers);

    // Calcul du score de compatibilité basé sur la cohérence des réponses
    int compatibilityScore = _calculateCompatibilityScore(profile, answers);

    // Génération du profil personnalisé
    return _createPersonalizedProfile(analysisResult, compatibilityScore, answers);
  }

  Map<String, dynamic> _performDeepPatternAnalysis(Map<String, int> profile, List<int> answers) {
    // Analyse des patterns spécifiques selon les combinaisons de réponses

    // Pattern 1: Cohérence traditionnelle
    bool isTraditionallyConsistent = _analyzeTraditionalConsistency(answers);

    // Pattern 2: Innovation moderne
    bool isModernInnovator = _analyzeModernInnovation(answers);

    // Pattern 3: Equilibre harmonieux
    bool isBalancedHarmonious = _analyzeHarmoniousBalance(answers);

    // Pattern 4: Créativité audacieuse
    bool isCreativelyBold = _analyzeCreativeBoldness(answers);

    // Pattern 5: Pragmatisme élégant
    bool isPragmaticallyElegant = _analyzePragmaticElegance(answers);

    return {
      'traditionalConsistent': isTraditionallyConsistent,
      'modernInnovator': isModernInnovator,
      'balancedHarmonious': isBalancedHarmonious,
      'creativelyBold': isCreativelyBold,
      'pragmaticallyElegant': isPragmaticallyElegant,
      'dominantTraits': _identifyDominantTraits(profile),
      'uniqueCombination': _getUniqueCombination(answers),
    };
  }

  bool _analyzeTraditionalConsistency(List<int> answers) {
    // Vérifie si les réponses montrent une préférence cohérente pour le traditionnel
    return (answers[0] == 0 || answers[0] == 3) && // Cérémonies traditionnelles/religieuses
        (answers[1] == 1) && // Tons terreux
        (answers[2] == 1) && // Fidèle aux traditions
        (answers[3] == 0) && // Bogolan traditionnel
        (answers[4] == 0);   // Bijoux traditionnels
  }

  bool _analyzeModernInnovation(List<int> answers) {
    // Détecte l'innovation moderne pure
    return (answers[0] == 1) && // Réunions professionnelles
        (answers[1] == 3) && // Couleurs monochromes
        (answers[2] == 2) && // Tendances contemporaines
        (answers[3] == 3) && // Tissus modernes
        (answers[4] == 1);   // Accessoires modernes
  }

  bool _analyzeHarmoniousBalance(List<int> answers) {
    // Identifie l'équilibre entre traditionnel et moderne
    return (answers[2] == 0) || // Mélange traditionnel-moderne
        (_calculateStyleVariance(answers) < 2.0); // Faible variance = équilibre
  }

  bool _analyzeCreativeBoldness(List<int> answers) {
    // Détecte la créativité et l'audace
    return (answers[1] == 0) && // Couleurs vives
        (answers[4] == 1 || answers[4] == 0) && // Accessoires expressifs
        (_hasCreativePatterns(answers));
  }

  bool _analyzePragmaticElegance(List<int> answers) {
    // Identifie le pragmatisme élégant
    return (answers[0] == 2) && // Sorties décontractées
        (answers[3] == 1) && // Coton confortable
        (answers[4] == 2 || answers[4] == 3); // Simplicité élégante
  }

  double _calculateStyleVariance(List<int> answers) {
    // Calcule la variance pour mesurer la cohérence
    double mean = answers.reduce((a, b) => a + b) / answers.length;
    double variance = answers.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / answers.length;
    return variance;
  }

  bool _hasCreativePatterns(List<int> answers) {
    // Logique pour détecter les patterns créatifs
    Set<int> uniqueAnswers = answers.toSet();
    return uniqueAnswers.length >= 3; // Diversité dans les choix
  }

  List<String> _identifyDominantTraits(Map<String, int> profile) {
    return profile.entries
        .where((entry) => entry.value >= 6)
        .map((entry) => entry.key)
        .toList();
  }

  String _getUniqueCombination(List<int> answers) {
    // Génère un code unique basé sur la combinaison de réponses
    return answers.join('-');
  }

  int _calculateCompatibilityScore(Map<String, int> profile, List<int> answers) {
    int baseScore = profile.values.reduce((a, b) => a + b);
    int cohesionBonus = _calculateCohesionBonus(answers);
    int uniquenessBonus = _calculateUniquenessBonus(answers);

    return ((baseScore + cohesionBonus + uniquenessBonus) / 35 * 100).clamp(70, 98).round();
  }

  int _calculateCohesionBonus(List<int> answers) {
    // Bonus pour la cohérence des réponses
    double variance = _calculateStyleVariance(answers);
    return variance < 1.0 ? 5 : (variance < 2.0 ? 3 : 0);
  }

  int _calculateUniquenessBonus(List<int> answers) {
    // Bonus pour l'originalité
    Set<int> unique = answers.toSet();
    return unique.length >= 4 ? 3 : (unique.length >= 3 ? 2 : 1);
  }

  Map<String, dynamic> _createPersonalizedProfile(Map<String, dynamic> analysis, int score, List<int> answers) {
    String profileKey = _determineUniqueProfileKey(analysis, answers);

    final profiles = {
      'traditional_pure': {
        'name': 'Gardien des Traditions Authentiques',
        'emoji': '👑',
        'gradient': [const Color(0xFF8B4513), const Color(0xFFCD853F)],
        'description': 'Vous êtes un véritable ambassadeur de l\'héritage culturel burkinabé. Votre style reflète un profond respect pour les traditions ancestrales tout en affirmant votre identité avec fierté et élégance.',
        'personality': 'Vous privilégiez l\'authenticité et la signification culturelle dans chaque choix vestimentaire. Votre présence inspire le respect et rappelle l\'importance de préserver nos racines.',
        'strengths': [
          'Maîtrise parfaite des codes vestimentaires traditionnels burkinabé',
          'Capacité naturelle à transmettre les valeurs culturelles par le style',
          'Présence majestueuse lors des cérémonies importantes',
          'Connaissance approfondie des symboliques des tissus et motifs',
          'Leadership culturel qui inspire les jeunes générations',
        ],
        'personalizedAdvice': [
          'Investissez dans des pièces de Faso Dan Fani tissées par des artisans locaux reconnus',
          'Créez une collection de bijoux traditionnels en or pour différentes occasions',
          'Apprenez l\'histoire derrière chaque motif que vous portez pour enrichir votre discours',
          'Devenez mentor pour transmettre l\'art du style traditionnel aux plus jeunes',
          'Organisez des événements culturels pour célébrer la mode traditionnelle',
        ],
        'wardrobe': _generateTraditionalWardrobe(),
        'occasions': ['Mariages traditionnels', 'Cérémonies coutumières', 'Fêtes nationales'],
        'colorPalette': ['Ocre', 'Brun royal', 'Rouge traditionnel', 'Blanc pur', 'Or authentique'],
      },

      'modern_innovator': {
        'name': 'Innovateur du Style Contemporain',
        'emoji': '🚀',
        'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
        'description': 'Vous êtes à l\'avant-garde de la mode burkinabé moderne. Votre vision novatrice transforme les codes traditionnels en créations contemporaines audacieuses qui définissent les tendances de demain.',
        'personality': 'Visionnaire et créatif, vous n\'hésitez pas à repousser les limites tout en respectant l\'essence de votre culture. Votre style influence et inspire votre génération.',
        'strengths': [
          'Vision futuriste de la mode africaine contemporaine',
          'Maîtrise des tendances globales adaptées au contexte local',
          'Capacité d\'innovation dans l\'association des matières et formes',
          'Influence sur les réseaux sociaux et la mode urbaine',
          'Talent pour créer des looks photographiques et mémorables',
        ],
        'personalizedAdvice': [
          'Collaborez avec des designers burkinabé émergents pour créer des pièces uniques',
          'Expérimentez les techniques de customisation sur tissus traditionnels',
          'Intégrez des éléments tech-wear dans vos tenues ceremoniales',
          'Créez votre propre marque ou blog de mode afro-contemporaine',
          'Participez aux fashion weeks pour représenter le Burkina Faso',
        ],
        'wardrobe': _generateModernWardrobe(),
        'occasions': ['Événements professionnels', 'Galas modernes', 'Shootings photo'],
        'colorPalette': ['Noir sophistiqué', 'Blanc pur', 'Métalliques', 'Néons subtils', 'Monochromes'],
      },

      'harmonic_fusion': {
        'name': 'Maître de la Fusion Harmonieuse',
        'emoji': '🎭',
        'gradient': [const Color(0xFF6A4C93), const Color(0xFF8B5A83)],
        'description': 'Vous excellez dans l\'art délicat de fusionner tradition et modernité. Votre style unique crée des ponts entre les générations et inspire une nouvelle approche de la mode burkinabé.',
        'personality': 'Équilibré et diplomate, vous savez adapter votre style à chaque situation tout en conservant votre authenticité. Vous êtes un pont naturel entre les mondes.',
        'strengths': [
          'Talent exceptionnel pour marier ancien et moderne avec goût',
          'Adaptabilité remarquable selon les contextes sociaux',
          'Capacité à créer des looks uniques qui plaisent à tous',
          'Influence apaisante et rassembleuse par votre style',
          'Innovation respectueuse des traditions familiales',
        ],
        'personalizedAdvice': [
          'Créez une garde-robe modulaire avec des bases traditionnelles et des accents modernes',
          'Investissez dans des accessoires polyvalents qui transforment vos looks',
          'Maîtrisez l\'art du layering intelligent pour toutes les occasions',
          'Développez votre signature personnelle reconnaissable entre tradition et modernité',
          'Devenez consultant en style pour aider d\'autres à trouver leur équilibre',
        ],
        'wardrobe': _generateFusionWardrobe(),
        'occasions': ['Tous types d\'événements', 'Rencontres intergénérationnelles', 'Voyages d\'affaires'],
        'colorPalette': ['Terres chaudes', 'Bleus profonds', 'Roses poudrés', 'Verts olive', 'Dorés subtils'],
      },

      'creative_artist': {
        'name': 'Artiste Créatif Expressif',
        'emoji': '🎨',
        'gradient': [const Color(0xFFff9a9e), const Color(0xFFfecfef)],
        'description': 'Votre style est votre toile d\'expression artistique. Chaque tenue raconte une histoire et chaque combinaison révèle votre créativité débordante et votre joie de vivre contagieuse.',
        'personality': 'Spontané et expressif, vous utilisez la mode comme langage artistique. Votre audace chromatique et vos associations inattendues créent constamment la surprise et l\'admiration.',
        'strengths': [
          'Créativité illimitée dans les associations de couleurs et textures',
          'Capacité à transformer n\'importe quelle pièce en œuvre d\'art portable',
          'Influence inspirante sur la scène artistique locale',
          'Talent pour créer des looks photographiques spectaculaires',
          'Innovation constante qui redéfinit les codes esthétiques',
        ],
        'personalizedAdvice': [
          'Explorez les techniques artisanales : tie-dye, batik, broderie créative',
          'Créez vos propres imprimés en collaboration avec des artistes locaux',
          'Documentez vos créations pour constituer un portfolio artistique',
          'Organisez des défilés ou expositions mêlant mode et art contemporain',
          'Lancez des ateliers de customisation créative pour partager votre talent',
        ],
        'wardrobe': _generateCreativeWardrobe(),
        'occasions': ['Événements artistiques', 'Festivals culturels', 'Vernissages'],
        'colorPalette': ['Arc-en-ciel audacieux', 'Couleurs primaires', 'Pastels pop', 'Néons créatifs', 'Métalliques brillants'],
      },

      'elegant_pragmatist': {
        'name': 'Pragmatique Élégant du Quotidien',
        'emoji': '💎',
        'gradient': [const Color(0xFF11998e), const Color(0xFF38ef7d)],
        'description': 'Votre élégance réside dans la simplicité réfléchie et le confort intelligent. Vous prouvez qu\'on peut être authentiquement stylé dans la vie de tous les jours sans effort apparent.',
        'personality': 'Pratique et raffiné, vous privilégiez la qualité sur la quantité. Votre style effortless inspire ceux qui recherchent l\'élégance accessible et authentique.',
        'strengths': [
          'Maîtrise de l\'élégance décontractée et accessible',
          'Sens pratique qui optimise confort et style au quotidien',
          'Influence positive sur l\'estime de soi de votre entourage',
          'Capacité à rendre le style traditionnel portable et moderne',
          'Expertise dans la création de garde-robes durables et polyvalentes',
        ],
        'personalizedAdvice': [
          'Créez une garde-robe capsule avec des basiques de qualité supérieure',
          'Investissez dans des tissus naturels respirants adaptés au climat',
          'Développez votre collection d\'accessoires simples mais distinctifs',
          'Maîtrisez l\'art du styling minimal avec maximum d\'impact',
          'Partagez vos astuces de style pratique via des tutoriels accessibles',
        ],
        'wardrobe': _generatePragmaticWardrobe(),
        'occasions': ['Quotidien professionnel', 'Sorties familiales', 'Voyages'],
        'colorPalette': ['Neutres chauds', 'Bleus apaisants', 'Verts naturels', 'Beiges sophistiqués', 'Blancs purs'],
      },
    };

    return profiles[profileKey] ?? profiles['harmonic_fusion']!
      ..['score'] = score
      ..['uniqueInsights'] = _generateUniqueInsights(analysis, answers)
      ..['personalizedChallenges'] = _generatePersonalizedChallenges(analysis)
      ..['styleEvolution'] = _generateStyleEvolution(answers);
  }

  String _determineUniqueProfileKey(Map<String, dynamic> analysis, List<int> answers) {
    if (analysis['traditionalConsistent']) return 'traditional_pure';
    if (analysis['modernInnovator']) return 'modern_innovator';
    if (analysis['balancedHarmonious']) return 'harmonic_fusion';
    if (analysis['creativelyBold']) return 'creative_artist';
    if (analysis['pragmaticallyElegant']) return 'elegant_pragmatist';

    // Analyse fine basée sur les patterns de réponses
    if (answers[2] == 0) return 'harmonic_fusion'; // Aime mélanger
    if (answers[1] == 0 && answers[4] == 1) return 'creative_artist'; // Couleurs vives + accessoires modernes

    return 'harmonic_fusion'; // Défaut équilibré
  }

  List<Map<String, String>> _generateTraditionalWardrobe() {
    return [
      {'item': 'Grand Boubou en Faso Dan Fani', 'description': 'Pièce maîtresse pour les grandes occasions'},
      {'item': 'Collection de Pagnes Traditionnels', 'description': 'Variété de motifs selon les cérémonies'},
      {'item': 'Bijoux en Or Authentique', 'description': 'Parures traditionnelles de famille'},
      {'item': 'Chaussures en Cuir Local', 'description': 'Babouches et sandales artisanales'},
      {'item': 'Accessoires Symboliques', 'description': 'Coiffes, ceintures et amulettes traditionnelles'},
    ];
  }

  List<Map<String, String>> _generateModernWardrobe() {
    return [
      {'item': 'Blazer sur Mesure en Faso Dan Fani', 'description': 'Coupe moderne, tissu traditionnel'},
      {'item': 'Collection de Basics Premium', 'description': 'T-shirts, chemises en coton bio local'},
      {'item': 'Accessoires Tech-Chic', 'description': 'Montres connectées, sacs design'},
      {'item': 'Sneakers de Créateurs Africains', 'description': 'Chaussures contemporaines et éthiques'},
      {'item': 'Pièces Statement Uniques', 'description': 'Créations exclusives de designers locaux'},
    ];
  }

  List<Map<String, String>> _generateFusionWardrobe() {
    return [
      {'item': 'Robes Fusion Tradition-Moderne', 'description': 'Coupes actuelles en tissus ancestraux'},
      {'item': 'Vestes Adaptables', 'description': 'Pieces qui se transforment selon l\'occasion'},
      {'item': 'Accessoires Polyvalents', 'description': 'Bijoux modulables jour/soir'},
      {'item': 'Chaussures Multi-Occasions', 'description': 'Confort et élégance combinés'},
      {'item': 'Sacs Iconiques', 'description': 'Maroquinerie alliant savoir-faire et design'},
    ];
  }

  List<Map<String, String>> _generateCreativeWardrobe() {
    return [
      {'item': 'Pièces Customisées Personnelles', 'description': 'Créations uniques et artistiques'},
      {'item': 'Collection de Tissus Artistiques', 'description': 'Batik, tie-dye, impressions originales'},
      {'item': 'Accessoires Statement', 'description': 'Bijoux volumineux et expressifs'},
      {'item': 'Chaussures Artistiques', 'description': 'Painted shoes et créations colorées'},
      {'item': 'Props Créatifs', 'description': 'Éléments de mise en scène personnelle'},
    ];
  }

  List<Map<String, String>> _generatePragmaticWardrobe() {
    return [
      {'item': 'Basics de Qualité Supérieure', 'description': 'Essentiels durables et polyvalents'},
      {'item': 'Pièces Climat-Adaptées', 'description': 'Tissus respirants et confortables'},
      {'item': 'Accessoires Fonctionnels', 'description': 'Pratiques et élégants'},
      {'item': 'Chaussures Confort-Chic', 'description': 'Style sans compromis sur le confort'},
      {'item': 'Solutions Multi-Usages', 'description': 'Pièces transformables et pratiques'},
    ];
  }

  List<String> _generateUniqueInsights(Map<String, dynamic> analysis, List<int> answers) {
    List<String> insights = [];

    if (analysis['traditionalConsistent']) {
      insights.add("Votre cohérence traditionnelle révèle une personnalité stable et respectueuse des valeurs");
    }
    if (analysis['modernInnovator']) {
      insights.add("Votre vision moderne indique un leadership naturel dans les tendances");
    }
    if (analysis['balancedHarmonious']) {
      insights.add("Votre équilibre démontre une maturité émotionnelle et sociale remarquable");
    }

    // Insights basés sur des combinaisons spécifiques
    if (answers[0] == 1 && answers[3] == 2) {
      insights.add("Votre combinaison professionnel/soie révèle une ambition aristocratique naturelle");
    }

    return insights;
  }

  List<String> _generatePersonalizedChallenges(Map<String, dynamic> analysis) {
    List<String> challenges = [];

    if (analysis['traditionalConsistent']) {
      challenges.add("Défi : Intégrer subtilement un élément moderne dans une tenue traditionnelle");
    }
    if (analysis['modernInnovator']) {
      challenges.add("Défi : Créer un look moderne qui honore explicitement vos ancêtres");
    }

    challenges.add("Défi mensuel : Sortir de votre zone de confort avec une nouvelle combinaison");
    challenges.add("Défi créatif : Customiser une pièce basique pour la rendre unique");

    return challenges;
  }

  Map<String, String> _generateStyleEvolution(List<int> answers) {
    return {
      'current': 'Phase de découverte et d\'affirmation de votre identité stylistique',
      'next_6_months': 'Développement de votre signature personnelle reconnaissable',
      'next_year': 'Maîtrise complète de votre style et influence sur votre entourage',
      'long_term': 'Devenir une référence style dans votre communauté et au-delà',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return _buildAIAnalyzingScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildEnhancedSliverAppBar(),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildEnhancedProfileCard(),
                          const SizedBox(height: 24),
                          _buildPersonalityInsightsSection(),
                          const SizedBox(height: 24),
                          _buildStrengthsSection(),
                          const SizedBox(height: 24),
                          _buildPersonalizedAdviceSection(),
                          const SizedBox(height: 24),
                          _buildWardrobeRecommendationsSection(),
                          const SizedBox(height: 24),
                          _buildStyleEvolutionSection(),
                          const SizedBox(height: 24),
                          _buildPersonalizedChallengesSection(),
                          const SizedBox(height: 24),
                          _buildColorPaletteSection(),
                          const SizedBox(height: 32),
                          _buildEnhancedActionButtons(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalyzingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6A4C93).withOpacity(0.3),
                    const Color(0xFF8B5A83).withOpacity(0.3),
                  ],
                ),
              ),
              child: const Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A4C93)),
                      ),
                    ),
                    Text("🧠", style: TextStyle(fontSize: 32)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Analyse IA de votre profil en cours...",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Intelligence artificielle spécialisée en style burkinabé",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "🎨 ✨ 👑 🚀 💎",
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            Text(
              "Analyse des patterns comportementaux...",
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEnhancedSliverAppBar() {
    final profile = _aiStyleProfile!;
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: profile['gradient'] as List<Color>,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PatternPainter(),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                profile['emoji'],
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              "Score IA: ${profile['score']}%",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareResults,
        ),
      ],
    );
  }

  Widget _buildEnhancedProfileCard() {
    final profile = _aiStyleProfile!;
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (_cardController.value * 0.1),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: profile['gradient'] as List<Color>,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        profile['emoji'],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A4C93).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Profil IA Avancé",
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF6A4C93),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  profile['description'],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCompatibilityMeter(profile['score']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompatibilityMeter(int score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Compatibilité de votre profil",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  height: 8,
                  width: MediaQuery.of(context).size.width * 0.8 * _progressAnimation.value * (score / 100),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: score >= 90
                          ? [const Color(0xFF48BB78), const Color(0xFF38A169)]
                          : score >= 80
                          ? [const Color(0xFF4299E1), const Color(0xFF3182CE)]
                          : [const Color(0xFFED8936), const Color(0xFFDD6B20)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "$score% - ${_getScoreDescription(score)}",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getScoreDescription(int score) {
    if (score >= 95) return "Profil Exceptionnel";
    if (score >= 90) return "Très Haute Compatibilité";
    if (score >= 85) return "Haute Compatibilité";
    if (score >= 80) return "Bonne Compatibilité";
    return "Compatibilité Modérée";
  }

  Widget _buildPersonalityInsightsSection() {
    final profile = _aiStyleProfile!;
    return _buildSection(
      title: "🧠 Insights Personnalité",
      subtitle: "Analyse comportementale avancée",
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea).withOpacity(0.1),
                  const Color(0xFF764ba2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF667eea).withOpacity(0.2)),
            ),
            child: Text(
              profile['personality'],
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (profile['uniqueInsights'] != null)
            ...List.generate(
              (profile['uniqueInsights'] as List<String>).length,
                  (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF667eea),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        (profile['uniqueInsights'] as List<String>)[index],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStrengthsSection() {
    final profile = _aiStyleProfile!;
    final strengths = profile['strengths'] as List<String>;

    return _buildSection(
      title: "💪 Forces Identifiées",
      subtitle: "Vos atouts stylistiques uniques",
      child: Column(
        children: List.generate(strengths.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF48BB78).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xFF48BB78),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strengths[index],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3748),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPersonalizedAdviceSection() {
    final profile = _aiStyleProfile!;
    final advice = profile['personalizedAdvice'] as List<String>;

    return _buildSection(
      title: "🎯 Conseils Personnalisés IA",
      subtitle: "Recommandations sur mesure pour votre évolution",
      child: Column(
        children: List.generate(advice.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (profile['gradient'] as List<Color>)[0].withOpacity(0.05),
                    (profile['gradient'] as List<Color>)[1].withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: (profile['gradient'] as List<Color>)[0].withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: profile['gradient'] as List<Color>,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      advice[index],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3748),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWardrobeRecommendationsSection() {
    final profile = _aiStyleProfile!;
    final wardrobe = profile['wardrobe'] as List<Map<String, String>>;

    return _buildSection(
      title: "👗 Garde-robe Intelligente",
      subtitle: "Pièces essentielles pour votre profil",
      child: Column(
        children: List.generate(wardrobe.length, (index) {
          final item = wardrobe[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['item']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['description']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStyleEvolutionSection() {
    final profile = _aiStyleProfile!;
    final evolution = profile['styleEvolution'] as Map<String, String>;

    return _buildSection(
      title: "📈 Évolution Stylistique",
      subtitle: "Votre parcours de développement personnel",
      child: Column(
        children: [
          _buildEvolutionStep("Actuellement", evolution['current']!, Icons.person, const Color(0xFF4299E1)),
          _buildEvolutionStep("6 mois", evolution['next_6_months']!, Icons.trending_up, const Color(0xFF48BB78)),
          _buildEvolutionStep("1 an", evolution['next_year']!, Icons.star, const Color(0xFFED8936)),
          _buildEvolutionStep("Long terme", evolution['long_term']!, Icons.emoji_events, const Color(0xFF9F7AEA)),
        ],
      ),
    );
  }

  Widget _buildEvolutionStep(String period, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedChallengesSection() {
    final profile = _aiStyleProfile!;
    final challenges = profile['personalizedChallenges'] as List<String>;

    return _buildSection(
      title: "🚀 Défis Personnalisés",
      subtitle: "Challenges pour booster votre style",
      child: Column(
        children: List.generate(challenges.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B6B).withOpacity(0.1),
                    const Color(0xFFFFE66D).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Color(0xFFFF6B6B), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      challenges[index],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3748),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildColorPaletteSection() {
    final profile = _aiStyleProfile!;
    final palette = profile['colorPalette'] as List<String>;

    return _buildSection(
      title: "🎨 Palette Couleurs IA",
      subtitle: "Couleurs optimales pour votre profil",
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(palette.length, (index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getColorFromName(palette[index]).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getColorFromName(palette[index]).withOpacity(0.3)),
            ),
            child: Text(
              palette[index],
              style: TextStyle(
                fontSize: 12,
                color: _getColorFromName(palette[index]),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    final colorMap = {
      'Ocre': const Color(0xFFCC8C00),
      'Brun royal': const Color(0xFF8B4513),
      'Rouge traditionnel': const Color(0xFFDC143C),
      'Blanc pur': const Color(0xFFFFFFFF),
      'Or authentique': const Color(0xFFFFD700),
      'Noir sophistiqué': const Color(0xFF2D3748),
      'Métalliques': const Color(0xFF718096),
      'Néons subtils': const Color(0xFF00FFFF),
      'Monochromes': const Color(0xFF4A5568),
      'Terres chaudes': const Color(0xFFD2691E),
      'Bleus profonds': const Color(0xFF1E3A8A),
      'Roses poudrés': const Color(0xFFFFC0CB),
      'Verts olive': const Color(0xFF808000),
      'Dorés subtils': const Color(0xFFDAA520),
      'Arc-en-ciel audacieux': const Color(0xFFFF69B4),
      'Couleurs primaires': const Color(0xFFFF0000),
      'Pastels pop': const Color(0xFFFFB6C1),
      'Néons créatifs': const Color(0xFF00FF00),
      'Métalliques brillants': const Color(0xFFC0C0C0),
      'Neutres chauds': const Color(0xFFF5DEB3),
      'Bleus apaisants': const Color(0xFF87CEEB),
      'Verts naturels': const Color(0xFF228B22),
      'Beiges sophistiqués': const Color(0xFFF5F5DC),
    };
    return colorMap[colorName] ?? const Color(0xFF6A4C93);
  }

  Widget _buildSection({required String title, required String subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareResults,
                icon: const Icon(Icons.share),
                label: const Text("Partager"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4299E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text("Sauvegarder"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF48BB78),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _retakeQuiz,
            icon: const Icon(Icons.refresh),
            label: const Text("Refaire le Quiz"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6A4C93),
              side: const BorderSide(color: Color(0xFF6A4C93)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _shareResults() {
    final profile = _aiStyleProfile!;
    HapticFeedback.lightImpact();
    // Logique de partage à implémenter
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Profil ${profile['name']} prêt à être partagé!"),
        backgroundColor: const Color(0xFF48BB78),
      ),
    );
  }

  void _saveProfile() {
    HapticFeedback.lightImpact();
    // Logique de sauvegarde à implémenter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profil sauvegardé avec succès!"),
        backgroundColor: Color(0xFF4299E1),
      ),
    );
  }

  void _retakeQuiz() {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const StyleQuizScreen()),
    );
  }
}

// Classe pour dessiner des motifs décoratifs
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Dessine des motifs géométriques inspirés des tissus burkinabé
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        final rect = Rect.fromLTWH(
          i * (size.width / 5) + 10,
          j * (size.height / 3) + 20,
          30,
          20,
        );
        canvas.drawOval(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}