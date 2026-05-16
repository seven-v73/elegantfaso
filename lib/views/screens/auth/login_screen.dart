import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../design/app_icons.dart';
import '../../../core/account_roles.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onRegisterClicked;

  const LoginScreen({super.key, this.onRegisterClicked, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAdminBootstrapLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const _primary = Color(0xFF0F766E);
  static const _tealDark = Color(0xFF115E59);
  static const _violet = Color(0xFF7C3AED);
  static const _rose = Color(0xFFE11D48);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _bg = Color(0xFFF6F7F9);
  static const _surface = Colors.white;
  static const _border = Color(0xFFE5E7EB);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authRepository.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      widget.onLoginSuccess?.call();
      await _redirect(result);
    } on FirebaseAuthException catch (e) {
      _showError(_authError(e));
    } catch (_) {
      _showError('Connexion impossible pour le moment.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authRepository.signInWithGoogle();
      widget.onLoginSuccess?.call();
      await _redirect(result);
    } on FirebaseAuthException catch (e) {
      _showError(_authError(e));
    } catch (_) {
      _showError('Connexion Google impossible.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  bool get _showAdminBootstrap {
    if (kReleaseMode) return false;
    return (dotenv.env['ENABLE_DEFAULT_ADMIN_BOOTSTRAP'] ?? '')
            .trim()
            .toLowerCase() ==
        'true';
  }

  String get _defaultAdminEmail {
    return (dotenv.env['DEFAULT_ADMIN_EMAIL'] ?? '').trim();
  }

  String get _defaultAdminPassword {
    return dotenv.env['DEFAULT_ADMIN_PASSWORD'] ?? '';
  }

  String get _defaultAdminName {
    return (dotenv.env['DEFAULT_ADMIN_NAME'] ?? 'Administrateur ElegantStyle')
        .trim();
  }

  Future<void> _bootstrapDefaultAdmin() async {
    final email = _defaultAdminEmail;
    final password = _defaultAdminPassword;
    if (email.isEmpty || password.length < 6) {
      _showError(
        'Configuration admin locale incomplète. Email et mot de passe de 6 caractères minimum requis.',
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isAdminBootstrapLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authRepository.bootstrapDefaultAdmin(
        email: email,
        password: password,
        name: _defaultAdminName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin prêt: $email'),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _redirect(result);
    } on FirebaseAuthException catch (e) {
      _showError(_authError(e));
    } catch (_) {
      _showError('Initialisation admin impossible pour le moment.');
    } finally {
      if (mounted) setState(() => _isAdminBootstrapLoading = false);
    }
  }

  Future<void> _redirect(AuthResult result) async {
    if (!mounted) return;
    final route =
        result.redirectRoute ??
        _routeForRole(result.userRole ?? AccountRoles.client);
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Entrez votre email pour réinitialiser le mot de passe.');
      return;
    }

    try {
      await _authRepository.resetPassword(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email de réinitialisation envoyé à $email'),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      _showError('Impossible d’envoyer l’email de réinitialisation.');
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    HapticFeedback.mediumImpact();
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'account-closed':
        return 'Ce compte est fermé. Contactez l’administration pour demander une réactivation.';
      case 'account-suspended':
        return 'Ce compte est suspendu. Contactez l’administration pour plus d’informations.';
      case 'network-request-failed':
        return e.message ??
            'Connexion impossible. Vérifiez Internet puis réessayez.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'google-signin-aborted':
        return 'Connexion Google annulée.';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec une autre méthode de connexion.';
      default:
        return e.message ?? 'Connexion échouée.';
    }
  }

  String _routeForRole(String role) {
    switch (role) {
      case AccountRoles.admin:
        return '/admin';
      case AccountRoles.client:
      case AccountRoles.createur:
      case AccountRoles.boutique:
      default:
        return '/home';
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
          SizedBox(height: compact ? 22 : 44),
          Text(
            'Bon retour dans ElegantStyle',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 28 : 36,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Retrouvez vos commandes, vos messages, vos inspirations et votre vitrine au même endroit.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _BrandChip(icon: AppIcons.salon, label: 'Salon'),
              _BrandChip(icon: AppIcons.creator, label: 'Atelier'),
              _BrandChip(icon: AppIcons.boutique, label: 'Boutique'),
            ],
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
              'Connexion',
              style: TextStyle(
                color: _ink,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Entrez vos identifiants pour reprendre là où vous vous êtes arrêté.',
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
              controller: _emailController,
              label: 'Email',
              icon: Icons.mail_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
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
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _login(),
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
                if (value == null || value.isEmpty) {
                  return 'Mot de passe requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: const Text('Mot de passe oublié ?'),
              ),
            ),
            const SizedBox(height: 12),
            _PrimaryButton(
              label: 'Se connecter',
              icon: Icons.login_rounded,
              loading: _isLoading,
              onPressed: _login,
            ),
            const SizedBox(height: 14),
            _SocialButton(
              label: 'Se connecter avec Google',
              loading: _isGoogleLoading,
              onPressed: _googleLogin,
            ),
            if (_showAdminBootstrap) ...[
              const SizedBox(height: 12),
              _AdminBootstrapButton(
                email: _defaultAdminEmail,
                loading: _isAdminBootstrapLoading,
                onPressed: _bootstrapDefaultAdmin,
              ),
            ],
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Pas encore de compte ? ',
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onRegisterClicked?.call();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Créer un compte client'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BrandChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
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
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.suffix,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      autocorrect: !obscureText,
      enableSuggestions: !obscureText,
      enableInteractiveSelection: true,
      cursorColor: _LoginScreenState._primary,
      style: const TextStyle(
        color: _LoginScreenState._ink,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _LoginScreenState._muted,
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: const TextStyle(
          color: _LoginScreenState._primary,
          fontWeight: FontWeight.w800,
        ),
        prefixIcon: Icon(icon, color: _LoginScreenState._primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: _LoginScreenState._bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _LoginScreenState._primary),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
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
          loading ? 'Veuillez patienter...' : label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _LoginScreenState._primary,
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
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
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
          foregroundColor: _LoginScreenState._ink,
          side: const BorderSide(color: _LoginScreenState._border),
          minimumSize: const Size(0, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _AdminBootstrapButton extends StatelessWidget {
  const _AdminBootstrapButton({
    required this.email,
    required this.loading,
    required this.onPressed,
  });

  final String email;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 720;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: _LoginScreenState._tealDark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _LoginScreenState._tealDark.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: _LoginScreenState._tealDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Initialisation admin',
                  style: TextStyle(
                    color: _LoginScreenState._tealDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _LoginScreenState._muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          SizedBox(height: compact ? 8 : 10),
          SizedBox(
            width: double.infinity,
            height: compact ? 40 : 44,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onPressed,
              icon:
                  loading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.verified_user_rounded, size: 18),
              label: Text(
                loading ? 'Préparation...' : 'Créer / ouvrir admin',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _LoginScreenState._tealDark,
                side: BorderSide(
                  color: _LoginScreenState._tealDark.withValues(alpha: 0.24),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
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
        color: _LoginScreenState._rose.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _LoginScreenState._rose.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _LoginScreenState._rose,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _LoginScreenState._ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
