import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/account_roles.dart';
import '../../../../data/repositories/auth_repository.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onLoginClicked;
  final VoidCallback? onRegisterSuccess;

  const RegisterScreen({
    super.key,
    this.onLoginClicked,
    this.onRegisterSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  String? _errorMessage;
  String _passwordStrength = '';

  static const _primary = Color(0xFF0F766E);
  static const _tealDark = Color(0xFF115E59);
  static const _violet = Color(0xFF7C3AED);
  static const _amber = Color(0xFFF59E0B);
  static const _rose = Color(0xFFE11D48);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _bg = Color(0xFFF6F7F9);
  static const _surface = Colors.white;
  static const _border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final value = _passwordController.text;
    final next =
        value.isEmpty
            ? ''
            : value.length >= 10 &&
                RegExp(r'[A-Z]').hasMatch(value) &&
                RegExp(r'[0-9]').hasMatch(value)
            ? 'Fort'
            : value.length >= 6
            ? 'Moyen'
            : 'Faible';
    if (next != _passwordStrength) {
      setState(() => _passwordStrength = next);
    }
  }

  Future<void> _register() async {
    if (_isLoading || _isGoogleLoading) return;
    if (!_termsAccepted) {
      _showError('Veuillez accepter les conditions pour continuer.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authRepository.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: AccountRoles.client,
      );
      widget.onRegisterSuccess?.call();
      await _redirect(result);
    } on FirebaseAuthException catch (e) {
      _showError(_authError(e));
    } catch (_) {
      _showError('Inscription impossible pour le moment.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleRegister() async {
    if (_isLoading || _isGoogleLoading) return;
    if (!_termsAccepted) {
      _showError(
        'Veuillez accepter les conditions pour continuer avec Google.',
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authRepository.signInWithGoogle(
        role: AccountRoles.client,
      );
      widget.onRegisterSuccess?.call();
      await _redirect(result);
    } on FirebaseAuthException catch (e) {
      _showError(_authError(e));
    } catch (_) {
      _showError('Inscription Google impossible.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _redirect(AuthResult result) async {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      result.redirectRoute ?? '/home',
      (route) => false,
    );
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    HapticFeedback.mediumImpact();
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'network-request-failed':
        return e.message ??
            'Connexion impossible. Vérifiez Internet puis réessayez.';
      case 'google-signin-aborted':
        return 'Inscription Google annulée.';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec une autre méthode de connexion.';
      case 'account-closed':
        return 'Ce compte est fermé. Contactez l’administration pour le réactiver avant de continuer.';
      case 'account-suspended':
        return 'Ce compte est suspendu. Contactez l’administration pour plus d’informations.';
      default:
        return e.message ?? 'Inscription échouée.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 760;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child:
                      isWide
                          ? Row(
                            children: [
                              Expanded(child: _buildBrandPanel()),
                              const SizedBox(width: 22),
                              Expanded(child: _buildFormCard()),
                            ],
                          )
                          : Column(
                            children: [
                              _buildBrandPanel(compact: true),
                              const SizedBox(height: 18),
                              _buildFormCard(),
                            ],
                          ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandPanel({bool compact = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 22 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _tealDark, _violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogoBadge(),
          SizedBox(height: compact ? 22 : 42),
          Text(
            'Créez votre compte client',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 28 : 36,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Commencez par explorer le Salon. Vous pourrez ensuite ouvrir votre atelier ou votre boutique quand vous serez prêt.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Un compte suffit pour suivre vos favoris, vos commandes et vos échanges.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoBadge() {
    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: SvgPicture.asset(
        'assets/logo/logo.svg',
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 30,
            offset: Offset(0, 16),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Inscription',
              style: TextStyle(
                color: _ink,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Quelques informations, et vous entrez dans le Salon.',
              style: TextStyle(
                color: _muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            if (_errorMessage != null) ...[
              _ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 14),
            ],
            _AuthField(
              controller: _nameController,
              label: 'Nom complet',
              icon: Icons.person_rounded,
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Nom requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _AuthField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.mail_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email requis';
                }
                if (!value.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _AuthField(
              controller: _passwordController,
              label: 'Mot de passe',
              icon: Icons.lock_rounded,
              obscureText: _obscurePassword,
              suffix: IconButton(
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: _muted,
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Minimum 6 caractères';
                }
                return null;
              },
            ),
            if (_passwordStrength.isNotEmpty) ...[
              const SizedBox(height: 8),
              _PasswordStrength(label: _passwordStrength),
            ],
            const SizedBox(height: 14),
            _AuthField(
              controller: _confirmPasswordController,
              label: 'Confirmer le mot de passe',
              icon: Icons.lock_reset_rounded,
              obscureText: _obscureConfirmPassword,
              suffix: IconButton(
                onPressed:
                    () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: _muted,
                ),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTerms(),
            const SizedBox(height: 18),
            _PrimaryButton(
              label: 'Créer mon compte client',
              icon: Icons.person_add_alt_rounded,
              loading: _isLoading,
              enabled: !_isGoogleLoading,
              onPressed: _register,
            ),
            const SizedBox(height: 14),
            _SocialButton(
              label: 'Créer mon compte avec Google',
              loading: _isGoogleLoading,
              enabled: !_isLoading,
              onPressed: _googleRegister,
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Déjà inscrit ? ',
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onLoginClicked?.call();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return InkWell(
      onTap: () => setState(() => _termsAccepted = !_termsAccepted),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _termsAccepted ? _primary.withValues(alpha: 0.28) : _border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _termsAccepted,
              onChanged:
                  (value) => setState(() => _termsAccepted = value ?? false),
              activeColor: _primary,
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 11),
                child: Text(
                  'J’accepte les conditions d’utilisation et la politique de confidentialité.',
                  style: TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _RegisterScreenState._primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: _RegisterScreenState._bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _RegisterScreenState._primary),
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  final String label;

  const _PasswordStrength({required this.label});

  @override
  Widget build(BuildContext context) {
    final color =
        label == 'Fort'
            ? _RegisterScreenState._primary
            : label == 'Moyen'
            ? _RegisterScreenState._amber
            : _RegisterScreenState._rose;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value:
                  label == 'Fort'
                      ? 1
                      : label == 'Moyen'
                      ? .62
                      : .32,
              minHeight: 6,
              backgroundColor: _RegisterScreenState._border,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.loading,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: loading || !enabled ? null : onPressed,
        icon:
            loading
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Icon(icon),
        label: Text(
          loading ? 'Création...' : label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _RegisterScreenState._primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.loading,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: loading || !enabled ? null : onPressed,
        icon:
            loading
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.g_mobiledata_rounded, size: 28),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _RegisterScreenState._ink,
          side: const BorderSide(color: _RegisterScreenState._border),
          minimumSize: const Size(0, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _RegisterScreenState._rose.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _RegisterScreenState._rose.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _RegisterScreenState._rose,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _RegisterScreenState._ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
