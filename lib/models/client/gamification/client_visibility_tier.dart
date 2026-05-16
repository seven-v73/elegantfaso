import 'package:flutter/material.dart';

import '../../../design/modern_design_system.dart';

class ClientVisibilityTier {
  const ClientVisibilityTier({
    required this.id,
    required this.label,
    required this.category,
    required this.minPoints,
    required this.nextPoints,
    required this.visibilityBoost,
    required this.recommendationWeight,
    required this.description,
    required this.color,
  });

  final String id;
  final String label;
  final String category;
  final int minPoints;
  final int nextPoints;
  final double visibilityBoost;
  final int recommendationWeight;
  final String description;
  final Color color;

  bool get isMaxLevel => nextPoints <= minPoints;

  double progressFor(int points) {
    if (isMaxLevel) return 1;
    final current = (points - minPoints).clamp(0, nextPoints - minPoints);
    return (current / (nextPoints - minPoints)).clamp(0, 1).toDouble();
  }

  int pointsToNext(int points) {
    if (isMaxLevel) return 0;
    return (nextPoints - points).clamp(0, nextPoints);
  }
}

class ClientVisibilityTiers {
  const ClientVisibilityTiers._();

  static const explorer = ClientVisibilityTier(
    id: 'explorer',
    label: 'Explorateur style',
    category: 'Visibilité douce',
    minPoints: 0,
    nextPoints: 600,
    visibilityBoost: 1,
    recommendationWeight: 10,
    description: 'Découvre la communauté et publie tes premières pièces.',
    color: ModernColors.client,
  );

  static const curator = ClientVisibilityTier(
    id: 'curator',
    label: 'Curateur attentif',
    category: 'Mise en avant légère',
    minPoints: 600,
    nextPoints: 1200,
    visibilityBoost: 1.25,
    recommendationWeight: 25,
    description: 'Tes annonces gagnent un peu plus de présence dans le Salon.',
    color: ModernColors.primary,
  );

  static const trusted = ClientVisibilityTier(
    id: 'trusted',
    label: 'Client de confiance',
    category: 'Recommandé',
    minPoints: 1200,
    nextPoints: 2500,
    visibilityBoost: 1.55,
    recommendationWeight: 45,
    description: 'Tes pièces remontent mieux dans les recommandations.',
    color: ModernColors.accent,
  );

  static const ambassador = ClientVisibilityTier(
    id: 'ambassador',
    label: 'Ambassadeur circulaire',
    category: 'Priorité communauté',
    minPoints: 2500,
    nextPoints: 2500,
    visibilityBoost: 1.9,
    recommendationWeight: 70,
    description: 'Tes annonces ont la meilleure visibilité organique.',
    color: ModernColors.rose,
  );

  static const values = [explorer, curator, trusted, ambassador];

  static ClientVisibilityTier fromPoints(int points) {
    if (points >= ambassador.minPoints) return ambassador;
    if (points >= trusted.minPoints) return trusted;
    if (points >= curator.minPoints) return curator;
    return explorer;
  }

  static ClientVisibilityTier fromId(String id) {
    return values.firstWhere((tier) => tier.id == id, orElse: () => explorer);
  }
}
