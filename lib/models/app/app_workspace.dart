import 'package:flutter/material.dart';

import '../../core/account_roles.dart';
import '../../design/app_icons.dart';
import '../../design/modern_design_system.dart';

enum AppWorkspace { publicSalon, client, creator, boutique, admin }

extension AppWorkspaceX on AppWorkspace {
  String get role {
    switch (this) {
      case AppWorkspace.publicSalon:
      case AppWorkspace.client:
        return AccountRoles.client;
      case AppWorkspace.creator:
        return AccountRoles.createur;
      case AppWorkspace.boutique:
        return AccountRoles.boutique;
      case AppWorkspace.admin:
        return AccountRoles.admin;
    }
  }

  String get label {
    switch (this) {
      case AppWorkspace.publicSalon:
        return 'Salon';
      case AppWorkspace.client:
        return 'Client';
      case AppWorkspace.creator:
        return 'Créateur';
      case AppWorkspace.boutique:
        return 'Boutique';
      case AppWorkspace.admin:
        return 'Admin';
    }
  }

  String get subtitle {
    switch (this) {
      case AppWorkspace.publicSalon:
        return 'Place publique mode';
      case AppWorkspace.client:
        return 'Style personnel, souhaits et commandes';
      case AppWorkspace.creator:
        return 'Atelier, créations, RDV et clients';
      case AppWorkspace.boutique:
        return 'Produits, commandes et visibilité';
      case AppWorkspace.admin:
        return 'Modération et gouvernance';
    }
  }

  IconData get icon {
    switch (this) {
      case AppWorkspace.publicSalon:
        return AppIcons.salon;
      case AppWorkspace.client:
        return AppIcons.profile;
      case AppWorkspace.creator:
        return AppIcons.creator;
      case AppWorkspace.boutique:
        return AppIcons.boutique;
      case AppWorkspace.admin:
        return AppIcons.admin;
    }
  }

  Color get accent {
    switch (this) {
      case AppWorkspace.publicSalon:
      case AppWorkspace.client:
        return ModernColors.primary;
      case AppWorkspace.creator:
        return ModernColors.creator;
      case AppWorkspace.boutique:
        return ModernColors.shop;
      case AppWorkspace.admin:
        return ModernColors.admin;
    }
  }

  String get route {
    switch (this) {
      case AppWorkspace.publicSalon:
      case AppWorkspace.client:
        return '/home';
      case AppWorkspace.creator:
        return '/creator-dashboard';
      case AppWorkspace.boutique:
        return '/shop-dashboard';
      case AppWorkspace.admin:
        return '/admin';
    }
  }

  static AppWorkspace fromRole(String? role) {
    switch (role) {
      case AccountRoles.admin:
        return AppWorkspace.admin;
      case AccountRoles.createur:
        return AppWorkspace.creator;
      case AccountRoles.boutique:
        return AppWorkspace.boutique;
      case AccountRoles.client:
      default:
        return AppWorkspace.client;
    }
  }
}
