import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/security/auth_security_service.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

/// Production-grade Firebase Authentication and Cloud Firestore User Repository.
class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;
  final AuthSecurityService _securityService;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    AuthSecurityService? securityService,
  })  : _customAuth = auth,
        _customFirestore = firestore,
        _securityService = securityService ?? AuthSecurityService();


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
    // 1. Enforce login throttling on repeated failures
    final throttleCheck = _securityService.checkLoginAllowed(email);
    if (!throttleCheck.isAllowed) {
      return AuthResult(
        isSuccess: false,
        message: throttleCheck.errorMessage ?? 'Too many failed login attempts. Please wait.',
      );
    }

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
        _securityService.recordFailedLogin(email);
        return const AuthResult(
          isSuccess: false,
          message: 'Authentication failed. Please verify credentials.',
        );
      }

      // Reset failed login counter upon successful authentication
      _securityService.recordSuccessfulLogin(email);

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
      _securityService.recordFailedLogin(email);
      return AuthResult(
        isSuccess: false,
        message: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      _securityService.recordFailedLogin(email);
      return AuthResult(
        isSuccess: false,
        message: 'Unexpected authentication error: ${e.toString()}',
      );
    }
  }


  @override
  Future<AuthResult> signInWithGoogle() async {
    if (!_isFirebaseReady) {
      return const AuthResult(
        isSuccess: false,
        message: 'Firebase is not configured. Google Sign-In requires active Firebase credentials.',
      );
    }

    try {
      final googleProvider = GoogleAuthProvider();
      final userCredential = await _auth.signInWithProvider(googleProvider);
      final user = userCredential.user;
      if (user == null) {
        return const AuthResult(
          isSuccess: false,
          message: 'Google Sign-In was cancelled or failed.',
        );
      }

      // Check if profile exists in Firestore
      var profile = await fetchUserProfile(user.uid);
      if (profile == null) {
        // Automatically provision a default, strictly unprivileged Player profile for new Google sign-in
        final newProfile = UserProfile(
          uid: user.uid,
          displayName: user.displayName?.isNotEmpty == true
              ? user.displayName!
              : (user.email?.split('@').first ?? 'Player'),
          email: user.email ?? '',
          role: UserRole.player, // Always default to Player for Google sign-in
          accountStatus: AccountStatus.active,
          createdAt: DateTime.now(),
          emailVerified: user.emailVerified,
          photoUrl: user.photoURL,
        );

        await _firestore.collection('users').doc(user.uid).set(newProfile.toFirestoreMap());
        await _firestore.collection('public_profiles').doc(user.uid).set({
          'uid': user.uid,
          'displayName': newProfile.displayName,
          'photoUrl': newProfile.photoUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        profile = newProfile;
      }

      _cachedProfile = profile;

      if (profile.isSuspended) {
        await _auth.signOut();
        _cachedProfile = null;
        return const AuthResult(
          isSuccess: false,
          message: 'Account suspended: Access denied due to policy violations.',
        );
      }

      return AuthResult(
        isSuccess: true,
        userId: user.uid,
        userProfile: profile,
        isEmailUnverified: !user.emailVerified,
        message: 'Signed in with Google successfully as ${profile.displayName}.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Google Sign-In failed: ${e.toString()}',
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
    // 1. Enforce backend rolling rate limit: max 4 requests per 90-second window
    final rateLimitCheck = _securityService.checkAndRecordPasswordReset(email);
    if (!rateLimitCheck.isAllowed) {
      return AuthResult(
        isSuccess: false,
        message: rateLimitCheck.errorMessage ??
            'Too many password reset requests. For security, please wait 90 seconds before requesting another link.',
      );
    }

    if (!_isFirebaseReady) {
      return const AuthResult(
        isSuccess: true,
        message:
            'If an account exists with this email address, a password reset link has been dispatched.',
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
    String? phoneNumber,
    String? phonePrivacy,
  }) async {
    final user = _isFirebaseReady ? _auth.currentUser : null;

    if (!_isFirebaseReady) {
      if (_cachedProfile != null) {
        _cachedProfile = _cachedProfile!.copyWith(
          displayName: displayName ?? _cachedProfile!.displayName,
          gameUids: gameUids ?? _cachedProfile!.gameUids,
          phoneNumber: phoneNumber ?? _cachedProfile!.phoneNumber,
          phonePrivacy: phonePrivacy ?? _cachedProfile!.phonePrivacy,
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
      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
      }
      if (phonePrivacy != null) {
        updates['phonePrivacy'] = phonePrivacy;
      }

      await _firestore.collection('users').doc(user.uid).update(updates);

      // Mirror permitted public profile fields for community discovery
      final publicUpdates = <String, dynamic>{
        'uid': user.uid,
        'displayName': updates['displayName'] ?? _cachedProfile?.displayName ?? user.displayName ?? 'Player',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (updates.containsKey('gameUids')) publicUpdates['gameUids'] = updates['gameUids'];
      if (updates.containsKey('phonePrivacy')) publicUpdates['phonePrivacy'] = updates['phonePrivacy'];
      if (updates.containsKey('phoneNumber')) publicUpdates['phoneNumber'] = updates['phoneNumber'];

      await _firestore
          .collection('public_profiles')
          .doc(user.uid)
          .set(publicUpdates, SetOptions(merge: true));

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

  @override
  Future<AuthResult> deleteAccount({required String password}) async {
    if (!_isFirebaseReady) {
      return const AuthResult(
        isSuccess: false,
        message: 'No authenticated user session found to delete.',
      );
    }
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return const AuthResult(
        isSuccess: false,
        message: 'No authenticated user session found to delete.',
      );
    }

    try {
      // 1. Re-authenticate user before sensitive deletion
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      final uid = user.uid;

      // 2. Cascade cleanup of personal user data in Firestore
      if (_isFirebaseReady) {
        final batch = _firestore.batch();
        final userDoc = _firestore.collection('users').doc(uid);

        final policies = await userDoc.collection('policy_acceptances').get();
        for (final doc in policies.docs) {
          batch.delete(doc.reference);
        }

        final notifs = await userDoc.collection('notifications').get();
        for (final doc in notifs.docs) {
          batch.delete(doc.reference);
        }

        final settings = await userDoc.collection('settings').get();
        for (final doc in settings.docs) {
          batch.delete(doc.reference);
        }

        batch.delete(userDoc);
        await batch.commit();

        _securityService.recordAccountDeletion(uid: uid);
      }

      // 3. Delete Firebase Auth user account
      await user.delete();
      _cachedProfile = null;

      return const AuthResult(
        isSuccess: true,
        message: 'Your account and personal data have been permanently deleted.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return const AuthResult(
          isSuccess: false,
          message: 'Incorrect password. Re-authentication failed.',
        );
      }
      return AuthResult(
        isSuccess: false,
        message: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Failed to delete account: ${e.toString()}',
      );
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

