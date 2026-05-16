import 'package:flutter/material.dart';

import '../../app/routes.dart';

class ErrorScreen extends StatelessWidget {
  final String routeName;

  const ErrorScreen({super.key, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Erreur de Navigation'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Route non trouvée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'La route "$routeName" n\'existe pas dans la configuration de l\'application',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed:
                  () => Navigator.pushReplacementNamed(context, AppRoutes.auth),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
