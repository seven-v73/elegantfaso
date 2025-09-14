import 'package:googleapis/androidpublisher/v3.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class Produit {
  final String id;
  final String nom;
  final double prix;
  final String imageUrl;
  final String description;
  final int quantiteDisponible;
  final double? prixPromo;
  final List<String> categories;
  final double? noteMoyenne;
  final int nombreAvis;
  final DateTime dateCreation;
  final String? boutiqueId;

  Produit({
    required this.id,
    required this.nom,
    required this.prix,
    required this.imageUrl,
    required this.description,
    this.quantiteDisponible = 0,
    this.prixPromo,
    this.categories = const [],
    this.noteMoyenne,
    this.nombreAvis = 0,
    required this.dateCreation,
    this.boutiqueId,
  });

  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'] ?? '',
      nom: map['nom'] ?? 'Produit sans nom',
      prix: (map['prix'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      quantiteDisponible: (map['quantiteDisponible'] as int?) ?? 0,
      prixPromo: (map['prixPromo'] as num?)?.toDouble(),
      categories: List<String>.from(map['categories'] ?? []),
      noteMoyenne: (map['noteMoyenne'] as num?)?.toDouble(),
      nombreAvis: (map['nombreAvis'] as int?) ?? 0,
      dateCreation: map['dateCreation'] != null
        ? (map['dateCreation'] as firestore.Timestamp).toDate()
          : DateTime.now(),
      boutiqueId: map['boutiqueId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prix': prix,
      'imageUrl': imageUrl,
      'description': description,
      'quantiteDisponible': quantiteDisponible,
      'prixPromo': prixPromo,
      'categories': categories,
      'noteMoyenne': noteMoyenne,
      'nombreAvis': nombreAvis,
      'dateCreation': firestore.Timestamp.fromDate(dateCreation),
      'boutiqueId': boutiqueId,
    };
  }

  double get prixEffectif => prixPromo ?? prix;

  String get prixFormate {
    return prixPromo != null
        ? '${prix.toStringAsFixed(2)} € (-${((prix - prixPromo!) / prix * 100).toStringAsFixed(0)}%)'
        : '${prix.toStringAsFixed(2)} €';
  }
}