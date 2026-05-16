import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';

import '../../../services/media/media_asset_service.dart';
import '../../../services/media/media_upload_service.dart';
import '../../../services/notifications/app_notification_service.dart';
import '../../../models/messages/conversation_context.dart';
import 'message_model.dart';
import 'product_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MediaUploadService _mediaUploadService = MediaUploadService();
  final MediaAssetService _mediaAssetService = MediaAssetService();
  final AppNotificationService _notificationService = AppNotificationService();
  final Uuid _uuid = const Uuid();

  // Générer un ID de conversation unique
  String genererIdConversation(
    String id1,
    String id2, {
    String role1 = 'client',
    String role2 = 'client',
    ConversationContext context = const ConversationContext(),
  }) {
    final actors = ['${id1}_$role1', '${id2}_$role2']..sort();
    final contextKey =
        context.id.isEmpty
            ? context.type
            : '${context.type}_${context.id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}';
    return 'conv_${actors[0]}_${actors[1]}_$contextKey';
  }

  // Vérifier et créer une conversation si nécessaire
  Future<void> verifierOuCreerConversation(
    String idConversation,
    List<String> participants, {
    Map<String, String> participantRoles = const {},
    Map<String, String> participantNames = const {},
    Map<String, String> participantPhotos = const {},
    ConversationContext context = const ConversationContext(),
    String status = ConversationStatuses.active,
  }) async {
    final docRef = _firestore.collection('conversations').doc(idConversation);
    final doc = await docRef.get();

    if (!doc.exists) {
      final compteurNonLu = {for (var id in participants) id: 0};
      final saisieEnCours = {for (var id in participants) id: false};

      await docRef.set({
        'participants': participants,
        'creeLe': FieldValue.serverTimestamp(),
        'misAJourLe': FieldValue.serverTimestamp(),
        'compteurNonLu': compteurNonLu,
        'dernierMessage': '',
        'typeDernierMessage': TypeMessage.texte.name,
        'saisieEnCours': saisieEnCours,
        'participantRoles': participantRoles,
        'participantNames': participantNames,
        'participantPhotos': participantPhotos,
        'context': context.toMap(),
        'contextType': context.type,
        'contextId': context.id,
        'contextTitle': context.title,
        'contextImage': context.imageUrl,
        'status': status,
        'archivedFor': [],
        'blockedFor': [],
      });
      return;
    }

    await docRef.set({
      if (participantRoles.isNotEmpty) 'participantRoles': participantRoles,
      if (participantNames.isNotEmpty) 'participantNames': participantNames,
      if (participantPhotos.isNotEmpty) 'participantPhotos': participantPhotos,
      if (context.hasContent) ...{
        'context': context.toMap(),
        'contextType': context.type,
        'contextId': context.id,
        'contextTitle': context.title,
        'contextImage': context.imageUrl,
      },
      'status': doc.data()?['status'] ?? status,
      'misAJourLe': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Méthode principale pour envoyer un message
  Future<void> envoyerMessage({
    required String idConversation,
    required String idDestinataire,
    required String contenu,
    required TypeMessage type,
    String? nomExpediteur,
    String? imageExpediteur,
    Map<String, dynamic>? metadonnees,
    String senderRole = 'client',
    String receiverRole = 'client',
    ConversationContext context = const ConversationContext(),
    Map<String, String> participantNames = const {},
    Map<String, String> participantPhotos = const {},
  }) async {
    final idExpediteur = _auth.currentUser?.uid;
    if (idExpediteur == null) throw "Utilisateur non connecté";

    await verifierOuCreerConversation(
      idConversation,
      [idExpediteur, idDestinataire],
      participantRoles: {
        idExpediteur: senderRole,
        idDestinataire: receiverRole,
      },
      participantNames: participantNames,
      participantPhotos: participantPhotos,
      context: context,
    );

    final idMessage = _uuid.v4();
    final horodatage = Timestamp.now();
    final batch = _firestore.batch();

    // Création du message
    final message = Message(
      id: idMessage,
      idConversation: idConversation,
      idExpediteur: idExpediteur,
      idDestinataire: idDestinataire,
      contenu: contenu,
      type: type,
      horodatage: horodatage,
      nomExpediteur: nomExpediteur,
      imageExpediteur: imageExpediteur,
      metadonnees: metadonnees,
      statut: MessageStatut.envoye,
      senderRole: senderRole,
      receiverRole: receiverRole,
    );

    batch.set(
      _firestore.collection('messages').doc(idMessage),
      message.toMap(),
    );

    // Mise à jour de la conversation
    final dernierMessage =
        type == TypeMessage.texte ? contenu : '[${_nomTypeMessage(type)}]';

    batch.update(_firestore.collection('conversations').doc(idConversation), {
      'dernierMessage': dernierMessage,
      'typeDernierMessage': type.name,
      'horodatageDernierMessage': horodatage,
      'idDernierExpediteur': idExpediteur,
      'misAJourLe': FieldValue.serverTimestamp(),
      'compteurNonLu.$idDestinataire': FieldValue.increment(1),
      'participantRoles.$idExpediteur': senderRole,
      'participantRoles.$idDestinataire': receiverRole,
      'status': ConversationStatuses.active,
      'archivedFor': FieldValue.arrayRemove([idExpediteur, idDestinataire]),
    });

    await batch.commit();

    await _creerNotificationMessage(
      idDestinataire: idDestinataire,
      nomExpediteur: nomExpediteur ?? 'Expéditeur',
      contenu: dernierMessage,
      idConversation: idConversation,
    );
  }

  Future<void> modifierMessage({
    required String messageId,
    required String contenu,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw StateError('Utilisateur non connecté');
    final ref = _firestore.collection('messages').doc(messageId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;
    if (data['idExpediteur'] != userId) {
      throw StateError('Modification non autorisée');
    }
    await ref.update({
      'contenu': contenu,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> supprimerMessage(String messageId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw StateError('Utilisateur non connecté');
    final ref = _firestore.collection('messages').doc(messageId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;
    if (data['idExpediteur'] != userId) {
      throw StateError('Suppression non autorisée');
    }
    await ref.update({
      'contenu': '',
      'statut': MessageStatut.supprime.name,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': userId,
    });
  }

  // Obtenir le nom du type de message
  String _nomTypeMessage(TypeMessage type) {
    return switch (type) {
      TypeMessage.image => 'Image',
      TypeMessage.video => 'Vidéo',
      TypeMessage.audio => 'Audio',
      TypeMessage.document => 'Document',
      TypeMessage.produit => 'Produit',
      TypeMessage.localisation => 'Localisation',
      _ => 'Message',
    };
  }

  Future<void> _creerNotificationMessage({
    required String idDestinataire,
    required String nomExpediteur,
    required String contenu,
    required String idConversation,
  }) async {
    try {
      await _notificationService.notifyMessage(
        recipientId: idDestinataire,
        senderName: nomExpediteur,
        preview: contenu,
        conversationId: idConversation,
      );
    } catch (e) {
      debugPrint("Erreur notification: $e");
    }
  }

  // Téléverser un fichier via le service média centralisé
  Future<String> televerserFichier(File fichier, TypeMessage type) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw StateError('Utilisateur non connecté');
      }
      final extension = _extensionFromPath(fichier.path);
      final nomFichier =
          '${type.name}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final folder = 'messages/$userId';
      final publicId = nomFichier.replaceAll(extension, '');

      final upload =
          type == TypeMessage.video
              ? await _mediaUploadService.uploadVideo(
                file: fichier,
                folder: folder,
                publicId: publicId,
              )
              : type == TypeMessage.image
              ? await _mediaUploadService.uploadImage(
                file: fichier,
                folder: folder,
                publicId: publicId,
              )
              : await _mediaUploadService.uploadFile(
                file: fichier,
                folder: folder,
                publicId: publicId,
              );
      await _mediaAssetService.recordUpload(
        upload: upload,
        ownerId: userId,
        ownerRole: 'client',
        usage: 'message_${type.name}',
        status: 'private',
        linkedCollection: 'conversations',
      );
      return type == TypeMessage.image ? upload.optimizedUrl : upload.url;
    } catch (e) {
      debugPrint("Erreur téléversement fichier: $e");
      rethrow;
    }
  }

  String _extensionFromPath(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  // Marquer les messages comme lus
  Future<void> marquerMessagesLus(String idConversation, String userId) async {
    final query =
        await _firestore
            .collection('messages')
            .where('idConversation', isEqualTo: idConversation)
            .where('idDestinataire', isEqualTo: userId)
            .where(
              'statut',
              whereIn: [MessageStatut.envoye.name, MessageStatut.delivre.name],
            )
            .limit(40)
            .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      final message = Message.fromMap(doc.data());
      if (!message.lusPar.contains(userId)) {
        batch.update(doc.reference, {
          'lusPar': FieldValue.arrayUnion([userId]),
          'statut': MessageStatut.lu.name,
        });
      }
    }

    await batch.commit();

    await _firestore.collection('conversations').doc(idConversation).set({
      'compteurNonLu.$userId': 0,
    }, SetOptions(merge: true));
  }

  // Effacer l'historique d'une conversation
  Future<void> effacerHistoriqueChat(String idConversation) async {
    final messages =
        await _firestore
            .collection('messages')
            .where('idConversation', isEqualTo: idConversation)
            .limit(500)
            .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    await _firestore.collection('conversations').doc(idConversation).delete();
  }

  Future<void> archiverConversation(
    String idConversation,
    String userId,
  ) async {
    await _firestore.collection('conversations').doc(idConversation).set({
      'archivedFor': FieldValue.arrayUnion([userId]),
      'misAJourLe': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> bloquerConversation(String idConversation, String userId) async {
    await _firestore.collection('conversations').doc(idConversation).set({
      'blockedFor': FieldValue.arrayUnion([userId]),
      'status': ConversationStatuses.blocked,
      'misAJourLe': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Obtenir le flux des messages
  Stream<QuerySnapshot> streamMessages(
    String idConversation, {
    int limit = 50,
  }) {
    return _firestore
        .collection('messages')
        .where('idConversation', isEqualTo: idConversation)
        .orderBy('horodatage', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Obtenir le flux des conversations
  Stream<QuerySnapshot> streamConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('misAJourLe', descending: true)
        .snapshots();
  }

  // Mettre à jour le statut de saisie en cours
  Future<void> mettreAJourStatutSaisie(
    String idConversation,
    String userId,
    bool estEnTrainDeTaper,
  ) async {
    await _firestore.collection('conversations').doc(idConversation).set({
      'saisieEnCours.$userId': estEnTrainDeTaper,
    }, SetOptions(merge: true));
  }

  // Télécharger un fichier depuis une URL
  Future<File> telechargerFichier(String url, String cheminDestination) async {
    try {
      final response = await http.get(Uri.parse(url));
      final fichier = File(cheminDestination);
      await fichier.writeAsBytes(response.bodyBytes);
      return fichier;
    } catch (e) {
      debugPrint("Erreur téléchargement fichier: $e");
      rethrow;
    }
  }

  // --- Méthodes spécifiques pour chaque type de média ---

  // Envoyer une image
  Future<void> envoyerImage({
    required String idConversation,
    required String idDestinataire,
    required File image,
    String? nomExpediteur,
    String? imageExpediteur,
    String senderRole = 'client',
    String receiverRole = 'client',
    ConversationContext context = const ConversationContext(),
    Map<String, String> participantNames = const {},
    Map<String, String> participantPhotos = const {},
  }) async {
    final url = await televerserFichier(image, TypeMessage.image);
    await envoyerMessage(
      idConversation: idConversation,
      idDestinataire: idDestinataire,
      contenu: url,
      type: TypeMessage.image,
      nomExpediteur: nomExpediteur,
      imageExpediteur: imageExpediteur,
      senderRole: senderRole,
      receiverRole: receiverRole,
      context: context,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
      metadonnees: {
        'nomFichier': path.basename(image.path),
        'taille': image.lengthSync(),
      },
    );
  }

  // Envoyer une vidéo
  Future<void> envoyerVideo({
    required String idConversation,
    required String idDestinataire,
    required File video,
    String? nomExpediteur,
    String? imageExpediteur,
  }) async {
    final url = await televerserFichier(video, TypeMessage.video);
    await envoyerMessage(
      idConversation: idConversation,
      idDestinataire: idDestinataire,
      contenu: url,
      type: TypeMessage.video,
      nomExpediteur: nomExpediteur,
      imageExpediteur: imageExpediteur,
      metadonnees: {
        'nomFichier': path.basename(video.path),
        'taille': video.lengthSync(),
        'duree': await _getVideoDuration(video),
      },
    );
  }

  // Obtenir la durée d'une vidéo
  Future<int> _getVideoDuration(File video) async {
    VideoPlayerController controller = VideoPlayerController.file(video);

    try {
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      return duration.inSeconds;
    } catch (e) {
      debugPrint("Erreur durée vidéo: $e");
      await controller.dispose();
      return 0;
    }
  }

  // Envoyer un document
  Future<void> envoyerDocument({
    required String idConversation,
    required String idDestinataire,
    required File fichier,
    required String nomFichier,
    String? nomExpediteur,
    String? imageExpediteur,
    String senderRole = 'client',
    String receiverRole = 'client',
    ConversationContext context = const ConversationContext(),
    Map<String, String> participantNames = const {},
    Map<String, String> participantPhotos = const {},
  }) async {
    final url = await televerserFichier(fichier, TypeMessage.document);
    await envoyerMessage(
      idConversation: idConversation,
      idDestinataire: idDestinataire,
      contenu: url,
      type: TypeMessage.document,
      nomExpediteur: nomExpediteur,
      imageExpediteur: imageExpediteur,
      senderRole: senderRole,
      receiverRole: receiverRole,
      context: context,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
      metadonnees: {
        'nomFichier': nomFichier,
        'taille': fichier.lengthSync(),
        'extension': path.extension(nomFichier).toLowerCase(),
      },
    );
  }

  // Envoyer un audio
  Future<void> envoyerAudio({
    required String idConversation,
    required String idDestinataire,
    required File audio,
    int? dureeSecondes,
    String? nomExpediteur,
    String? imageExpediteur,
    String senderRole = 'client',
    String receiverRole = 'client',
    ConversationContext context = const ConversationContext(),
    Map<String, String> participantNames = const {},
    Map<String, String> participantPhotos = const {},
  }) async {
    final url = await televerserFichier(audio, TypeMessage.audio);
    await envoyerMessage(
      idConversation: idConversation,
      idDestinataire: idDestinataire,
      contenu: url,
      type: TypeMessage.audio,
      nomExpediteur: nomExpediteur,
      imageExpediteur: imageExpediteur,
      senderRole: senderRole,
      receiverRole: receiverRole,
      context: context,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
      metadonnees: {
        'nomFichier': path.basename(audio.path),
        'taille': audio.lengthSync(),
        'duree': dureeSecondes,
      },
    );
  }

  // Envoyer un produit
  Future<void> envoyerProduit({
    required String idConversation,
    required String idDestinataire,
    required Produit produit,
    String? nomExpediteur,
    String? imageExpediteur,
    String senderRole = 'client',
    String receiverRole = 'client',
    ConversationContext context = const ConversationContext(),
    Map<String, String> participantNames = const {},
    Map<String, String> participantPhotos = const {},
  }) async {
    await envoyerMessage(
      idConversation: idConversation,
      idDestinataire: idDestinataire,
      contenu: produit.nom,
      type: TypeMessage.produit,
      nomExpediteur: nomExpediteur,
      imageExpediteur: imageExpediteur,
      senderRole: senderRole,
      receiverRole: receiverRole,
      context: context,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
      metadonnees: produit.toMap(),
    );
  }

  // Envoyer une localisation
  Future<void> envoyerLocalisation({
    required String idConversation,
    required String idDestinataire,
    required double latitude,
    required double longitude,
    String? adresse,
    String? nomExpediteur,
    String? imageExpediteur,
    String senderRole = 'client',
    String receiverRole = 'client',
    ConversationContext context = const ConversationContext(),
    Map<String, String> participantNames = const {},
    Map<String, String> participantPhotos = const {},
  }) async {
    await envoyerMessage(
      idConversation: idConversation,
      idDestinataire: idDestinataire,
      contenu: 'Position partagée',
      type: TypeMessage.localisation,
      nomExpediteur: nomExpediteur,
      imageExpediteur: imageExpediteur,
      senderRole: senderRole,
      receiverRole: receiverRole,
      context: context,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
      metadonnees: {
        'latitude': latitude,
        'longitude': longitude,
        'adresse': adresse,
      },
    );
  }

  // Enregistrer le token FCM
  Future<void> enregistrerTokenFCM(String userId) async {
    await _notificationService.syncDeviceToken(userId: userId);
  }

  // Mettre à jour la présence utilisateur
  Future<void> mettreAJourPresence(String userId, bool estEnLigne) async {
    await _firestore.collection('users').doc(userId).set({
      'isOnline': estEnLigne,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
