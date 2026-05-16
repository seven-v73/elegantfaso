import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/repositories/auth_repository.dart';
import '../design/modern_design_system.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.enableNavigation = true});

  final bool enableNavigation;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _ambientController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  Timer? _messageTimer;
  bool _navigated = false;
  int _messageIndex = 0;

  static const _messages = [
    'Votre style se prépare',
    'Ateliers, boutiques et inspirations',
    'Une mode locale, vivante et soignée',
  ];

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _introController, curve: Curves.easeOut);
    _scale = Tween<double>(begin: .92, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, .08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _messageTimer = Timer.periodic(const Duration(milliseconds: 1250), (_) {
      if (!mounted) return;
      setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
    });

    if (widget.enableNavigation) {
      Timer(const Duration(milliseconds: 2300), _navigate);
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted || _navigated) return;
    _navigated = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _go('/auth');
      return;
    }

    try {
      final authResult = await AuthRepository().getCurrentUserInfo().timeout(
        const Duration(seconds: 6),
      );
      if (!mounted) return;
      _go(authResult?.redirectRoute ?? '/home');
    } catch (_) {
      if (mounted) _go('/home');
    }
  }

  void _go(String route) {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _ambientController,
          builder: (context, child) {
            final pulse = _ambientController.value;
            return Stack(
              children: [
                Positioned(
                  top: -90 + pulse * 18,
                  right: -80,
                  child: _Aura(
                    size: 220,
                    color: ModernColors.primary.withValues(alpha: .08),
                  ),
                ),
                Positioned(
                  bottom: -110,
                  left: -70 + pulse * 14,
                  child: _Aura(
                    size: 240,
                    color: ModernColors.accent.withValues(alpha: .09),
                  ),
                ),
                Positioned.fill(child: child!),
              ],
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          width: 118,
                          height: 118,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: ModernColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .9),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ModernColors.primary.withValues(
                                  alpha: .12,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/logo/logo.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ElegantStyle',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: ModernColors.ink,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mode, style et créations locales',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: ModernColors.inkSoft,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: ModernColors.surface.withValues(alpha: .86),
                          borderRadius: BorderRadius.circular(ModernRadius.sm),
                          border: Border.all(color: ModernColors.line),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Text(
                            _messages[_messageIndex],
                            key: ValueKey(_messageIndex),
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(
                              color: ModernColors.primaryDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: 156,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 4,
                            value: widget.enableNavigation ? null : .72,
                            color: ModernColors.primary,
                            backgroundColor: ModernColors.primary.withValues(
                              alpha: .12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Aura extends StatelessWidget {
  const _Aura({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
