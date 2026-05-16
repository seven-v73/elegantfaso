import 'package:flutter/material.dart';

import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';
import '../../../services/account/account_closure_service.dart';
import '../forms/app_text_field.dart';

Future<bool?> showAccountClosureSheet(
  BuildContext context, {
  required AccountClosureTarget target,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AccountClosureSheet(target: target),
  );
}

class _AccountClosureSheet extends StatefulWidget {
  const _AccountClosureSheet({required this.target});

  final AccountClosureTarget target;

  @override
  State<_AccountClosureSheet> createState() => _AccountClosureSheetState();
}

class _AccountClosureSheetState extends State<_AccountClosureSheet> {
  final AccountClosureService _service = AccountClosureService();
  final TextEditingController _detailsController = TextEditingController();

  AccountClosureReason _selectedReason = AccountClosureService.reasons.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isFullAccount = widget.target == AccountClosureTarget.account;
    final isBusinessSpace = !isFullAccount;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: ModernColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ModernColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: ModernColors.rose.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.pause_circle_outline_rounded,
                            color: ModernColors.rose,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isFullAccount
                                    ? 'Fermer mon compte'
                                    : 'Fermer mon ${widget.target.label}',
                                style: const TextStyle(
                                  color: ModernColors.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isFullAccount
                                    ? 'Votre accès sera mis en pause puis examiné par l’administration.'
                                    : 'Cet espace sera fermé immédiatement après confirmation.',
                                style: const TextStyle(
                                  color: ModernColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pourquoi souhaitez-vous fermer ?',
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          AccountClosureService.reasons.map((reason) {
                            final selected = reason.id == _selectedReason.id;
                            return ChoiceChip(
                              selected: selected,
                              label: Text(reason.label),
                              onSelected:
                                  _isSubmitting
                                      ? null
                                      : (_) => setState(
                                        () => _selectedReason = reason,
                                      ),
                              selectedColor: ModernColors.rose.withValues(
                                alpha: 0.12,
                              ),
                              labelStyle: TextStyle(
                                color:
                                    selected
                                        ? ModernColors.rose
                                        : ModernColors.ink,
                                fontWeight:
                                    selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _detailsController,
                      enabled: !_isSubmitting,
                      label: 'Détail optionnel',
                      hint: 'Ex: Je souhaite réactiver plus tard',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                      maxLength: 280,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isFullAccount
                          ? 'Après soumission, vous serez redirigé vers le Salon invité. La connexion avec cet email restera bloquée jusqu’à réactivation ou suppression définitive par l’admin.'
                          : 'Votre compte client reste actif. Vous pourrez demander à rouvrir cet espace plus tard depuis votre compte.',
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon:
                                _isSubmitting
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(Icons.send_rounded),
                            label: Text(
                              isBusinessSpace ? 'Fermer' : 'Soumettre',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: ModernColors.rose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await _service.submitClosureRequest(
        target: widget.target,
        reasonId: _selectedReason.id,
        reasonLabel: _selectedReason.label,
        details: _detailsController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de soumettre la demande. Réessayez.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ModernColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
