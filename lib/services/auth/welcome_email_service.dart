import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class WelcomeEmailService {
  WelcomeEmailService({FirebaseFirestore? firestore, Logger? logger})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _logger = logger ?? Logger();

  final FirebaseFirestore _firestore;
  final Logger _logger;

  Future<void> queueWelcomeEmail({
    required String uid,
    required String email,
    String? displayName,
    String? locale,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (uid.trim().isEmpty || normalizedEmail.isEmpty) return;

    final name = (displayName ?? '').trim();
    final greeting = name.isEmpty ? 'Bonjour,' : 'Bonjour $name,';
    final textBody = '''
$greeting

Bienvenue sur ElegantStyle.

ElegantStyle est votre espace mode pour découvrir des inspirations, sauvegarder vos envies, organiser votre style, contacter des créateurs et boutiques, et explorer des créations locales comme internationales.

Nous sommes ravis de vous accompagner dans une expérience mode simple, personnelle et ouverte sur le monde.

L'équipe ElegantStyle
''';

    final htmlBody = '''
<div style="font-family:Inter,Arial,sans-serif;line-height:1.6;color:#111827">
  <p>$greeting</p>
  <p><strong>Bienvenue sur ElegantStyle.</strong></p>
  <p>
    ElegantStyle est votre espace mode pour découvrir des inspirations,
    sauvegarder vos envies, organiser votre style, contacter des créateurs
    et boutiques, et explorer des créations locales comme internationales.
  </p>
  <p>
    Nous sommes ravis de vous accompagner dans une expérience mode simple,
    personnelle et ouverte sur le monde.
  </p>
  <p style="margin-top:24px">L'équipe ElegantStyle</p>
</div>
''';

    final mailRef = _firestore.collection('mail').doc('welcome_$uid');

    try {
      await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(mailRef);
        if (existing.exists) return;

        transaction.set(mailRef, {
          'to': [normalizedEmail],
          'message': {
            'subject': 'Bienvenue sur ElegantStyle',
            'text': textBody.trim(),
            'html': htmlBody.trim(),
          },
          'type': 'welcome',
          'userId': uid,
          'locale': locale ?? 'fr',
          'status': 'queued',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e, stack) {
      _logger.w(
        'Impossible de mettre en file l’email de bienvenue',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
