import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'fashion_assistant.dart';
import 'user_profile.dart';
import 'mesurement.dart';
import 'chat_screen.dart';
import 'garde_robe.dart';

class StyleHubScreen extends StatefulWidget {
  const StyleHubScreen({super.key});

  @override
  State<StyleHubScreen> createState() => _StyleHubScreenState();
}

class _StyleHubScreenState extends State<StyleHubScreen>
    with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  String userName = "Cher Client";

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _backgroundController;
  late AnimationController _cardController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _backgroundAnimation;
  late Animation<double> _cardAnimation;

  List<AnimationController> _buttonControllers = [];
  List<Animation<double>> _buttonAnimations = [];

  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchUserName();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    _backgroundAnimation = ColorTween(
      begin: const Color(0xFF667eea),
      end: const Color(0xFF764ba2),
    ).animate(_backgroundController);

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeInOut),
    );

    // Initialiser les animations des boutons
    for (int i = 0; i < 4; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 600 + (i * 100)),
        vsync: this,
      );
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutBack,
        ),
      );
      _buttonControllers.add(controller);
      _buttonAnimations.add(animation);
    }

    // Démarrer les animations avec des délais échelonnés
    _startAnimations();
  }

  void _startAnimations() {
    // Annuler tout timer existant
    _animationTimer?.cancel();

    _animationTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _fadeController.forward();
      _backgroundController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);

      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _scaleController.forward();
      });

      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        _slideController.forward();
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        _cardController.forward();
      });

      // Animer les boutons un par un
      for (int i = 0; i < _buttonControllers.length; i++) {
        Future.delayed(Duration(milliseconds: 800 + (i * 150)), () {
          if (!mounted) return;
          _buttonControllers[i].forward();
        });
      }
    });
  }

  void _fetchUserName() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          userName = doc.data()?['name'] ?? "Cher Client";
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération du nom: $e");
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    _cardController.dispose();
    for (var controller in _buttonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _backgroundController,
          _fadeController,
          _scaleController,
          _slideController,
          _pulseController,
          _cardController,
        ]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundAnimation.value ?? const Color(0xFF667eea),
                  const Color(0xFF764ba2),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    // En-tête avec animation de fade
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
                            child: _buildHeader(isSmallScreen),
                          ),
                        );
                      },
                    ),

                    // Illustration centrale avec animation
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: _buildCentralIllustration(context),
                        );
                      },
                    ),

                    // Boutons avec animations individuelles
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_cardAnimation.value * 0.2),
          child: Container(
            margin: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 10),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFE8EAF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Bonjour, ",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 30,
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.8,
                          ),
                        ),
                        TextSpan(
                          text: userName,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const TextSpan(
                          text: " ✨",
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Découvrez votre style unique avec nos conseils personnalisés",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 17,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCentralIllustration(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Multiples cercles avec effet pulsant
              ...List.generate(3, (index) {
                return Transform.scale(
                  scale: _pulseAnimation.value * (1 - index * 0.1),
                  child: Container(
                    width: screenWidth * (0.8 - index * 0.15),
                    height: screenWidth * (0.8 - index * 0.15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.15 - index * 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                );
              }),

              // Icône centrale avec effet glassmorphism amélioré
              Container(
                width: screenWidth * 0.4,
                height: screenWidth * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final buttonConfigs = [
      {
        'icon': Icons.psychology_outlined,
        'label': 'CONSEILLER DE STYLE',
        'subtitle': 'Chat IA personnalisé',
        'gradient': const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'shadowColor': const Color(0xFF667eea),
        'onPressed': () => _navigateToChat(context),
      },
      {
        'icon': Icons.diamond_outlined,
        'label': 'RECOMMANDATIONS',
        'subtitle': 'Suggestions personnalisées',
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'shadowColor': const Color(0xFFFF6B6B),
        'onPressed': () => _navigateToRecommendations(context),
      },
      {
        'icon': Icons.straighten,
        'label': 'MES MENSURATIONS',
        'subtitle': 'Gérez votre profil de mesures',
        'gradient': const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'shadowColor': const Color(0xFF4ECDC4),
        'onPressed': () => _navigateToMeasurements(context),
      },
      {
        'icon': Icons.style_outlined,
        'label': 'GARDE-ROBE',
        'subtitle': 'Collection personnelle',
        'gradient': const LinearGradient(
          colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'shadowColor': const Color(0xFF9B59B6),
        'onPressed': () => _navigateToWardrobe(context),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: List.generate(buttonConfigs.length, (index) {
          return AnimatedBuilder(
            animation: _buttonAnimations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - _buttonAnimations[index].value)),
                child: Opacity(
                  opacity: _buttonAnimations[index].value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.8 + (_buttonAnimations[index].value * 0.2),
                    child: _buildEnhancedButton(
                      context: context,
                      config: buttonConfigs[index],
                      index: index,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildEnhancedButton({
    required BuildContext context,
    required Map<String, dynamic> config,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            config['onPressed']();
          },
          borderRadius: BorderRadius.circular(25),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: config['gradient'],
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: config['shadowColor'].withOpacity(0.3),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      config['icon'],
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config['label'],
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          config['subtitle'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.9),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Méthodes de navigation avec animations personnalisées
  void _navigateToChat(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) => const ChatScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      _showLoginSnackBar(context);
    }
  }

  void _navigateToRecommendations(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const BurkinabeFashionAssistant(),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _navigateToMeasurements(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const ProfileMeasurementsPage(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _navigateToWardrobe(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => WardrobeScreen(),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showLoginSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Veuillez vous connecter pour accéder au chat'),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Se connecter',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, '/login'),
        ),
      ),
    );
  }
}