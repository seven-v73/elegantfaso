import 'package:flutter/material.dart';

enum SalonActionType {
  save,
  share,
  contact,
  buy,
  book,
  tryOn,
  similar,
  creator,
  tutorials,
}

class SalonAction {
  const SalonAction({
    required this.type,
    required this.label,
    required this.icon,
  });

  final SalonActionType type;
  final String label;
  final IconData icon;
}
