import 'package:flutter_test/flutter_test.dart';
import 'package:tourney_zone/core/security/auth_security_service.dart';
import 'package:tourney_zone/features/auth/domain/models/user_profile.dart';
import 'package:tourney_zone/features/auth/domain/repositories/auth_repository.dart';
import 'package:tourney_zone/features/auth/data/repositories/dev_auth_repository.dart';
import 'package:tourney_zone/features/auth/data/repositories/firebase_auth_repository.dart';

void main() {
  group('1. Password-Reset Rate Limiting (Rolling 90-Second Window)', () {
    late AuthSecurityService securityService;
    DateTime simulatedNow = DateTime(2026, 10, 22, 12, 0, 0);

    setUp(() {
      simulatedNow = DateTime(2026, 10, 22, 12, 0, 0);
      securityService = AuthSecurityService(
        maxPasswordResetsPerWindow: 4,
        passwordResetWindow: const Duration(seconds: 90),
        clock: () => simulatedNow,
      );
    });

    test('Allows exactly 4 password-reset requests within 90 seconds', () {
      const email = 'player@tourneyzone.com';

      // 1st request
      final r1 = securityService.checkAndRecordPasswordReset(email);
      expect(r1.isAllowed, isTrue);
      expect(r1.currentAttemptCount, equals(1));

      // 2nd request (after 10s)
      simulatedNow = simulatedNow.add(const Duration(seconds: 10));
      final r2 = securityService.checkAndRecordPasswordReset(email);
      expect(r2.isAllowed, isTrue);
      expect(r2.currentAttemptCount, equals(2));

      // 3rd request (after 20s)
      simulatedNow = simulatedNow.add(const Duration(seconds: 20));
      final r3 = securityService.checkAndRecordPasswordReset(email);
      expect(r3.isAllowed, isTrue);
      expect(r3.currentAttemptCount, equals(3));

      // 4th request (after 30s)
      simulatedNow = simulatedNow.add(const Duration(seconds: 30));
      final r4 = securityService.checkAndRecordPasswordReset(email);
      expect(r4.isAllowed, isTrue);
      expect(r4.currentAttemptCount, equals(4));
    });

    test('Strictly throttles the 5th request within the rolling 90-second window', () {
      const email = 'player@tourneyzone.com';

      // Send 4 requests
      for (int i = 0; i < 4; i++) {
        simulatedNow = simulatedNow.add(const Duration(seconds: 10));
        final res = securityService.checkAndRecordPasswordReset(email);
        expect(res.isAllowed, isTrue);
      }

      // 5th request at t=45s (within the 90s window)
      simulatedNow = simulatedNow.add(const Duration(seconds: 5));
      final r5 = securityService.checkAndRecordPasswordReset(email);

      expect(r5.isAllowed, isFalse);
      expect(r5.errorMessage, contains('Too many password reset requests'));
      expect(r5.retryAfter, isNotNull);
      expect(r5.retryAfter!.inSeconds, greaterThan(0));
      expect(r5.retryAfter!.inSeconds, lessThanOrEqualTo(90));
    });

    test('Resets counter after rolling 90-second window expires', () {
      const email = 'player@tourneyzone.com';

      // Send 4 requests
      for (int i = 0; i < 4; i++) {
        final res = securityService.checkAndRecordPasswordReset(email);
        expect(res.isAllowed, isTrue);
      }

      // Fast forward past the 90-second window (e.g. 95 seconds)
      simulatedNow = simulatedNow.add(const Duration(seconds: 95));

      // 5th attempt after window expiration is allowed
      final rAfterWindow = securityService.checkAndRecordPasswordReset(email);
      expect(rAfterWindow.isAllowed, isTrue);
      expect(rAfterWindow.currentAttemptCount, equals(1));
    });

    test('Tracks rate limits independently per email account', () {
      const emailA = 'userA@tourneyzone.com';
      const emailB = 'userB@tourneyzone.com';

      // Exhaust limit for emailA
      for (int i = 0; i < 4; i++) {
        securityService.checkAndRecordPasswordReset(emailA);
      }
      expect(securityService.checkAndRecordPasswordReset(emailA).isAllowed, isFalse);

      // emailB should still be permitted
      final rB = securityService.checkAndRecordPasswordReset(emailB);
      expect(rB.isAllowed, isTrue);
    });
  });

  group('2. Failed-Login Throttling & Account Lockout Prevention', () {
    late AuthSecurityService securityService;
    DateTime simulatedNow = DateTime(2026, 10, 22, 12, 0, 0);

    setUp(() {
      simulatedNow = DateTime(2026, 10, 22, 12, 0, 0);
      securityService = AuthSecurityService(
        failedLoginThreshold: 5,
        failedLoginCooldown: const Duration(seconds: 60),
        clock: () => simulatedNow,
      );
    });

    test('Allows login attempts below the threshold', () {
      const email = 'victim@tourneyzone.com';

      for (int i = 0; i < 4; i++) {
        final check = securityService.checkLoginAllowed(email);
        expect(check.isAllowed, isTrue);
        securityService.recordFailedLogin(email);
      }
    });

    test('Throttles on 5th consecutive failed login attempt', () {
      const email = 'victim@tourneyzone.com';

      for (int i = 0; i < 5; i++) {
        securityService.recordFailedLogin(email);
      }

      final check = securityService.checkLoginAllowed(email);
      expect(check.isAllowed, isFalse);
      expect(check.errorMessage, contains('Too many failed login attempts'));
      expect(check.retryAfter!.inSeconds, greaterThan(0));
    });

    test('Successful login clears the failure counter', () {
      const email = 'player@tourneyzone.com';

      // 3 failed logins
      for (int i = 0; i < 3; i++) {
        securityService.recordFailedLogin(email);
      }

      // Successful login
      securityService.recordSuccessfulLogin(email);

      // Subsequent check is clean
      final check = securityService.checkLoginAllowed(email);
      expect(check.isAllowed, isTrue);
    });

    test('Does not permanently lock the account; restores access after cooldown', () {
      const email = 'player@tourneyzone.com';

      for (int i = 0; i < 5; i++) {
        securityService.recordFailedLogin(email);
      }
      expect(securityService.checkLoginAllowed(email).isAllowed, isFalse);

      // Advance time beyond cooldown (65 seconds)
      simulatedNow = simulatedNow.add(const Duration(seconds: 65));

      final check = securityService.checkLoginAllowed(email);
      expect(check.isAllowed, isTrue);
    });
  });

  group('3. Player-to-Admin Privilege Escalation Protection', () {
    test('Default user role is strictly player and cannot self-assign organizer or admin', () {
      const profile = UserProfile(
        uid: 'user_exploit',
        displayName: 'Attacker',
        email: 'attacker@evil.com',
      );

      expect(profile.role, equals(UserRole.player));
      expect(profile.isAdmin, isFalse);
      expect(profile.isOrganizer, isFalse);
    });

    test('UserRole.fromString defaults unauthorized or unknown strings to UserRole.player', () {
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString('superadmin'), equals(UserRole.player));
      expect(UserRole.fromString('root'), equals(UserRole.player));
      expect(UserRole.fromString('SYSTEM'), equals(UserRole.player));
      expect(UserRole.fromString(null), equals(UserRole.player));
    });

    test('UserProfile copyWith preserves role unless explicitly administrative', () {
      const playerProfile = UserProfile(
        uid: 'user_norm',
        displayName: 'Normal Player',
        email: 'norm@tourneyzone.com',
        role: UserRole.player,
      );

      final updated = playerProfile.copyWith(displayName: 'Updated Name');
      expect(updated.role, equals(UserRole.player));
      expect(updated.isAdmin, isFalse);
    });
  });

  group('4. Account Privacy, Generic Responses & Audit Logs', () {
    test('Password reset returns generic response to prevent account enumeration', () async {
      final securityService = AuthSecurityService();
      final repo = FirebaseAuthRepository(
        securityService: securityService,
      );

      // In sandbox mode without live Firebase, returns generic safe message
      final result = await repo.sendPasswordResetEmail(email: 'unregistered@unknown.com');
      expect(result.isSuccess, isTrue);
      expect(
        result.message,
        contains('If an account exists with this email address, a password reset link has been dispatched'),
      );
    });

    test('Audit logging records events immutably without logging passwords or secrets', () {
      final securityService = AuthSecurityService();

      securityService.checkAndRecordPasswordReset('target@tourneyzone.com');
      securityService.recordFailedLogin('target@tourneyzone.com');
      securityService.recordPrivilegeEscalationAttempt(
        uid: 'uid_test',
        attemptedRole: 'admin',
        endpoint: '/users/uid_test',
      );
      securityService.recordAccountDeletion(uid: 'uid_test');

      final logs = securityService.auditLogs;
      expect(logs.length, equals(4));

      // Verify no sensitive credentials in metadata
      for (final log in logs) {
        expect(log.metadata.containsKey('password'), isFalse);
        expect(log.metadata.containsKey('token'), isFalse);
        expect(log.metadata.containsKey('secret'), isFalse);
      }

      expect(logs[2].eventType, equals(SecurityEventType.privilegeEscalationAttempt));
      expect(logs[3].eventType, equals(SecurityEventType.accountDeleted));
    });
  });

  group('5. Safe Account Deletion & Cascading Cleanup', () {
    test('DevAuthRepository implements deleteAccount and clears active session', () async {
      final devRepo = DevAuthRepository();
      await devRepo.signIn(email: 'test@example.com', password: 'Password123!', role: 'Player');
      expect(devRepo.isAuthenticated, isTrue);

      final deleteResult = await devRepo.deleteAccount(password: 'Password123!');
      expect(deleteResult.isSuccess, isTrue);
      expect(devRepo.isAuthenticated, isFalse);
      expect(devRepo.currentUserProfile, isNull);
    });

    test('FirebaseAuthRepository deleteAccount requires authenticated user', () async {
      final repo = FirebaseAuthRepository();
      // When no user is logged in, deleteAccount returns failure safely
      final result = await repo.deleteAccount(password: 'dummy');
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('No authenticated user'));
    });
  });
}

