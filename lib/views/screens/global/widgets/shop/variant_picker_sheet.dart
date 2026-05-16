import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/shop/product_variant.dart';
import '../../../../../models/shop/public_listing.dart';
import '../../../../widgets/forms/app_text_field.dart';

class VariantSelection {
  const VariantSelection({
    required this.quantity,
    this.size = '',
    this.color = '',
    this.note = '',
  });

  final int quantity;
  final String size;
  final String color;
  final String note;

  ProductVariant get variant => ProductVariant(size: size, color: color);
}

class VariantPickerSheet extends StatefulWidget {
  const VariantPickerSheet({super.key, required this.listing});

  final PublicListing listing;

  @override
  State<VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends State<VariantPickerSheet> {
  final TextEditingController _noteController = TextEditingController();
  String _size = '';
  String _color = '';
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _size = widget.listing.sizes.firstOrNull ?? '';
    _color = widget.listing.colors.firstOrNull ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  ProductVariant? get _selectedManagedVariant {
    final variants = widget.listing.variants;
    if (variants.isEmpty) return null;
    final index = variants.indexWhere(
      (variant) => variant.matches(size: _size, color: _color),
    );
    return index < 0 ? null : variants[index];
  }

  int get _stockLimit {
    final stock = _selectedManagedVariant?.stock ?? widget.listing.stock;
    if (stock == null || stock <= 0) return 0;
    return stock.clamp(1, 99);
  }

  bool _isSizeAvailable(String size) {
    final matching = widget.listing.variants.where(
      (variant) => variant.matches(size: size, color: _color),
    );
    return matching.isEmpty || matching.any((variant) => !variant.isOutOfStock);
  }

  bool _isColorAvailable(String color) {
    final matching = widget.listing.variants.where(
      (variant) => variant.matches(size: _size, color: color),
    );
    return matching.isEmpty || matching.any((variant) => !variant.isOutOfStock);
  }

  void _selectSize(String size) {
    setState(() {
      _size = size;
      if (_stockLimit > 0 && _quantity > _stockLimit) _quantity = _stockLimit;
      if (_stockLimit == 0) _quantity = 1;
    });
  }

  void _selectColor(String color) {
    setState(() {
      _color = color;
      if (_stockLimit > 0 && _quantity > _stockLimit) _quantity = _stockLimit;
      if (_stockLimit == 0) _quantity = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ModernColors.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: ModernShadows.elevated,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.listing.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            if (widget.listing.sizes.isNotEmpty) ...[
              const _SheetLabel('Taille'),
              Wrap(
                spacing: 8,
                children:
                    widget.listing.sizes.map((size) {
                      final available = _isSizeAvailable(size);
                      return ChoiceChip(
                        label: Text(size),
                        selected: _size == size,
                        onSelected: available ? (_) => _selectSize(size) : null,
                        disabledColor: ModernColors.line,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.listing.colors.isNotEmpty) ...[
              const _SheetLabel('Couleur'),
              Wrap(
                spacing: 8,
                children:
                    widget.listing.colors.map((color) {
                      final available = _isColorAvailable(color);
                      return ChoiceChip(
                        label: Text(color),
                        selected: _color == color,
                        onSelected:
                            available ? (_) => _selectColor(color) : null,
                        disabledColor: ModernColors.line,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (_stockLimit == 0) ...[
              const Text(
                'Cette combinaison est momentanément indisponible.',
                style: TextStyle(
                  color: ModernColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
            ],
            const _SheetLabel('Quantité'),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed:
                      _quantity <= 1 ? null : () => setState(() => _quantity--),
                  icon: const Icon(Icons.remove_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed:
                      _stockLimit == 0 || _quantity >= _stockLimit
                          ? null
                          : () => setState(() => _quantity++),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _noteController,
              label: 'Note au vendeur',
              hint: 'Mesure, ajustement, préférence',
              icon: Icons.notes_rounded,
              minLines: 1,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Continuer',
              onPressed:
                  _stockLimit == 0
                      ? null
                      : () {
                        Navigator.pop(
                          context,
                          VariantSelection(
                            quantity: _quantity,
                            size: _size,
                            color: _color,
                            note: _noteController.text.trim(),
                          ),
                        );
                      },
              icon: Icons.add_shopping_cart_rounded,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: ModernColors.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
