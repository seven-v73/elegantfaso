import 'package:flutter/material.dart';
import 'style_quiz.dart';
import 'community_screen.dart';

class StyleAdvisorSection extends StatelessWidget {
  const StyleAdvisorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFAB47BC), Color(0xFF5C6BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conseiller Style Personnel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Obtenez des conseils personnalisés',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StyleQuizScreen()),
                    );
                  },
                  icon: const Icon(Icons.quiz),
                  label: const Text('Quiz Style'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                  ),
                ),
              ),

              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CommunityScreen()),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Espace Communauté'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }
}