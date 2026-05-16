import 'package:flutter/material.dart';

class FormFieldConfig {
  const FormFieldConfig({
    required this.label,
    this.hint,
    this.icon,
    this.required = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
  });

  final String label;
  final String? hint;
  final IconData? icon;
  final bool required;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
}
