import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoutiqueSettingsScreen extends StatefulWidget {
  @override
  _BoutiqueSettingsScreenState createState() => _BoutiqueSettingsScreenState();
}

class _BoutiqueSettingsScreenState extends State<BoutiqueSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Paramètres')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text('Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          SwitchListTile(
            title: Text('Mode sombre'),
            value: _darkMode,
            onChanged: (value) => setState(() => _darkMode = value),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Changer le mot de passe'),
            onTap: _changePassword,
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Aide et support'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('À propos'),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    // Implémentez la logique de changement de mot de passe
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (Route<dynamic> route) => false
    );
  }
}