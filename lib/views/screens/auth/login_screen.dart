import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onRegisterClicked;

  const LoginScreen({super.key, this.onRegisterClicked, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _mainController;
  late AnimationController _floatingElementsController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideUpAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  Timer? _errorMessageTimer;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;

  // Dynamic color palette
  static const _primaryColor = Color(0xFF1E40AF); // Rich blue
  static const _secondaryColor = Color(0xFF3B82F6); // Bright blue
  static const _accentColor = Color(0xFF10B981); // Emerald green
  static const _surfaceColor = Color(0xFFF8FAFC); // Light gray
  static const _cardColor = Color(0xFFFFFFFF); // Pure white
  static const _textPrimary = Color(0xFF0F172A); // Dark slate
  static const _textSecondary = Color(0xFF64748B); // Medium slate
  static const _errorColor = Color(0xFFF59E0B); // Amber
  static const _successColor = Color(0xFF059669); // Dark emerald

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _floatingElementsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideUpAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_floatingElementsController);

    _mainController.forward();
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    HapticFeedback.lightImpact();
    _clearErrorMessage();
  }

  void _clearErrorMessage() {
    _errorMessageTimer?.cancel();
    _errorMessageTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await _redirectBasedOnRole(userCredential.user!);
        widget.onLoginSuccess?.call();
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getErrorMessage(e.code));
    } catch (e) {
      _showError('Une erreur inattendue s\'est produite');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _redirectBasedOnRole(userCredential.user!);
        widget.onLoginSuccess?.call();
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getErrorMessage(e.code));
    } catch (e) {
      _showError('Erreur lors de la connexion avec Google');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _redirectBasedOnRole(User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || !userDoc.data()!.containsKey('role')) {
        _showError('Profil utilisateur incomplet');
        await FirebaseAuth.instance.signOut();
        return;
      }

      final role = userDoc.data()!['role'] as String;
      if (!mounted) return;

      switch (role) {
        case 'createur':
          Navigator.pushReplacementNamed(context, '/creator-dashboard');
          break;
        case 'client':
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 'boutique':
          Navigator.pushReplacementNamed(context, '/shop-dashboard');
          break;
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
          break;
        default:
          _showError('Rôle non reconnu: $role');
      }
    } catch (e) {
      _showError('Erreur lors de la vérification du profil');
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Veuillez entrer une adresse email valide');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Email de réinitialisation envoyé à $email'),
                ),
              ],
            ),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      _showError('Échec de l\'envoi de l\'email de réinitialisation');
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-email':
        return 'Format d\'email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      default:
        return 'Connexion échouée. Veuillez réessayer.';
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatingElementsController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _errorMessageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: _surfaceColor,
      body: Stack(
        children: [
          // Animated background elements
          AnimatedBuilder(
            animation: _floatingElementsController,
            builder: (context, child) {
              return CustomPaint(
                painter: FloatingElementsPainter(_rotationAnimation.value),
                size: size,
              );
            },
          ),

          // Main content
          SafeArea(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.translate(
                    offset: Offset(0, _slideUpAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 24 : 48,
                            vertical: 32,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: size.height * 0.05),
                              _buildLogo(),
                              const SizedBox(height: 48),
                              _buildLoginCard(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.2 + _pulseController.value * 0.2),
                    blurRadius: 25 + _pulseController.value * 15,
                    spreadRadius: _pulseController.value * 8,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Transform.scale(
                scale: 1.0 + _pulseController.value * 0.1,
                child: SvgPicture.asset(
                  'assets/logo/logo.svg',
                  width: 68,
                  height: 68,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    _primaryColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ElegantFaso',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre plateforme Personnelle de Mode Burkinabè',
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Connexion',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null) ...[
                _buildErrorCard(),
                const SizedBox(height: 24),
              ],

              _buildEmailField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: Text(
                    'Mot de passe oublié?',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              _buildLoginButton(),
              const SizedBox(height: 32),

              _buildDivider(),
              const SizedBox(height: 32),

              _buildGoogleButton(),
              const SizedBox(height: 32),

              _buildRegisterLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: _errorColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: _errorColor),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).shake();
  }

  Widget _buildEmailField() {
    return Focus(
      onFocusChange: (focused) => setState(() => _isEmailFocused = focused),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Email requis';
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Format email invalide';
          }
          return null;
        },
        style: TextStyle(
          color: _textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Adresse email',
          hintText: 'votre@email.com',
          prefixIcon: Icon(
            Icons.email_outlined,
            color: _isEmailFocused ? _primaryColor : _textSecondary,
          ),
          filled: true,
          fillColor: _isEmailFocused ? _primaryColor.withOpacity(0.05) : _surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _errorColor, width: 2),
          ),
          labelStyle: TextStyle(
            color: _isEmailFocused ? _primaryColor : _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Focus(
      onFocusChange: (focused) => setState(() => _isPasswordFocused = focused),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submitForm(),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Mot de passe requis';
          if (value.length < 6) return 'Minimum 6 caractères';
          return null;
        },
        style: TextStyle(
          color: _textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Mot de passe',
          prefixIcon: Icon(
            Icons.lock_outline,
            color: _isPasswordFocused ? _primaryColor : _textSecondary,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: _isPasswordFocused ? _primaryColor : _textSecondary,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          filled: true,
          fillColor: _isPasswordFocused ? _primaryColor.withOpacity(0.05) : _surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _errorColor, width: 2),
          ),
          labelStyle: TextStyle(
            color: _isPasswordFocused ? _primaryColor : _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _submitForm,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
                : Text(
              'SE CONNECTER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _textSecondary.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OU',
            style: TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: _textSecondary.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _textSecondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _signInWithGoogle,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FontAwesome.google, color: const Color(0xFFDB4437), size: 20),
              const SizedBox(width: 12),
              Text(
                'Continuer avec Google',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: Text.rich(
        TextSpan(
          text: 'Nouveau sur ElegantFaso? ',
          style: TextStyle(color: _textSecondary, fontSize: 16),
          children: [
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_primaryColor),
                strokeWidth: 4,
              ),
              const SizedBox(height: 16),
              Text(
                'Connexion en cours...',
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FloatingElementsPainter extends CustomPainter {
  final double rotation;

  FloatingElementsPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E40AF).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw floating circles
    for (int i = 0; i < 6; i++) {
      final angle = (rotation + i * math.pi / 3) % (2 * math.pi);
      final radius = 60 + i * 20;
      final x = size.width * 0.8 + radius * math.cos(angle);
      final y = size.height * 0.3 + radius * math.sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        8 + i * 2,
        paint..color = Color(0xFF1E40AF).withOpacity(0.05 + i * 0.02),
      );
    }

    // Draw floating shapes on the left
    for (int i = 0; i < 4; i++) {
      final angle = (rotation * 0.7 + i * math.pi / 2) % (2 * math.pi);
      final radius = 40 + i * 15;
      final x = size.width * 0.1 + radius * math.cos(angle);
      final y = size.height * 0.7 + radius * math.sin(angle);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 12, height: 12),
          const Radius.circular(3),
        ),
        paint..color = Color(0xFF10B981).withOpacity(0.08 + i * 0.02),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}