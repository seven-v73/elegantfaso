import 'package:flutter/material.dart';

class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    this.icon,
    this.validator,
    this.itemLabelBuilder,
  });

  final T? value;
  final List<T> items;
  final String label;
  final IconData? icon;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final String Function(T item)? itemLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: icon == null ? null : Icon(icon, size: 21),
      ),
      items:
          items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabelBuilder?.call(item) ?? item.toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }
}
