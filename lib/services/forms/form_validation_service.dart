class FormValidationService {
  const FormValidationService._();

  static String? requiredText(
    String? value, {
    required String message,
    int minLength = 1,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.length < minLength) return message;
    if (_containsUnsafeText(normalized)) {
      return 'Retirez les scripts, liens techniques ou caractères non autorisés.';
    }
    return null;
  }

  static String? email(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'Ajoutez une adresse email.';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized);
    return ok ? null : 'Cette adresse email ne semble pas valide.';
  }

  static String? phone(String? value, {bool required = false}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return required ? 'Ajoutez un numéro de contact.' : null;
    }
    final digits = normalized.replaceAll(RegExp(r'[^0-9+]'), '');
    return digits.length >= 8 ? null : 'Ajoutez un numéro joignable.';
  }

  static String? price(String? value) {
    final normalized = value?.trim().replaceAll(',', '.') ?? '';
    if (normalized.isEmpty) return 'Ajoutez un prix pour informer le client.';
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) return 'Ajoutez un prix valide.';
    return null;
  }

  static String? stock(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'Ajoutez la quantité disponible.';
    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed < 0) return 'Ajoutez un stock valide.';
    return null;
  }

  static String? url(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return null;
    final uri = Uri.tryParse(normalized);
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (scheme != 'https' && scheme != 'http')) {
      return 'Ajoutez un lien valide.';
    }
    return null;
  }

  static String? city(String? value) {
    return requiredText(
      value,
      message: 'Ajoutez une ville pour améliorer la recherche locale.',
      minLength: 2,
    );
  }

  static String? description(String? value, {int minLength = 20}) {
    return requiredText(
      value,
      message: 'Ajoutez une description utile pour guider le client.',
      minLength: minLength,
    );
  }

  static bool _containsUnsafeText(String value) {
    final lower = value.toLowerCase();
    return value.contains('\u0000') ||
        lower.contains('<script') ||
        lower.contains('javascript:') ||
        lower.contains('data:text/html') ||
        lower.contains('data:application');
  }
}
