import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

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

  bool _isProcessingAuth = false;

  final List<String> allowedRoles = ['client', 'createur', 'boutique', 'admin'];

  String _getRouteForRole(String role) {
    switch (role) {
      case 'client':
        return '/home';
      case 'createur':
        return '/creator-dashboard';
      case 'boutique':
        return '/shop-dashboard';
      case 'admin':
        return '/admin-dashboard';
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

      final Map<String, dynamic> baseData = {
        'name': name ?? '',
        'email': email ?? '',
        'photoUrl': photoUrl ?? '',
        'authMethod': authMethod.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String finalRole;
      bool isNewUser = false;

      if (isRegistration) {
        if (role == null || !allowedRoles.contains(role)) {
          throw FirebaseAuthException(
            code: 'invalid-role',
            message: 'Rôle utilisateur invalide ou manquant',
          );
        }

        if (userDoc.exists) {
          throw FirebaseAuthException(
            code: 'user-already-exists',
            message: 'Un compte existe déjà avec cet identifiant',
          );
        }

        await userRef.set({
          ...baseData,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        finalRole = role;
        isNewUser = true;
        _logger.i('Document utilisateur créé pour $uid avec rôle $role');
      } else {
        if (userDoc.exists) {
          final existingData = userDoc.data() as Map<String, dynamic>;
          finalRole = existingData['role'] ?? 'client';

          final Map<String, dynamic> updateData = {};

          if (name != null && name.isNotEmpty && existingData['name'] != name) {
            updateData['name'] = name;
          }
          if (email != null && email.isNotEmpty && existingData['email'] != email) {
            updateData['email'] = email;
          }
          if (photoUrl != null && photoUrl.isNotEmpty && existingData['photoUrl'] != photoUrl) {
            updateData['photoUrl'] = photoUrl;
          }
          if (existingData['authMethod'] != authMethod.name) {
            updateData['authMethod'] = authMethod.name;
          }

          if (updateData.isNotEmpty) {
            updateData['updatedAt'] = FieldValue.serverTimestamp();
            await userRef.update(updateData);
            _logger.i('Document utilisateur mis à jour pour $uid');
          }
        } else {
          finalRole = role ?? 'client';
          isNewUser = true;

          await userRef.set({
            ...baseData,
            'role': finalRole,
            'createdAt': FieldValue.serverTimestamp(),
          });
          _logger.i('Document utilisateur créé pour $uid avec rôle par défaut');
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));

      return AuthResult(
        user: _firebaseAuth.currentUser,
        userRole: finalRole,
        isNewUser: isNewUser,
        redirectRoute: _getRouteForRole(finalRole),
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e, stack) {
      _logger.e('Erreur lors de la création du document utilisateur',
          error: e, stackTrace: stack);
      throw FirebaseAuthException(
        code: 'user-document-failed',
        message: 'Échec de la création du profil utilisateur',
      );
    }
  }

  // === AUTHENTIFICATION EMAIL ===
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    if (_isProcessingAuth) {
      throw FirebaseAuthException(
        code: 'auth-in-progress',
        message: 'Une authentification est déjà en cours',
      );
    }

    try {
      _isProcessingAuth = true;
      _logger.d('Inscription avec email: $email');

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

      await user.updateDisplayName(name);

      final result = await _createUserDocument(
        uid: user.uid,
        authMethod: AuthMethod.email,
        name: name,
        email: email,
        role: role,
        isRegistration: true,
      );

      _logger.i('Inscription réussie pour $email avec rôle $role');
      return result;
    } on FirebaseAuthException catch (e) {
      _logger.e('Erreur inscription: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthError(e);
    } catch (e, stack) {
      _logger.e('Erreur inattendue lors de l\'inscription', error: e, stackTrace: stack);
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Échec du processus d\'inscription',
      );
    } finally {
      _isProcessingAuth = false;
    }
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
      _logger.d('Connexion avec email: $email');

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

      _logger.i('Connexion réussie pour $email');
      return result;
    } on FirebaseAuthException catch (e) {
      _logger.e('Erreur connexion: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthError(e);
    } catch (e, stack) {
      _logger.e('Erreur inattendue lors de la connexion', error: e, stackTrace: stack);
      throw FirebaseAuthException(
        code: 'signin-failed',
        message: 'Échec du processus de connexion',
      );
    } finally {
      _isProcessingAuth = false;
    }
  }

  // === AUTHENTIFICATION GOOGLE ===
  Future<AuthResult> signInWithGoogle({String? role}) async {
    if (_isProcessingAuth) {
      throw FirebaseAuthException(
        code: 'auth-in-progress',
        message: 'Une authentification est déjà en cours',
      );
    }

    try {
      _isProcessingAuth = true;
      _logger.d('Début de la connexion Google');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-signin-aborted',
          message: 'Connexion Google annulée',
        );
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
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

      _logger.i('Connexion Google réussie pour ${user.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      _logger.e('Erreur Google Sign-In: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthError(e);
    } catch (e, stack) {
      _logger.e('Erreur inattendue Google Sign-In', error: e, stackTrace: stack);
      throw FirebaseAuthException(
        code: 'google-signin-failed',
        message: 'Échec de la connexion Google',
      );
    } finally {
      _isProcessingAuth = false;
    }
  }


  // === MÉTHODES UTILITAIRES ===
  Future<AuthResult?> getCurrentUserInfo() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      await Future.delayed(const Duration(milliseconds: 500));

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      final userRole = userData['role'] ?? 'client';

      return AuthResult(
        user: user,
        userRole: userRole,
        isNewUser: false,
        redirectRoute: _getRouteForRole(userRole),
      );
    } catch (e, stack) {
      _logger.e('Erreur récupération infos utilisateur', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _logger.i('Email de réinitialisation envoyé à $email');
    } on FirebaseAuthException catch (e) {
      _logger.e('Erreur réinitialisation: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthError(e);
    } catch (e, stack) {
      _logger.e('Erreur inattendue réinitialisation', error: e, stackTrace: stack);
      throw FirebaseAuthException(
        code: 'reset-password-failed',
        message: 'Échec de la réinitialisation du mot de passe',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _firebaseAuth.signOut(),
      ]);

      _isProcessingAuth = false;
      _logger.i('Déconnexion réussie');
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
        message = 'Mot de passe incorrect';
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
      case 'facebook-auth-cancelled':
        message = 'Connexion Facebook annulée par l\'utilisateur';
        break;
      case 'facebook-permission-denied':
        message = 'Permissions Facebook refusées';
        break;
      case 'facebook-invalid-config':
        message = 'Configuration Facebook invalide';
        break;
      case 'facebook-signin-failed':
        message = 'Échec de la connexion Facebook';
        break;
      case 'user-document-not-found':
        message = 'Profil utilisateur introuvable. Veuillez réessayer.';
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
        message = 'Erreur d\'authentification: ${e.message}';
    }

    return FirebaseAuthException(code: e.code, message: message);
  }

  // Getters et méthodes utilitaires
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e, stack) {
      _logger.e('Erreur vérification existence utilisateur', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<DocumentSnapshot> getUserDocument(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e, stack) {
      _logger.e('Erreur récupération document utilisateur', error: e, stackTrace: stack);
      return _firestore.collection('users').doc('invalid').get();
    }
  }
}