import 'package:flutter/material.dart';

import 'app_text_field.dart';

class AppMoneyField extends StatelessWidget {
  const AppMoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.currencySymbol = 'FCFA',
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String currencySymbol;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: Icons.payments_rounded,
      prefixText: '$currencySymbol ',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      validator: validator,
    );
  }
}
