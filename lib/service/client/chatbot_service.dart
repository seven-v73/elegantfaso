
class ChatbotService {
  static Future<Map<String, dynamic>> sendMessage({
    required String text,
    required String conversationId,
    String? gender,
    String? budget,
    String? temperature,
    String? culture,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    final cleanedInput = text.toLowerCase().trim();
    final now = DateTime.now();

    // Handle greetings
    if (_isGreeting(cleanedInput)) {
      return _buildResponse(
        text: _getGreetingResponse(now),
        intent: 'greeting',
      );
    }

    // Handle outfit recommendations
    if (_isRecommendationRequest(cleanedInput)) {
      return _generateOutfitRecommendation(
        cleanedInput,
        gender: gender,
        budget: budget,
        temperature: temperature,
        culture: culture,
      );
    }

    // Handle style advice
    if (_isStyleAdviceRequest(cleanedInput)) {
      return _generateStyleAdvice(
        cleanedInput,
        gender: gender,
      );
    }

    // Handle shopping inquiries
    if (_isShoppingInquiry(cleanedInput)) {
      return _generateShoppingResponse(
        cleanedInput,
        budget: budget,
      );
    }

    // Handle unknown requests
    return _buildResponse(
      text: "Je ne comprends pas. Pouvez-vous reformuler ou poser une question sur la mode, les tendances ou les tenues?",
      intent: 'unknown',
    );
  }

  static bool _isGreeting(String input) {
    return input.contains('bonjour') ||
        input.contains('salut') ||
        input.contains('coucou') ||
        input.contains('hello');
  }

  static String _getGreetingResponse(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Bonjour! Comment puis-je vous aider avec votre style aujourd\'hui?';
    if (hour < 18) return 'Bon après-midi! Besoin de conseils de mode?';
    return 'Bonsoir! Prêt à découvrir les dernières tendances?';
  }

  static bool _isRecommendationRequest(String input) {
    return input.contains('recommande') ||
        input.contains('suggestion') ||
        input.contains('conseille') ||
        input.contains('tenue') ||
        input.contains('porter');
  }

  static Map<String, dynamic> _generateOutfitRecommendation(
      String input, {
        String? gender,
        String? budget,
        String? temperature,
        String? culture,
      }) {
    final occasion = _detectOccasion(input);
    final season = _getCurrentSeason();

    final outfits = _getOutfitSuggestions(
      occasion: occasion,
      gender: gender ?? 'Unisexe',
      budget: budget ?? 'Moyen',
      temperature: temperature,
      culture: culture,
      season: season,
    );

    if (outfits.isEmpty) {
      return _buildResponse(
        text: "Je n'ai pas de recommandations pour cette occasion. Essayez avec une autre description!",
        intent: 'no_recommendation',
      );
    }

    final selectedOutfit = outfits[DateTime.now().second % outfits.length];
    return _buildOutfitResponse(selectedOutfit, occasion);
  }

  static String _detectOccasion(String input) {
    if (input.contains('travail') || input.contains('bureau')) return 'travail';
    if (input.contains('soirée') || input.contains('fête')) return 'soirée';
    if (input.contains('mariage') || input.contains('cérémonie')) return 'mariage';
    if (input.contains('date') || input.contains('rendez-vous')) return 'rendez-vous';
    if (input.contains('sport') || input.contains('gym')) return 'sport';
    if (input.contains('quotidien') || input.contains('journalier')) return 'quotidien';
    return 'général';
  }

  static String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'printemps';
    if (month >= 6 && month <= 8) return 'été';
    if (month >= 9 && month <= 11) return 'automne';
    return 'hiver';
  }

  static List<OutfitRecommendation> _getOutfitSuggestions({
    required String occasion,
    required String gender,
    required String budget,
    required String season,
    String? temperature,
    String? culture,
  }) {
    final List<OutfitRecommendation> allOutfits = [
      OutfitRecommendation(
        description: "Ensemble complet en coton avec motifs africains",
        occasion: "travail",
        gender: "Unisexe",
        budget: "Moyen",
        season: "toutes saisons",
        accessories: "Sac en cuir, chaussures fermées",
        culturalInfluence: "Inspiration Faso Dan Fani",
      ),
      OutfitRecommendation(
        description: "Robe longue en bazin riche avec broderies",
        occasion: "soirée",
        gender: "Femme",
        budget: "Haut de gamme",
        season: "été",
        accessories: "Bijoux en or, sandales élégantes",
        culturalInfluence: "Style Mandé traditionnel",
      ),
      OutfitRecommendation(
        description: "Costume trois pièces en lin avec touches bogolan",
        occasion: "mariage",
        gender: "Homme",
        budget: "Haut de gamme",
        season: "printemps",
        accessories: "Chapeau traditionnel, chaussures en cuir",
        culturalInfluence: "Fusion moderne et tradition",
      ),
      OutfitRecommendation(
        description: "Jupe et haut assortis en tissu wax",
        occasion: "rendez-vous",
        gender: "Femme",
        budget: "Économique",
        season: "printemps",
        accessories: "Collier coloré, sandales plates",
        culturalInfluence: "Style Afropop urbain",
      ),
      OutfitRecommendation(
        description: "Pantalon léger et chemise à manches courtes",
        occasion: "quotidien",
        gender: "Homme",
        budget: "Économique",
        season: "été",
        accessories: "Baskets confortables, casquette",
        culturalInfluence: "Style urbain africain",
      ),
    ];

    return allOutfits.where((outfit) {
      return outfit.occasion == occasion &&
          (outfit.gender == gender || outfit.gender == "Unisexe") &&
          outfit.budget == budget &&
          (outfit.season == season || outfit.season == "toutes saisons");
    }).toList();
  }

  static Map<String, dynamic> _buildOutfitResponse(OutfitRecommendation outfit, String occasion) {
    return {
      "text": "Pour une occasion $occasion, je recommande: ${outfit.description}",
      "intention": "recommendation",
      "recommendation": {
        "description": outfit.description,
        "occasion": occasion,
        "accessories": outfit.accessories,
        "cultural_influence": outfit.culturalInfluence,
      }
    };
  }

  static bool _isStyleAdviceRequest(String input) {
    return input.contains('conseil') ||
        input.contains('style') ||
        input.contains('tendance') ||
        input.contains('mode') ||
        input.contains('aller avec');
  }

  static Map<String, dynamic> _generateStyleAdvice(String input, {String? gender}) {
    final advice = [
      "Les couleurs vives comme le jaune soleil et le vert émeraude sont très tendance cette saison",
      "Essayez de mixer les imprimés traditionnels avec des pièces modernes pour un look unique",
      "Les accessoires en bois et perles artisanales ajoutent une touche authentique à toute tenue",
      "Optez pour des tissus légers et respirants comme le coton et le lin pour le confort",
      "Les coupes amples sont à l'honneur cette année, parfaites pour notre climat"
    ];

    final specificAdvice = gender == "Femme"
        ? "Les robes longues fluides et les jupes portefeuille sont particulièrement élégantes"
        : gender == "Homme"
        ? "Les chemises à motifs africains portées ouvertes sur un t-shirt simple font fureur"
        : "Les ensembles coordonnés (two-pieces) sont un excellent choix pour un look stylé";

    return _buildResponse(
      text: "$specificAdvice. ${advice[DateTime.now().second % advice.length]}",
      intent: 'style_advice',
    );
  }

  static bool _isShoppingInquiry(String input) {
    return input.contains('acheter') ||
        input.contains('boutique') ||
        input.contains('magasin') ||
        input.contains('prix') ||
        input.contains('où trouver');
  }

  static Map<String, dynamic> _generateShoppingResponse(String input, {String? budget}) {
    final budgetPrefix = budget == "Économique"
        ? "Pour les petits budgets"
        : budget == "Haut de gamme"
        ? "Pour les budgets plus élevés"
        : "Pour votre budget";

    final places = [
      "le marché artisanal local",
      "notre boutique en ligne ElegantFaso",
      "les créateurs locaux du quartier des artisans",
      "les pop-up stores du centre ville"
    ];

    return _buildResponse(
      text: "$budgetPrefix, je vous suggère de visiter ${places[DateTime.now().second % places.length]}. Vous y trouverez des pièces uniques et de qualité!",
      intent: 'shopping',
    );
  }

  static Map<String, dynamic> _buildResponse({
    required String text,
    String? intent,
    Map<String, dynamic>? recommendation,
  }) {
    return {
      "text": text,
      "intention": intent ?? "information",
      "recommendation": recommendation,
    };
  }

  static List<String> getQuickReplies() {
    return [
      "Conseils style",
      "Tenue soirée",
      "Idées travail",
      "Tendances actuelles"
    ];
  }
}

class OutfitRecommendation {
  final String description;
  final String occasion;
  final String gender;
  final String budget;
  final String season;
  final String accessories;
  final String culturalInfluence;

  OutfitRecommendation({
    required this.description,
    required this.occasion,
    required this.gender,
    required this.budget,
    required this.season,
    required this.accessories,
    required this.culturalInfluence,
  });
}