import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';

import 'user_model.dart';
import 'message_model.dart';
import 'product_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _stockage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Uuid _uuid = const Uuid();

  // Générer un ID de conversation unique
  String genererIdConversation(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return 'conv_${ids[0]}_${ids[1]}';
  }

  // Vérifier et créer une conversation si nécessaire
  Future<void> verifierOuCreerConversation(
      String idConversation,
      List<String> participants,
      ) async {
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
      });
    }
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
  }) async {
    final idExpediteur = _auth.currentUser?.uid;
    if (idExpediteur == null) throw "Utilisateur non connecté";

    await verifierOuCreerConversation(idConversation, [idExpediteur, idDestinataire]);

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
    );

    batch.set(
      _firestore.collection('messages').doc(idMessage),
      message.toMap(),
    );

    // Mise à jour de la conversation
    final dernierMessage = type == TypeMessage.texte
        ? contenu
        : '[${_nomTypeMessage(type)}]';

    batch.update(
      _firestore.collection('conversations').doc(idConversation),
      {
        'dernierMessage': dernierMessage,
        'typeDernierMessage': type.name,
        'horodatageDernierMessage': horodatage,
        'idDernierExpediteur': idExpediteur,
        'misAJourLe': FieldValue.serverTimestamp(),
        'compteurNonLu.$idDestinataire': FieldValue.increment(1),
      },
    );

    await batch.commit();

    await _envoyerNotificationPush(
      idDestinataire,
      nomExpediteur ?? 'Expéditeur',
      dernierMessage,
      type,
      idConversation,
    );
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

  // Envoyer une notification push
  Future<void> _envoyerNotificationPush(
      String idDestinataire,
      String nomExpediteur,
      String contenu,
      TypeMessage type,
      String idConversation,
      ) async {
    try {
      final doc = await _firestore.collection('utilisateurs').doc(idDestinataire).get();
      if (!doc.exists) return;

      final token = doc.get('fcmToken') as String?;
      if (token == null || token.isEmpty) return;

      final titre = switch (type) {
        TypeMessage.produit => "Nouveau produit partagé",
        TypeMessage.localisation => "Localisation reçue",
        _ => "Message de $nomExpediteur",
      };

      final corps = switch (type) {
        TypeMessage.produit => "$nomExpediteur a partagé un produit avec vous",
        TypeMessage.localisation => "$nomExpediteur a partagé sa position",
        _ => contenu.length > 100 ? "${contenu.substring(0, 100)}..." : contenu,
      };

      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=VOTRE_CLE_FCM',
        },
        body: jsonEncode({
          'to': token,
          'priority': 'high',
          'notification': {
            'title': titre,
            'body': corps,
            'sound': 'default',
            'badge': '1',
          },
          'data': {
            'type': 'message',
            'conversationId': idConversation,
            'senderId': _auth.currentUser?.uid,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          }
        }),
      );
    } catch (e) {
      debugPrint("Erreur notification: $e");
    }
  }

  // Téléverser un fichier sur Firebase Storage
  Future<String> televerserFichier(File fichier, TypeMessage type) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      final extension = path.extension(fichier.path).toLowerCase();
      final nomFichier = '${type.name}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final ref = _stockage.ref().child('chat/$userId/$nomFichier');

      final metadata = SettableMetadata(
        contentType: _getMimeType(type, extension),
      );

      final task = ref.putFile(fichier, metadata);
      final snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Erreur téléversement fichier: $e");
      rethrow;
    }
  }

  // Obtenir le type MIME selon le type de fichier
  String? _getMimeType(TypeMessage type, String extension) {
    switch (type) {
      case TypeMessage.image:
        return switch (extension) {
          '.jpg' || '.jpeg' => 'image/jpeg',
          '.png' => 'image/png',
          '.gif' => 'image/gif',
          '.webp' => 'image/webp',
          _ => 'image/*',
        };
      case TypeMessage.video:
        return switch (extension) {
          '.mp4' => 'video/mp4',
          '.mov' => 'video/quicktime',
          '.avi' => 'video/x-msvideo',
          '.mkv' => 'video/x-matroska',
          _ => 'video/*',
        };
      case TypeMessage.audio:
        return switch (extension) {
          '.mp3' => 'audio/mpeg',
          '.wav' => 'audio/wav',
          '.ogg' => 'audio/ogg',
          '.m4a' => 'audio/mp4',
          _ => 'audio/*',
        };
      case TypeMessage.document:
        return switch (extension) {
          '.pdf' => 'application/pdf',
          '.doc' => 'application/msword',
          '.docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          '.xls' => 'application/vnd.ms-excel',
          '.xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          '.ppt' => 'application/vnd.ms-powerpoint',
          '.pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
          '.txt' => 'text/plain',
          '.zip' => 'application/zip',
          _ => 'application/octet-stream',
        };
      default:
        return null;
    }
  }

  // Marquer les messages comme lus
  Future<void> marquerMessagesLus(String idConversation, String userId) async {
    final query = await _firestore
        .collection('messages')
        .where('idConversation', isEqualTo: idConversation)
        .where('idDestinataire', isEqualTo: userId)
        .where('statut', whereIn: [MessageStatut.envoye.name, MessageStatut.delivre.name])
        .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      final message = Message.fromMap(doc.data() as Map<String, dynamic>);
      if (!message.lusPar.contains(userId)) {
        batch.update(doc.reference, {
          'lusPar': FieldValue.arrayUnion([userId]),
          'statut': MessageStatut.lu.name,
        });
      }
    }

    await batch.commit();

    await _firestore.collection('conversations').doc(idConversation).update({
      'compteurNonLu.$userId': 0,
    });
  }

  // Effacer l'historique d'une conversation
  Future<void> effacerHistoriqueChat(String idConversation) async {
    final messages = await _firestore
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

  // Obtenir le flux des messages
  Stream<QuerySnapshot> streamMessages(String idConversation, {int limit = 100}) {
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
    await _firestore.collection('conversations').doc(idConversation).update({
      'saisieEnCours.$userId': estEnTrainDeTaper,
    });
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
  }) async {
    final url = await televerserFichier(image, TypeMessage.image);
    await envoyerMessage(
      idConversation: idConversation,
      idDestinataire: idDestinataire,
      contenu: url,
      type: TypeMessage.image,
      nomExpediteur: nomExpediteur,
      imageExpediteur: imageExpediteur,
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
  }) async {
    final url = await televerserFichier(fichier, TypeMessage.document);
    await envoyerMessage(
      idConversation: idConversation,
      idDestinataire: idDestinataire,
      contenu: url,
      type: TypeMessage.document,
      nomExpediteur: nomExpediteur,
      imageExpediteur: imageExpediteur,
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
  }) async {
    final url = await televerserFichier(audio, TypeMessage.audio);
    await envoyerMessage(
      idConversation: idConversation,
      idDestinataire: idDestinataire,
      contenu: url,
      type: TypeMessage.audio,
      nomExpediteur: nomExpediteur,
      imageExpediteur: imageExpediteur,
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
  }) async {
    await envoyerMessage(
      idConversation: idConversation,
      idDestinataire: idDestinataire,
      contenu: produit.nom,
      type: TypeMessage.produit,
      nomExpediteur: nomExpediteur,
      imageExpediteur: imageExpediteur,
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
  }) async {
    await envoyerMessage(
      idConversation: idConversation,
      idDestinataire: idDestinataire,
      contenu: 'Position partagée',
      type: TypeMessage.localisation,
      nomExpediteur: nomExpediteur,
      imageExpediteur: imageExpediteur,
      metadonnees: {
        'latitude': latitude,
        'longitude': longitude,
        'adresse': adresse,
      },
    );
  }

  // Enregistrer le token FCM
  Future<void> enregistrerTokenFCM(String userId) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('utilisateurs').doc(userId).update({
        'fcmToken': token,
      });
    }
  }

  // Mettre à jour la présence utilisateur
  Future<void> mettreAJourPresence(String userId, bool estEnLigne) async {
    await _firestore.collection('utilisateurs').doc(userId).update({
      'isOnline': estEnLigne,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}