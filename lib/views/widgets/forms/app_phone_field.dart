import 'package:flutter/material.dart';

import 'app_text_field.dart';

class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    required this.controller,
    this.label = 'Téléphone',
    this.hint,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: Icons.call_rounded,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      validator: validator,
    );
  }
}
