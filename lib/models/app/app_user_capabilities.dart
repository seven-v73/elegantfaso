import '../../core/account_roles.dart';

enum AppActionIntent {
  explore,
  save,
  share,
  contact,
  follow,
  buy,
  book,
  tryOn,
  publish,
  manageProduct,
  manageOrder,
  moderate,
}

class AppUserCapabilities {
  final String? userId;
  final String activeRole;
  final List<String> roles;
  final bool isAuthenticated;

  const AppUserCapabilities({
    required this.userId,
    required this.activeRole,
    required this.roles,
    required this.isAuthenticated,
  });

  factory AppUserCapabilities.guest() {
    return const AppUserCapabilities(
      userId: null,
      activeRole: AccountRoles.client,
      roles: [AccountRoles.client],
      isAuthenticated: false,
    );
  }

  bool hasRole(String role) => roles.contains(role);
  bool get canCreate => hasRole(AccountRoles.createur);
  bool get canSell => hasRole(AccountRoles.boutique);
  bool get isAdmin => hasRole(AccountRoles.admin);

  bool can(AppActionIntent action, {String? ownerId}) {
    switch (action) {
      case AppActionIntent.explore:
      case AppActionIntent.share:
        return true;
      case AppActionIntent.save:
      case AppActionIntent.follow:
      case AppActionIntent.tryOn:
        return isAuthenticated;
      case AppActionIntent.contact:
      case AppActionIntent.book:
        return isAuthenticated && !_isOwner(ownerId);
      case AppActionIntent.buy:
        return isAuthenticated && !_isOwner(ownerId);
      case AppActionIntent.publish:
        return isAuthenticated && canCreate;
      case AppActionIntent.manageProduct:
      case AppActionIntent.manageOrder:
        return isAuthenticated && canSell;
      case AppActionIntent.moderate:
        return isAuthenticated && isAdmin;
    }
  }

  String blockedReason(AppActionIntent action, {String? ownerId}) {
    if (!isAuthenticated && action != AppActionIntent.explore) {
      return 'Connectez-vous pour continuer.';
    }
    if (_isOwner(ownerId) &&
        (action == AppActionIntent.buy ||
            action == AppActionIntent.contact ||
            action == AppActionIntent.book)) {
      return 'Cette action est désactivée sur votre propre contenu.';
    }
    if (action == AppActionIntent.publish && !canCreate) {
      return 'Activez l’espace Créateur pour publier.';
    }
    if ((action == AppActionIntent.manageProduct ||
            action == AppActionIntent.manageOrder) &&
        !canSell) {
      return 'Activez l’espace Boutique pour gérer cette action.';
    }
    if (action == AppActionIntent.moderate && !isAdmin) {
      return 'Action réservée à l’administration.';
    }
    return 'Action indisponible.';
  }

  bool _isOwner(String? ownerId) {
    return ownerId != null && ownerId.isNotEmpty && ownerId == userId;
  }
}
