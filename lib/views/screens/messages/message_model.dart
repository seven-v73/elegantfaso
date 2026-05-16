import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeMessage { texte, image, video, audio, document, produit, localisation }

enum MessageStatut { envoye, delivre, lu, supprime }

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
  final String senderRole;
  final String receiverRole;
  final Timestamp? editedAt;
  final Timestamp? deletedAt;
  final String? deletedBy;

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
    this.senderRole = 'client',
    this.receiverRole = 'client',
    this.editedAt,
    this.deletedAt,
    this.deletedBy,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    TypeMessage parseType(dynamic value) {
      final raw = value?.toString() ?? TypeMessage.texte.name;
      return TypeMessage.values.firstWhere(
        (type) => type.name == raw,
        orElse: () => TypeMessage.texte,
      );
    }

    MessageStatut parseStatus(dynamic value) {
      final raw = value?.toString() ?? MessageStatut.envoye.name;
      return MessageStatut.values.firstWhere(
        (status) => status.name == raw,
        orElse: () => MessageStatut.envoye,
      );
    }

    return Message(
      id: map['id'] ?? '',
      idConversation: map['idConversation'] ?? '',
      idExpediteur: map['idExpediteur'] ?? '',
      idDestinataire: map['idDestinataire'] ?? '',
      contenu: map['contenu'] ?? '',
      type: parseType(map['type']),
      horodatage: map['horodatage'] ?? Timestamp.now(),
      statut: parseStatus(map['statut']),
      nomExpediteur: map['nomExpediteur'],
      imageExpediteur: map['imageExpediteur'],
      metadonnees:
          map['metadonnees'] != null
              ? Map<String, dynamic>.from(map['metadonnees'])
              : null,
      lusPar: List<String>.from(map['lusPar'] ?? []),
      senderRole: map['senderRole']?.toString() ?? 'client',
      receiverRole: map['receiverRole']?.toString() ?? 'client',
      editedAt: map['editedAt'] as Timestamp?,
      deletedAt: map['deletedAt'] as Timestamp?,
      deletedBy: map['deletedBy']?.toString(),
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
      'senderRole': senderRole,
      'receiverRole': receiverRole,
      'editedAt': editedAt,
      'deletedAt': deletedAt,
      'deletedBy': deletedBy,
    };
  }

  bool estLuPar(String userId) => lusPar.contains(userId);
  bool get isDeleted => statut == MessageStatut.supprime || deletedAt != null;
  bool get isEdited => editedAt != null && !isDeleted;
}
