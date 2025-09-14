// keep_alive_screen.dart
import 'package:flutter/material.dart';

class KeepAliveScreen extends StatefulWidget {
  final Widget child;

  const KeepAliveScreen({super.key, required this.child});

  @override
  State<KeepAliveScreen> createState() => _KeepAliveScreenState();
}

class _KeepAliveScreenState extends State<KeepAliveScreen> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // Nécessaire pour maintenir l'état
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
