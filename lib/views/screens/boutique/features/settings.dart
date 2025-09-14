import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BoutiqueSettingsScreen extends StatefulWidget {
  const BoutiqueSettingsScreen({Key? key}) : super(key: key);

  @override
  _BoutiqueSettingsScreenState createState() => _BoutiqueSettingsScreenState();
}

class _BoutiqueSettingsScreenState extends State<BoutiqueSettingsScreen> {
  final String boutiqueId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isActive = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadBoutiqueData();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  Future<void> _loadBoutiqueData() async {
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(boutiqueId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _locationController.text = data['address'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _imageUrl = data['imageUrl'];
        _isActive = data['status'] == 'active';
      }
    } catch (e) {
      debugPrint('Error loading boutique data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLogoSection(),
            const SizedBox(height: 24),
            _buildFormField('Nom de la boutique', _nameController, Icons.store),
            const SizedBox(height: 16),
            _buildFormField('Description', _descriptionController, Icons.description, maxLines: 3),
            const SizedBox(height: 16),
            _buildFormField('Adresse', _locationController, Icons.location_on),
            const SizedBox(height: 16),
            _buildFormField('Téléphone', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildFormField('Email', _emailController, Icons.email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 24),
            _buildSwitchSetting('Boutique active', _isActive, (value) {
              setState(() => _isActive = value);
            }),
            const SizedBox(height: 16),
            _buildSwitchSetting('Notifications', true, (value) {}),
            const SizedBox(height: 16),
            _buildSwitchSetting('Paiements en ligne', false, (value) {}),
            const SizedBox(height: 32),
            _buildActionButton('Changer le mot de passe', Icons.lock, _changePassword),
            const SizedBox(height: 16),
            _buildActionButton('Se déconnecter', Icons.logout, _logout),
            const SizedBox(height: 16),
            _buildActionButton('Supprimer le compte', Icons.delete, _deleteAccount, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: ClipOval(
              child: _imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: _imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                ),
                errorWidget: (context, url, error) => const Icon(Icons.store),
              )
                  : Icon(Icons.store, size: 60, color: Colors.grey[400]),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 20),
                onPressed: _changeLogo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est requis';
        }
        return null;
      },
    );
  }

  Widget _buildSwitchSetting(String title, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6A11CB),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed, {bool isDestructive = false}) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: isDestructive ? Colors.white : null),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? Colors.red : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
    );

  }

  Future<void> _changeLogo() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('boutique_logos/$boutiqueId/logo_${DateTime.now().millisecondsSinceEpoch}');

      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('boutiques')
          .doc(boutiqueId)
          .update({'imageUrl': url});

      setState(() => _imageUrl = url);
    } catch (e) {
      debugPrint('Error changing logo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec du changement de logo')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(boutiqueId)
          .update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'status': _isActive ? 'active' : 'inactive',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres sauvegardés avec succès')),
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la sauvegarde')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changePassword() {
    // Implementation for changing password
  }

  void _logout() {
    // Implementation for logout
  }

  void _deleteAccount() {
    // Implementation for account deletion
  }
}