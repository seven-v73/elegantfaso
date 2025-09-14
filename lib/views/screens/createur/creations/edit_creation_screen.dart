import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import '../model/creation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FirestoreService {
  static Future<void> updateCreation(Creation creation) async {
    await FirebaseFirestore.instance
        .collection('creations')
        .doc(creation.id)
        .update(creation.toJson());
  }
}

class StorageService {
  static Future<void> deleteImages(List<String> urls) async {
    for (final url in urls) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      } catch (e) {
        debugPrint("Error deleting image: $e");
      }
    }
  }

  static Future<List<String>> uploadImages(
      List<File> files, {
        required void Function(double) onProgress,
      }) async {
    final List<String> urls = [];
    final int total = files.length;
    int completed = 0;

    for (final file in files) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child('creations/$fileName');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      urls.add(url);

      completed++;
      onProgress(completed / total);
    }
    return urls;
  }
}

class EditCreationScreen extends StatefulWidget {
  final Creation creation;

  const EditCreationScreen({super.key, required this.creation});

  @override
  _EditCreationScreenState createState() => _EditCreationScreenState();
}

class _EditCreationScreenState extends State<EditCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  late String _selectedCategory;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  final user = FirebaseAuth.instance.currentUser;

  // Images management
  final List<String> _existingImages = [];
  final List<XFile> _newImages = [];
  final List<String> _deletedImages = [];

  final List<String> _categories = [
    "Robe",
    "Boubou",
    "Accessoire",
    "Tenue traditionnelle",
    "Autre"
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with existing creation data
    _titleController.text = widget.creation.title;
    _descriptionController.text = widget.creation.description;
    _priceController.text = widget.creation.price.toString();
    _selectedCategory = widget.creation.category;
    _existingImages.addAll(widget.creation.images);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier la Création",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            )),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageUploadSection(),
                    const SizedBox(height: 28),
                    _buildTitleField(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildCategoryDropdown(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: _buildPriceField(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDescriptionField(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          if (_isUploading) _buildProgressOverlay(),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    final totalImages = _existingImages.length + _newImages.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 3,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library,
                    color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  "Galerie de la création",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (totalImages > 0) _buildImagePreviewGrid(),
            if (totalImages == 0) _buildEmptyImagePlaceholder(),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_a_photo, size: 22),
              label: const Text("Ajouter des photos",
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                foregroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _pickImages,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Maximum 5 images (${totalImages}/5)",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyImagePlaceholder() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "Ajoutez vos photos",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Glissez-déposez ou cliquez pour ajouter",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewGrid() {
    final allImages = [
      ..._existingImages.map((url) => ImageItem(url: url, isExisting: true)),
      ..._newImages.map((file) => ImageItem(file: file, isExisting: false)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        return _buildImageItem(allImages[index], index);
      },
    );
  }

  Widget _buildImageItem(ImageItem item, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Display image
            if (item.isExisting && item.url != null)
              CachedNetworkImage(
                imageUrl: item.url!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                ),
              )
            else if (!item.isExisting && item.file != null)
              Image.file(
                File(item.file!.path),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),

            // Image type indicator
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.isExisting ? Colors.blue : Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.isExisting ? "EXISTANT" : "NOUVELLE",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Delete button
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => _handleRemoveImage(item),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            ),

            // Image number
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Text(
                    "Image ${index + 1}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: "Catégorie",
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: InputBorder.none,
            labelStyle: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          items: _categories
              .map((category) => DropdownMenuItem(
            value: category,
            child: Text(category, style: TextStyle(fontSize: 15)),
          ))
              .toList(),
          onChanged: (value) => setState(() => _selectedCategory = value!),
          validator: (value) =>
          value == null ? "Veuillez sélectionner une catégorie" : null,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down,
              color: Theme.of(context).primaryColor),
          dropdownColor: Colors.white,
          style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildPriceField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: TextFormField(
        controller: _priceController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: "Prix (XOF)",
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Text(
              "FCFA",
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          labelStyle: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Prix requis";
          }
          if (double.tryParse(value) == null) {
            return "Prix invalide";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: TextFormField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: "Titre de la création",
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: InputBorder.none,
          prefixIcon: Icon(Icons.title, color: Theme.of(context).primaryColor),
          labelStyle: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Veuillez saisir un titre";
          }
          if (value.length < 3) {
            return "Titre trop court (min. 3 caractères)";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: "Description détaillée",
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: InputBorder.none,
          alignLabelWithHint: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Icon(Icons.description, color: Theme.of(context).primaryColor),
          ),
          labelStyle: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          hintText: "Décrivez votre création...",
          contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        ),
        maxLines: 5,
        minLines: 3,
        style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Ce champ est obligatoire";
          }
          if (value.length < 20) {
            return "La description doit contenir au moins 20 caractères";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Colors.blue.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: _isUploading ? null : _updateCreation,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isUploading
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            const SizedBox(width: 15),
            Text(
              "MISE À JOUR EN COURS...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.update, size: 24),
            const SizedBox(width: 10),
            Text(
              "METTRE À JOUR",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _uploadProgress,
                      strokeWidth: 6,
                      color: Theme.of(context).primaryColor,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  Text(
                    "${(_uploadProgress * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Text(
                "Mise à jour en cours",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Vos modifications sont en cours d'enregistrement...",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _uploadProgress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRemoveImage(ImageItem item) {
    setState(() {
      if (item.isExisting && item.url != null) {
        _existingImages.remove(item.url);
        _deletedImages.add(item.url!);
      } else if (!item.isExisting && item.file != null) {
        _newImages.remove(item.file);
      }
    });
  }

  Future<void> _pickImages() async {
    try {
      final status = await Permission.photos.request();

      if (status.isGranted) {
        final pickedImages = await ImagePicker().pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 90,
        );

        if (pickedImages != null && pickedImages.isNotEmpty) {
          final totalImages = _existingImages.length + _newImages.length;
          final remaining = 5 - totalImages;

          if (remaining > 0) {
            setState(() {
              _newImages.addAll(pickedImages.take(remaining));
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Maximum 5 images atteint"),
                backgroundColor: Theme.of(context).primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Permission refusée pour accéder aux photos"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur sélection images : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _updateCreation() async {
    if (!_formKey.currentState!.validate()) return;

    final totalImages = _existingImages.length + _newImages.length;
    if (totalImages == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Veuillez ajouter au moins une image"),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload new images
      List<String> uploadedUrls = [];
      if (_newImages.isNotEmpty) {
        // Compress new images
        final compressedFiles = await Future.wait(_newImages.map((image) =>
            _compressImage(File(image.path))));

        // Upload compressed images
        uploadedUrls = await StorageService.uploadImages(
          compressedFiles,
          onProgress: (progress) => setState(() => _uploadProgress = progress),
        );
      }

      // Delete removed images
      if (_deletedImages.isNotEmpty) {
        await StorageService.deleteImages(_deletedImages);
      }

      // Combine existing and new images
      final allImageUrls = [..._existingImages, ...uploadedUrls];

      // Convert price
      final price = double.tryParse(_priceController.text) ?? 0.0;

      // Create updated Creation object
      final updatedCreation = Creation(
        id: widget.creation.id,
        createurId: widget.creation.createurId,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        images: allImageUrls,
        price: price,
        createdAt: widget.creation.createdAt,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await FirestoreService.updateCreation(updatedCreation);

      // Success
      Navigator.pop(context, updatedCreation); // Return updated creation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Création mise à jour avec succès!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint("Error updating creation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.path}_compressed.jpg',
        quality: 75,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint("Image compression error: $e");
      return file;
    }
  }
}

class ImageItem {
  final String? url;
  final XFile? file;
  final bool isExisting;

  ImageItem({this.url, this.file, required this.isExisting});
}