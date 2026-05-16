import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../design/modern_design_system.dart';

class AppConnectivityBanner extends StatefulWidget {
  const AppConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  State<AppConnectivityBanner> createState() => _AppConnectivityBannerState();
}

class _AppConnectivityBannerState extends State<AppConnectivityBanner> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialStatus() async {
    try {
      _updateStatus(await _connectivity.checkConnectivity());
    } catch (_) {
      // Connectivity is only an affordance; the app must never block on it.
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
    if (offline == _offline || !mounted) return;
    setState(() => _offline = offline);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child:
                  _offline ? const _OfflineNotice() : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: ModernColors.ink,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ModernShadows.elevated,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Connexion faible: les contenus déjà chargés restent disponibles.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
