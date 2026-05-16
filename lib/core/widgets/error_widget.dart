import 'package:flutter/material.dart';

import '../../app/color_constants.dart';
import '../../main.dart';

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElegantStyle - Error',
      theme: ThemeData(
        primaryColor: ColorConstants.primary,
        scaffoldBackgroundColor: ColorConstants.background,
      ),
      home: Scaffold(
        backgroundColor: ColorConstants.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Impossible de démarrer l\'application : $error',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: ColorConstants.hint),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => main(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
