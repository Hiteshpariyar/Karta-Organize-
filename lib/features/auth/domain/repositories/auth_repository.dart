import '../models/user_profile.dart';

/// Detailed result of an authentication or profile operation.
class AuthResult {
  final bool isSuccess;
  final String? message;
  final String? userId;
  final UserProfile? userProfile;
  final bool requiresProfileSetup;
  final bool isEmailUnverified;

  const AuthResult({
    required this.isSuccess,
    this.message,
    this.userId,
    this.userProfile,
    this.requiresProfileSetup = false,
    this.isEmailUnverified = false,
  });
}

/// Abstract contract for authentication and profile management.
/// Integrates Firebase Authentication and Cloud Firestore.
abstract class IAuthRepository {
  /// Stream emitting the active user profile whenever authentication state or profile changes.
  Stream<UserProfile?> get authStateChanges;

  /// The currently cached user profile.
  UserProfile? get currentUserProfile;

  /// Current authenticated Firebase UID if logged in.
  String? get currentUid;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated;

  /// Sign in with email and password, retrieving and validating the verified Firestore profile.
  Future<AuthResult> signIn({
    required String email,
    required String password,
    required String role,
  });

  /// Register a new Player account with Firebase Auth, Cloud Firestore profile,
  /// and explicit policy acceptance records.
  Future<AuthResult> registerPlayer({
    required String fullName,
    required String email,
    required String password,
    required bool policyAccepted,
    required String policyVersion,
    String privacyVersion = '0.1.0-draft',
  });

  /// Recovery flow: creates Firestore profile for an existing Firebase Auth user
  /// if initial profile creation failed or timed out.
  Future<AuthResult> completeProfileCreation({
    required String fullName,
    required bool policyAccepted,
    required String policyVersion,
    String privacyVersion = '0.1.0-draft',
  });

  /// Dispatches a password reset email via Firebase Authentication.
  Future<AuthResult> sendPasswordResetEmail({
    required String email,
  });

  /// Sends email verification link to current authenticated user.
  Future<AuthResult> sendEmailVerification();

  /// Reloads user token to verify if email verification link was confirmed.
  Future<bool> checkEmailVerificationStatus();

  /// Fetches the latest Firestore user profile for a given UID.
  Future<UserProfile?> fetchUserProfile(String uid);

  /// Updates permitted profile fields (displayName, gameUids) without modifying
  /// privileged security fields (role, accountStatus, policy acceptance).
  Future<AuthResult> updateProfile({
    String? displayName,
    Map<String, String>? gameUids,
  });

  /// Signs out of Firebase Authentication and clears session cache.
  Future<void> signOut();
}
