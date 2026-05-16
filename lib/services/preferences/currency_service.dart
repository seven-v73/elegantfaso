import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.label,
    required this.symbol,
    this.locale = 'fr_FR',
  });

  final String code;
  final String label;
  final String symbol;
  final String locale;
}

class CurrencyService {
  CurrencyService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const defaultCode = 'XOF';
  static const options = [
    CurrencyOption(code: 'XOF', label: 'Franc CFA BCEAO', symbol: 'FCFA'),
    CurrencyOption(code: 'XAF', label: 'Franc CFA CEMAC', symbol: 'FCFA'),
    CurrencyOption(code: 'EUR', label: 'Euro', symbol: '€', locale: 'fr_FR'),
    CurrencyOption(
      code: 'USD',
      label: 'Dollar US',
      symbol: r'$',
      locale: 'en_US',
    ),
    CurrencyOption(
      code: 'GBP',
      label: 'Livre sterling',
      symbol: '£',
      locale: 'en_GB',
    ),
    CurrencyOption(
      code: 'CAD',
      label: 'Dollar canadien',
      symbol: r'CA$',
      locale: 'en_CA',
    ),
    CurrencyOption(code: 'NGN', label: 'Naira', symbol: '₦', locale: 'en_NG'),
    CurrencyOption(code: 'GHS', label: 'Cedi', symbol: 'GH₵', locale: 'en_GH'),
    CurrencyOption(code: 'MAD', label: 'Dirham marocain', symbol: 'MAD'),
    CurrencyOption(
      code: 'ZAR',
      label: 'Rand sud-africain',
      symbol: 'R',
      locale: 'en_ZA',
    ),
  ];

  static CurrencyOption optionFor(String? code) {
    final normalized = normalize(code);
    return options.firstWhere(
      (option) => option.code == normalized,
      orElse: () => options.first,
    );
  }

  static String normalize(String? code) {
    final normalized = (code ?? '').trim().toUpperCase();
    if (normalized == 'FCFA' || normalized == 'CFA') return defaultCode;
    if (options.any((option) => option.code == normalized)) return normalized;
    return defaultCode;
  }

  static String format(num value, {String? code}) {
    final option = optionFor(code);
    return NumberFormat.currency(
      locale: option.locale,
      symbol: option.symbol,
      decimalDigits: value % 1 == 0 ? 0 : 2,
    ).format(value);
  }

  Future<String> currentUserCurrency() async {
    final user = _auth.currentUser;
    if (user == null) return defaultCode;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return currencyFromUserData(doc.data() ?? const {});
  }

  static String currencyFromUserData(Map<String, dynamic> data) {
    final shopProfile =
        data['shopProfile'] is Map
            ? Map<String, dynamic>.from(data['shopProfile'] as Map)
            : const <String, dynamic>{};
    final creatorProfile =
        data['creatorProfile'] is Map
            ? Map<String, dynamic>.from(data['creatorProfile'] as Map)
            : const <String, dynamic>{};
    return normalize(
      data['currency'] ??
          data['preferredCurrency'] ??
          shopProfile['currency'] ??
          creatorProfile['currency'],
    );
  }

  Future<void> updateCurrentUserCurrency(String code) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecté');
    final normalized = normalize(code);
    await _firestore.collection('users').doc(user.uid).set({
      'currency': normalized,
      'preferredCurrency': normalized,
      'shopProfile.currency': normalized,
      'creatorProfile.currency': normalized,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
