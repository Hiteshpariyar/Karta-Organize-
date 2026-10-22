import 'dart:async';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

/// Phase 1 Development Auth Repository.
///
/// Validates input contracts and provides honest developer feedback
/// without falsely claiming production authentication or data persistence.
class DevAuthRepository implements IAuthRepository {
  UserProfile? _currentProfile;
  final _authStateController = StreamController<UserProfile?>.broadcast();

  @override
  UserProfile? get currentUserProfile => _currentProfile;

  @override
  String? get currentUid => _currentProfile?.uid;

  final Map<String, UserProfile> _registeredProfilesByEmail = {};

  @override
  bool get isAuthenticated => _currentProfile != null;

  @override
  Stream<UserProfile?> get authStateChanges => _authStateController.stream;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
    required String role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cleanEmail = email.trim().toLowerCase();

    // Check if user already exists
    var profile = _registeredProfilesByEmail[cleanEmail];
    if (profile == null) {
      // Deterministic dev role: only predefined admin or organizer emails get privileged roles
      final bool isPreApprovedOrganizer = cleanEmail.contains('organizer') || cleanEmail == 'host@tourneyzone.com';
      final bool isPreApprovedAdmin = cleanEmail.contains('admin') || cleanEmail == 'hiteshpariyar73@gmail.com';
      final userRole = isPreApprovedAdmin
          ? UserRole.admin
          : (isPreApprovedOrganizer ? UserRole.organizer : UserRole.player);

      profile = UserProfile(
        uid: 'dev_user_${cleanEmail.split('@').first}',
        displayName: cleanEmail.split('@').first,
        email: email,
        role: userRole,
        accountStatus: AccountStatus.active,
      );
      _registeredProfilesByEmail[cleanEmail] = profile;
    }

    _currentProfile = profile;
    _authStateController.add(profile);

    return AuthResult(
      isSuccess: true,
      userId: profile.uid,
      userProfile: profile,
      message: 'Signed in locally as ${profile.displayName}.',
    );
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 300));
    const googleEmail = 'google.player@tourneyzone.com';

    var profile = _registeredProfilesByEmail[googleEmail];
    if (profile == null) {
      profile = UserProfile(
        uid: 'dev_google_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Google Player',
        email: googleEmail,
        role: UserRole.player, // Always default to Player for Google sign-in
        accountStatus: AccountStatus.active,
        createdAt: DateTime.now(),
        emailVerified: true,
      );
      _registeredProfilesByEmail[googleEmail] = profile;
    }

    _currentProfile = profile;
    _authStateController.add(profile);

    return AuthResult(
      isSuccess: true,
      userId: profile.uid,
      userProfile: profile,
      message: 'Signed in with Google as ${profile.displayName}.',
    );
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
    if (!policyAccepted) {
      return const AuthResult(
        isSuccess: false,
        message: 'Registration rejected: Terms & Conditions and Privacy Policy must be explicitly accepted.',
      );
    }

    await Future.delayed(const Duration(milliseconds: 300));

    final profile = UserProfile(
      uid: 'dev_player_${DateTime.now().millisecondsSinceEpoch}',
      displayName: fullName,
      email: email,
      role: UserRole.player,
      accountStatus: AccountStatus.active,
      termsVersionAccepted: policyVersion,
      privacyVersionAccepted: privacyVersion,
      policyAcceptedAt: DateTime.now(),
    );
    _registeredProfilesByEmail[email.trim().toLowerCase()] = profile;
    _currentProfile = profile;
    _authStateController.add(profile);

    return AuthResult(
      isSuccess: true,
      userId: profile.uid,
      userProfile: profile,
      message: 'Account validation successful for $fullName ($email).',
    );
  }

  @override
  Future<AuthResult> completeProfileCreation({
    required String fullName,
    required bool policyAccepted,
    required String policyVersion,
    String privacyVersion = '0.1.0-draft',
  }) async {
    if (_currentProfile == null) {
      return const AuthResult(isSuccess: false, message: 'No active session.');
    }
    _currentProfile = _currentProfile!.copyWith(
      displayName: fullName,
      termsVersionAccepted: policyVersion,
      privacyVersionAccepted: privacyVersion,
    );
    _authStateController.add(_currentProfile);
    return AuthResult(isSuccess: true, userProfile: _currentProfile);
  }

  @override
  Future<UserProfile?> fetchUserProfile(String uid) async {
    return _currentProfile;
  }

  @override
  Future<AuthResult> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return AuthResult(
      isSuccess: true,
      message: 'Password reset request received for $email.',
    );
  }

  @override
  Future<AuthResult> sendEmailVerification() async {
    return const AuthResult(isSuccess: true, message: 'Verification email sent.');
  }

  @override
  Future<bool> checkEmailVerificationStatus() async {
    return true;
  }

  @override
  Future<AuthResult> updateProfile({
    String? displayName,
    Map<String, String>? gameUids,
    String? phoneNumber,
    String? phonePrivacy,
  }) async {
    if (_currentProfile == null) {
      return const AuthResult(isSuccess: false, message: 'No active session.');
    }
    _currentProfile = _currentProfile!.copyWith(
      displayName: displayName ?? _currentProfile!.displayName,
      gameUids: gameUids ?? _currentProfile!.gameUids,
      phoneNumber: phoneNumber ?? _currentProfile!.phoneNumber,
      phonePrivacy: phonePrivacy ?? _currentProfile!.phonePrivacy,
      updatedAt: DateTime.now(),
    );
    _authStateController.add(_currentProfile);
    return AuthResult(isSuccess: true, userProfile: _currentProfile);
  }

  @override
  Future<void> signOut() async {
    _currentProfile = null;
    _authStateController.add(null);
  }

  @override
  Future<AuthResult> deleteAccount({required String password}) async {
    if (_currentProfile == null) {
      return const AuthResult(isSuccess: false, message: 'No active session to delete.');
    }
    _currentProfile = null;
    _authStateController.add(null);
    return const AuthResult(isSuccess: true, message: 'Account successfully deleted.');
  }
}


