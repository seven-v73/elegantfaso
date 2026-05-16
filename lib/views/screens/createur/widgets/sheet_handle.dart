import 'package:flutter/material.dart';

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
    );
  }
}
