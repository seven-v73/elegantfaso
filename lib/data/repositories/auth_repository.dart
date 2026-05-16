import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import '../../core/account_roles.dart';
import '../../services/auth/welcome_email_service.dart';
import '../../services/profile/public_profile_service.dart';

enum AuthMethod { email, google }

class AuthResult {
  final User? user;
  final String? userRole;
  final bool isNewUser;
  final String? redirectRoute;

  AuthResult({
    this.user,
    this.userRole,
    this.isNewUser = false,
    this.redirectRoute,
  });
}

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  final WelcomeEmailService _welcomeEmailService = WelcomeEmailService();
  final PublicProfileService _publicProfileService = PublicProfileService();

  bool _isProcessingAuth = false;

  final List<String> allowedRoles = AccountRoles.all;

  String _getRouteForRole(String role) {
    switch (role) {
      case AccountRoles.client:
        return '/home';
      case AccountRoles.createur:
        return '/creator-dashboard';
      case AccountRoles.boutique:
        return '/shop-dashboard';
      case AccountRoles.admin:
        return '/admin';
      default:
        return '/home';
    }
  }

  Future<AuthResult> _createUserDocument({
    required String uid,
    required AuthMethod authMethod,
    String? name,
    String? email,
    String? role,
    String? photoUrl,
    bool isRegistration = false,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await userRef.get();

      final baseData = <String, dynamic>{
        'name': name ?? '',
        'displayName': name ?? '',
        'email': email ?? '',
        'photoUrl': photoUrl ?? '',
        'authMethod': authMethod.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String finalRole;
      bool isNewUser = false;

      if (isRegistration) {
        final requestedRole =
            role != null && allowedRoles.contains(role)
                ? role
                : AccountRoles.client;

        if (userDoc.exists) {
          final existingData = userDoc.data() as Map<String, dynamic>;
          final existingRole = AccountRoles.activeRole(existingData);
          final updateData = <String, dynamic>{};

          if (name != null && name.isNotEmpty && existingData['name'] != name) {
            updateData['name'] = name;
            updateData['displayName'] = name;
          }
          if (email != null &&
              email.isNotEmpty &&
              existingData['email'] != email) {
            updateData['email'] = email;
          }
          if (existingData['authMethod'] != authMethod.name) {
            updateData['authMethod'] = authMethod.name;
          }
          if (existingData['roles'] == null) {
            final roles = AccountRoles.normalize(existingData);
            updateData['roles'] = roles;
            updateData['roleFlags'] = AccountRoleService.roleFlags(roles);
          }
          if (updateData.isNotEmpty) {
            updateData['updatedAt'] = FieldValue.serverTimestamp();
            await userRef.update(updateData);
          }

          finalRole = existingRole;
          isNewUser = false;
          _logger.i(
            'Profil users/$uid déjà présent, inscription reprise sans doublon',
          );
        } else {
          final roles = AccountRoles.normalize({
            'role': requestedRole,
            'roles': [requestedRole],
          });

          await userRef.set({
            ...baseData,
            'role': requestedRole,
            'activeRole': requestedRole,
            'roles': roles,
            'roleFlags': AccountRoleService.roleFlags(roles),
            'stats': {
              'productsCount': 0,
              'creationsCount': 0,
              'followersCount': 0,
            },
            'createdAt': FieldValue.serverTimestamp(),
          });

          finalRole = requestedRole;
          isNewUser = true;
          _logger.i(
            'Document utilisateur créé dans users/$uid avec rôle $requestedRole',
          );
        }
      } else if (userDoc.exists) {
        final existingData = userDoc.data() as Map<String, dynamic>;
        finalRole = AccountRoles.activeRole(existingData);
        final existingRoles = AccountRoles.normalize(existingData);

        final updateData = <String, dynamic>{};

        if (name != null && name.isNotEmpty && existingData['name'] != name) {
          updateData['name'] = name;
          updateData['displayName'] = name;
        }
        if (email != null &&
            email.isNotEmpty &&
            existingData['email'] != email) {
          updateData['email'] = email;
        }
        if (photoUrl != null &&
            photoUrl.isNotEmpty &&
            existingData['photoUrl'] != photoUrl) {
          updateData['photoUrl'] = photoUrl;
        }
        if (existingData['authMethod'] != authMethod.name) {
          updateData['authMethod'] = authMethod.name;
        }
        if (existingData['activeRole'] != finalRole) {
          updateData['activeRole'] = finalRole;
        }
        if (existingData['roles'] == null) {
          updateData['roles'] = existingRoles;
        }
        if (existingData['roleFlags'] == null) {
          updateData['roleFlags'] = AccountRoleService.roleFlags(existingRoles);
        }
        if (existingData['stats'] == null) {
          updateData['stats'] = {
            'productsCount': existingData['productsCount'] ?? 0,
            'creationsCount': existingData['creationsCount'] ?? 0,
            'followersCount': existingData['followersCount'] ?? 0,
          };
        }

        if (updateData.isNotEmpty) {
          updateData['updatedAt'] = FieldValue.serverTimestamp();
          await userRef.update(updateData);
          _logger.i('Document utilisateur mis à jour pour $uid');
        }
      } else {
        finalRole = role ?? AccountRoles.client;
        isNewUser = true;
        final roles = AccountRoles.normalize({
          'role': finalRole,
          'roles': [finalRole],
        });

        await userRef.set({
          ...baseData,
          'role': finalRole,
          'activeRole': finalRole,
          'roles': roles,
          'roleFlags': AccountRoleService.roleFlags(roles),
          'stats': {
            'productsCount': 0,
            'creationsCount': 0,
            'followersCount': 0,
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
        _logger.i('Document utilisateur créé dans users/$uid avec rôle client');
      }

      final latestUserDoc = await userRef.get();
      try {
        await _publicProfileService.syncFromUserData(
          userId: uid,
          data: latestUserDoc.data() ?? baseData,
          authDisplayName: name,
          authPhotoUrl: photoUrl,
        );
      } catch (e, stack) {
        _logger.w(
          'Synchronisation du profil public différée pour $uid',
          error: e,
          stackTrace: stack,
        );
      }

      return AuthResult(
        user: _firebaseAuth.currentUser,
        userRole: finalRole,
        isNewUser: isNewUser,
        redirectRoute: _getRouteForRole(finalRole),
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e, stack) {
      _logger.e(
        'Erreur lors de la création du document utilisateur',
        error: e,
        stackTrace: stack,
      );
      throw FirebaseAuthException(
        code: 'user-document-failed',
        message: 'Échec de la création du profil utilisateur',
      );
    }
  }

  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String role = AccountRoles.client,
  }) async {
    if (_isProcessingAuth) {
      throw FirebaseAuthException(
        code: 'auth-in-progress',
        message: 'Une authentification est déjà en cours',
      );
    }

    try {
      _isProcessingAuth = true;
      _logger.d('Inscription Firebase avec email: $email');

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'Échec de la création du compte',
        );
      }

      try {
        await user.updateDisplayName(name);
      } catch (e, stack) {
        _logger.w(
          'Nom Firebase Auth non synchronisé immédiatement pour ${user.uid}',
          error: e,
          stackTrace: stack,
        );
      }

      final result = await _createUserDocument(
        uid: user.uid,
        authMethod: AuthMethod.email,
        name: name,
        email: email,
        role: role,
        isRegistration: true,
      );

      if (result.isNewUser) {
        unawaited(
          _welcomeEmailService.queueWelcomeEmail(
            uid: user.uid,
            email: email,
            displayName: name,
          ),
        );
      }

      _logger.i('Inscription Firebase réussie pour $email avec rôle $role');
      return result;
    } on FirebaseAuthException catch (e) {
      _logger.e('Erreur inscription: ${e.code} - ${e.message}');
      if (e.code == 'email-already-in-use') {
        final recovered = await _recoverCurrentEmailRegistration(
          email: email,
          name: name,
          role: role,
        );
        if (recovered != null) return recovered;
      }
      throw _handleFirebaseAuthError(e);
    } catch (e, stack) {
      _logger.e(
        'Erreur inattendue lors de l\'inscription',
        error: e,
        stackTrace: stack,
      );
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Échec du processus d\'inscription',
      );
    } finally {
      _isProcessingAuth = false;
    }
  }

  Future<AuthResult?> _recoverCurrentEmailRegistration({
    required String email,
    required String name,
    required String role,
  }) async {
    final user = _firebaseAuth.currentUser;
    final currentEmail = user?.email?.trim().toLowerCase();
    final requestedEmail = email.trim().toLowerCase();
    if (user == null || currentEmail != requestedEmail) return null;

    _logger.i(
      'Reprise inscription: compte Auth déjà créé pour $requestedEmail',
    );

    if ((user.displayName ?? '').trim() != name.trim()) {
      await user.updateDisplayName(name.trim());
    }

    final result = await _createUserDocument(
      uid: user.uid,
      authMethod: AuthMethod.email,
      name: name,
      email: requestedEmail,
      role: role,
      isRegistration: false,
    );
    await _assertAccountCanAuthenticate(user.uid);
    return result;
  }

  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_isProcessingAuth) {
      throw FirebaseAuthException(
        code: 'auth-in-progress',
        message: 'Une authentification est déjà en cours',
      );
    }

    try {
      _isProcessingAuth = true;
      _logger.d('Connexion Firebase avec email: $email');

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'signin-failed',
          message: 'Échec de la connexion',
        );
      }

      final result = await _createUserDocument(
        uid: user.uid,
        authMethod: AuthMethod.email,
        name: user.displayName,
        email: email,
      );
      await _assertAccountCanAuthenticate(user.uid);

      _logger.i('Connexion Firebase réussie pour $email');
      return result;
    } on FirebaseAuthException catch (e) {
      _logger.e('Erreur connexion: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthError(e);
    } catch (e, stack) {
      _logger.e(
        'Erreur inattendue lors de la connexion',
        error: e,
        stackTrace: stack,
      );
      throw FirebaseAuthException(
        code: 'signin-failed',
        message: 'Échec du processus de connexion',
      );
    } finally {
      _isProcessingAuth = false;
    }
  }

  Future<AuthResult> bootstrapDefaultAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    if (_isProcessingAuth) {
      throw FirebaseAuthException(
        code: 'auth-in-progress',
        message: 'Une authentification est déjà en cours',
      );
    }

    try {
      _isProcessingAuth = true;
      final normalizedEmail = email.trim().toLowerCase();
      UserCredential credential;

      try {
        credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') rethrow;
        credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      }

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'admin-bootstrap-failed',
          message: 'Impossible de préparer le compte administrateur',
        );
      }

      if ((user.displayName ?? '').trim() != name.trim()) {
        await user.updateDisplayName(name.trim());
      }

      final roles = AccountRoles.normalize({
        'role': AccountRoles.admin,
        'activeRole': AccountRoles.admin,
        'roles': [AccountRoles.client, AccountRoles.admin],
      });

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'displayName': name.trim(),
        'email': normalizedEmail,
        'photoUrl': user.photoURL ?? '',
        'authMethod': AuthMethod.email.name,
        'role': AccountRoles.admin,
        'activeRole': AccountRoles.admin,
        'roles': roles,
        'roleFlags': AccountRoleService.roleFlags(roles),
        'admin': {
          'bootstrap': true,
          'status': 'active',
          'canManageCommerce': true,
          'canManageUsers': true,
          'canModerateSalon': true,
        },
        'stats': {'productsCount': 0, 'creationsCount': 0, 'followersCount': 0},
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _publicProfileService.syncFromUserData(
        userId: user.uid,
        data: {
          'name': name.trim(),
          'displayName': name.trim(),
          'email': normalizedEmail,
          'photoUrl': user.photoURL ?? '',
          'role': AccountRoles.admin,
          'activeRole': AccountRoles.admin,
          'roles': roles,
          'roleFlags': AccountRoleService.roleFlags(roles),
          'isVerified': true,
          'publicBadges': const ['Administration'],
        },
        authDisplayName: name.trim(),
        authPhotoUrl: user.photoURL,
      );

      _logger.i('Compte administrateur préparé pour $normalizedEmail');
      return AuthResult(
        user: user,
        userRole: AccountRoles.admin,
        isNewUser: credential.additionalUserInfo?.isNewUser ?? false,
        redirectRoute: _getRouteForRole(AccountRoles.admin),
      );
    } on FirebaseAuthException catch (e) {
      _logger.e('Erreur bootstrap admin: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthError(e);
    } catch (e, stack) {
      _logger.e(
        'Erreur inattendue bootstrap admin',
        error: e,
        stackTrace: stack,
      );
      throw FirebaseAuthException(
        code: 'admin-bootstrap-failed',
        message: 'Échec de préparation du compte administrateur',
      );
    } finally {
      _isProcessingAuth = false;
    }
  }

  Future<AuthResult> signInWithGoogle({String? role}) async {
    if (_isProcessingAuth) {
      throw FirebaseAuthException(
        code: 'auth-in-progress',
        message: 'Une authentification est déjà en cours',
      );
    }

    try {
      _isProcessingAuth = true;
      _logger.d('Début de la connexion Google Firebase');

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-signin-aborted',
          message: 'Connexion Google annulée',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'google-signin-failed',
          message: 'Échec de la connexion Google',
        );
      }

      final result = await _createUserDocument(
        uid: user.uid,
        authMethod: AuthMethod.google,
        name: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
        role: role,
      );
      await _assertAccountCanAuthenticate(user.uid);

      final isNewGoogleAccount =
          userCredential.additionalUserInfo?.isNewUser ?? result.isNewUser;
      if (isNewGoogleAccount && (user.email ?? '').trim().isNotEmpty) {
        unawaited(
          _welcomeEmailService.queueWelcomeEmail(
            uid: user.uid,
            email: user.email!,
            displayName: user.displayName,
          ),
        );
      }

      _logger.i('Connexion Google Firebase réussie pour ${user.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      _logger.e('Erreur Google Sign-In: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthError(e);
    } catch (e, stack) {
      _logger.e(
        'Erreur inattendue Google Sign-In',
        error: e,
        stackTrace: stack,
      );
      throw FirebaseAuthException(
        code: 'google-signin-failed',
        message: 'Échec de la connexion Google',
      );
    } finally {
      _isProcessingAuth = false;
    }
  }

  Future<AuthResult?> getCurrentUserInfo() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        _logger.i(
          'Profil manquant pour ${user.uid}, réparation automatique en client',
        );
        final repaired = await _createUserDocument(
          uid: user.uid,
          authMethod: _authMethodForProvider(user),
          name: user.displayName,
          email: user.email,
          role: AccountRoles.client,
          photoUrl: user.photoURL,
          isRegistration: false,
        );
        await _assertAccountCanAuthenticate(user.uid);
        return repaired;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      await _assertAccountCanAuthenticate(user.uid, userData: userData);
      final userRole = AccountRoles.activeRole(userData);

      return AuthResult(
        user: user,
        userRole: userRole,
        isNewUser: false,
        redirectRoute: _getRouteForRole(userRole),
      );
    } catch (e, stack) {
      _logger.e(
        'Erreur récupération infos utilisateur',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  AuthMethod _authMethodForProvider(User user) {
    final providers = user.providerData.map((info) => info.providerId).toSet();
    if (providers.contains('google.com')) return AuthMethod.google;
    return AuthMethod.email;
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _logger.i('Email de réinitialisation envoyé à $email');
    } on FirebaseAuthException catch (e) {
      _logger.e('Erreur réinitialisation: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthError(e);
    } catch (e, stack) {
      _logger.e(
        'Erreur inattendue réinitialisation',
        error: e,
        stackTrace: stack,
      );
      throw FirebaseAuthException(
        code: 'reset-password-failed',
        message: 'Échec de la réinitialisation du mot de passe',
      );
    }
  }

  Future<void> _assertAccountCanAuthenticate(
    String uid, {
    Map<String, dynamic>? userData,
  }) async {
    final data =
        userData ??
        ((await _firestore.collection('users').doc(uid).get()).data() ??
            const <String, dynamic>{});
    final status = (data['accountStatus'] ?? '').toString().toLowerCase();
    final closure = Map<String, dynamic>.from(data['closure'] ?? const {});
    final closureStatus = (closure['status'] ?? '').toString().toLowerCase();

    final blockedStatuses = {
      'closed',
      'closure_requested',
      'deactivated',
      'disabled',
      'suspended',
      'blocked',
      'deleting',
      'closure_approved',
    };

    if (blockedStatuses.contains(status) ||
        blockedStatuses.contains(closureStatus)) {
      await signOut();
      throw FirebaseAuthException(
        code: status == 'suspended' ? 'account-suspended' : 'account-closed',
        message:
            'Ce compte est fermé ou désactivé. Contactez l’administration pour une réactivation.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([_googleSignIn.signOut(), _firebaseAuth.signOut()]);
      _isProcessingAuth = false;
      _logger.i('Déconnexion Firebase réussie');
    } catch (e, stack) {
      _logger.e('Erreur déconnexion', error: e, stackTrace: stack);
      throw FirebaseAuthException(
        code: 'signout-failed',
        message: 'Échec de la déconnexion',
      );
    }
  }

  FirebaseAuthException _handleFirebaseAuthError(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'auth-in-progress':
        message = 'Une authentification est déjà en cours';
        break;
      case 'email-already-in-use':
        message = 'Cette adresse email est déjà utilisée';
        break;
      case 'invalid-email':
        message = 'Format d\'email invalide';
        break;
      case 'weak-password':
        message = 'Mot de passe trop faible (minimum 6 caractères)';
        break;
      case 'user-not-found':
        message = 'Aucun compte associé à cet identifiant';
        break;
      case 'wrong-password':
      case 'invalid-credential':
        message = 'Email ou mot de passe incorrect';
        break;
      case 'too-many-requests':
        message = 'Trop de tentatives. Réessayez plus tard';
        break;
      case 'invalid-role':
        message = 'Rôle utilisateur invalide';
        break;
      case 'user-already-exists':
        message = 'Un compte existe déjà avec cet identifiant';
        break;
      case 'google-signin-aborted':
        message = 'Connexion Google annulée par l\'utilisateur';
        break;
      case 'google-signin-failed':
        message = 'Échec de la connexion Google';
        break;
      case 'user-document-not-found':
        message = 'Profil utilisateur introuvable. Veuillez réessayer.';
        break;
      case 'account-closed':
        message =
            'Ce compte est fermé. Contactez l’administration pour le réactiver.';
        break;
      case 'account-suspended':
        message =
            'Ce compte est suspendu. Contactez l’administration pour plus d’informations.';
        break;
      case 'user-document-failed':
        message = 'Échec de la création du profil utilisateur';
        break;
      case 'network-request-failed':
        message = 'Problème de connexion réseau';
        break;
      case 'account-exists-with-different-credential':
        message = 'Un compte existe déjà avec un autre fournisseur';
        break;
      default:
        message = e.message ?? 'Erreur d\'authentification';
    }

    return FirebaseAuthException(code: e.code, message: message);
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e, stack) {
      _logger.e(
        'Erreur vérification existence utilisateur',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  Future<DocumentSnapshot> getUserDocument(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e, stack) {
      _logger.e(
        'Erreur récupération document utilisateur',
        error: e,
        stackTrace: stack,
      );
      return _firestore.collection('users').doc('invalid').get();
    }
  }
}
