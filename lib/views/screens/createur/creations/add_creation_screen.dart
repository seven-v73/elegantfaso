import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../service/firestore_service.dart';
import '../service/storage_service.dart';
import '../model/creation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AddCreationScreen extends StatefulWidget {
  @override
  _AddCreationScreenState createState() => _AddCreationScreenState();
}

class _AddCreationScreenState extends State<AddCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<XFile> _images = [];
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = "Robe";
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  final user = FirebaseAuth.instance.currentUser;

  final List<String> _categories = [
    "Robe",
    "Boubou",
    "Accessoire",
    "Tenue traditionnelle",
    "Autre"
  ];

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
        title: const Text("Nouvelle Création",
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
            if (_images.isNotEmpty) _buildImagePreviewGrid(),
            if (_images.isEmpty) _buildEmptyImagePlaceholder(),
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
                "Maximum 5 images (1 minimum requise)",
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        return _buildImageItem(_images[index], index);
      },
    );
  }

  Widget _buildImageItem(XFile image, int index) {
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
            Image.file(
              File(image.path),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => _removeImage(image),
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
            Theme.of(context).primaryColor.withOpacity(0.8),
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
        onPressed: _isUploading ? null : _submitCreation,
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
              "PUBLICATION EN COURS...",
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
            const Icon(Icons.upload, size: 24),
            const SizedBox(width: 10),
            Text(
              "PUBLIER LA CRÉATION",
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
                "Téléchargement en cours",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Vos images sont en cours d'envoi...",
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
          final remaining = 5 - _images.length;
          if (remaining > 0) {
            setState(() {
              _images.addAll(pickedImages.take(remaining));
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

  void _removeImage(XFile image) {
    setState(() {
      _images.remove(image);
    });
  }

  void _showFullScreenImage(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageGallery(
          images: _images,
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _submitCreation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
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
      // Compress images before upload
      final compressedFiles = await Future.wait(_images.map((image) =>
          _compressImage(File(image.path))));

      // Upload images to Firebase Storage
      final imageUrls = await StorageService.uploadImages(
        compressedFiles,
        onProgress: (progress) => setState(() => _uploadProgress = progress),
      );

      // Convert price
      final price = double.tryParse(_priceController.text) ?? 0.0;

      // Create Creation object
      final creation = Creation(
        createurId: user!.uid,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        images: imageUrls,
        price: price,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await FirestoreService.addCreation(creation);

      // Success
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Création publiée avec succès!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint("Error submitting creation: $e");
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

class FullScreenImageGallery extends StatefulWidget {
  final List<XFile> images;
  final int initialIndex;

  const FullScreenImageGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text("${_currentIndex + 1}/${widget.images.length}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 3.0,
            child: Center(
              child: Hero(
                tag: 'image_$index',
                child: Image.file(
                  File(widget.images[index].path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}