import 'package:flutter/material.dart';

import '../../../design/modern_design_system.dart';
import '../../../services/preferences/currency_service.dart';

class CurrencyPreferenceTile extends StatefulWidget {
  const CurrencyPreferenceTile({
    super.key,
    required this.initialCurrency,
    this.enabled = true,
    this.onChanged,
  });

  final String initialCurrency;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<CurrencyPreferenceTile> createState() => _CurrencyPreferenceTileState();
}

class _CurrencyPreferenceTileState extends State<CurrencyPreferenceTile> {
  late String _currency = CurrencyService.normalize(widget.initialCurrency);
  bool _saving = false;

  @override
  void didUpdateWidget(covariant CurrencyPreferenceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = CurrencyService.normalize(widget.initialCurrency);
    if (!_saving && next != _currency) _currency = next;
  }

  @override
  Widget build(BuildContext context) {
    final option = CurrencyService.optionFor(_currency);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
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
            child: const Icon(
              Icons.payments_rounded,
              color: ModernColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: option.code,
                isExpanded: true,
                icon:
                    _saving
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.expand_more_rounded),
                items:
                    CurrencyService.options
                        .map(
                          (currency) => DropdownMenuItem(
                            value: currency.code,
                            child: Text(
                              '${currency.symbol}  ${currency.code} - ${currency.label}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: widget.enabled && !_saving ? _changeCurrency : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeCurrency(String? value) async {
    if (value == null) return;
    final previous = _currency;
    setState(() {
      _currency = CurrencyService.normalize(value);
      _saving = true;
    });
    try {
      await CurrencyService().updateCurrentUserCurrency(_currency);
      widget.onChanged?.call(_currency);
    } catch (_) {
      if (!mounted) return;
      setState(() => _currency = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible de mettre à jour la devise.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
