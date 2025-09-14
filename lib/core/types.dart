import 'package:flutter/material.dart';

class AppUserRoles {
  static const String client = 'client';
  static const String createur = 'createur';
  static const String boutique = 'boutique';
  static const String admin = 'admin';

  static String getDisplayName(String role) {
    switch (role) {
      case client: return 'Client';
      case createur: return 'Créateur';
      case boutique: return 'Boutique';
      case admin: return 'Admin';
      default: return '';
    }
  }

  static IconData getIcon(String role) {
    switch (role) {
      case client: return Icons.person;
      case createur: return Icons.brush;
      case boutique: return Icons.store;
      default: return Icons.error;
    }
  }
}