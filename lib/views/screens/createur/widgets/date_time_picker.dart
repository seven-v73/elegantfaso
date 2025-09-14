import 'package:flutter/material.dart';

class DateTimePicker extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const DateTimePicker({
    Key? key,
    required this.label,
    required this.value,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(value),
      ),
    );
  }
}