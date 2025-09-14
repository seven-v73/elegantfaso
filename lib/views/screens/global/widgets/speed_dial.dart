import 'package:flutter/material.dart';

class SpeedDial extends StatelessWidget {
  const SpeedDial({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {},
      backgroundColor: Colors.green[700],
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }
}