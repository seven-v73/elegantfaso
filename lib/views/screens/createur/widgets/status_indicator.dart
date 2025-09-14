import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;

  const StatusIndicator({
    super.key,
    required this.isOnline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFF2A9D8F) : Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: isOnline
                      ? [
                    BoxShadow(
                      color: const Color(0xFF2A9D8F).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                      : null,
                ),
              ),
              Text(
                isOnline ? 'En ligne' : 'Hors ligne',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          Switch.adaptive(
            value: isOnline,
            onChanged: onChanged,
            activeColor: const Color(0xFF2A9D8F),
            activeTrackColor: const Color(0xFF2A9D8F).withOpacity(0.4),
            inactiveThumbColor: Colors.grey[300],
            inactiveTrackColor: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}