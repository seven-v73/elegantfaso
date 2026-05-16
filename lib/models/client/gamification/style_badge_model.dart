import 'package:flutter/material.dart';

class StyleBadgeModel {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final bool unlocked;

  const StyleBadgeModel({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.unlocked,
  });
}
