import 'package:flutter/material.dart';

import '../widgets/createurs/featured_creators.dart';
import '../widgets/createurs/creator_categories.dart';
import '../widgets/createurs/creators_list.dart';

class CreateursTab extends StatelessWidget {
  const CreateursTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          FeaturedCreators(),
          CreatorCategories(),
          CreatorsList(),
        ],
      ),
    );
  }
}