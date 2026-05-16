import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/account_roles.dart';
import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';
import '../../../services/salon/pro_story_service.dart';

class ProStoryPublishScreen extends StatefulWidget {
  const ProStoryPublishScreen({super.key, required this.role});

  final String role;

  @override
  State<ProStoryPublishScreen> createState() => _ProStoryPublishScreenState();
}

class _ProStoryPublishScreenState extends State<ProStoryPublishScreen> {
  final _picker = ImagePicker();
  final _captionController = TextEditingController();
  final _service = ProStoryService();
  XFile? _image;
  bool _publishing = false;

  bool get _isCreator => widget.role == AccountRoles.createur;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image == null || !mounted) return;
    setState(() => _image = image);
  }

  Future<void> _publish() async {
    final image = _image;
    if (image == null) {
      _snack('Ajoutez une photo pour publier une story.', danger: true);
      return;
    }
    setState(() => _publishing = true);
    try {
      await _service.publishImageStory(
        role: widget.role,
        image: File(image.path),
        caption: _captionController.text,
        ctaLabel: _isCreator ? 'Voir l’atelier' : 'Voir la boutique',
      );
      if (!mounted) return;
      _snack('Story publiée pour 24h dans le Salon.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack('Publication impossible: $e', danger: true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _snack(String message, {bool danger = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: danger ? ModernColors.danger : ModernColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isCreator ? ModernColors.creator : ModernColors.shop;
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: const Text('Story Salon'),
        backgroundColor: ModernColors.canvas,
        foregroundColor: ModernColors.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              color: ModernColors.ink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_stories_rounded, color: accent, size: 34),
                  const SizedBox(height: 12),
                  const Text(
                    'Publier une story pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Visible dans le Salon pendant 24h. Idéal pour nouveautés, arrivages, disponibilité atelier ou coulisses.',
                    style: TextStyle(
                      color: Color(0xFFE5E7EB),
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _publishing ? null : _pickImage,
              child: AspectRatio(
                aspectRatio: 9 / 13,
                child: Container(
                  decoration: BoxDecoration(
                    color: ModernColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ModernColors.line),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      _image == null
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                color: accent,
                                size: 42,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Choisir une photo',
                                style: TextStyle(
                                  color: ModernColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          )
                          : Image.file(File(_image!.path), fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _captionController,
              maxLength: 120,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Texte court',
                hintText:
                    'Nouvel arrivage, création disponible, promo du jour...',
              ),
            ),
            const SizedBox(height: 8),
            const AppCard(
              elevated: false,
              child: Text(
                'Conseil: montrez une vraie pièce, un détail textile, un essayage ou une nouveauté. Les stories pro doivent rester utiles et inspirantes.',
                style: TextStyle(
                  color: ModernColors.inkSoft,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            border: Border(top: BorderSide(color: ModernColors.line)),
          ),
          child: AppButton(
            label: 'Publier',
            icon: Icons.upload_rounded,
            onPressed: _publish,
            loading: _publishing,
            expand: true,
          ),
        ),
      ),
    );
  }
}
