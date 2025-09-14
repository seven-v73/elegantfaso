import 'package:flutter/material.dart';

class BoutiqueStatsCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const BoutiqueStatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                      : Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            isLoading
                ? LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            )
                : Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}