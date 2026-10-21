import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

/// Production-grade Firebase Authentication and Cloud Firestore User Repository.
class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _customAuth = auth,
        _customFirestore = firestore;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  UserProfile? _cachedProfile;

  @override
  UserProfile? get currentUserProfile => _cachedProfile;

  @override
  String? get currentUid => _isFirebaseReady ? _auth.currentUser?.uid : null;

  @override
  bool get isAuthenticated => _isFirebaseReady && _auth.currentUser != null;

  @override
  Stream<UserProfile?> get authStateChanges {
    if (!_isFirebaseReady) {
      return Stream.value(null);
    }

    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _cachedProfile = null;
        return null;
      }
      try {
        final profile = await fetchUserProfile(user.uid);
        _cachedProfile = profile;
        return profile;
      } catch (_) {
        // If profile fetch fails or document missing, return temporary unverified profile
        return UserProfile(
          uid: user.uid,
          displayName: user.displayName ?? '',
          email: user.email ?? '',
          emailVerified: user.emailVerified,
        );
      }
    });
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
    required String role,
  }) async {
    if (!_isFirebaseReady) {
      return const AuthResult(
        isSuccess: false,
        message: 'Firebase is not configured. Please run "flutterfire configure" to link your project.',
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return const AuthResult(
          isSuccess: false,
          message: 'Authentication failed. Please verify credentials.',
        );
      }

      // Fetch verified server-side user profile from Firestore
      final profile = await fetchUserProfile(user.uid);

      if (profile == null) {
        return AuthResult(
          isSuccess: true,
          userId: user.uid,
          requiresProfileSetup: true,
          message: 'Account signed in. Firestore profile setup is required.',
        );
      }

      _cachedProfile = profile;

      // Enforce account status check
      if (profile.isSuspended) {
        await _auth.signOut();
        _cachedProfile = null;
        return const AuthResult(
          isSuccess: false,
          message:
              'Account suspended: Access denied due to policy violations. Contact support for assistance.',
        );
      }

      return AuthResult(
        isSuccess: true,
        userId: user.uid,
        userProfile: profile,
        isEmailUnverified: !user.emailVerified,
        message: 'Signed in successfully as ${profile.displayName}.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Unexpected authentication error: ${e.toString()}',
      );
    }
  }

  @override
  Future<AuthResult> registerPlayer({
    required String fullName,
    required String email,
    required String password,
    required bool policyAccepted,
    required String policyVersion,
    String privacyVersion = '0.1.0-draft',
  }) async {
    // 1. Mandatory policy acceptance enforcement
    if (!policyAccepted) {
      return const AuthResult(
        isSuccess: false,
        message: 'Registration rejected: Terms & Conditions and Privacy Policy must be accepted.',
      );
    }

    if (!_isFirebaseReady) {
      return const AuthResult(
        isSuccess: false,
        message: 'Firebase is not configured. Please run "flutterfire configure" to link your project.',
      );
    }

    UserCredential? credential;
    try {
      // 2. Create Firebase Authentication account
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return const AuthResult(
          isSuccess: false,
          message: 'User account creation failed with authentication provider.',
        );
      }

      // 3. Update auth display name
      await user.updateDisplayName(fullName.trim());

      // 4. Send email verification link
      try {
        await user.sendEmailVerification();
      } catch (_) {
        // Non-blocking error if verification dispatch encounters rate limit
      }

      // 5. Create Cloud Firestore profile with server timestamp
      final profile = UserProfile(
        uid: user.uid,
        displayName: fullName.trim(),
        email: user.email ?? email.trim(),
        role: UserRole.player, // Always default to player; never allow self-elevation
        accountStatus: AccountStatus.active,
        termsVersionAccepted: policyVersion,
        privacyVersionAccepted: privacyVersion,
        policyAcceptedAt: DateTime.now(),
        emailVerified: user.emailVerified,
      );

      await _saveProfileAndPolicyAcceptance(profile, user.uid, policyVersion, privacyVersion);

      _cachedProfile = profile;

      return AuthResult(
        isSuccess: true,
        userId: user.uid,
        userProfile: profile,
        message: 'Account created successfully. A verification link has been sent to ${user.email}.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: _mapFirebaseAuthError(e),
      );
    } on FirebaseException catch (e) {
      // Recovery: Auth user was created, but Firestore profile write failed
      return AuthResult(
        isSuccess: false,
        userId: credential?.user?.uid,
        requiresProfileSetup: true,
        message:
            'Authentication account registered, but database initialization failed: ${e.message}. You can retry profile initialization.',
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'An error occurred during account creation: ${e.toString()}',
      );
    }
  }

  @override
  Future<AuthResult> completeProfileCreation({
    required String fullName,
    required bool policyAccepted,
    required String policyVersion,
    String privacyVersion = '0.1.0-draft',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AuthResult(
        isSuccess: false,
        message: 'No authenticated session found to initialize profile.',
      );
    }

    if (!policyAccepted) {
      return const AuthResult(
        isSuccess: false,
        message: 'Terms & Conditions and Privacy Policy must be explicitly accepted.',
      );
    }

    try {
      final profile = UserProfile(
        uid: user.uid,
        displayName: fullName.trim().isNotEmpty ? fullName.trim() : (user.displayName ?? 'Player'),
        email: user.email ?? '',
        role: UserRole.player,
        accountStatus: AccountStatus.active,
        termsVersionAccepted: policyVersion,
        privacyVersionAccepted: privacyVersion,
        policyAcceptedAt: DateTime.now(),
        emailVerified: user.emailVerified,
      );

      await _saveProfileAndPolicyAcceptance(profile, user.uid, policyVersion, privacyVersion);

      _cachedProfile = profile;

      return AuthResult(
        isSuccess: true,
        userId: user.uid,
        userProfile: profile,
        message: 'Profile initialized successfully.',
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Failed to initialize profile: ${e.toString()}',
      );
    }
  }

  Future<void> _saveProfileAndPolicyAcceptance(
    UserProfile profile,
    String uid,
    String termsVersion,
    String privacyVersion,
  ) async {
    final batch = _firestore.batch();

    // User Profile document: /users/{uid}
    final userDocRef = _firestore.collection('users').doc(uid);
    batch.set(userDocRef, profile.toFirestoreMap(), SetOptions(merge: true));

    // Player terms acceptance record: /users/{uid}/policy_acceptances/player_terms
    final termsDocRef = userDocRef.collection('policy_acceptances').doc('player_terms');
    batch.set(
      termsDocRef,
      {
        'userId': uid,
        'policyType': 'player_terms',
        'policyVersion': termsVersion,
        'accepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Privacy policy acceptance record: /users/{uid}/policy_acceptances/privacy_policy
    final privacyDocRef = userDocRef.collection('policy_acceptances').doc('privacy_policy');
    batch.set(
      privacyDocRef,
      {
        'userId': uid,
        'policyType': 'privacy_policy',
        'policyVersion': privacyVersion,
        'accepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  @override
  Future<AuthResult> sendPasswordResetEmail({required String email}) async {
    if (!_isFirebaseReady) {
      return const AuthResult(
        isSuccess: false,
        message: 'Firebase is not configured. Please run "flutterfire configure" to link your project.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      // Security best practice: Do not disclose whether email exists
      return const AuthResult(
        isSuccess: true,
        message:
            'If an account exists with this email address, a password reset link has been dispatched.',
      );
    } on FirebaseAuthException catch (e) {
      // Still show generic message for user-not-found to prevent account enumeration
      if (e.code == 'user-not-found') {
        return const AuthResult(
          isSuccess: true,
          message:
              'If an account exists with this email address, a password reset link has been dispatched.',
        );
      }
      return AuthResult(
        isSuccess: false,
        message: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Could not send reset email: ${e.toString()}',
      );
    }
  }

  @override
  Future<AuthResult> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AuthResult(
        isSuccess: false,
        message: 'No authenticated user to verify.',
      );
    }

    try {
      await user.sendEmailVerification();
      return AuthResult(
        isSuccess: true,
        message: 'Verification email sent to ${user.email}.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: _mapFirebaseAuthError(e),
      );
    }
  }

  @override
  Future<bool> checkEmailVerificationStatus() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<UserProfile?> fetchUserProfile(String uid) async {
    if (!_isFirebaseReady) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserProfile.fromMap(doc.data()!, docId: doc.id);
  }

  @override
  Future<AuthResult> updateProfile({
    String? displayName,
    Map<String, String>? gameUids,
  }) async {
    final user = _isFirebaseReady ? _auth.currentUser : null;

    if (!_isFirebaseReady) {
      if (_cachedProfile != null) {
        _cachedProfile = _cachedProfile!.copyWith(
          displayName: displayName ?? _cachedProfile!.displayName,
          gameUids: gameUids ?? _cachedProfile!.gameUids,
        );
        return AuthResult(isSuccess: true, userProfile: _cachedProfile);
      }
      return const AuthResult(isSuccess: true, message: 'Profile updated in sandbox mode.');
    }

    if (user == null) {
      return const AuthResult(
        isSuccess: false,
        message: 'No authenticated user to update.',
      );
    }

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null && displayName.trim().isNotEmpty) {
        updates['displayName'] = displayName.trim();
        await user.updateDisplayName(displayName.trim());
      }
      if (gameUids != null) {
        updates['gameUids'] = gameUids;
      }

      await _firestore.collection('users').doc(user.uid).update(updates);

      final updatedProfile = await fetchUserProfile(user.uid);
      _cachedProfile = updatedProfile;

      return AuthResult(
        isSuccess: true,
        userProfile: updatedProfile,
        message: 'Profile updated successfully.',
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    _cachedProfile = null;
    if (_isFirebaseReady) {
      await _auth.signOut();
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase Console. Please enable it in Authentication > Sign-in method.';
      case 'email-already-in-use':
        return 'This email address is already registered. Please sign in or reset your password.';
      case 'invalid-email':
        return 'The email address format is invalid. Please check for typos.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 8 characters with numbers and letters.';
      case 'user-disabled':
        return 'This account has been disabled by administrators. Contact support for help.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email address or password. Please verify and try again.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Access is temporarily paused for security. Try again later.';
      case 'network-request-failed':
        return 'Network connection error. Please verify your internet connection.';
      default:
        return e.message ?? 'Authentication operation failed (${e.code}).';
    }
  }
}

