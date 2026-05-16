import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/modern_design_system.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.validator,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixText,
    this.suffixText,
    this.suffixIcon,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final String? prefixText;
  final String? suffixText;
  final Widget? suffixIcon;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 21),
        prefixText: prefixText,
        suffixText: suffixText,
        suffixIcon: suffixIcon,
        helperText: helperText,
        errorText: errorText,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      style: const TextStyle(
        color: ModernColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
