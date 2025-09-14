import 'package:flutter/material.dart';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:confetti/confetti.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    title: 'FasoStyle',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      fontFamily: 'Roboto',
    ),
    home: const ProfileWrapper(),
  ));
}

class ProfileWrapper extends StatefulWidget {
  const ProfileWrapper({super.key});

  @override
  State<ProfileWrapper> createState() => _ProfileWrapperState();
}

class _ProfileWrapperState extends State<ProfileWrapper> {
  UserProfile? _currentUser;
  bool _isLoading = true;
  bool _showProfileDialog = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _currentUser = UserProfile.fromFirestore(doc.data()!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentUser = UserProfile.defaultProfile(
            name: user.displayName ?? "Ami(e)",
            uid: user.uid,
          );
          _showProfileDialog = true;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _currentUser = UserProfile.defaultProfile(uid: 'guest');
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile(UserProfile profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(user.uid)
          .set(profile.toFirestore());
    }
  }

  void _handleProfileSubmit(UserProfile profile) {
    _saveProfile(profile);
    setState(() {
      _currentUser = profile;
      _showProfileDialog = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        FasoStyleScreen(currentUser: _currentUser),
        if (_showProfileDialog)
          ProfileSetupDialog(
            initialProfile: _currentUser!,
            onSubmit: _handleProfileSubmit,
          ),
      ],
    );
  }
}

class ProfileSetupDialog extends StatefulWidget {
  final UserProfile initialProfile;
  final Function(UserProfile) onSubmit;

  const ProfileSetupDialog({
    super.key,
    required this.initialProfile,
    required this.onSubmit,
  });

  @override
  State<ProfileSetupDialog> createState() => _ProfileSetupDialogState();
}

class _ProfileSetupDialogState extends State<ProfileSetupDialog> {
  late String _gender;
  late String _ethnicity;
  late Season _season;
  late Occasion _occasion;
  late TextEditingController _nameController;
  late TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialProfile.gender ?? "neutre";
    _ethnicity = widget.initialProfile.ethnicity ?? "mossi";
    _season = widget.initialProfile.season ?? Season.dry;
    _occasion = widget.initialProfile.occasion ?? Occasion.daily;
    _nameController = TextEditingController(text: widget.initialProfile.name);
    _cityController = TextEditingController(text: widget.initialProfile.city);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isFormValid = _gender != null && _ethnicity != null && _season != null && _occasion != null;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          gradient: isDarkMode
              ? null
              : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF9C4), Color(0xFFFFFDE7)],
          ),
        ),
        child: Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                widget.onSubmit(widget.initialProfile);
                Navigator.of(context).pop();
              },
              tooltip: "Fermer",
              alignment: Alignment.topRight,
            ),
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Complétez votre profil",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE74C3C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Personnalisez votre expérience FasoStyle en nous partageant quelques informations :",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _nameController,
                    label: "Votre nom",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 15),
                  _buildDropdown<String>(
                    label: "Genre",
                    value: _gender,
                    items: const ["homme", "femme", "neutre"],
                    displayText: (value) => value == "homme"
                        ? "Homme 👨"
                        : value == "femme"
                        ? "Femme 👩"
                        : "Neutre 🧑",
                    onChanged: (value) => setState(() => _gender = value!),
                  ),
                  const SizedBox(height: 15),
                  _buildDropdown<String>(
                    label: "Origine ethnique",
                    value: _ethnicity,
                    items: const [
                      "mossi",
                      "peul",
                      "gourmantche",
                      "bobo",
                      "dioula",
                      "lobi",
                      "dagara",
                      "senoufo"
                    ],
                    displayText: (value) => UserProfile.describeEthnicity(value!),
                    onChanged: (value) => setState(() => _ethnicity = value!),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _cityController,
                    label: "Votre ville",
                    icon: Icons.location_city,
                  ),
                  const SizedBox(height: 15),
                  _buildDropdown<Season>(
                    label: "Saison actuelle",
                    value: _season,
                    items: Season.values,
                    displayText: (value) => UserProfile.describeSeason(value!),
                    onChanged: (value) => setState(() => _season = value!),
                  ),
                  const SizedBox(height: 15),
                  _buildDropdown<Occasion>(
                    label: "Occasion fréquente",
                    value: _occasion,
                    items: Occasion.values,
                    displayText: (value) => UserProfile.describeOccasion(value!),
                    onChanged: (value) => setState(() => _occasion = value!),
                  ),
                  const SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: isFormValid
                        ? () {
                      final updatedProfile = widget.initialProfile.copyWith(
                        name: _nameController.text,
                        city: _cityController.text,
                        gender: _gender,
                        ethnicity: _ethnicity,
                        season: _season,
                        occasion: _occasion,
                        profileCompleted: true,
                      );
                      widget.onSubmit(updatedProfile);
                      Navigator.of(context).pop();
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Enregistrer mon profil",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () {
                      widget.onSubmit(widget.initialProfile);
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "Plus tard",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T?) displayText,
    required Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  displayText(item),
                  style: const TextStyle(fontSize: 15),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// Modèles de données
enum ClothingType { top, bottom, shoes, accessory, outerwear, traditional, headwear }
enum Season { spring, summer, autumn, winter, dry, rainy }
enum Occasion { casual, formal, business, sport, party, wedding, funeral, baptism, ceremony, daily }
enum ColorPalette { black, white, gray, navy, brown, red, blue, green, yellow, pink, purple, beige, gold, silver, burgundy, orange, indigo, turquoise }

class ClothingItem {
  final String id;
  final String name;
  final ClothingType type;
  final ColorPalette color;
  final List<Season> seasons;
  final List<Occasion> occasions;
  final int warmthLevel;
  final List<ColorPalette> compatibleColors;
  final String? fabricType;
  final String? culturalOrigin;
  final String? imageUrl;

  ClothingItem({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.seasons,
    required this.occasions,
    required this.warmthLevel,
    required this.compatibleColors,
    this.fabricType,
    this.culturalOrigin,
    this.imageUrl,
  });
}

class Outfit {
  final List<ClothingItem> items;
  final double compatibilityScore;
  final Season season;
  final Occasion occasion;
  final String? description;

  Outfit({
    required this.items,
    required this.compatibilityScore,
    required this.season,
    required this.occasion,
    this.description,
  });

  ClothingItem? get top => items.firstWhereOrNull((item) => item.type == ClothingType.top);
  ClothingItem? get bottom => items.firstWhereOrNull((item) => item.type == ClothingType.bottom);
  ClothingItem? get shoes => items.firstWhereOrNull((item) => item.type == ClothingType.shoes);
  ClothingItem? get traditional => items.firstWhereOrNull((item) => item.type == ClothingType.traditional);
  ClothingItem? get headwear => items.firstWhereOrNull((item) => item.type == ClothingType.headwear);
  List<ClothingItem> get accessories => items.where((item) => item.type == ClothingType.accessory).toList();
}

// Service de génération de tenues
class BurkinabeOutfitGenerator {
  final Random _random = Random();

  static const Map<ColorPalette, List<ColorPalette>> colorCompatibility = {
    ColorPalette.black: [ColorPalette.white, ColorPalette.gray, ColorPalette.red, ColorPalette.gold, ColorPalette.orange],
    ColorPalette.white: [ColorPalette.black, ColorPalette.navy, ColorPalette.green, ColorPalette.red, ColorPalette.gold],
    ColorPalette.gray: [ColorPalette.black, ColorPalette.white, ColorPalette.navy, ColorPalette.burgundy],
    ColorPalette.navy: [ColorPalette.white, ColorPalette.beige, ColorPalette.gray, ColorPalette.gold],
    ColorPalette.brown: [ColorPalette.white, ColorPalette.beige, ColorPalette.green, ColorPalette.orange],
    ColorPalette.red: [ColorPalette.black, ColorPalette.white, ColorPalette.gold, ColorPalette.beige],
    ColorPalette.blue: [ColorPalette.white, ColorPalette.gray, ColorPalette.beige, ColorPalette.silver],
    ColorPalette.green: [ColorPalette.white, ColorPalette.brown, ColorPalette.beige, ColorPalette.gold],
    ColorPalette.yellow: [ColorPalette.black, ColorPalette.gray, ColorPalette.brown, ColorPalette.green],
    ColorPalette.pink: [ColorPalette.black, ColorPalette.white, ColorPalette.gray, ColorPalette.burgundy],
    ColorPalette.purple: [ColorPalette.black, ColorPalette.white, ColorPalette.gray, ColorPalette.silver],
    ColorPalette.beige: [ColorPalette.navy, ColorPalette.brown, ColorPalette.white, ColorPalette.green],
    ColorPalette.gold: [ColorPalette.black, ColorPalette.red, ColorPalette.green, ColorPalette.purple],
    ColorPalette.silver: [ColorPalette.blue, ColorPalette.purple, ColorPalette.gray, ColorPalette.black],
    ColorPalette.burgundy: [ColorPalette.gold, ColorPalette.beige, ColorPalette.gray, ColorPalette.black],
    ColorPalette.orange: [ColorPalette.brown, ColorPalette.blue, ColorPalette.white, ColorPalette.gold],
    ColorPalette.indigo: [ColorPalette.silver, ColorPalette.white, ColorPalette.orange, ColorPalette.gold],
    ColorPalette.turquoise: [ColorPalette.brown, ColorPalette.gold, ColorPalette.beige, ColorPalette.navy],
  };

  List<Outfit> generateOutfits({
    required List<ClothingItem> wardrobe,
    required Season season,
    required Occasion occasion,
    String? culturalStyle,
    int count = 3,
  }) {
    List<Outfit> outfits = [];
    List<ClothingItem> suitableItems = wardrobe.where((item) {
      return item.seasons.contains(season) &&
          item.occasions.contains(occasion) &&
          (culturalStyle == null || item.culturalOrigin?.toLowerCase() == culturalStyle.toLowerCase());
    }).toList();

    List<ClothingItem> tops = suitableItems.where((item) => item.type == ClothingType.top).toList();
    List<ClothingItem> bottoms = suitableItems.where((item) => item.type == ClothingType.bottom).toList();
    List<ClothingItem> shoes = suitableItems.where((item) => item.type == ClothingType.shoes).toList();
    List<ClothingItem> accessories = suitableItems.where((item) => item.type == ClothingType.accessory).toList();
    List<ClothingItem> outerwear = suitableItems.where((item) => item.type == ClothingType.outerwear).toList();
    List<ClothingItem> traditional = suitableItems.where((item) => item.type == ClothingType.traditional).toList();
    List<ClothingItem> headwear = suitableItems.where((item) => item.type == ClothingType.headwear).toList();

    int attempts = 0;
    while (outfits.length < count && attempts < count * 15) {
      attempts++;
      Outfit? outfit = _generateSingleOutfit(
        tops: tops,
        bottoms: bottoms,
        shoes: shoes,
        accessories: accessories,
        outerwear: outerwear,
        traditional: traditional,
        headwear: headwear,
        season: season,
        occasion: occasion,
        culturalStyle: culturalStyle,
      );

      if (outfit != null && !_isDuplicateOutfit(outfit, outfits)) {
        outfits.add(outfit);
      }
    }

    outfits.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
    return outfits;
  }

  Outfit? _generateSingleOutfit({
    required List<ClothingItem> tops,
    required List<ClothingItem> bottoms,
    required List<ClothingItem> shoes,
    required List<ClothingItem> accessories,
    required List<ClothingItem> outerwear,
    required List<ClothingItem> traditional,
    required List<ClothingItem> headwear,
    required Season season,
    required Occasion occasion,
    String? culturalStyle,
  }) {
    List<ClothingItem> outfitItems = [];
    double baseScore = 0.0;

    final useTraditional = (culturalStyle != null || [Occasion.wedding, Occasion.ceremony, Occasion.funeral].contains(occasion)) &&
        traditional.isNotEmpty &&
        _random.nextDouble() > 0.3;

    if (useTraditional) {
      ClothingItem selectedTraditional = traditional[_random.nextInt(traditional.length)];
      outfitItems.add(selectedTraditional);
      baseScore += 15.0;

      if (accessories.isNotEmpty && _random.nextBool()) {
        List<ClothingItem> compatibleAccessories = accessories.where((acc) =>
        _areColorsCompatible(selectedTraditional.color, acc.color) &&
            (acc.culturalOrigin == selectedTraditional.culturalOrigin)
        ).toList();

        if (compatibleAccessories.isNotEmpty) {
          outfitItems.add(compatibleAccessories[_random.nextInt(compatibleAccessories.length)]);
        }
      }

      if (shoes.isNotEmpty) {
        List<ClothingItem> compatibleShoes = shoes.where((shoe) =>
        _areColorsCompatible(selectedTraditional.color, shoe.color) &&
            (shoe.culturalOrigin == selectedTraditional.culturalOrigin)
        ).toList();

        if (compatibleShoes.isNotEmpty) {
          outfitItems.add(compatibleShoes[_random.nextInt(compatibleShoes.length)]);
        }
      }

      if (headwear.isNotEmpty && _random.nextDouble() > 0.5) {
        List<ClothingItem> compatibleHeadwear = headwear.where((head) =>
        _areColorsCompatible(selectedTraditional.color, head.color) &&
            (head.culturalOrigin == selectedTraditional.culturalOrigin)
        ).toList();

        if (compatibleHeadwear.isNotEmpty) {
          outfitItems.add(compatibleHeadwear[_random.nextInt(compatibleHeadwear.length)]);
        }
      }
    } else {
      if (tops.isEmpty || bottoms.isEmpty || shoes.isEmpty) return null;

      ClothingItem selectedTop = tops[_random.nextInt(tops.length)];
      outfitItems.add(selectedTop);

      List<ClothingItem> compatibleBottoms = bottoms.where((bottom) =>
          _areColorsCompatible(selectedTop.color, bottom.color)
      ).toList();

      if (compatibleBottoms.isEmpty) return null;
      ClothingItem selectedBottom = compatibleBottoms[_random.nextInt(compatibleBottoms.length)];
      outfitItems.add(selectedBottom);

      List<ClothingItem> compatibleShoes = shoes.where((shoe) =>
      _areColorsCompatible(selectedTop.color, shoe.color) ||
          _areColorsCompatible(selectedBottom.color, shoe.color)
      ).toList();

      if (compatibleShoes.isEmpty) return null;
      outfitItems.add(compatibleShoes[_random.nextInt(compatibleShoes.length)]);

      if (accessories.isNotEmpty && _random.nextBool()) {
        List<ClothingItem> compatibleAccessories = accessories.where((accessory) =>
            outfitItems.any((item) => _areColorsCompatible(item.color, accessory.color))
        ).toList();

        if (compatibleAccessories.isNotEmpty) {
          outfitItems.add(compatibleAccessories[_random.nextInt(compatibleAccessories.length)]);
        }
      }
    }

    if ((season == Season.winter || season == Season.autumn || season == Season.rainy) &&
        outerwear.isNotEmpty &&
        _random.nextDouble() > 0.4) {
      ClothingItem? selectedOuterwear;

      if (outfitItems.isNotEmpty) {
        final mainItem = outfitItems.first;
        List<ClothingItem> compatibleOuterwear = outerwear.where((outer) =>
            _areColorsCompatible(mainItem.color, outer.color)
        ).toList();

        if (compatibleOuterwear.isNotEmpty) {
          selectedOuterwear = compatibleOuterwear[_random.nextInt(compatibleOuterwear.length)];
        }
      }

      selectedOuterwear ??= outerwear[_random.nextInt(outerwear.length)];
      outfitItems.add(selectedOuterwear);
    }

    double score = baseScore + _calculateCompatibilityScore(outfitItems, season, occasion);
    String description = _generateOutfitDescription(outfitItems, culturalStyle);

    return Outfit(
      items: outfitItems,
      compatibilityScore: score,
      season: season,
      occasion: occasion,
      description: description,
    );
  }

  bool _areColorsCompatible(ColorPalette color1, ColorPalette color2) {
    return color1 == color2 || (colorCompatibility[color1]?.contains(color2) ?? false);
  }

  double _calculateCompatibilityScore(List<ClothingItem> items, Season season, Occasion occasion) {
    double score = 0.0;

    for (int i = 0; i < items.length; i++) {
      for (int j = i + 1; j < items.length; j++) {
        if (_areColorsCompatible(items[i].color, items[j].color)) score += 8.0;
      }
    }

    int totalWarmth = items.fold(0, (sum, item) => sum + item.warmthLevel);
    int idealWarmth = _getIdealWarmthLevel(season);
    double warmthScore = 20.0 - (totalWarmth - idealWarmth).abs() * 2.0;
    score += warmthScore.clamp(0.0, 20.0);

    if (items.every((item) => item.occasions.contains(occasion))) score += 15.0;

    Set<ClothingType> types = items.map((item) => item.type).toSet();
    score += types.length * 4.0;

    final culturalOrigins = items.map((e) => e.culturalOrigin).whereNotNull().toSet();
    if (culturalOrigins.length == 1) score += 12.0;

    return score;
  }

  int _getIdealWarmthLevel(Season season) {
    switch (season) {
      case Season.summer:
      case Season.dry:
        return 6;
      case Season.spring:
        return 9;
      case Season.autumn:
      case Season.rainy:
        return 12;
      case Season.winter:
        return 15;
    }
  }

  bool _isDuplicateOutfit(Outfit newOutfit, List<Outfit> existingOutfits) {
    return existingOutfits.any((existing) {
      Set<String> newIds = newOutfit.items.map((item) => item.id).toSet();
      Set<String> existingIds = existing.items.map((item) => item.id).toSet();
      return newIds.difference(existingIds).isEmpty;
    });
  }

  String _generateOutfitDescription(List<ClothingItem> items, String? culturalStyle) {
    final mainItems = items.where((item) => item.type != ClothingType.accessory).toList();
    final accessories = items.where((item) => item.type == ClothingType.accessory).toList();

    final descriptions = [
      "Une tenue élégante qui marie parfaitement",
      "Un ensemble harmonieux mettant en valeur",
      "Une combinaison raffinée mettant en avant",
      "Un look sophistiqué qui sublime",
      "Une création équilibrée mettant en lumière"
    ];

    final culturalPhrases = {
      'mossi': "inspirée de la tradition mossi",
      'peul': "aux influences peules authentiques",
      'gourmantche': "dans le pur style gourmantché",
      'bobo': "revisitée du patrimoine bobo",
      null: "contemporaine"
    };

    String mainDescription = mainItems.map((item) {
      final fabric = item.fabricType != null ? " en ${item.fabricType}" : "";
      return "${item.name}$fabric";
    }).join(" avec ");

    String accessoryDescription = accessories.isNotEmpty
        ? ", accessoirisé avec ${accessories.map((a) => a.name).join(' et ')}"
        : "";

    String culturalTag = culturalPhrases[culturalStyle] ?? culturalPhrases[null]!;

    return "${descriptions[_random.nextInt(descriptions.length)]} $mainDescription$accessoryDescription, $culturalTag.";
  }
}

// Modèle utilisateur
class UserProfile {
  final String? uid;
  final String? name;
  final String? gender;
  final String? timeOfDay;
  final Occasion? occasion;
  final String? ethnicity;
  final Season? season;
  final String? fabricPreference;
  final String? city;
  final List<ClothingItem> wardrobe;
  final bool profileCompleted;

  UserProfile({
    this.uid,
    this.name,
    this.gender,
    this.timeOfDay,
    this.occasion,
    this.ethnicity,
    this.season,
    this.fabricPreference,
    this.city,
    this.wardrobe = const [],
    this.profileCompleted = false,
  });

  factory UserProfile.defaultProfile({String name = "Ami(e)", String uid = 'guest'}) {
    return UserProfile(
      uid: uid,
      name: name,
      gender: "neutre",
      timeOfDay: "jour",
      occasion: Occasion.daily,
      ethnicity: "mossi",
      season: Season.dry,
      fabricPreference: "faso_dan_fani",
      city: "Ouagadougou",
    );
  }

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'],
      name: data['name'],
      gender: data['gender'],
      timeOfDay: data['timeOfDay'],
      occasion: data['occasion'] != null ? Occasion.values[data['occasion']] : null,
      ethnicity: data['ethnicity'],
      season: data['season'] != null ? Season.values[data['season']] : null,
      fabricPreference: data['fabricPreference'],
      city: data['city'],
      profileCompleted: data['profileCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'gender': gender,
      'timeOfDay': timeOfDay,
      'occasion': occasion?.index,
      'ethnicity': ethnicity,
      'season': season?.index,
      'fabricPreference': fabricPreference,
      'city': city,
      'profileCompleted': profileCompleted,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? gender,
    String? timeOfDay,
    Occasion? occasion,
    String? ethnicity,
    Season? season,
    String? fabricPreference,
    String? city,
    List<ClothingItem>? wardrobe,
    bool? profileCompleted,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      occasion: occasion ?? this.occasion,
      ethnicity: ethnicity ?? this.ethnicity,
      season: season ?? this.season,
      fabricPreference: fabricPreference ?? this.fabricPreference,
      city: city ?? this.city,
      wardrobe: wardrobe ?? this.wardrobe,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }

  bool hasUserData() {
    return gender != "neutre" ||
        timeOfDay != "jour" ||
        occasion != Occasion.daily ||
        ethnicity != "mossi" ||
        season != Season.dry ||
        fabricPreference != "faso_dan_fani";
  }

  String getProfileSummary() {
    List<String> parts = [];

    if (name != null && name!.isNotEmpty) {
      parts.add(name!);
    }

    if (gender != null && gender != "neutre") {
      parts.add(gender == "homme" ? "Homme" : "Femme");
    }

    if (ethnicity != null && ethnicity != "mossi") {
      parts.add(describeEthnicity(ethnicity!));
    }

    if (occasion != null && occasion != Occasion.daily) {
      parts.add(describeOccasion(occasion!));
    }

    if (season != null && season != Season.dry) {
      parts.add(describeSeason(season!));
    }

    return parts.isEmpty ? "Profil détecté automatiquement" : parts.join(" • ");
  }

  static String describeEthnicity(String ethnicity) {
    switch (ethnicity) {
      case "mossi": return "Mossi";
      case "peul": return "Peul";
      case "gourmantche": return "Gourmantché";
      case "bobo": return "Bobo";
      case "dioula": return "Dioula";
      case "lobi": return "Lobi";
      case "dagara": return "Dagara";
      case "senoufo": return "Sénoufo";
      case "samogo": return "Samo";
      case "gourounsi": return "Gourounsi";
      case "bissa": return "Bissa";
      case "toussian": return "Toussian";
      case "marka": return "Marka";
      case "kassena": return "Kasséna";
      case "nouna": return "Nounas";
      default: return "Autre ethnie";
    }
  }

  static String describeOccasion(Occasion occasion) {
    switch (occasion) {
      case Occasion.wedding: return "Mariage";
      case Occasion.business: return "Travail";
      case Occasion.baptism: return "Baptême";
      case Occasion.funeral: return "Funérailles";
      case Occasion.ceremony: return "Cérémonie";
      case Occasion.party: return "Fête";
      case Occasion.casual: return "Décontracté";
      default: return "Autre occasion";
    }
  }

  static String describeSeason(Season season) {
    switch (season) {
      case Season.rainy: return "Saison des pluies";
      case Season.dry: return "Saison sèche";
      case Season.winter: return "Hiver";
      case Season.summer: return "Été";
      case Season.spring: return "Printemps";
      case Season.autumn: return "Automne";
    }
  }
}

// Système d'intelligence conversationnelle
enum Intent {
  greeting,
  requestHelp,
  requestOutfit,
  requestColorAdvice,
  requestOccasionAdvice,
  expressGratitude,
  general
}

enum EmotionalState {
  frustrated,
  confused,
  excited,
  hesitant,
  satisfied,
  neutral
}

class ConversationResponse {
  final String text;
  final Intent intent;
  final EmotionalState emotion;
  final bool hasVisual;
  final String? visualType;
  final List<Outfit>? outfits;
  final List<String>? suggestions;

  ConversationResponse({
    required this.text,
    required this.intent,
    required this.emotion,
    this.hasVisual = false,
    this.visualType,
    this.outfits,
    this.suggestions,
  });
}

class FasoStyleIntelligence {
  UserProfile? userProfile;

  FasoStyleIntelligence(this.userProfile);

  ConversationResponse generateResponse(
      String userMessage,
      Season? season,
      Occasion? occasion
      ) {
    final intent = _detectIntent(userMessage);
    final emotion = _detectEmotion(userMessage);
    final entities = _extractEntities(userMessage);

    return _generateResponse(intent, emotion, entities, season, occasion);
  }

  Intent _detectIntent(String message) {
    final lowerMessage = message.toLowerCase();

    if (RegExp(r'\b(bonjour|salut|coucou|hello|salam)\b').hasMatch(lowerMessage)) {
      return Intent.greeting;
    }

    if (RegExp(r'\b(merci|remercie|apprécie|gratitude)\b').hasMatch(lowerMessage)) {
      return Intent.expressGratitude;
    }

    if (RegExp(r'\b(tenue|outfit|vêtement|habit|look|style)\b').hasMatch(lowerMessage)) {
      return Intent.requestOutfit;
    }

    if (RegExp(r'\b(couleur|teinte|nuance|coloris|assortir)\b').hasMatch(lowerMessage)) {
      return Intent.requestColorAdvice;
    }

    if (RegExp(r'\b(occasion|événement|cérémonie|fête|mariage|funérailles|baptême|travail)\b').hasMatch(lowerMessage)) {
      return Intent.requestOccasionAdvice;
    }

    return Intent.general;
  }

  EmotionalState _detectEmotion(String message) {
    final lowerMessage = message.toLowerCase();

    if (RegExp(r'\b(frustré|énervé|agacé|fâché|insatisfait)\b').hasMatch(lowerMessage)) {
      return EmotionalState.frustrated;
    }

    if (RegExp(r'\b(confus|perdu|incompris|doute|pas sûr)\b').hasMatch(lowerMessage)) {
      return EmotionalState.confused;
    }

    if (RegExp(r'\b(enthousiaste|impatient|excité|content|heureux)\b').hasMatch(lowerMessage)) {
      return EmotionalState.excited;
    }

    if (RegExp(r'\b(hésite|incertain|pas décidé|débattu)\b').hasMatch(lowerMessage)) {
      return EmotionalState.hesitant;
    }

    return EmotionalState.neutral;
  }

  Map<String, dynamic> _extractEntities(String message) {
    final lowerMessage = message.toLowerCase();
    final entities = <String, dynamic>{};

    if (RegExp(r'\b(mariage|noces|union)\b').hasMatch(lowerMessage)) {
      entities['occasion'] = Occasion.wedding;
    } else if (RegExp(r'\b(funérailles|obsèques|deuil)\b').hasMatch(lowerMessage)) {
      entities['occasion'] = Occasion.funeral;
    } else if (RegExp(r'\b(baptême|nomination)\b').hasMatch(lowerMessage)) {
      entities['occasion'] = Occasion.baptism;
    } else if (RegExp(r'\b(travail|bureau|professionnel)\b').hasMatch(lowerMessage)) {
      entities['occasion'] = Occasion.business;
    }

    final colorMatches = RegExp(r'\b(rouge|bleu|vert|jaune|noir|blanc|orange|violet|rose|or|argent)\b')
        .allMatches(lowerMessage);
    if (colorMatches.isNotEmpty) {
      entities['couleurs'] = colorMatches.map((m) => m.group(0)).toList();
    }

    if (RegExp(r'\b(traditionnel|ethnique|culturel|ancestral)\b').hasMatch(lowerMessage)) {
      entities['style'] = 'traditionnel';
    } else if (RegExp(r'\b(moderne|contemporain|tendance|branché)\b').hasMatch(lowerMessage)) {
      entities['style'] = 'moderne';
    }

    return entities;
  }

  ConversationResponse _generateResponse(
      Intent intent,
      EmotionalState emotion,
      Map<String, dynamic> entities,
      Season? season,
      Occasion? occasion,
      ) {
    final currentSeason = season ?? Season.dry;
    final currentOccasion = occasion ?? Occasion.daily;
    final ethnicity = userProfile?.ethnicity;

    switch (intent) {
      case Intent.greeting:
        return _generateGreetingResponse(emotion);

      case Intent.requestOutfit:
        return _generateOutfitResponse(entities, currentSeason, currentOccasion, ethnicity, emotion);

      case Intent.requestColorAdvice:
        return _generateColorResponse(entities, ethnicity, emotion);

      case Intent.requestOccasionAdvice:
        return _generateOccasionResponse(entities, ethnicity, emotion);

      case Intent.expressGratitude:
        return _generateGratitudeResponse(emotion);

      default:
        return _generateGeneralResponse(emotion);
    }
  }

  ConversationResponse _generateGreetingResponse(EmotionalState emotion) {
    final name = userProfile?.name ?? "Ami(e)";
    final greeting = userProfile != null
        ? _getEthnicGreeting(userProfile!.ethnicity)
        : "Bonjour";

    String response = "$greeting $name ! Je suis FasoStyle, votre assistant mode burkinabé. Comment puis-je vous aider aujourd'hui ?";

    if (emotion == EmotionalState.excited) {
      response = "$response Vous semblez de bonne humeur, c'est parfait pour choisir une tenue !";
    }

    return ConversationResponse(
      text: response,
      intent: Intent.greeting,
      emotion: emotion,
    );
  }

  String _getEthnicGreeting(String? ethnicity) {
    switch (ethnicity) {
      case "mossi": return "Ne y yibeogo";
      case "peul": return "Jam tan";
      case "gourmantche": return "Manta";
      case "bobo": return "Yèrè sogoma";
      default: return "Bonjour";
    }
  }

  ConversationResponse _generateOutfitResponse(
      Map<String, dynamic> entities,
      Season season,
      Occasion occasion,
      String? ethnicity,
      EmotionalState emotion
      ) {
    final style = entities['style'] as String? ?? 'mixte';
    final colors = entities['couleurs'] as List<String>?;

    String response = "Je prépare des suggestions spécialement pour vous...";

    if (emotion == EmotionalState.hesitant) {
      response = "Je sens que vous hésitez. Je vais vous proposer plusieurs options pour vous inspirer !";
    }

    String culturalTip = "";
    if (ethnicity == "mossi") {
      culturalTip = "\n\nConseil mossi : Privilégiez le Faso Dan Fani rouge et or pour les grandes occasions.";
    } else if (ethnicity == "peul") {
      culturalTip = "\n\nConseil peul : Les broderies fines et les couleurs vives mettent en valeur votre élégance naturelle.";
    }

    return ConversationResponse(
      text: response + culturalTip,
      intent: Intent.requestOutfit,
      emotion: emotion,
      hasVisual: true,
      visualType: 'outfit_suggestion',
      suggestions: [
        "Tenue traditionnelle",
        "Style moderne",
        "Pour ${UserProfile.describeOccasion(occasion)}",
        "Couleurs spécifiques"
      ],
    );
  }

  ConversationResponse _generateColorResponse(
      Map<String, dynamic> entities,
      String? ethnicity,
      EmotionalState emotion
      ) {
    final colors = entities['couleurs'] as List<String>?;

    String response = "Les couleurs sont essentielles pour une tenue harmonieuse ! ";

    if (colors != null && colors.isNotEmpty) {
      response += "Le ${colors.first} est un excellent choix. ";
    }

    if (ethnicity == "mossi") {
      response += "Dans la tradition mossi, le rouge symbolise la vie et l'énergie, "
          "tandis que le blanc représente la pureté.";
    } else if (ethnicity == "peul") {
      response += "Les Peuls privilégient souvent le bleu indigo profond et le vert émeraude "
          "pour leurs tenues traditionnelles.";
    }

    return ConversationResponse(
      text: response,
      intent: Intent.requestColorAdvice,
      emotion: emotion,
      hasVisual: true,
      visualType: 'colors_burkina',
      suggestions: [
        "Associations avec ${colors?.first ?? 'rouge'}",
        "Signification des couleurs",
        "Couleurs traditionnelles"
      ],
    );
  }

  ConversationResponse _generateOccasionResponse(
      Map<String, dynamic> entities,
      String? ethnicity,
      EmotionalState emotion
      ) {
    final occasion = entities['occasion'] as Occasion?;

    String response = "Chaque occasion a son code vestimentaire ! ";

    if (occasion != null) {
      response += "Pour ${UserProfile.describeOccasion(occasion)}, ";

      switch (occasion) {
        case Occasion.wedding:
          response += "optez pour des tenues élégantes et colorées. ";
          break;
        case Occasion.funeral:
          response += "privilégiez des couleurs sobres comme le noir, blanc ou bleu foncé. ";
          break;
        case Occasion.business:
          response += "choisissez des tenues professionnelles mais confortables. ";
          break;
        default:
          response += "vous pouvez être plus créatif avec votre style. ";
      }
    }

    if (ethnicity == "mossi" && occasion == Occasion.wedding) {
      response += "Chez les Mossi, la mariée porte traditionnellement un pagne en Faso Dan Fani "
          "avec des motifs symboliques.";
    }

    return ConversationResponse(
      text: response,
      intent: Intent.requestOccasionAdvice,
      emotion: emotion,
      suggestions: [
        if (occasion != null) "Tenues pour ${UserProfile.describeOccasion(occasion)}",
        "Accessoires appropriés",
        "Conseils tissus"
      ],
    );
  }

  ConversationResponse _generateGratitudeResponse(EmotionalState emotion) {
    final responses = [
      "C'est un plaisir de vous aider ! N'hésitez pas si vous avez d'autres questions.",
      "Merci à vous ! Je suis toujours là pour vous conseiller sur votre style.",
      "Votre satisfaction est ma plus grande récompense !"
    ];

    return ConversationResponse(
      text: responses[Random().nextInt(responses.length)],
      intent: Intent.expressGratitude,
      emotion: emotion,
    );
  }

  ConversationResponse _generateGeneralResponse(EmotionalState emotion) {
    String response = "Je suis FasoStyle, votre assistant mode burkinabé. "
        "Je peux vous aider à créer des tenues parfaites pour chaque occasion !";

    if (emotion == EmotionalState.confused) {
      response = "Je peux vous guider étape par étape. "
          "Dites-moi simplement ce que vous cherchez : une tenue, des conseils de couleurs, ou des idées pour une occasion spécifique ?";
    }

    return ConversationResponse(
      text: response,
      intent: Intent.general,
      emotion: emotion,
      suggestions: [
        "Créer une tenue",
        "Conseils couleurs",
        "Idées pour une occasion"
      ],
    );
  }
}

// Contexte conversationnel
class ConversationContext {
  String? currentTopic;
  Map<String, dynamic> topicDetails = {};
  List<String> recentTopics = [];
  DateTime? lastInteraction;

  void updateContext(String newTopic, [Map<String, dynamic>? details]) {
    recentTopics.add(newTopic);
    if (recentTopics.length > 3) recentTopics.removeAt(0);
    currentTopic = newTopic;
    topicDetails = details ?? {};
    lastInteraction = DateTime.now();
  }

  bool isRelated(String message) {
    if (currentTopic == null) return false;
    if (lastInteraction == null) return false;

    final elapsed = DateTime.now().difference(lastInteraction!).inMinutes;
    if (elapsed > 5) return false;

    final keywords = {
      'mariage': ["mariage", "noces", "union", "fiancaille", "dot", "fiançailles"],
      'funerailles': ["funérailles", "deuil", "décès", "enterrement", "obsèques"],
      'bapteme': ["baptême", "bébé", "nouveau-né", "nommage"],
      'travail': ["travail", "bureau", "professionnel", "réunion"],
      'fête': ["fête", "soirée", "ambiance", "dancing", "anniversaire"],
      'religion': ["culte", "messe", "prière", "mosquée", "église"],
      'festival': ["festival", "culturel", "masque", "danse", "tradition"],
      'marché': ["marché", "courses", "shopping", "achat"],
      'décontracté': ["casual", "quotidien", "balade", "repos"],
    }[currentTopic];

    return keywords?.any((k) => message.contains(k)) ?? false;
  }
}

// Base de données de style
class FasoStyleDatabase {
  static final Map<String, String> _greetingCache = {};

  String getPersonalizedGreeting(UserProfile? profile) {
    final ethnicity = profile?.ethnicity?.toLowerCase() ?? 'default';
    if (_greetingCache.containsKey(ethnicity)) return _greetingCache[ethnicity]!;

    final ethnicGreetings = {
      "mossi": "Yaa soaba!",
      "peul": "Jam tan!",
      "gourmantche": "Diebu!",
      "bobo": "I ni ce!",
      "lobi": "A nɔɔnɛ!",
      "dagara": "Bɛɛ kɔɔ!",
      "senoufo": "Fo!",
      "samogo": "N bɛ se!",
      "dioula": "I ni sogoma!",
      "gourounsi": "N ba wa!",
      "bissa": "Fō!",
      "kassena": "Nie goa!",
      "marka": "Wa ka kenè!",
      "toussian": "Sɔgɔma!",
    };

    final greeting = ethnicGreetings[ethnicity] ?? "Bonjour !";
    _greetingCache[ethnicity] = greeting;
    return greeting;
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool hasVisual;
  final String? visualType;
  final List<Outfit>? outfits;
  final List<String>? suggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.hasVisual = false,
    this.visualType,
    this.outfits,
    this.suggestions,
  });
}

class AnimatedText extends StatefulWidget {
  final List<String> texts;
  final TextStyle? textStyle;
  final Duration duration;

  const AnimatedText({
    super.key,
    required this.texts,
    this.textStyle,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Correction pour éviter RangeError avec liste vide
    if (widget.texts.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final index = (value * widget.texts.length).floor() % widget.texts.length;

        if (index != _currentIndex) {
          _currentIndex = index;
        }

        return Text(
          widget.texts[_currentIndex],
          style: widget.textStyle,
        );
      },
    );
  }
}

// Écran principal amélioré
class FasoStyleScreen extends StatefulWidget {
  final UserProfile? currentUser;

  const FasoStyleScreen({super.key, this.currentUser});

  @override
  State<FasoStyleScreen> createState() => _FasoStyleScreenState();
}

class _FasoStyleScreenState extends State<FasoStyleScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final FocusNode _chatFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  final ConversationContext _conversationContext = ConversationContext();
  UserProfile? _detectedProfile;
  final BurkinabeOutfitGenerator _outfitGenerator = BurkinabeOutfitGenerator();
  final FasoStyleDatabase _styleDatabase = FasoStyleDatabase();
  late FasoStyleIntelligence _styleIntelligence;
  late AnimationController _typingController;
  late ConfettiController _confettiController;
  Map<String, dynamic> _contextMemory = {};
  bool _showContextualHelp = false;
  String? _activeTopic;
  final Map<String, DateTime> _topicTimestamps = {};
  DateTime? _lastConfettiTime; // Gestion du cooldown pour confetti

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _detectedProfile = widget.currentUser ?? UserProfile.defaultProfile();
    _styleIntelligence = FasoStyleIntelligence(_detectedProfile);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initiateContextualConversation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForContextualPrompt();
    }
  }

  void _initiateContextualConversation() {
    final now = TimeOfDay.now();
    String timeGreeting = "Bonjour";

    if (now.hour < 12) {
      timeGreeting = "Bon matin";
    } else if (now.hour < 18) {
      timeGreeting = "Bon après-midi";
    } else {
      timeGreeting = "Bonsoir";
    }

    final userName = _detectedProfile?.name ?? "Ami(e)";
    final greeting = _styleDatabase.getPersonalizedGreeting(_detectedProfile);

    _addBotMessage(
        "$timeGreeting $userName ! $greeting\n\n"
            "💬 Que souhaitez-vous explorer aujourd'hui ? "
            "Je peux vous aider à trouver une tenue adaptée à votre journée, "
            "vous donner des conseils de style, ou vous inspirer avec les dernières tendances burkinabées.",
        suggestions: [
          "Tenue pour aujourd'hui",
          "Conseils couleurs",
          "Idées pour une occasion spéciale",
          "Inspiration traditionnelle"
        ],
        delay: 1500
    );
  }

  void _checkForContextualPrompt() {
    final now = DateTime.now();
    final lastInteraction = _conversationContext.lastInteraction;

    if (lastInteraction != null &&
        now.difference(lastInteraction) > const Duration(minutes: 10)) {
      _addBotMessage(
          "Content de vous revoir ! Où en étions-nous ? "
              "Souhaitez-vous continuer à explorer ${_conversationContext.currentTopic ?? 'nos dernières suggestions'} ?",
          suggestions: ["Reprendre la discussion", "Nouveau sujet"],
          delay: 2000
      );
    }
  }

  void _sendChatMessage() {
    if (_chatController.text.trim().isEmpty) return;
    final message = _chatController.text.trim();
    _addUserMessage(message);
    _chatController.clear();

    _contextMemory = _analyzeMessageForContext(message, _contextMemory);
    _generateIntelligentResponse(message);
    _scrollToBottom();
  }

  Map<String, dynamic> _analyzeMessageForContext(String message, Map<String, dynamic> currentContext) {
    final lowerMsg = message.toLowerCase();
    Map<String, dynamic> newContext = {...currentContext};

    if (lowerMsg.contains(RegExp(r'\b(tenue|outfit|look|style|vêtement)\b'))) {
      newContext['topic'] = 'outfit_creation';
      _activeTopic = 'outfit_creation';
      _topicTimestamps[_activeTopic!] = DateTime.now();
    }

    if (lowerMsg.contains(RegExp(r'\b(couleur|teinte|nuance|coloris)\b'))) {
      newContext['topic'] = 'color_advice';
      _activeTopic = 'color_advice';
      _topicTimestamps[_activeTopic!] = DateTime.now();
    }

    final preferenceRegex = RegExp(r"\b(j'aime|j'adore|je préfère|je préfere|je préfère|je kiffe)\b", caseSensitive: false);

    if (preferenceRegex.hasMatch(lowerMsg)) {
      newContext['preferences'] ??= [];

      if (lowerMsg.contains(RegExp(r'\btraditionnel(le)?\b'))) {
        newContext['preferences'].add('traditional');
      }

      if (lowerMsg.contains(RegExp(r'\bmoderne\b'))) {
        newContext['preferences'].add('modern');
      }
    }

    return newContext;
  }

  void _generateIntelligentResponse(String userMessage) {
    setState(() => _isTyping = true);
    _analyzeUserMessageAdvanced(userMessage);

    Future.microtask(() async {
      await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(1200)));
      if (!mounted) return;

      final response = _styleIntelligence.generateResponse(
        userMessage,
        _detectedProfile?.season,
        _detectedProfile?.occasion,
      );

      if (response.intent != Intent.general) {
        _conversationContext.updateContext(response.intent.toString());
      }

      // Gestion du confetti avec cooldown de 5 secondes
      if (response.emotion == EmotionalState.satisfied &&
          _messages.length > 5 &&
          (_lastConfettiTime == null ||
              DateTime.now().difference(_lastConfettiTime!) > const Duration(seconds: 5))) {
        _confettiController.play();
        _lastConfettiTime = DateTime.now();
      }

      setState(() => _isTyping = false);
      _addBotMessage(
        response.text,
        hasVisual: response.hasVisual,
        visualType: response.visualType,
        outfits: response.outfits,
        suggestions: response.suggestions,
      );
      _scrollToBottom();
    });
  }

  void _analyzeUserMessageAdvanced(String message) {
    final lowerMessage = message.toLowerCase();
    setState(() {
      if (lowerMessage.contains(RegExp(r'\b(je suis.*homme|monsieur)\b'))) {
        _detectedProfile = _detectedProfile!.copyWith(gender: 'homme');
      } else if (lowerMessage.contains(RegExp(r'\b(je suis.*femme|madame)\b'))) {
        _detectedProfile = _detectedProfile!.copyWith(gender: 'femme');
      }

      if (lowerMessage.contains(RegExp(r'\b(mariage|noces)\b'))) {
        _detectedProfile = _detectedProfile!.copyWith(occasion: Occasion.wedding);
      } else if (lowerMessage.contains(RegExp(r'\b(funérailles|décès)\b'))) {
        _detectedProfile = _detectedProfile!.copyWith(occasion: Occasion.funeral);
      } else if (lowerMessage.contains(RegExp(r'\b(baptême)\b'))) {
        _detectedProfile = _detectedProfile!.copyWith(occasion: Occasion.baptism);
      }

      if (lowerMessage.contains(RegExp(r'\b(saison.*sèche)\b'))) {
        _detectedProfile = _detectedProfile!.copyWith(season: Season.dry);
      } else if (lowerMessage.contains(RegExp(r'\b(saison.*pluies)\b'))) {
        _detectedProfile = _detectedProfile!.copyWith(season: Season.rainy);
      }

      if (lowerMessage.contains(RegExp(r'\b(mossi)\b'))) {
        _detectedProfile = _detectedProfile!.copyWith(ethnicity: 'mossi');
      } else if (lowerMessage.contains(RegExp(r'\b(peul)\b'))) {
        _detectedProfile = _detectedProfile!.copyWith(ethnicity: 'peul');
      }

      _styleIntelligence.userProfile = _detectedProfile;
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _addBotMessage(String text, {
    bool hasVisual = false,
    String? visualType,
    List<Outfit>? outfits,
    List<String>? suggestions,
    int delay = 0,
  }) {
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        final message = ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
          hasVisual: hasVisual,
          visualType: visualType,
          outfits: outfits,
          suggestions: suggestions,
        );
        _messages.add(message);
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildVisualContent(String? visualType) {
    switch (visualType) {
      case 'welcome_burkina':
        return _buildWelcomeBurkinaVisual();
      case 'colors_burkina':
        return _buildBurkinaColorPalette();
      case 'outfit_suggestion':
        return _buildBurkinaOutfitVisual();
      case 'traditional_burkina':
        return _buildTraditionalBurkinaVisual();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeBurkinaVisual() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE74C3C), Color(0xFFF1C40F), Color(0xFF27AE60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text("🇧🇫 FASOSTYLE",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 15,
            runSpacing: 10,
            children: [
              _buildIconWithLabel("👨‍💼", "Homme", Colors.white),
              _buildIconWithLabel("👩‍💼", "Femme", Colors.white),
              _buildIconWithLabel("🌅", "Matin", Colors.white),
              _buildIconWithLabel("🌇", "Soir", Colors.white),
              _buildIconWithLabel("🎭", "Traditionnel", Colors.white),
              _buildIconWithLabel("🏢", "Moderne", Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBurkinaOutfitVisual() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildOutfitCard("👘", "Boubou", "Faso Dan Fani", const Color(0xFFE74C3C)),
          _buildOutfitCard("👗", "Robe", "Wax moderne", const Color(0xFFF1C40F)),
          _buildOutfitCard("👕", "Complet", "Coton local", const Color(0xFF27AE60)),
        ],
      ),
    );
  }

  Widget _buildBurkinaColorPalette() {
    const List<Color> burkinaColors = [
      Color(0xFFE74C3C),
      Color(0xFFF1C40F),
      Color(0xFF27AE60),
      Color(0xFF8B4513),
      Color(0xFFD2691E),
      Color(0xFF2E8B57),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🎨 COULEURS BURKINABÉ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: burkinaColors.map((color) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTraditionalBurkinaVisual() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 20,
        children: [
          _buildIconWithLabel("👑", "Chef Mossi", Colors.black),
          _buildIconWithLabel("🎭", "Masque", Colors.black),
          _buildIconWithLabel("🥁", "Tam-tam", Colors.black),
          _buildIconWithLabel("🏺", "Poterie", Colors.black),
        ],
      ),
    );
  }

  Widget _buildIconWithLabel(String icon, String label, [Color? textColor]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
            fontSize: 10,
            color: textColor ?? Colors.grey.shade600,
            fontWeight: FontWeight.w500
        )),
      ],
    );
  }

  Widget _buildOutfitCard(String icon, String title, String description, Color bgColor) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(description, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildOutfitVisuals(List<Outfit> outfits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text("👗 TENUES SUGGÉRÉES", style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue.shade800
        )),
        const SizedBox(height: 12),
        ...outfits.map((outfit) => _buildOutfitCardDetail(outfit)).toList(),
      ],
    );
  }

  IconData _getClothingIcon(ClothingType type) {
    switch (type) {
      case ClothingType.top: return Icons.checkroom;
      case ClothingType.bottom: return Icons.airline_seat_legroom_reduced;
      case ClothingType.shoes: return Icons.directions_walk;
      case ClothingType.accessory: return Icons.watch;
      case ClothingType.outerwear: return Icons.card_travel;
      case ClothingType.traditional: return Icons.flag;
      case ClothingType.headwear: return Icons.face_retouching_natural;
      default: return Icons.checkroom;
    }
  }

  Widget _buildOutfitCardDetail(Outfit outfit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (outfit.description != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                outfit.description!,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: outfit.items.map((item) => Chip(
              avatar: Icon(_getClothingIcon(item.type)),
              label: Text(item.name),
              backgroundColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text("Compatibilité: ${outfit.compatibilityScore.toStringAsFixed(1)}/100",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const Spacer(),
              ...List.generate(5, (index) => Icon(
                Icons.star,
                color: outfit.compatibilityScore > (index * 20) ? Colors.amber : Colors.grey.shade400,
                size: 16,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            _buildAnimatedAvatar(),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser && _detectedProfile?.name != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      _detectedProfile!.name!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(left: 8, right: 8),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? LinearGradient(colors: [Color(0xFFF1C40F).withOpacity(0.3), Color(0xFFE74C3C).withOpacity(0.1)])
                        : LinearGradient(colors: [Colors.grey.shade50, Colors.white]),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 20 : 4),
                      topRight: Radius.circular(isUser ? 4 : 20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? const Color(0xFFE74C3C) : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),

                if (message.suggestions != null && message.suggestions!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8, left: 8, right: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: message.suggestions!.map((suggestion) =>
                          ActionChip(
                            label: Text(suggestion),
                            backgroundColor: const Color(0xFF27AE60).withOpacity(0.1),
                            onPressed: () {
                              _chatController.text = suggestion;
                              _sendChatMessage();
                            },
                          )
                      ).toList(),
                    ),
                  ),

                if (message.hasVisual && message.visualType != null)
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: const EdgeInsets.only(left: 8, right: 8, top: 4),
                    child: _buildVisualContent(message.visualType),
                  ),
                if (message.outfits != null)
                  _buildOutfitVisuals(message.outfits!),
              ],
            ),
          ),
          if (isUser)
            _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAnimatedAvatar() {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_typingController.value * 0.1),
          child: child,
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFE74C3C), Color(0xFFF1C40F), Color(0xFF27AE60)],
          ),
        ),
        child: const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.transparent,
          child: Text("🇧🇫", style: TextStyle(fontSize: 20)),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFE74C3C), Color(0xFFF1C40F)],
        ),
      ),
      child: const CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(Icons.person, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: const Color(0xFFE74C3C),
            highlightColor: const Color(0xFFF1C40F),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE74C3C),
              child: Text("🇧🇫", style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedText(
                    texts: const [
                      "Je réfléchis à votre style...",
                      "Je consulte nos tendances...",
                      "Je prépare des suggestions...",
                    ],
                    textStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    duration: const Duration(seconds: 3),
                  ),
                  const SizedBox(width: 8),
                  _buildTypingDots(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAnimatedDot(0),
        _buildAnimatedDot(1),
        _buildAnimatedDot(2),
      ],
    );
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        final delay = index * 0.2;
        double value = (_typingController.value - delay).clamp(0.0, 1.0);
        // Correction pour éviter les valeurs NaN
        if (value.isNaN) value = 0.0;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -2 * value),
            child: child,
          ),
        );
      },
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: const BoxDecoration(
          color: Color(0xFFE74C3C),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  String _getContextualHelpTip() {
    if (_activeTopic == 'outfit_creation') {
      return "Astuce : Dites 'pour un mariage' ou 'pour le travail' pour des tenues plus spécifiques";
    } else if (_activeTopic == 'color_advice') {
      return "Astuce : Demandez 'quelles couleurs vont avec le rouge ?' pour des conseils d'assortiment";
    }
    return "Astuce : Dites 'aide' pour découvrir tout ce que je peux faire pour vous";
  }

  bool _showContextualPrompt() {
    return _messages.length > 3 &&
        _activeTopic != null &&
        _topicTimestamps[_activeTopic] != null &&
        DateTime.now().difference(_topicTimestamps[_activeTopic]!) > const Duration(minutes: 2);
  }

  Widget _buildContextualPrompt() {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text("Continuer sur ce sujet ?", style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(width: 8),
          ..._buildContextualActions(),
        ],
      ),
    );
  }

  List<Widget> _buildContextualActions() {
    switch (_activeTopic) {
      case 'outfit_creation':
        return [
          _buildContextualAction("Plus d'options", Icons.refresh),
          _buildContextualAction("Changer d'occasion", Icons.event),
        ];
      case 'color_advice':
        return [
          _buildContextualAction("Palette complète", Icons.palette),
          _buildContextualAction("Couleurs traditionnelles", Icons.flag),
        ];
      default:
        return [
          _buildContextualAction("Explorer les tendances", Icons.trending_up),
        ];
    }
  }

  Widget _buildContextualAction(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16),
        label: Text(text, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          _chatController.text = text;
          _sendChatMessage();
        },
      ),
    );
  }

  Widget _buildContextualHelpBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF27AE60).withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFF27AE60), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getContextualHelpTip(),
              style: const TextStyle(color: Color(0xFF27AE60)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _showContextualHelp = false),
          ),
        ],
      ),
    );
  }

  String _getInputHint() {
    if (_activeTopic == 'outfit_creation') {
      return "Ex: Tenue pour un mariage mossi en saison des pluies";
    } else if (_activeTopic == 'color_advice') {
      return "Ex: Quelles couleurs vont avec le rouge ?";
    }
    return "Parlez-moi de votre style ou posez une question...";
  }

  Widget _buildActiveTopicIndicator() {
    String topicText = "";
    Color topicColor = Colors.white;

    switch (_activeTopic) {
      case 'outfit_creation':
        topicText = "Création de tenue";
        topicColor = const Color(0xFFF1C40F);
        break;
      case 'color_advice':
        topicText = "Conseils couleurs";
        topicColor = const Color(0xFF27AE60);
        break;
      default:
        topicText = "Conversation";
        topicColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: topicColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: topicColor),
      ),
      child: Text(
        topicText,
        style: TextStyle(
          color: topicColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    // Correction pour éviter le RangeError sur substring
    final initial = _detectedProfile?.name?.isNotEmpty == true
        ? _detectedProfile!.name!.substring(0, 1)
        : "A";

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          initial,
          style: const TextStyle(color: Color(0xFFE74C3C)),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildIntelligentAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Text("🇧🇫"),
          const SizedBox(width: 8),
          const Text(
            "FasoStyle",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_activeTopic != null) ...[
            const SizedBox(width: 8),
            _buildActiveTopicIndicator(),
          ]
        ],
      ),
      backgroundColor: const Color(0xFFE74C3C),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE74C3C), Color(0xFFF1C40F), Color(0xFF27AE60)],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () => setState(() => _showContextualHelp = !_showContextualHelp),
          tooltip: "Aide contextuelle",
        ),
        _buildProfileAvatar(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: _buildIntelligentAppBar(),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF1C40F).withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              children: [
                if (_showContextualHelp) _buildContextualHelpBar(),
                if (_detectedProfile != null && _detectedProfile!.hasUserData())
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27AE60).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_pin, color: const Color(0xFF27AE60)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _detectedProfile!.getProfileSummary(),
                            style: TextStyle(
                              color: const Color(0xFF27AE60),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.clear, size: 18, color: const Color(0xFF27AE60)),
                          onPressed: () {
                            setState(() {
                              _detectedProfile = UserProfile.defaultProfile();
                              _conversationContext.updateContext('general');
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildChatBubble(_messages[index]);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE74C3C).withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_showContextualPrompt()) _buildContextualPrompt(),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1C40F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: const Color(0xFFF1C40F).withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: _chatController,
                                      focusNode: _chatFocusNode,
                                      decoration: InputDecoration(
                                        hintText: _getInputHint(),
                                        hintStyle: TextStyle(color: Colors.grey.shade500),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      minLines: 1,
                                      maxLines: 4,
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (_) => _sendChatMessage(),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.emoji_emotions, color: const Color(0xFFE74C3C)),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE74C3C), Color(0xFFF1C40F)],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE74C3C).withOpacity(0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              radius: 28,
                              child: IconButton(
                                icon: const Icon(Icons.send_rounded, color: Colors.white),
                                onPressed: _isTyping ? null : _sendChatMessage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFFE74C3C),
              Color(0xFFF1C40F),
              Color(0xFF27AE60),
              Colors.white,
            ],
          ),
        ),
      ],
    );
  }
}

// Exemple de garde-robe
final List<ClothingItem> sampleWardrobe = [
  ClothingItem(
    id: '1',
    name: 'Boubou Mossi',
    type: ClothingType.traditional,
    color: ColorPalette.indigo,
    seasons: [Season.dry, Season.rainy],
    occasions: [Occasion.wedding, Occasion.ceremony],
    warmthLevel: 2,
    compatibleColors: [ColorPalette.gold, ColorPalette.white],
    fabricType: 'Faso Dan Fani',
    culturalOrigin: 'mossi',
  ),
  ClothingItem(
    id: '2',
    name: 'Pagne Peul',
    type: ClothingType.bottom,
    color: ColorPalette.blue,
    seasons: [Season.dry, Season.rainy],
    occasions: [Occasion.casual, Occasion.party],
    warmthLevel: 1,
    compatibleColors: [ColorPalette.white, ColorPalette.yellow],
    fabricType: 'Bazin',
    culturalOrigin: 'peul',
  ),
  ClothingItem(
    id: '3',
    name: 'Chemise brodée',
    type: ClothingType.top,
    color: ColorPalette.white,
    seasons: [Season.dry, Season.rainy],
    occasions: [Occasion.business, Occasion.formal],
    warmthLevel: 2,
    compatibleColors: [ColorPalette.black, ColorPalette.navy],
  ),
];