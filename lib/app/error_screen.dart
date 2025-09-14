import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String routeName;

  const ErrorScreen({
    Key? key,
    required this.routeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Une erreur est survenue',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Route: $routeName',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                        (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('Retour à l\'accueil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',
                          (Route<dynamic> route) => false,
                    );
                  }
                },
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}