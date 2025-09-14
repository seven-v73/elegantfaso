import 'package:flutter/material.dart';

import '../widgets/inspiration/style_advisor_section.dart';
import '../widgets/inspiration/trending_looks.dart';
import '../widgets/inspiration/cultural_inspiration.dart';
import '../widgets/inspiration/fashion_tutorials.dart';
import '../widgets/inspiration/style_quiz.dart';
import '../widgets/inspiration/community_screen.dart';

class InspirationTab extends StatelessWidget {
  const InspirationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          StyleAdvisorSection(),
          TrendingLooks(),
          CulturalInspiration(),
          FashionTutorials(),
        ],
      ),
    );
  }
}