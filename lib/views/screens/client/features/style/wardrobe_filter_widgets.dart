part of 'garde_robe.dart';

class _FiltersSheet extends StatefulWidget {
  final List<String> colors;
  final List<String> brands;
  final String selectedCategory;
  final String selectedColor;
  final String selectedBrand;
  final String selectedOccasion;
  final String selectedSeason;
  final void Function(String, String, String, String, String) onApply;

  const _FiltersSheet({
    required this.colors,
    required this.brands,
    required this.selectedCategory,
    required this.selectedColor,
    required this.selectedBrand,
    required this.selectedOccasion,
    required this.selectedSeason,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String category = widget.selectedCategory;
  late String color = widget.selectedColor;
  late String brand = widget.selectedBrand;
  late String occasion = widget.selectedOccasion;
  late String season = widget.selectedSeason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtres avancés',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _drop(
            'Catégorie',
            category,
            _WardrobeScreenState._categories,
            (v) => category = v,
          ),
          _drop('Couleur', color, widget.colors, (v) => color = v),
          _drop('Marque', brand, widget.brands, (v) => brand = v),
          _drop(
            'Occasion',
            occasion,
            _WardrobeScreenState._occasions,
            (v) => occasion = v,
          ),
          _drop(
            'Saison',
            season,
            _WardrobeScreenState._seasons,
            (v) => season = v,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(
                      'Tous',
                      'Toutes',
                      'Toutes',
                      'Toutes',
                      'Toutes',
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(category, color, brand, occasion, season);
                    Navigator.pop(context);
                  },
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drop(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> onChanged,
  ) {
    final safeValues = values.isEmpty ? ['Toutes'] : values;
    final safeValue = safeValues.contains(value) ? value : safeValues.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF3F5F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        items:
            safeValues
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() => onChanged(value));
        },
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = _WardrobeScreenState._primaryColor;
    const border = _WardrobeScreenState._borderColor;
    const text = _WardrobeScreenState._textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? primary : border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: selected ? Colors.white : primary),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = _WardrobeScreenState._primaryColor;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickMenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _QuickMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        danger
            ? _WardrobeScreenState._errorRed
            : _WardrobeScreenState._primaryColor;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
