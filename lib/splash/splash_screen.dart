import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  late AnimationController _shimmerController;
  late AnimationController _fashionController;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _backgroundOpacity;
  late Animation<double> _shimmerPosition;
  late Animation<double> _fashionElements;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _scheduleNavigation();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _fashionController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    ));

    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _backgroundOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _shimmerPosition = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _fashionElements = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fashionController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() async {
    if (!mounted) return;

    _backgroundController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _textController.forward();
  }

  void _scheduleNavigation() {
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted || _hasNavigated) return;
      _navigateToNextScreen();
    });
  }

  String _getRouteForRole(String role) {
    switch (role) {
      case 'client':
        return '/home';
      case 'boutique':
        return '/shop-dashboard';
      case 'createur':
        return '/creator-dashboard';
      case 'admin':
        return '/admin';
      default:
        return '/auth';
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('No authenticated user found, navigating to auth');
        _navigateToRoute('/auth');
        return;
      }

      final uid = user.uid;
      debugPrint('Fetching user data for uid: $uid');

      // Add timeout to prevent hanging
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final userData = doc.data();
      if (userData == null) {
        debugPrint('No user data found in Firestore, navigating to auth');
        _navigateToRoute('/auth');
        return;
      }

      final role = userData['role'] as String? ?? 'client';
      final route = _getRouteForRole(role);

      debugPrint('User role: $role, navigating to: $route');
      _navigateToRoute(route);

    } on TimeoutException catch (e) {
      debugPrint('Timeout getting user data: $e');
      if (mounted) {
        _navigateToRoute('/auth');
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: $e');
      if (mounted) {
        _navigateToRoute('/auth');
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) {
        _navigateToRoute('/auth');
      }
    }
  }

  void _navigateToRoute(String route) {
    if (!mounted) return;

    try {
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
            (route) => false,
      );
    } catch (e) {
      debugPrint('Navigation error to $route: $e');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    _shimmerController.dispose();
    _fashionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: Listenable.merge([
            _backgroundController,
            _logoController,
            _textController,
            _shimmerController,
            _fashionController,
          ]),
          builder: (context, child) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFDFDFD),
                    Color(0xFFF8F8F8),
                    Color(0xFFF0F0F0),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  _buildFashionBackground(),
                  ..._buildFloatingFashionElements(),
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAnimatedLogo(),
                          const SizedBox(height: 55),
                          _buildAnimatedTitle(),
                          const SizedBox(height: 25),
                          _buildAnimatedSubtitle(),
                          const SizedBox(height: 90),
                          _buildLoadingIndicator(),
                          const SizedBox(height: 40),
                          _buildLoadingText(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Opacity(
            opacity: _logoOpacity.value,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Colors.white,
                    Color(0xFFFAFAFA),
                    Color(0xFFEEEEEE),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 40,
                    spreadRadius: 12,
                  ),
                  BoxShadow(
                    color: const Color(0xFFE74C3C).withOpacity(0.08),
                    blurRadius: 25,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE8E8E8),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/logo/logo.svg',
                    width: 95,
                    height: 95,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF2C3E50),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTitle() {
    return AnimatedBuilder(
      animation: Listenable.merge([_textController, _shimmerController]),
      builder: (context, child) {
        return SlideTransition(
          position: _textSlide,
          child: FadeTransition(
            opacity: _textOpacity,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [
                    Color(0xFF2C3E50),
                    Color(0xFFE74C3C),
                    Color(0xFF8B4513),
                    Color(0xFF2C3E50),
                  ],
                  stops: [
                    (_shimmerPosition.value - 0.6).clamp(0.0, 1.0),
                    (_shimmerPosition.value - 0.2).clamp(0.0, 1.0),
                    (_shimmerPosition.value + 0.2).clamp(0.0, 1.0),
                    (_shimmerPosition.value + 0.6).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                'ElegantFaso',
                style: TextStyle(
                  fontSize: 42,
                  fontFamily: 'Lora',
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: 3.5,
                  height: 1.1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSubtitle() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return SlideTransition(
          position: _textSlide,
          child: FadeTransition(
            opacity: _textOpacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Text(
                    'Élégance locale, culture globale',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Lora',
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF546E7A),
                      letterSpacing: 1.2,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: 80,
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFE74C3C).withOpacity(0.6),
                          const Color(0xFFF39C12).withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Mode & Culture Burkinabè',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Lora',
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF78909C),
                      letterSpacing: 2.0,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _fashionController,
      builder: (context, child) {
        return SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: _fashionElements.value * 2 * math.pi,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE8E8E8),
                      width: 1.5,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFE74C3C).withOpacity(0.4),
                          const Color(0xFFF39C12).withOpacity(0.4),
                          const Color(0xFF8B4513).withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Transform.rotate(
                angle: -_fashionElements.value * math.pi,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE74C3C).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE74C3C).withOpacity(0.8),
                      const Color(0xFFF39C12).withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingText() {
    return AnimatedBuilder(
      animation: _fashionController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.6 + 0.4 * math.sin(_fashionElements.value * 2 * math.pi),
          child: const Text(
            'Chargement...',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Lora',
              fontWeight: FontWeight.w300,
              color: Color(0xFF90A4AE),
              letterSpacing: 1.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFashionBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Positioned.fill(
          child: Opacity(
            opacity: _backgroundOpacity.value * 0.3,
            child: CustomPaint(
              painter: FashionBackgroundPainter(_backgroundOpacity.value),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingFashionElements() {
    return List.generate(8, (index) {
      return AnimatedBuilder(
        animation: _fashionController,
        builder: (context, child) {
          final offset = (index * 0.25 + _fashionElements.value) % 1.0;
          final size = 15.0 + (index % 4) * 8.0;
          final opacity = (0.2 + 0.3 * math.sin(offset * 2 * math.pi)).clamp(0.0, 1.0);

          return Positioned(
            left: (index * 70 + 40) % (MediaQuery.of(context).size.width - 80),
            top: 80 + (index * 100) % (MediaQuery.of(context).size.height - 160),
            child: Transform.translate(
              offset: Offset(
                25 * math.sin(offset * 2 * math.pi),
                15 * math.cos(offset * 2 * math.pi),
              ),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: index % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
                    color: [
                      const Color(0xFFE74C3C).withOpacity(0.12),
                      const Color(0xFFF39C12).withOpacity(0.12),
                      const Color(0xFF8B4513).withOpacity(0.12),
                      const Color(0xFF27AE60).withOpacity(0.12),
                    ][index % 4],
                    borderRadius: index % 3 == 1 ? BorderRadius.circular(6) :
                    index % 3 == 2 ? BorderRadius.circular(size / 4) : null,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class FashionBackgroundPainter extends CustomPainter {
  final double animationValue;

  FashionBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFFE8E8E8).withOpacity(0.4);

    final path = Path();

    // Draw horizontal lines
    for (int i = 0; i < 6; i++) {
      final y = (size.height / 6) * i;
      path.moveTo(0, y);
      path.lineTo(size.width * animationValue, y + 60);
    }

    // Draw vertical lines
    for (int i = 0; i < 4; i++) {
      final x = (size.width / 4) * i;
      path.moveTo(x, 0);
      path.lineTo(x + 40, size.height * animationValue);
    }

    canvas.drawPath(path, paint);

    // Draw decorative circles
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFE74C3C).withOpacity(0.04);

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.15),
      90 * animationValue,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.85),
      70 * animationValue,
      paint..color = const Color(0xFFF39C12).withOpacity(0.04),
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.1),
      50 * animationValue,
      paint..color = const Color(0xFF8B4513).withOpacity(0.04),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}