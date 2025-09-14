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
import '../../../../data/repositories/auth_repository.dart';
import 'login_screen.dart';

enum UserRole { client, createur, boutique }

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onLoginClicked;
  final VoidCallback? onRegisterSuccess;

  const RegisterScreen({super.key, this.onLoginClicked, this.onRegisterSuccess});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {

  // Animation controllers
  late AnimationController _mainController;
  late AnimationController _floatingElementsController;
  late AnimationController _pulseController;
  late AnimationController _roleSelectionController;
  late AnimationController _logoController;
  late AnimationController _shakeController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideUpAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _roleSelectionAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _logoGlowAnimation;
  late Animation<double> _shakeAnimation;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  String? _errorMessage;
  Timer? _errorMessageTimer;
  UserRole? _selectedRole;
  String _passwordStrength = '';

  // Focus states
  bool _isNameFocused = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;

  // Current authentication method for loading indicator
  AuthMethod? _currentAuthMethod;

  // Dynamic color palette
  static const _primaryColor = Color(0xFF1E40AF);
  static const _secondaryColor = Color(0xFF3B82F6);
  static const _accentColor = Color(0xFF10B981);
  static const _surfaceColor = Color(0xFFF8FAFC);
  static const _cardColor = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _errorColor = Color(0xFFF59E0B);
  static const _successColor = Color(0xFF059669);
  static const _facebookColor = Color(0xFF1877F2);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _initAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _floatingElementsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _roleSelectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _slideUpAnimation = Tween<double>(
      begin: 80.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
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

    _roleSelectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _roleSelectionController,
      curve: Curves.elasticOut,
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _logoGlowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));

    _mainController.forward();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    String strength = '';

    if (password.isEmpty) {
      strength = '';
    } else if (password.length < 6) {
      strength = 'Faible';
    } else if (password.length >= 12 &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password)) {
      strength = 'Très fort';
    } else if (password.length >= 8 &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength = 'Fort';
    } else {
      strength = 'Moyen';
    }

    if (_passwordStrength != strength) {
      setState(() => _passwordStrength = strength);
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    HapticFeedback.lightImpact();
    _shakeController.forward().then((_) => _shakeController.reset());
    _clearErrorMessage();
  }

  void _clearErrorMessage() {
    _errorMessageTimer?.cancel();
    _errorMessageTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _register() async {
    if (_selectedRole == null) {
      _showError('Veuillez sélectionner votre rôle');
      _roleSelectionController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _roleSelectionController.reverse();
        });
      });
      return;
    }
    if (!_termsAccepted) {
      _showError('Veuillez accepter les conditions d\'utilisation');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authResult = await _authRepository.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole.toString().split('.').last,
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pushReplacementNamed(context, authResult.redirectRoute!);
        widget.onRegisterSuccess?.call();
      }
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      _showError(_getErrorMessage(e.code));
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showError('Erreur inattendue: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_selectedRole == null) {
      _showError('Veuillez sélectionner votre rôle');
      _roleSelectionController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _roleSelectionController.reverse();
        });
      });
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentAuthMethod = AuthMethod.google;
    });

    try {
      final authResult = await _authRepository.signInWithGoogle(
        role: _selectedRole.toString().split('.').last,
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pushReplacementNamed(context, authResult.redirectRoute!);
        widget.onRegisterSuccess?.call();
      }
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      _showError(_getErrorMessage(e.code));
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showError('Erreur Google: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentAuthMethod = null;
        });
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cette adresse email est déjà utilisée';
      case 'invalid-email':
        return 'Format d\'email invalide';
      case 'operation-not-allowed':
        return 'Opération non autorisée';
      case 'weak-password':
        return 'Mot de passe trop faible (minimum 6 caractères)';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'facebook-signin-failed':
        return 'Échec de la connexion Facebook. Veuillez réessayer.';
      case 'google-signin-failed':
        return 'Échec de la connexion Google. Veuillez réessayer.';
      case 'facebook-auth-cancelled':
        return 'Connexion Facebook annulée';
      case 'facebook-permission-denied':
        return 'Permission refusée par Facebook';
      case 'facebook-invalid-config':
        return 'Configuration Facebook invalide';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec un autre fournisseur';
      default:
        return 'Erreur lors de l\'inscription';
    }
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case 'Très fort':
        return _successColor;
      case 'Fort':
        return _accentColor;
      case 'Moyen':
        return _errorColor;
      case 'Faible':
        return Colors.red;
      default:
        return _textSecondary;
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatingElementsController.dispose();
    _pulseController.dispose();
    _roleSelectionController.dispose();
    _logoController.dispose();
    _shakeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _errorMessageTimer?.cancel();
    super.dispose();
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête professionnel
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: _primaryColor.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.gavel_rounded,
                          color: _primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conditions Générales d\'Utilisation',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ElegantFaso',
                              style: TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: _textSecondary),
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 24,
                      ),
                    ],
                  ),
                ),

                // Contenu avec défilement
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('PRÉAMBULE'),
                        _buildSectionText('Bienvenue sur ElegantFaso, plateforme numérique dédiée à la valorisation de la mode burkinabè et ouest-africaine. Notre écosystème connecte créateurs, artisans, boutiques locales et clients à travers des technologies d\'intelligence artificielle, d\'e-commerce et d\'expérience utilisateur innovantes.'),

                        _buildSectionTitle('ARTICLE 1 - DÉFINITIONS'),
                        _buildSectionSubtitle('1.1 ElegantFaso'),
                        _buildSectionText('Désigne la plateforme numérique comprenant l\'application mobile, le site web et l\'ensemble des services connectés exploités par la société ElegantFaso SARL, immatriculée au Registre du Commerce et du Crédit Mobilier du Burkina Faso.'),

                        _buildSectionSubtitle('1.2 Utilisateurs'),
                        _buildDefinitionItem('Client Final', 'Consommateur utilisant la plateforme pour rechercher et acquérir des produits de mode.'),
                        _buildDefinitionItem('Créateur/Artisan', 'Professionnel indépendant proposant ses créations originales via la plateforme.'),
                        _buildDefinitionItem('Boutique Partenaire', 'Entité commerciale physique distribuant des produits de mode via notre réseau.'),
                        _buildDefinitionItem('Assistant IA', 'Système d\'intelligence artificielle intégré fournissant des recommandations personnalisées.'),

                        _buildSectionTitle('ARTICLE 2 - ACCEPTATION ET OPPOSABILITÉ'),
                        _buildSectionText('L\'utilisation de la plateforme ElegantFaso est conditionnée à l\'acceptation expresse et sans réserve des présentes Conditions Générales d\'Utilisation. Cette acceptation est matérialisée par la création d\'un compte utilisateur.'),

                        _buildSectionSubtitle('2.1 Modalités d\'acceptation'),
                        _buildBulletPoint('Validation explicite lors de l\'inscription'),
                        _buildBulletPoint('Notification et validation lors des mises à jour importantes'),
                        _buildBulletPoint('Acceptation tacite pour les améliorations techniques mineures'),

                        _buildSectionTitle('ARTICLE 3 - AUTHENTIFICATION ET SÉCURITÉ'),
                        _buildSectionSubtitle('3.1 Obligation d\'authentification'),
                        _buildSectionText('L\'accès à l\'ensemble des fonctionnalités de la plateforme nécessite une authentification préalable via un compte personnel sécurisé.'),

                        _buildSectionSubtitle('3.2 Moyens d\'authentification'),
                        _buildBulletPoint('Compte personnel (adresse email et mot de passe sécurisé)'),
                        _buildBulletPoint('Authentification biométrique (optionnelle)'),
                        _buildBulletPoint('Connexion via fournisseurs tiers (Facebook, Google)'),

                        _buildSectionTitle('ARTICLE 4 - SERVICES PROPOSÉS'),
                        _buildSectionSubtitle('4.1 Services aux clients'),
                        _buildBulletPoint('Personnalisation intelligente basée sur l\'IA'),
                        _buildBulletPoint('Essayage virtuel et réalité augmentée'),
                        _buildBulletPoint('Recommandations adaptées aux conditions météorologiques'),
                        _buildBulletPoint('Plateforme d\'achat sécurisée et salon communautaire'),

                        _buildSectionSubtitle('4.2 Services aux créateurs'),
                        _buildBulletPoint('Vitrine digitale personnalisée et gestion de collections'),
                        _buildBulletPoint('Outils d\'analyse et de promotion payante'),
                        _buildBulletPoint('Système de gestion des commandes et relation client'),

                        _buildSectionSubtitle('4.3 Services aux boutiques'),
                        _buildBulletPoint('Plateforme géolocalisée et gestion multi-canal'),
                        _buildBulletPoint('Outils d\'analyse business et tableaux de bord'),
                        _buildBulletPoint('Intégration des systèmes de paiement locaux'),

                        _buildSectionTitle('ARTICLE 5 - MODÈLE ÉCONOMIQUE'),
                        _buildSectionSubtitle('5.1 Moyens de paiement acceptés'),
                        _buildBulletPoint('Mobile Money (Orange Money, Moov Money)'),
                        _buildBulletPoint('Cartes bancaires nationales et internationales'),
                        _buildBulletPoint('Virements bancaires et paiement à la livraison'),

                        _buildSectionSubtitle('5.2 Structure tarifaire'),
                        _buildSectionText('Les tarifs sont clairement affichés sur la plateforme. Les commissions et frais de service sont transparents et communiqués préalablement à toute transaction.'),

                        _buildSectionTitle('ARTICLE 6 - PROTECTION DES DONNÉES'),
                        _buildSectionText('ElegantFaso s\'engage au respect strict des législations burkinabè, des normes CEDEAO et des standards internationaux en matière de protection des données personnelles. Toutes les données sont sécurisées par chiffrement SSL 256 bits.'),

                        _buildSectionTitle('ARTICLE 7 - RESPONSABILITÉS'),
                        _buildSectionSubtitle('7.1 Responsabilité de la plateforme'),
                        _buildSectionText('ElegantFaso s\'engage à maintenir la qualité et la sécurité des services proposés, dans la limite des contraintes techniques et réglementaires.'),

                        _buildSectionSubtitle('7.2 Responsabilité des utilisateurs'),
                        _buildSectionText('Les utilisateurs sont responsables de l\'exactitude des informations fournies et de l\'utilisation conforme des services proposés.'),

                        _buildSectionTitle('ARTICLE 8 - DURÉE ET RÉSILIATION'),
                        _buildSectionText('Les présentes conditions s\'appliquent pour toute la durée d\'utilisation de la plateforme. Elles peuvent être résiliées à tout moment par l\'utilisateur ou par ElegantFaso selon les modalités définies.'),

                        _buildSectionTitle('ARTICLE 9 - DROIT APPLICABLE'),
                        _buildSectionText('Les présentes conditions sont régies par le droit burkinabè. Tout litige relève de la compétence exclusive des tribunaux de Ouagadougou, sauf résolution amiable préalable.'),

                        const SizedBox(height: 24),

                        // Informations légales
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _primaryColor.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INFORMATIONS LÉGALES',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildLegalInfo('Société', 'ElegantFaso'),
                              _buildLegalInfo('Siège social', 'Ouagadougou, Burkina Faso'),
                              _buildLegalInfo('Email', 'support@elegantfaso.bf'),
                              _buildLegalInfo('Téléphone', '(+226) 05 67 09 81'),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Version 1.0',
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Mise à jour : 12 juillet 2025',
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bouton d'acceptation professionnel
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.02),
                    border: Border(
                      top: BorderSide(
                        color: _primaryColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _termsAccepted = true);
                        Navigator.pop(context);
                        HapticFeedback.lightImpact();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'J\'accepte les conditions générales d\'utilisation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate(
          delay: 100.ms,
          effects: [
            ScaleEffect(
              begin: const Offset(0.95, 0.95),
              curve: Curves.easeOutQuart,
              duration: 300.ms,
            ),
            FadeEffect(
              curve: Curves.easeInOut,
              duration: 250.ms,
            ),
          ],
        );
      },
    ).then((_) {
      HapticFeedback.lightImpact();
    });
  }

// Méthodes utilitaires professionnelles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _primaryColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildSectionSubtitle(String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: _textSecondary,
          height: 1.6,
          letterSpacing: 0.1,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildDefinitionItem(String term, String definition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: _textSecondary,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: '$term : ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            TextSpan(text: definition),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 12),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label :',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildProfileItem(String icon, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded( // Évite l'overflow pour les descriptions longues
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final screenHeight = size.height;
    final screenWidth = size.width;

    return Scaffold(
      backgroundColor: _surfaceColor,
      body: Stack(
        children: [
          // Enhanced animated background elements
          AnimatedBuilder(
            animation: _floatingElementsController,
            builder: (context, child) {
              return CustomPaint(
                painter: EnhancedFloatingElementsPainter(_rotationAnimation.value),
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
                            horizontal: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.1,
                            vertical: screenHeight * 0.02,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              _buildEnhancedLogo(),
                              SizedBox(height: screenHeight * 0.03),
                              _buildRegisterCard(),
                              SizedBox(height: screenHeight * 0.02),
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
          if (_isLoading) _buildEnhancedLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildEnhancedLogo() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final logoSize = isSmallScreen ? 80.0 : 120.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primaryColor.withOpacity(0.1),
                    _primaryColor.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(_logoGlowAnimation.value * 0.3),
                    blurRadius: 30 + _pulseController.value * 20,
                    spreadRadius: _pulseController.value * 10,
                  ),
                  BoxShadow(
                    color: _secondaryColor.withOpacity(_logoGlowAnimation.value * 0.2),
                    blurRadius: 50 + _logoController.value * 20,
                    spreadRadius: _logoController.value * 5,
                  ),
                ],
              ),
              child: Center(
                child: Transform.scale(
                  scale: _logoScaleAnimation.value,
                  child: Transform.rotate(
                    angle: _logoRotationAnimation.value,
                    child: Container(
                      width: logoSize * 0.7,
                      height: logoSize * 0.7,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        'assets/logo/logo.svg',
                        colorFilter: ColorFilter.mode(
                          _primaryColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              'Rejoignez ElegantFaso',
              style: TextStyle(
                fontSize: isSmallScreen ? 24 : 28,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
                letterSpacing: -0.8,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'Créez votre compte professionnel',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: _primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRegisterCard() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final screenHeight = size.height;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation.value * 10 * math.sin(_shakeController.value * math.pi * 8),
            0,
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: isSmallScreen ? double.infinity : 500),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: _primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 26,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    if (_errorMessage != null) ...[
                      _buildEnhancedErrorCard(),
                      SizedBox(height: screenHeight * 0.02),
                    ],

                    _buildEnhancedNameField(),
                    SizedBox(height: screenHeight * 0.02),

                    _buildEnhancedEmailField(),
                    SizedBox(height: screenHeight * 0.02),

                    _buildEnhancedPasswordField(),
                    SizedBox(height: screenHeight * 0.02),
                    _buildEnhancedConfirmPasswordField(),
                    SizedBox(height: screenHeight * 0.02),

                    _buildEnhancedRoleSelection(),
                    SizedBox(height: screenHeight * 0.02),

                    _buildEnhancedTermsAcceptance(),
                    SizedBox(height: screenHeight * 0.03),

                    _buildEnhancedRegisterButton(),
                    SizedBox(height: screenHeight * 0.03),

                    _buildEnhancedDivider(),
                    SizedBox(height: screenHeight * 0.03),

                    // Social buttons
                    _buildEnhancedGoogleButton(),
                    SizedBox(height: screenHeight * 0.03),

                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedTermsAcceptance() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: _termsAccepted,
            onChanged: (value) {
              setState(() {
                _termsAccepted = value ?? false;
                if (_termsAccepted) _errorMessage = null;
              });
              HapticFeedback.selectionClick();
            },
            activeColor: _primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () {
              _showTermsDialog();
              HapticFeedback.selectionClick();
            },
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'J\'accepte les '),
                  TextSpan(
                    text: 'Conditions d\'utilisation',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' et la '),
                  TextSpan(
                    text: 'Politique de confidentialité',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' d\'ElegantFaso'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _errorColor.withOpacity(0.1),
            _errorColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _errorColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _errorColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning_rounded, color: _errorColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: _errorColor),
            onPressed: () => setState(() => _errorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildEnhancedNameField() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nom complet',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() => _isNameFocused = hasFocus);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isNameFocused
                    ? _primaryColor
                    : Colors.grey.withOpacity(0.3),
                width: _isNameFocused ? 2 : 1,
              ),
              gradient: _isNameFocused
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor.withOpacity(0.05),
                  _secondaryColor.withOpacity(0.02),
                ],
              )
                  : null,
              boxShadow: _isNameFocused
                  ? [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [],
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Entrez votre nom complet',
                hintStyle: TextStyle(
                  color: _textSecondary.withOpacity(0.6),
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                prefixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isNameFocused
                        ? _primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: _isNameFocused ? _primaryColor : _textSecondary,
                    size: 20,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              style: TextStyle(
                color: _textPrimary,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                if (value.trim().length < 2) {
                  return 'Le nom doit contenir au moins 2 caractères';
                }
                return null;
              },
              onTap: () => HapticFeedback.selectionClick(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedEmailField() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adresse email',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() => _isEmailFocused = hasFocus);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isEmailFocused
                    ? _primaryColor
                    : Colors.grey.withOpacity(0.3),
                width: _isEmailFocused ? 2 : 1,
              ),
              gradient: _isEmailFocused
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor.withOpacity(0.05),
                  _secondaryColor.withOpacity(0.02),
                ],
              )
                  : null,
              boxShadow: _isEmailFocused
                  ? [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [],
            ),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'exemple@elegantfaso.com',
                hintStyle: TextStyle(
                  color: _textSecondary.withOpacity(0.6),
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                prefixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isEmailFocused
                        ? _primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: _isEmailFocused ? _primaryColor : _textSecondary,
                    size: 20,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              style: TextStyle(
                color: _textPrimary,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'email est obligatoire';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value.trim())) {
                  return 'Format d\'email invalide';
                }
                return null;
              },
              onTap: () => HapticFeedback.selectionClick(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedPasswordField() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mot de passe',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() => _isPasswordFocused = hasFocus);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPasswordFocused
                    ? _primaryColor
                    : Colors.grey.withOpacity(0.3),
                width: _isPasswordFocused ? 2 : 1,
              ),
              gradient: _isPasswordFocused
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor.withOpacity(0.05),
                  _secondaryColor.withOpacity(0.02),
                ],
              )
                  : null,
              boxShadow: _isPasswordFocused
                  ? [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [],
            ),
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Créez un mot de passe sécurisé',
                hintStyle: TextStyle(
                  color: _textSecondary.withOpacity(0.6),
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                prefixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isPasswordFocused
                        ? _primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: _isPasswordFocused ? _primaryColor : _textSecondary,
                    size: 20,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: _isPasswordFocused ? _primaryColor : _textSecondary,
                      size: 20,
                      key: ValueKey(_obscurePassword),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                    HapticFeedback.selectionClick();
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              style: TextStyle(
                color: _textPrimary,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le mot de passe est obligatoire';
                }
                if (value.length < 6) {
                  return 'Minimum 6 caractères requis';
                }
                return null;
              },
              onTap: () => HapticFeedback.selectionClick(),
            ),
          ),
        ),
        if (_passwordController.text.isNotEmpty) ...[
          SizedBox(height: isSmallScreen ? 4 : 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getPasswordStrengthColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getPasswordStrengthColor().withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _passwordStrength == 'Très fort'
                      ? Icons.check_circle
                      : _passwordStrength == 'Fort'
                      ? Icons.verified
                      : Icons.info_outline,
                  color: _getPasswordStrengthColor(),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Force: $_passwordStrength',
                  style: TextStyle(
                    color: _getPasswordStrengthColor(),
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnhancedConfirmPasswordField() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmez le mot de passe',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() => _isConfirmPasswordFocused = hasFocus);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isConfirmPasswordFocused
                    ? _primaryColor
                    : Colors.grey.withOpacity(0.3),
                width: _isConfirmPasswordFocused ? 2 : 1,
              ),
              gradient: _isConfirmPasswordFocused
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor.withOpacity(0.05),
                  _secondaryColor.withOpacity(0.02),
                ],
              )
                  : null,
              boxShadow: _isConfirmPasswordFocused
                  ? [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [],
            ),
            child: TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: 'Confirmez votre mot de passe',
                hintStyle: TextStyle(
                  color: _textSecondary.withOpacity(0.6),
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                prefixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isConfirmPasswordFocused
                        ? _primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: _isConfirmPasswordFocused ? _primaryColor : _textSecondary,
                    size: 20,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: _isConfirmPasswordFocused ? _primaryColor : _textSecondary,
                      size: 20,
                      key: ValueKey(_obscureConfirmPassword),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    HapticFeedback.selectionClick();
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              style: TextStyle(
                color: _textPrimary,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez confirmer votre mot de passe';
                }
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
              onTap: () => HapticFeedback.selectionClick(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedRoleSelection() {
    return AnimatedBuilder(
      animation: _roleSelectionController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_roleSelectionAnimation.value * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisissez votre profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedRole != null
                        ? _primaryColor.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                  ),
                  gradient: _selectedRole != null
                      ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _primaryColor.withOpacity(0.05),
                      _secondaryColor.withOpacity(0.02),
                    ],
                  )
                      : null,
                ),
                child: Column(
                  children: [
                    _buildRoleOption(
                      UserRole.client,
                      'Client',
                      'Découvrez et achetez des créations uniques',
                      Icons.shopping_bag_outlined,
                      _accentColor,
                    ),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                    _buildRoleOption(
                      UserRole.createur,
                      'Créateur',
                      'Vendez vos créations et développez votre marque',
                      Icons.palette_outlined,
                      _primaryColor,
                    ),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                    _buildRoleOption(
                      UserRole.boutique,
                      'Boutique',
                      'Gérez votre boutique et vos collections',
                      Icons.store_outlined,
                      _secondaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleOption(
      UserRole role,
      String title,
      String description,
      IconData icon,
      Color color,
      ) {
    final isSelected = _selectedRole == role;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = role;
            _errorMessage = null;
          });
          HapticFeedback.selectionClick();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? color : _textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.withOpacity(0.4),
                    width: 2,
                  ),
                  color: isSelected ? color : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedRegisterButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, _secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _primaryColor.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _isLoading ? null : _register,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2.5,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Créer mon compte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _textSecondary.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OU',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _textSecondary.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedGoogleButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _isLoading ? null : _signInWithGoogle,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isLoading && _currentAuthMethod == AuthMethod.google)
                Positioned(
                  right: 16,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _textPrimary,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/google.svg',
                    width: 24,
                    height: 24,
                  ),
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
            ],
          ),
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(),
      ).shake(
        hz: 2,
        curve: Curves.easeInOut,
        duration: 2000.ms,
      ),
    );
  }

  Widget _buildLoginLink() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Vous avez déjà un compte?',
            style: TextStyle(
              color: _textSecondary,
              fontSize: isSmallScreen ? 12 : 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Se connecter',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                strokeWidth: 3,
              ),
              SvgPicture.asset(
                'assets/logo/logo.svg',
                width: 36,
                height: 36,
                colorFilter: ColorFilter.mode(
                  _primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnhancedFloatingElementsPainter extends CustomPainter {
  final double rotationValue;

  EnhancedFloatingElementsPainter(this.rotationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF1E40AF).withOpacity(0.05),
          const Color(0xFF3B82F6).withOpacity(0.03),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 8; i++) {
      final angle = rotationValue + (i * math.pi / 4);
      final distance = size.width * 0.3;
      final offset = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      canvas.drawCircle(
        offset,
        size.width * 0.08,
        paint..color = const Color(0xFF1E40AF).withOpacity(0.03),
      );
    }

    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFEFF6FF),
          ],
        ).createShader(Rect.fromLTRB(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}