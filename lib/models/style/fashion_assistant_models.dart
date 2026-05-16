import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../measurements/measurement_profile.dart';
import '../wardrobe/wardrobe_item.dart';

class StyleSeason {
  final String id;
  final String name;
  final String climate;
  final String description;
  final List<String> colors;
  final List<String> fabrics;

  const StyleSeason({
    required this.id,
    required this.name,
    required this.climate,
    required this.description,
    this.colors = const [],
    this.fabrics = const [],
  });
}

class StyleOccasion {
  final String id;
  final String name;
  final String description;
  final int minBudget;
  final int maxBudget;
  final List<String> colors;

  const StyleOccasion({
    required this.id,
    required this.name,
    required this.description,
    required this.minBudget,
    required this.maxBudget,
    this.colors = const [],
  });
}

class ColorPalette {
  final String name;
  final int value;
  final String meaning;

  const ColorPalette({
    required this.name,
    required this.value,
    required this.meaning,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'value': value, 'meaning': meaning};
  }

  factory ColorPalette.fromMap(Map<String, dynamic> data) {
    return ColorPalette(
      name: data['name']?.toString() ?? '',
      value: (data['value'] as num?)?.toInt() ?? 0xFF0F766E,
      meaning: data['meaning']?.toString() ?? '',
    );
  }
}

class BudgetEstimate {
  final String label;
  final int amount;
  final String details;

  const BudgetEstimate({
    required this.label,
    required this.amount,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {'label': label, 'amount': amount, 'details': details};
  }

  factory BudgetEstimate.fromMap(Map<String, dynamic> data) {
    return BudgetEstimate(
      label: data['label']?.toString() ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      details: data['details']?.toString() ?? '',
    );
  }
}

class StyleContext {
  final String userId;
  final String prompt;
  final String gender;
  final String country;
  final String region;
  final String climate;
  final String cultureMode;
  final String currency;
  final StyleSeason season;
  final StyleOccasion occasion;
  final String imageStyle;
  final bool useWardrobe;
  final bool useMeasurements;
  final List<WardrobeItem> wardrobe;
  final MeasurementProfile? measurements;

  const StyleContext({
    required this.userId,
    required this.prompt,
    required this.gender,
    required this.country,
    required this.region,
    required this.climate,
    required this.cultureMode,
    required this.currency,
    required this.season,
    required this.occasion,
    required this.imageStyle,
    this.useWardrobe = true,
    this.useMeasurements = true,
    this.wardrobe = const [],
    this.measurements,
  });
}

class StyleUserContext {
  final String country;
  final String region;
  final String currency;
  final String styleProfile;
  final List<WardrobeItem> wardrobe;
  final MeasurementProfile? measurements;
  final GeneratedLook? latestLook;

  const StyleUserContext({
    this.country = 'Monde',
    this.region = 'Votre zone',
    this.currency = 'USD',
    this.styleProfile = 'Style personnel',
    this.wardrobe = const [],
    this.measurements,
    this.latestLook,
  });

  int get wardrobeCount => wardrobe.length;
  int get measurementPercent =>
      ((measurements?.completionRate ?? 0) * 100).round();
}

class GeneratedLook {
  final String id;
  final String title;
  final String prompt;
  final String consultation;
  final List<ColorPalette> palette;
  final List<BudgetEstimate> budget;
  final List<String> shoppingList;
  final List<String> culturalTips;
  final int score;
  final String currency;
  final String country;
  final String region;
  final String imageStyle;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final Map<String, dynamic>? imageMedia;
  final DateTime? createdAt;
  final bool favorite;

  const GeneratedLook({
    required this.id,
    required this.title,
    required this.prompt,
    required this.consultation,
    required this.palette,
    required this.budget,
    required this.shoppingList,
    required this.culturalTips,
    required this.score,
    required this.currency,
    required this.country,
    required this.region,
    required this.imageStyle,
    this.imageBytes,
    this.imageUrl,
    this.imageMedia,
    this.createdAt,
    this.favorite = false,
  });

  GeneratedLook copyWith({
    String? id,
    Uint8List? imageBytes,
    String? imageUrl,
    Map<String, dynamic>? imageMedia,
    bool? favorite,
  }) {
    return GeneratedLook(
      id: id ?? this.id,
      title: title,
      prompt: prompt,
      consultation: consultation,
      palette: palette,
      budget: budget,
      shoppingList: shoppingList,
      culturalTips: culturalTips,
      score: score,
      currency: currency,
      country: country,
      region: region,
      imageStyle: imageStyle,
      imageBytes: imageBytes ?? this.imageBytes,
      imageUrl: imageUrl ?? this.imageUrl,
      imageMedia: imageMedia ?? this.imageMedia,
      createdAt: createdAt,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toFirestore({bool includeCreatedAt = false}) {
    return {
      'title': title,
      'prompt': prompt,
      'consultation': consultation,
      'palette': palette.map((item) => item.toMap()).toList(),
      'budget': budget.map((item) => item.toMap()).toList(),
      'shoppingList': shoppingList,
      'culturalTips': culturalTips,
      'score': score,
      'currency': currency,
      'country': country,
      'region': region,
      'imageStyle': imageStyle,
      'imageUrl': imageUrl,
      'imageMedia': imageMedia,
      'favorite': favorite,
      'updatedAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory GeneratedLook.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return GeneratedLook(
      id: doc.id,
      title: data['title']?.toString() ?? 'Look généré',
      prompt: data['prompt']?.toString() ?? '',
      consultation: data['consultation']?.toString() ?? '',
      palette:
          (data['palette'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (item) => ColorPalette.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList(),
      budget:
          (data['budget'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (item) =>
                    BudgetEstimate.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList(),
      shoppingList: List<String>.from(data['shoppingList'] ?? const []),
      culturalTips: List<String>.from(data['culturalTips'] ?? const []),
      score: (data['score'] as num?)?.toInt() ?? 70,
      currency: data['currency']?.toString() ?? 'USD',
      country: data['country']?.toString() ?? 'Monde',
      region: data['region']?.toString() ?? '',
      imageStyle: data['imageStyle']?.toString() ?? 'editorial',
      imageUrl: data['imageUrl']?.toString(),
      imageMedia:
          data['imageMedia'] is Map
              ? Map<String, dynamic>.from(data['imageMedia'] as Map)
              : null,
      createdAt: _dateFrom(data['createdAt']),
      favorite: data['favorite'] == true,
    );
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
