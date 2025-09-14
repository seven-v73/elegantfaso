import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4A6FA5).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF4A6FA5).withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF2D3436).withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6FA5),
                  foregroundColor: Colors.white,
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}