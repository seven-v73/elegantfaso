import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../design/app_icons.dart';

class InspirationItem {
  const InspirationItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.badge,
    required this.color,
    required this.icon,
    required this.data,
    required this.createdAt,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final String badge;
  final Color color;
  final IconData icon;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  String get searchText =>
      '$title $subtitle ${data.values.join(' ')}'.toLowerCase();

  factory InspirationItem.creation(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final images = data['images'];
    return InspirationItem(
      title: data['title']?.toString() ?? 'Création inspirante',
      subtitle: data['category']?.toString() ?? 'Création utilisateur',
      imageUrl:
          images is List && images.isNotEmpty
              ? images.first.toString()
              : data['imageUrl']?.toString() ?? '',
      badge: 'Création',
      color: const Color(0xFF7C3AED),
      icon: Icons.palette_rounded,
      data: data,
      createdAt: _date(data['createdAt']),
    );
  }

  factory InspirationItem.product(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return InspirationItem(
      title: data['name']?.toString() ?? 'Pièce du Salon',
      subtitle: data['category']?.toString() ?? 'Shopping',
      imageUrl: data['imageUrl']?.toString() ?? '',
      badge: data['type']?.toString() ?? 'Produit',
      color: const Color(0xFF0F766E),
      icon: AppIcons.boutique,
      data: data,
      createdAt: _date(data['createdAt']),
    );
  }

  factory InspirationItem.editorial(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return InspirationItem(
      title: data['title']?.toString() ?? 'Idée style',
      subtitle:
          data['summary']?.toString() ??
          data['category']?.toString() ??
          'Inspiration',
      imageUrl:
          data['imageUrl']?.toString() ?? data['coverUrl']?.toString() ?? '',
      badge: 'Idée',
      color: const Color(0xFF2563EB),
      icon: AppIcons.inspiration,
      data: data,
      createdAt: _date(data['createdAt'] ?? data['publishedAt']),
    );
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
