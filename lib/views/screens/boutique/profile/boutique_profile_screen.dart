import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class BoutiqueProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const BoutiqueProfileScreen({Key? key, this.onLogout}) : super(key: key);

  @override
  _BoutiqueProfileScreenState createState() => _BoutiqueProfileScreenState();
}

class _BoutiqueProfileScreenState extends State<BoutiqueProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _specialityController;

  File? _imageFile;
  String? _photoUrl;
  bool _isLoading = false;
  bool _isEditing = false;

  // Nouvelles variables pour spécialités et paiements
  List<String> _selectedSpecialities = [];
  Map<String, String> _paymentMethods = {}; // Méthode -> Numéro

  final List<String> _availablePaymentMethods = [
    'Orange Money',
    'Moov Money'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfile();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _descriptionController = TextEditingController();
    _specialityController = TextEditingController();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?['role'] == 'boutique') {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? user.email ?? '';
        _phoneController.text = data['phone'] ?? '';
        _addressController.text = data['address'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _photoUrl = data['photoUrl'];

        // Charger spécialités
        if (data['specialities'] != null) {
          _selectedSpecialities = List<String>.from(data['specialities']);
        }

        // Charger méthodes de paiement
        if (data['paymentMethods'] != null) {
          _paymentMethods = Map<String, String>.from(data['paymentMethods']);
        }
      }
    } catch (e) {
      _showErrorSnackbar('Erreur de chargement: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildProfileForm(),
                  const SizedBox(height: 24),
                  _buildSpecialitiesSection(),
                  const SizedBox(height: 24),
                  _buildPaymentMethodsSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Boutons fixés en bas mais au-dessus de la barre de navigation
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: SafeArea(
              top: false,
              child: _buildActionButtons(),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 2,
      backgroundColor: Colors.white,
      title: const Text(
        'Profil de la Boutique',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 20,
        ),
      ),
      actions: [
        if (!_isEditing)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.deepPurple,
                  size: 20,
                ),
              ),
              onPressed: () => setState(() => _isEditing = true),
            ),
          ),
        if (_isEditing)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              onPressed: _cancelEditing,
            ),
          ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : _photoUrl != null && _photoUrl!.isNotEmpty
                    ? Image.network(_photoUrl!, fit: BoxFit.cover)
                    : Container(
                  color: Colors.deepPurple[50],
                  child: const Icon(
                    Icons.store,
                    size: 50,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),
            if (_isEditing)
              Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                  onPressed: _pickImage,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _nameController.text.isNotEmpty
              ? _nameController.text
              : 'Ma Boutique',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (_emailController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _emailController.text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Nom de la boutique',
          icon: Icons.store,
          enabled: _isEditing,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          enabled: false,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Téléphone',
          icon: Icons.phone,
          enabled: _isEditing,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Adresse',
          icon: Icons.location_on,
          enabled: _isEditing,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description',
          icon: Icons.description,
          enabled: _isEditing,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled
            ? [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: enabled ? Colors.deepPurple : Colors.grey,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.deepPurple.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.deepPurple,
              width: 2,
            ),
          ),
          labelStyle: TextStyle(
            color: enabled ? Colors.deepPurple : Colors.grey,
          ),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
      ),
    );
  }

  Widget _buildSpecialitiesSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.category, color: Colors.deepPurple, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Spécialités',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              const Text(
                'Ajoutez vos spécialités:',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _specialityController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Vêtements Femme, Chaussures...',
                          prefixIcon: const Icon(Icons.add, color: Colors.deepPurple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onFieldSubmitted: _addSpeciality,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _addSpeciality(_specialityController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text(
                        'Ajouter',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_selectedSpecialities.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Aucune spécialité ajoutée',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedSpecialities.map((speciality) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.withOpacity(0.1),
                          Colors.deepPurple.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Chip(
                      label: Text(
                        speciality,
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                      deleteIcon: _isEditing
                          ? const Icon(Icons.close, size: 18, color: Colors.deepPurple)
                          : null,
                      onDeleted: _isEditing
                          ? () => _removeSpeciality(speciality)
                          : null,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payment, color: Colors.deepPurple, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Méthodes de Paiement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._availablePaymentMethods.map((method) {
              return _buildPaymentMethodField(method);
            }).toList(),
            if (!_isEditing && _paymentMethods.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Aucune méthode de paiement configurée',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodField(String method) {
    final currentNumber = _paymentMethods[method] ?? '';
    final isConfigured = currentNumber.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: method == 'Orange Money'
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  method == 'Orange Money' ? Icons.phone_android : Icons.phone_iphone,
                  color: method == 'Orange Money' ? Colors.orange : Colors.green,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                method,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              if (isConfigured && !_isEditing)
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Configuré',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isEditing)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                initialValue: currentNumber,
                decoration: InputDecoration(
                  hintText: 'Ex: 70 XX XX XX XX',
                  prefixIcon: const Icon(Icons.phone, color: Colors.deepPurple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  if (value.trim().isEmpty) {
                    _paymentMethods.remove(method);
                  } else {
                    _paymentMethods[method] = value.trim();
                  }
                },
              ),
            )
          else if (isConfigured)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    currentNumber,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isEditing)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurpleAccent],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'SAUVEGARDER',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        if (_isEditing) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _handleLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'DÉCONNEXION',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la sélection de l\'image: ${e.toString()}');
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      String? newPhotoUrl = _photoUrl;

      // Upload nouvelle image si sélectionnée
      if (_imageFile != null) {
        final ref = _storage.ref().child(
            'users/${_auth.currentUser!.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = await ref.putFile(_imageFile!);
        newPhotoUrl = await uploadTask.ref.getDownloadURL();
      }

      // Mise à jour des données avec nouveaux champs
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'photoUrl': newPhotoUrl,
        'specialities': _selectedSpecialities,
        'paymentMethods': _paymentMethods,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackbar('Profil mis à jour avec succès');
      setState(() {
        _isEditing = false;
        _photoUrl = newPhotoUrl;
        _imageFile = null;
      });
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la sauvegarde: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _imageFile = null;
      _specialityController.clear();
      _loadProfile();
    });
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Déconnexion'),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        setState(() => _isLoading = true);
        await _auth.signOut();
        widget.onLogout?.call();
      } catch (e) {
        _showErrorSnackbar('Erreur lors de la déconnexion: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _addSpeciality(String speciality) {
    if (speciality.trim().isNotEmpty && !_selectedSpecialities.contains(speciality.trim())) {
      setState(() {
        _selectedSpecialities.add(speciality.trim());
        _specialityController.clear();
      });
    }
  }

  void _removeSpeciality(String speciality) {
    setState(() {
      _selectedSpecialities.remove(speciality);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _specialityController.dispose();
    super.dispose();
  }
}