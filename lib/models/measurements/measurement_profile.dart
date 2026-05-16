import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementProfile {
  static const int totalExpectedFields = 12;

  final String userId;
  final Map<String, num> values;
  final String braSize;
  final String cup;
  final String bodyProfile;
  final String unitSystem;
  final String shoeUnit;
  final String visibility;
  final List<String> sharedWith;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MeasurementProfile({
    required this.userId,
    this.values = const {},
    this.braSize = '',
    this.cup = '',
    this.bodyProfile = '',
    this.unitSystem = 'cm',
    this.shoeUnit = 'EU',
    this.visibility = 'private',
    this.sharedWith = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory MeasurementProfile.empty(String userId) {
    return MeasurementProfile(userId: userId);
  }

  factory MeasurementProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MeasurementProfile.fromMap(doc.data() ?? const {}, doc.id);
  }

  factory MeasurementProfile.fromMap(Map<String, dynamic> data, String userId) {
    final rawValues = data['values'];
    final values = <String, num>{};

    if (rawValues is Map) {
      rawValues.forEach((key, value) {
        final parsed = _numFrom(value);
        if (parsed != null) values[key.toString()] = parsed;
      });
    }

    for (final key in _legacyNumericKeys) {
      final parsed = _numFrom(data[key]);
      if (parsed != null) values[key] = parsed;
    }

    return MeasurementProfile(
      userId:
          data['userId']?.toString() ?? data['user_id']?.toString() ?? userId,
      values: values,
      braSize:
          data['braSize']?.toString() ??
          data['taille_soutien_gorge']?.toString() ??
          '',
      cup: data['cup']?.toString() ?? data['bonnet']?.toString() ?? '',
      bodyProfile: data['bodyProfile']?.toString() ?? '',
      unitSystem: data['unitSystem']?.toString() ?? 'cm',
      shoeUnit: data['shoeUnit']?.toString() ?? 'EU',
      visibility: data['visibility']?.toString() ?? 'private',
      sharedWith: List<String>.from(data['sharedWith'] ?? const []),
      createdAt: _dateFrom(data['createdAt'] ?? data['created_at']),
      updatedAt: _dateFrom(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore({bool includeCreatedAt = false}) {
    return {
      'userId': userId,
      'values': values,
      'braSize': braSize.trim(),
      'cup': cup.trim(),
      'bodyProfile': bodyProfile,
      'unitSystem': unitSystem,
      'shoeUnit': shoeUnit,
      'visibility': visibility,
      'sharedWith': sharedWith,
      'completionRate': completionRate,
      'completedCount': completedCount,
      'updatedAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toSnapshotMap() {
    return {
      'userId': userId,
      'values': values,
      'braSize': braSize.trim(),
      'cup': cup.trim(),
      'bodyProfile': bodyProfile,
      'unitSystem': unitSystem,
      'shoeUnit': shoeUnit,
      'visibility': visibility,
      'sharedWith': sharedWith,
      'completionRate': completionRate,
      'completedCount': completedCount,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  MeasurementProfile copyWith({
    String? userId,
    Map<String, num>? values,
    String? braSize,
    String? cup,
    String? bodyProfile,
    String? unitSystem,
    String? shoeUnit,
    String? visibility,
    List<String>? sharedWith,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeasurementProfile(
      userId: userId ?? this.userId,
      values: values ?? this.values,
      braSize: braSize ?? this.braSize,
      cup: cup ?? this.cup,
      bodyProfile: bodyProfile ?? this.bodyProfile,
      unitSystem: unitSystem ?? this.unitSystem,
      shoeUnit: shoeUnit ?? this.shoeUnit,
      visibility: visibility ?? this.visibility,
      sharedWith: sharedWith ?? this.sharedWith,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get completedCount {
    var count = values.length;
    if (braSize.trim().isNotEmpty) count++;
    if (cup.trim().isNotEmpty) count++;
    if (bodyProfile.trim().isNotEmpty) count++;
    return count.clamp(0, totalExpectedFields);
  }

  double get completionRate {
    return completedCount / totalExpectedFields;
  }

  Map<String, dynamic> toShareSummary() {
    return {
      'completedCount': completedCount,
      'completionRate': completionRate,
      'unitSystem': unitSystem,
      'shoeUnit': shoeUnit,
      'bodyProfile': bodyProfile,
      'keys': values.keys.toList(),
      'hasBraInfo': braSize.isNotEmpty || cup.isNotEmpty,
    };
  }

  static const List<String> _legacyNumericKeys = [
    'tour_poitrine',
    'tour_taille',
    'tour_hanches',
    'tour_bras',
    'tour_cuisse',
    'longueur_bras',
    'longueur_jambe',
    'largeur_epaules',
    'tour_cou',
    'pointure',
  ];

  static num? _numFrom(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      final normalized = value.replaceAll(',', '.').trim();
      if (normalized.isEmpty) return null;
      return num.tryParse(normalized);
    }
    return null;
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class MeasurementShare {
  final String id;
  final String clientId;
  final String creatorId;
  final String creatorName;
  final String status;
  final DateTime? sharedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;

  const MeasurementShare({
    required this.id,
    required this.clientId,
    required this.creatorId,
    required this.creatorName,
    required this.status,
    this.sharedAt,
    this.expiresAt,
    this.revokedAt,
  });

  factory MeasurementShare.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MeasurementShare(
      id: doc.id,
      clientId:
          data['clientId']?.toString() ?? data['client_id']?.toString() ?? '',
      creatorId:
          data['creatorId']?.toString() ?? data['creator_id']?.toString() ?? '',
      creatorName:
          data['creatorName']?.toString() ??
          data['creator_name']?.toString() ??
          'Créateur',
      status: data['status']?.toString() ?? 'active',
      sharedAt: MeasurementProfile._dateFrom(
        data['sharedAt'] ?? data['shared_at'],
      ),
      expiresAt: MeasurementProfile._dateFrom(data['expiresAt']),
      revokedAt: MeasurementProfile._dateFrom(data['revokedAt']),
    );
  }
}
