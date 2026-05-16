import 'package:flutter/material.dart';

class DailyChallengeModel {
  final String id;
  final String title;
  final String subtitle;
  final String intent;
  final String pointCategory;
  final int points;
  final IconData icon;
  final bool completed;
  final String actionLabel;
  final String proofHint;

  const DailyChallengeModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.intent,
    this.pointCategory = 'style',
    required this.points,
    required this.icon,
    this.completed = false,
    this.actionLabel = 'Commencer',
    this.proofHint = 'Points après action réelle',
  });

  DailyChallengeModel copyWith({bool? completed}) {
    return DailyChallengeModel(
      id: id,
      title: title,
      subtitle: subtitle,
      intent: intent,
      pointCategory: pointCategory,
      points: points,
      icon: icon,
      completed: completed ?? this.completed,
      actionLabel: actionLabel,
      proofHint: proofHint,
    );
  }
}
