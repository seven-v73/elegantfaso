import 'package:flutter/material.dart';

class BoutiqueActivitiesScreen extends StatelessWidget {
  const BoutiqueActivitiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activités récentes'),
      ),
      body: const Center(
        child: Text('Historique des activités'),
      ),
    );
  }
}