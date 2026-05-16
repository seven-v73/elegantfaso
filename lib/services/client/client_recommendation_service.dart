import 'package:flutter/material.dart';

import '../../design/app_icons.dart';
import '../../design/modern_design_system.dart';
import '../../models/client/client_action.dart';
import '../../models/client/client_dashboard_summary.dart';

class ClientRecommendationService {
  List<ClientAction> buildActions(ClientDashboardSummary summary) {
    final actions = <ClientAction>[
      const ClientAction(
        id: 'salon',
        title: 'Explorer le Salon',
        subtitle: 'Produits, talents et inspirations',
        icon: AppIcons.salon,
        color: ModernColors.accent,
        intent: 'salon',
      ),
      const ClientAction(
        id: 'style_advice',
        title: 'Demander un conseil',
        subtitle: 'Avis style personnalisé',
        icon: AppIcons.style,
        color: ModernColors.primary,
        intent: 'style',
      ),
      const ClientAction(
        id: 'wardrobe',
        title: 'Ajouter une pièce',
        subtitle: 'Compléter ma garde-robe',
        icon: AppIcons.wardrobe,
        color: ModernColors.client,
        intent: 'wardrobe',
      ),
      const ClientAction(
        id: 'try_on',
        title: 'Essayer un look',
        subtitle: 'Visualiser avant de choisir',
        icon: Icons.view_in_ar_rounded,
        color: ModernColors.creator,
        intent: 'try_on',
      ),
    ];

    if (summary.measurementCompletion < 0.7) {
      actions.insert(
        1,
        const ClientAction(
          id: 'measurements',
          title: 'Compléter mes tailles',
          subtitle: 'Des conseils plus précis',
          icon: AppIcons.measurements,
          color: ModernColors.rose,
          intent: 'measurements',
        ),
      );
    }

    return actions.take(5).toList();
  }
}
