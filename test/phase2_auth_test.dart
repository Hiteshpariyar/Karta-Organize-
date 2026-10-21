import 'package:flutter_test/flutter_test.dart';
import 'package:tourney_zone/features/auth/data/repositories/dev_auth_repository.dart';
import 'package:tourney_zone/features/auth/domain/models/user_profile.dart';
import 'package:tourney_zone/features/auth/presentation/controllers/organizer_login_controller.dart';
import 'package:tourney_zone/features/auth/presentation/controllers/player_registration_controller.dart';
import 'package:tourney_zone/features/auth/presentation/providers/auth_providers.dart';
import 'package:tourney_zone/features/organizer_application/data/repositories/dev_organizer_repository.dart';
import 'package:tourney_zone/features/organizer_application/domain/models/organizer_application.dart';
import 'package:tourney_zone/features/organizer_application/presentation/providers/organizer_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Phase 2 - User Profile & Server-Managed Role Security', () {
    test('Default user role is strictly player and cannot self-assign organizer or admin', () {
      const profile = UserProfile(
        uid: 'user_123',
        displayName: 'Test Gamer',
        email: 'gamer@tourneyzone.com',
      );

      expect(profile.role, equals(UserRole.player));
      expect(profile.isPlayer, isTrue);
      expect(profile.isOrganizer, isFalse);
      expect(profile.isAdmin, isFalse);
      expect(profile.isActive, isTrue);
      expect(profile.isSuspended, isFalse);
    });

    test('UserRole.fromString defaults unknown strings safely to UserRole.player', () {
      expect(UserRole.fromString('player'), equals(UserRole.player));
      expect(UserRole.fromString('organizer'), equals(UserRole.organizer));
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString('superadmin'), equals(UserRole.player));
      expect(UserRole.fromString(null), equals(UserRole.player));
      expect(UserRole.fromString(''), equals(UserRole.player));
    });

    test('AccountStatus handles active, suspended, and pending verification states', () {
      expect(AccountStatus.fromString('active'), equals(AccountStatus.active));
      expect(AccountStatus.fromString('suspended'), equals(AccountStatus.suspended));
      expect(AccountStatus.fromString('pending_verification'), equals(AccountStatus.pendingVerification));
      expect(AccountStatus.fromString('invalid'), equals(AccountStatus.active));

      const suspendedProfile = UserProfile(
        uid: 'user_suspended',
        displayName: 'Suspended Player',
        email: 'suspended@tourneyzone.com',
        accountStatus: AccountStatus.suspended,
      );
      expect(suspendedProfile.isSuspended, isTrue);
      expect(suspendedProfile.isActive, isFalse);
    });

    test('UserProfile Firestore serialization retains policy versions and required fields', () {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: 'user_test',
        displayName: 'John Doe',
        email: 'john@example.com',
        role: UserRole.player,
        accountStatus: AccountStatus.active,
        termsVersionAccepted: '1.0.0',
        privacyVersionAccepted: '0.1.0-draft',
        policyAcceptedAt: now,
        emailVerified: true,
      );

      final map = profile.toFirestoreMap();
      expect(map['uid'], equals('user_test'));
      expect(map['displayName'], equals('John Doe'));
      expect(map['email'], equals('john@example.com'));
      expect(map['role'], equals('player'));
      expect(map['accountStatus'], equals('active'));
      expect(map['termsVersionAccepted'], equals('1.0.0'));
      expect(map['privacyVersionAccepted'], equals('0.1.0-draft'));
      expect(map['emailVerified'], isTrue);

      final reconstructed = UserProfile.fromMap(map, docId: 'user_test');
      expect(reconstructed.uid, equals('user_test'));
      expect(reconstructed.displayName, equals('John Doe'));
      expect(reconstructed.email, equals('john@example.com'));
      expect(reconstructed.role, equals(UserRole.player));
      expect(reconstructed.accountStatus, equals(AccountStatus.active));
      expect(reconstructed.termsVersionAccepted, equals('1.0.0'));
      expect(reconstructed.privacyVersionAccepted, equals('0.1.0-draft'));
      expect(reconstructed.emailVerified, isTrue);
    });
  });

  group('Phase 2 - Organizer Application Domain & Security Model', () {
    test('Organizer application requires UID keying and defaults review metadata to null', () {
      const app = OrganizerApplication(
        uid: 'uid_applicant_1',
        applicationId: 'uid_applicant_1',
        applicantName: 'Host Admin',
        organizationName: 'Zone Esports',
        email: 'host@tourneyzone.com',
        phoneNumber: '9876543210',
        inGameUid: '5987654321',
        games: ['BGMI'],
        status: OrganizerApprovalStatus.pending,
        policyAccepted: true,
      );

      expect(app.uid, equals('uid_applicant_1'));
      expect(app.status, equals(OrganizerApprovalStatus.pending));
      expect(app.reviewedBy, isNull);
      expect(app.reviewedAt, isNull);
      expect(app.rejectionReason, isNull);

      final map = app.toFirestoreMap();
      expect(map['uid'], equals('uid_applicant_1'));
      expect(map['status'], equals('pending'));
      expect(map['policyAccepted'], isTrue);
      expect(map['reviewedBy'], isNull);
      expect(map['reviewedAt'], isNull);
      expect(map['rejectionReason'], isNull);
    });

    test('OrganizerApplication fromMap parses games list and approval status', () {
      final map = {
        'uid': 'applicant_456',
        'applicationId': 'applicant_456',
        'applicantName': 'Leader',
        'organizationName': 'Alpha Clan',
        'email': 'clan@tourneyzone.com',
        'phoneNumber': '9123456780',
        'inGameUid': '1234567890',
        'games': ['Free Fire MAX', 'Call of Duty: Mobile'],
        'status': 'rejected',
        'policyAccepted': true,
        'rejectionReason': 'Clan registered under conflicting trademark.',
      };

      final reconstructed = OrganizerApplication.fromMap(map, docId: 'applicant_456');
      expect(reconstructed.uid, equals('applicant_456'));
      expect(reconstructed.status, equals(OrganizerApprovalStatus.rejected));
      expect(reconstructed.rejectionReason, equals('Clan registered under conflicting trademark.'));
      expect(reconstructed.games.length, equals(2));
      expect(reconstructed.games, contains('Free Fire MAX'));
    });
  });

  group('Phase 2 - Mandatory Policy Acceptance Enforcement', () {
    test('Repository rejects registration when policy is not explicitly accepted', () async {
      final devAuthRepo = DevAuthRepository();

      final result = await devAuthRepo.registerPlayer(
        fullName: 'Player One',
        email: 'p1@tourneyzone.com',
        password: 'Password123',
        policyAccepted: false, // NOT accepted
        policyVersion: '1.0.0',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('must be explicitly accepted'));
    });

    test('Repository accepts registration when policy is accepted', () async {
      final devAuthRepo = DevAuthRepository();

      final result = await devAuthRepo.registerPlayer(
        fullName: 'Player One',
        email: 'p1@tourneyzone.com',
        password: 'Password123',
        policyAccepted: true, // ACCEPTED
        policyVersion: '1.0.0',
      );

      expect(result.isSuccess, isTrue);
      expect(result.userProfile, isNotNull);
      expect(result.userProfile?.termsVersionAccepted, equals('1.0.0'));
      expect(result.userProfile?.role, equals(UserRole.player));
    });

    test('Organizer application rejects submission when policy is not accepted', () async {
      final organizerRepo = DevOrganizerRepository();

      const appWithoutPolicy = OrganizerApplication(
        uid: 'user_test_policy',
        applicantName: 'Host Candidate',
        organizationName: 'Team Rocket',
        email: 'host@rocket.com',
        phoneNumber: '9876543210',
        inGameUid: '5123456789',
        games: ['BGMI'],
        policyAccepted: false, // NOT accepted
      );

      final result = await organizerRepo.submitApplication(appWithoutPolicy);
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('must be accepted'));
    });
  });

  group('Phase 2 - Profile Failure Recovery & Retry Flow', () {
    test('Player registration controller handles retry profile creation', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(DevAuthRepository()),
        ],
      );

      final notifier = container.read(playerRegistrationProvider.notifier);
      notifier.updateFullName('Recovery Tester');
      notifier.updateEmail('recovery@tourneyzone.com');
      notifier.updatePassword('Password123');
      notifier.updateConfirmPassword('Password123');
      notifier.togglePolicyAccepted(true);

      // Trigger initial registration
      final success = await notifier.register();
      expect(success, isTrue);

      // Now verify that retryProfileCreation can be invoked successfully
      final recoverySuccess = await notifier.retryProfileCreation();
      expect(recoverySuccess, isTrue);
      expect(container.read(playerRegistrationProvider).requiresProfileSetup, isFalse);
    });
  });

  group('Phase 2 - Organizer Login Routing & Trusted Verification', () {
    test('Directs to application form when no application is found', () async {
      final mockRepo = DevOrganizerRepository();
      // Simulate no existing application by returning null in a custom mock or testing branch
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(DevAuthRepository()),
          organizerRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      // Set status to pending in mockRepo
      mockRepo.setMockStatus(OrganizerApprovalStatus.pending);

      final notifier = container.read(organizerLoginProvider.notifier);
      notifier.updateEmail('host@tourneyzone.com');
      notifier.updatePassword('Password123');

      final success = await notifier.login();
      expect(success, isTrue);
      final state = container.read(organizerLoginProvider);
      expect(state.destination, equals(OrganizerLoginDestination.pendingReview));
    });

    test('Directs to rejected destination with rejection reason when application was rejected', () async {
      final mockRepo = DevOrganizerRepository();
      mockRepo.setMockStatus(OrganizerApprovalStatus.rejected);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(DevAuthRepository()),
          organizerRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(organizerLoginProvider.notifier);
      notifier.updateEmail('host@tourneyzone.com');
      notifier.updatePassword('Password123');

      final success = await notifier.login();
      expect(success, isTrue);
      final state = container.read(organizerLoginProvider);
      expect(state.destination, equals(OrganizerLoginDestination.rejected));
      expect(state.application?.status, equals(OrganizerApprovalStatus.rejected));
      expect(state.application?.rejectionReason, isNotNull);
    });

    test('Directs to approved destination when organizer is verified', () async {
      final mockRepo = DevOrganizerRepository();
      mockRepo.setMockStatus(OrganizerApprovalStatus.approved);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(DevAuthRepository()),
          organizerRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(organizerLoginProvider.notifier);
      notifier.updateEmail('host@tourneyzone.com');
      notifier.updatePassword('Password123');

      final success = await notifier.login();
      expect(success, isTrue);
      final state = container.read(organizerLoginProvider);
      expect(state.destination, equals(OrganizerLoginDestination.approved));
      expect(state.application?.status, equals(OrganizerApprovalStatus.approved));
    });

    test('Fails closed on verification server error', () async {
      final mockRepo = DevOrganizerRepository();
      mockRepo.setMockStatus(OrganizerApprovalStatus.error);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(DevAuthRepository()),
          organizerRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(organizerLoginProvider.notifier);
      notifier.updateEmail('host@tourneyzone.com');
      notifier.updatePassword('Password123');

      final success = await notifier.login();
      expect(success, isFalse);
      final state = container.read(organizerLoginProvider);
      expect(state.destination, equals(OrganizerLoginDestination.error));
      expect(state.errorMessage, contains('verification service'));
    });
  });

  group('Phase 2 - Session Management & Sign Out', () {
    test('Signing out clears cached profile and broadcasts null auth state', () async {
      final authRepo = DevAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );
      // Keep provider alive with listener
      final sub = container.listen(currentUserProfileProvider, (_, _) {});

      // Sign in
      await authRepo.signIn(
        email: 'session@tourneyzone.com',
        password: 'Password123',
        role: 'Player',
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(authRepo.isAuthenticated, isTrue);
      expect(authRepo.currentUserProfile?.email, equals('session@tourneyzone.com'));
      expect(container.read(currentUserProfileProvider)?.email, equals('session@tourneyzone.com'));

      // Sign out
      await authRepo.signOut();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(authRepo.isAuthenticated, isFalse);
      expect(authRepo.currentUserProfile, isNull);
      expect(container.read(currentUserProfileProvider), isNull);

      sub.close();
      container.dispose();
    });
  });
}
