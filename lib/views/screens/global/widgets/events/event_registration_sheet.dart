import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/events/salon_event.dart';
import '../../../../widgets/forms/app_text_field.dart';

class EventRegistrationSheet extends StatefulWidget {
  const EventRegistrationSheet({
    super.key,
    required this.event,
    required this.onSubmit,
  });

  final SalonEvent event;
  final Future<void> Function(String note) onSubmit;

  @override
  State<EventRegistrationSheet> createState() => _EventRegistrationSheetState();
}

class _EventRegistrationSheetState extends State<EventRegistrationSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_noteController.text);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Réserver une place',
                style: TextStyle(
                  color: ModernColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.event.title,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _noteController,
                label: 'Message',
                hint: 'Message optionnel pour l’organisateur',
                icon: Icons.notes_rounded,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Confirmer',
                onPressed: _isSubmitting ? null : _submit,
                icon: Icons.confirmation_number_rounded,
                loading: _isSubmitting,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
