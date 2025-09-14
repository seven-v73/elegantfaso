import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.green[700],
      unselectedItemColor: Colors.grey[600],
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Boutique'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Plus'),
      ],
    );
  }
}