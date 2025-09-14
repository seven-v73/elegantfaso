import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeMessage { texte, image, video, audio, document, produit, localisation }
enum MessageStatut { envoye, delivre, lu }

class Message {
  final String id;
  final String idConversation;
  final String idExpediteur;
  final String idDestinataire;
  final String contenu;
  final TypeMessage type;
  final Timestamp horodatage;
  final MessageStatut statut;
  final String? nomExpediteur;
  final String? imageExpediteur;
  final Map<String, dynamic>? metadonnees;
  final List<String> lusPar;

  Message({
    required this.id,
    required this.idConversation,
    required this.idExpediteur,
    required this.idDestinataire,
    required this.contenu,
    required this.type,
    required this.horodatage,
    this.statut = MessageStatut.envoye,
    this.nomExpediteur,
    this.imageExpediteur,
    this.metadonnees,
    this.lusPar = const [],
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      idConversation: map['idConversation'] ?? '',
      idExpediteur: map['idExpediteur'] ?? '',
      idDestinataire: map['idDestinataire'] ?? '',
      contenu: map['contenu'] ?? '',
      type: TypeMessage.values.byName(map['type'] ?? 'texte'),
      horodatage: map['horodatage'] ?? Timestamp.now(),
      statut: MessageStatut.values.byName(map['statut'] ?? 'envoye'),
      nomExpediteur: map['nomExpediteur'],
      imageExpediteur: map['imageExpediteur'],
      metadonnees: map['metadonnees'] != null
          ? Map<String, dynamic>.from(map['metadonnees'])
          : null,
      lusPar: List<String>.from(map['lusPar'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idConversation': idConversation,
      'idExpediteur': idExpediteur,
      'idDestinataire': idDestinataire,
      'contenu': contenu,
      'type': type.name,
      'horodatage': horodatage,
      'statut': statut.name,
      'nomExpediteur': nomExpediteur,
      'imageExpediteur': imageExpediteur,
      'metadonnees': metadonnees,
      'lusPar': lusPar,
    };
  }

  bool estLuPar(String userId) => lusPar.contains(userId);
}