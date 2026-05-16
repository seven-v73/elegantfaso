import 'dart:typed_data';

class TryOnResult {
  const TryOnResult({
    required this.success,
    this.data,
    required this.message,
    this.tryNext = false,
  });

  final bool success;
  final Uint8List? data;
  final String message;
  final bool tryNext;

  factory TryOnResult.fromMap(Map<String, dynamic> map) {
    return TryOnResult(
      success: map['success'] == true,
      data: map['data'] is Uint8List ? map['data'] as Uint8List : null,
      message: map['message']?.toString() ?? '',
      tryNext: map['tryNext'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'data': data,
      'message': message,
      'tryNext': tryNext,
    };
  }
}
