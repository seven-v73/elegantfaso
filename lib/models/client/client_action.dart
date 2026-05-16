import 'package:flutter/material.dart';

class ClientAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String intent;

  const ClientAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.intent,
  });
}
