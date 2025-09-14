import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elegantfaso/models/boutique/boutique_product.dart';
import 'dart:io';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _stockController;

  File? _imageFile;
  String? _imageUrl;
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Vêtements',
    'Accessoires',
    'Chaussures',
    'Tissus',
    'Bijoux'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _stockController = TextEditingController(text: '1');
    _selectedCategory = _categories[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ajouter un produit')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : _imageUrl != null
                      ? Image.network(_imageUrl!, fit: BoxFit.cover)
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 50),
                      Text('Ajouter une photo'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nom du produit'),
                validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                decoration: InputDecoration(labelText: 'Catégorie'),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Prix (FCFA)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Champ obligatoire';
                  if (double.tryParse(value) == null) return 'Prix invalide';
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(labelText: 'Quantité en stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Champ obligatoire';
                  if (int.tryParse(value) == null) return 'Quantité invalide';
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('ENREGISTRER LE PRODUIT'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Upload image if selected
        if (_imageFile != null) {
          final ref = _storage.ref().child(
              'products/${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}'
          );
          await ref.putFile(_imageFile!);
          _imageUrl = await ref.getDownloadURL();
        }

        // Save product data
        await _firestore.collection('products').add({
          'name': _nameController.text,
          'category': _selectedCategory,
          'price': double.parse(_priceController.text),
          'description': _descriptionController.text,
          'stock': int.parse(_stockController.text),
          'boutiqueId': FirebaseAuth.instance.currentUser!.uid,
          'imageUrl': _imageUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}