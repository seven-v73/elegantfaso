import 'package:flutter/material.dart';

import '../../../design/modern_design_system.dart';
import 'app_select_field.dart';
import 'app_text_field.dart';

class PaymentMethodsEditor extends StatefulWidget {
  const PaymentMethodsEditor({
    super.key,
    required this.methods,
    required this.onChanged,
    this.enabled = true,
    this.title = 'Paiements',
    this.subtitle = 'Retraits',
    this.emptyLabel = 'Aucun moyen enregistré',
    this.warningLabel = 'Ajoutez un numéro pour recevoir vos retraits.',
    this.readyLabel = 'Prêt',
    this.missingLabel = 'À compléter',
    this.availableMethods = const [
      'Orange Money',
      'Moov Money',
      'MTN Money',
      'Wave',
      'Sank Money',
      'Virement bancaire',
    ],
  });

  final Map<String, String> methods;
  final ValueChanged<Map<String, String>> onChanged;
  final bool enabled;
  final String title;
  final String subtitle;
  final String emptyLabel;
  final String warningLabel;
  final String readyLabel;
  final String missingLabel;
  final List<String> availableMethods;

  @override
  State<PaymentMethodsEditor> createState() => _PaymentMethodsEditorState();
}

class _PaymentMethodsEditorState extends State<PaymentMethodsEditor> {
  final TextEditingController _numberController = TextEditingController();
  late String _selectedMethod =
      widget.availableMethods.isEmpty
          ? 'Mobile Money'
          : widget.availableMethods.first;

  bool get _hasMethods =>
      widget.methods.values.any((value) => value.isNotEmpty);

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _syncNumber() {
    _numberController.text = widget.methods[_selectedMethod] ?? '';
  }

  void _addMethod() {
    final number = _numberController.text.trim();
    if (number.isEmpty) return;
    FocusScope.of(context).unfocus();
    widget.onChanged({...widget.methods, _selectedMethod: number});
    _numberController.clear();
  }

  void _removeMethod(String method) {
    final next = {...widget.methods}..remove(method);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final entries =
        widget.methods.entries
            .where((entry) => entry.value.trim().isNotEmpty)
            .toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _StatusPill(
                label: _hasMethods ? widget.readyLabel : widget.missingLabel,
                color:
                    _hasMethods ? ModernColors.success : ModernColors.warning,
                icon:
                    _hasMethods
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
              ),
            ],
          ),
          if (!_hasMethods) ...[
            const SizedBox(height: 14),
            _PaymentNotice(label: widget.warningLabel),
          ],
          if (widget.enabled) ...[
            const SizedBox(height: 14),
            _PaymentComposer(
              selectedMethod: _selectedMethod,
              methods: widget.availableMethods,
              numberController: _numberController,
              onMethodChanged: (value) {
                if (value == null) return;
                setState(() => _selectedMethod = value);
                _syncNumber();
              },
              onAdd: _addMethod,
            ),
          ],
          const SizedBox(height: 14),
          if (entries.isEmpty)
            _EmptyPaymentPreview(label: widget.emptyLabel)
          else
            ...entries.map(
              (entry) => _PaymentMethodTile(
                method: entry.key,
                number: entry.value,
                enabled: widget.enabled,
                onDelete: () => _removeMethod(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentComposer extends StatelessWidget {
  const _PaymentComposer({
    required this.selectedMethod,
    required this.methods,
    required this.numberController,
    required this.onMethodChanged,
    required this.onAdd,
  });

  final String selectedMethod;
  final List<String> methods;
  final TextEditingController numberController;
  final ValueChanged<String?> onMethodChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        children: [
          AppSelectField<String>(
            key: ValueKey(selectedMethod),
            value: selectedMethod,
            items: methods,
            label: 'Méthode',
            icon: _paymentIcon(selectedMethod),
            onChanged: onMethodChanged,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final input = AppTextField(
                controller: numberController,
                label: 'Numéro ou référence',
                hint: 'Ex: 70 00 00 00',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              );

              if (constraints.maxWidth < 330) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    input,
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Ajouter'),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: input),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton.filled(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Ajouter',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.number,
    required this.enabled,
    required this.onDelete,
  });

  final String method;
  final String number;
  final bool enabled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ModernColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_paymentIcon(method), color: ModernColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  number,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (enabled)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Retirer',
            ),
        ],
      ),
    );
  }
}

class _PaymentNotice extends StatelessWidget {
  const _PaymentNotice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ModernColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.warning.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: ModernColors.warning,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ModernColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPaymentPreview extends StatelessWidget {
  const _EmptyPaymentPreview({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.wallet_outlined, color: ModernColors.inkSoft),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ModernColors.inkSoft,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _paymentIcon(String method) {
  final normalized = method.toLowerCase();
  if (normalized.contains('bank') ||
      normalized.contains('banque') ||
      normalized.contains('virement')) {
    return Icons.account_balance_rounded;
  }
  if (normalized.contains('wave')) return Icons.waves_rounded;
  if (normalized.contains('orange')) return Icons.phone_android_rounded;
  if (normalized.contains('moov') || normalized.contains('mtn')) {
    return Icons.phone_iphone_rounded;
  }
  return Icons.account_balance_wallet_rounded;
}
