import 'package:flutter/material.dart';

import '../../../../design/modern_design_system.dart';
import '../../global/widgets/secondhand/secondhand_marketplace.dart';

class ClientSecondhandScreen extends StatelessWidget {
  const ClientSecondhandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: const Text('Vide-dressing'),
        backgroundColor: ModernColors.canvas,
        foregroundColor: ModernColors.ink,
        elevation: 0,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: 8, bottom: 28),
          child: SecondhandMarketplace(),
        ),
      ),
    );
  }
}
