import 'package:flutter/material.dart';

class SalonQuickEntry {
  const SalonQuickEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.query,
    required this.target,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String query;
  final SalonQuickTarget target;
  final Color color;
}

enum SalonQuickTarget { shop, talents, inspiration, agenda, map, community }
