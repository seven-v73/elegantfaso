import 'package:flutter/material.dart';

import '../../../core/account_roles.dart';
import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';
import '../../../services/inspiration/style_guide_service.dart';

class ProStyleGuideComposerScreen extends StatefulWidget {
  const ProStyleGuideComposerScreen({super.key, required this.role});

  final String role;

  @override
  State<ProStyleGuideComposerScreen> createState() =>
      _ProStyleGuideComposerScreenState();
}

class _ProStyleGuideComposerScreenState
    extends State<ProStyleGuideComposerScreen> {
  final _service = StyleGuideService();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _imageController = TextEditingController();
  final _steps = List.generate(3, (_) => TextEditingController());
  String _category = 'Tenues';
  bool _publishing = false;

  bool get _isCreator => widget.role == AccountRoles.createur;

  static const _categories = [
    'Tenues',
    'Coiffures',
    'Accessoires',
    'Chaussures',
    'Matières',
    'Cérémonie',
    'Entretien',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _imageController.dispose();
    for (final controller in _steps) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();
    final steps =
        _steps.map((controller) => controller.text.trim()).where((step) {
          return step.isNotEmpty;
        }).toList();
    if (title.isEmpty || subtitle.isEmpty || steps.length < 2) {
      _snack('Ajoutez un titre, une intention et au moins deux étapes.');
      return;
    }

    setState(() => _publishing = true);
    try {
      await _service.publishProGuide(
        role: widget.role,
        title: title,
        subtitle: subtitle,
        category: _category,
        steps: steps,
        imageUrl: _imageController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guide publié dans Inspiration.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      _snack('Publication impossible: $error');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ModernColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isCreator ? ModernColors.creator : ModernColors.shop;
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: const Text('Guide Style'),
        backgroundColor: ModernColors.canvas,
        foregroundColor: ModernColors.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
          children: [
            AppCard(
              color: ModernColors.ink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.school_rounded, color: accent, size: 34),
                  const SizedBox(height: 12),
                  const Text(
                    'Partager un mini-guide',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Un conseil pratique, court et utile pour aider les clients à porter, choisir ou entretenir une pièce.',
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
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex: 3 façons de porter un foulard',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitleController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Intention',
                hintText: 'Ce que le client va apprendre en quelques secondes',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items:
                  _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
              decoration: const InputDecoration(labelText: 'Catégorie'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(
                labelText: 'Image de couverture (URL optionnelle)',
                hintText: 'Cloudinary, photo produit ou création',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Étapes',
              style: TextStyle(
                color: ModernColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _steps.length; i++) ...[
              TextField(
                controller: _steps[i],
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Étape ${i + 1}',
                  hintText:
                      i == 0
                          ? 'Commencez par une base simple'
                          : 'Ajoutez un conseil concret',
                ),
              ),
              const SizedBox(height: 10),
            ],
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
            icon: Icons.publish_rounded,
            onPressed: _publish,
            loading: _publishing,
            expand: true,
          ),
        ),
      ),
    );
  }
}
