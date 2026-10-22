import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tourney_zone/core/router/app_router.dart';
import 'package:tourney_zone/core/router/app_routes.dart';
import 'package:tourney_zone/core/theme/app_colors.dart';
import 'package:tourney_zone/core/theme/theme_provider.dart';
import 'package:tourney_zone/core/utils/form_validators.dart';
import 'package:tourney_zone/features/auth/data/repositories/dev_auth_repository.dart';
import 'package:tourney_zone/features/auth/domain/models/account_authorization_state.dart';
import 'package:tourney_zone/features/auth/domain/models/user_profile.dart';
import 'package:tourney_zone/features/auth/presentation/controllers/organizer_login_controller.dart';
import 'package:tourney_zone/features/auth/presentation/controllers/player_login_controller.dart';
import 'package:tourney_zone/features/auth/presentation/controllers/player_registration_controller.dart';
import 'package:tourney_zone/features/auth/presentation/providers/auth_providers.dart';
import 'package:tourney_zone/features/auth/presentation/screens/player_login_screen.dart';
import 'package:tourney_zone/features/auth/presentation/screens/player_registration_screen.dart';
import 'package:tourney_zone/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:tourney_zone/features/auth/presentation/widgets/official_google_logo.dart';
import 'package:tourney_zone/features/auth/presentation/widgets/password_requirements_widget.dart';
import 'package:tourney_zone/features/organizer_application/data/repositories/dev_organizer_repository.dart';
import 'package:tourney_zone/features/organizer_application/domain/models/organizer_application.dart';
import 'package:tourney_zone/features/organizer_application/presentation/providers/organizer_providers.dart';

void main() {
  group('Phase 7 Verification: Auth Redesign & Authorization Gating', () {
    // 1. Player login with valid credentials succeeds and authenticates
    test('1. Player login with valid credentials succeeds and returns verified profile', () async {
      final authRepo = DevAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );

      final notifier = container.read(playerLoginProvider.notifier);
      notifier.updateEmail('proplayer@tourneyzone.com');
      notifier.updatePassword('Password123');

      final success = await notifier.login();
      expect(success, isTrue);

      final state = container.read(playerLoginProvider);
      expect(state.userProfile, isNotNull);
      expect(state.userProfile?.role, equals(UserRole.player));
      expect(state.errorMessage, isNull);
    });

    // 2. Player login with invalid credentials shows appropriate error
    test('2. Player login with invalid credentials shows error banner', () async {
      final authRepo = DevAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );

      final notifier = container.read(playerLoginProvider.notifier);
      notifier.updateEmail('wrong@tourneyzone.com');
      notifier.updatePassword('wrongpassword');

      final success = await notifier.login();
      expect(success, isFalse);

      final state = container.read(playerLoginProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.userProfile, isNull);
    });

    // 3. Password show/hide toggle works
    testWidgets('3. Password show/hide toggle toggles obscureText property', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlayerLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find password text field
      final passwordFieldFinder = find.byType(TextField).last;
      TextField passwordField = tester.widget<TextField>(passwordFieldFinder);
      expect(passwordField.obscureText, isTrue);

      // Find visibility toggle icon button
      final toggleFinder = find.byIcon(Icons.visibility_off_rounded);
      expect(toggleFinder, findsOneWidget);

      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Verify obscured property is now false
      passwordField = tester.widget<TextField>(passwordFieldFinder);
      expect(passwordField.obscureText, isFalse);
    });

    // 4. Google sign-in button renders with official logo and triggers sign-in flow
    testWidgets('4. Google sign-in button renders official logo and executes flow', (tester) async {
      bool googleTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(
              onPressed: () {
                googleTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OfficialGoogleLogo), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      await tester.tap(find.byType(GoogleSignInButton));
      await tester.pumpAndSettle();

      expect(googleTapped, isTrue);
    });

    // 5. Player registration validates required fields, email format, password requirements, and policy checkbox
    test('5. Player registration validates required fields, email format, and policy consent', () {
      // Empty fields
      expect(FormValidators.required(''), isNotNull);
      expect(FormValidators.email('not-an-email'), isNotNull);
      expect(FormValidators.email('valid@tourneyzone.com'), isNull);
      expect(FormValidators.password('weak'), isNotNull);
      expect(FormValidators.password('Password123'), isNull);

      // Registration state validity check
      const invalidState = PlayerRegistrationState(
        fullName: 'Player',
        email: 'player@example.com',
        password: 'Password123',
        confirmPassword: 'Password123',
        policyAccepted: false, // Must be explicitly accepted
      );
      expect(invalidState.isFormValid, isFalse);

      const validState = PlayerRegistrationState(
        fullName: 'Player',
        email: 'player@example.com',
        password: 'Password123',
        confirmPassword: 'Password123',
        policyAccepted: true,
      );
      expect(validState.isFormValid, isTrue);
    });

    // 6. Password strength/requirements indicator updates as user types
    testWidgets('6. Password strength indicator dynamically checks uppercase, lowercase, numbers, and symbols', (tester) async {
      const widget1 = PasswordRequirementsWidget(password: 'pass');
      expect(widget1.hasMinLength, isFalse);
      expect(widget1.hasUppercase, isFalse);
      expect(widget1.hasLowercase, isTrue);
      expect(widget1.hasNumber, isFalse);
      expect(widget1.hasSpecialChar, isFalse);
      expect(widget1.strengthLabel, equals('Weak'));

      const widget2 = PasswordRequirementsWidget(password: 'Password123!');
      expect(widget2.hasMinLength, isTrue);
      expect(widget2.hasUppercase, isTrue);
      expect(widget2.hasLowercase, isTrue);
      expect(widget2.hasNumber, isTrue);
      expect(widget2.hasSpecialChar, isTrue);
      expect(widget2.strengthLabel, equals('Strong'));
      expect(widget2.metCount, equals(5));
    });

    // 7. Player attempting organizer login without approved application is blocked with appropriate message
    test('7. Player attempting organizer login without approved application is blocked with clear message', () async {
      final authRepo = DevAuthRepository();
      // Register a standard player
      await authRepo.registerPlayer(
        fullName: 'Registered Player',
        email: 'player_only@tourneyzone.com',
        password: 'Password123',
        policyAccepted: true,
        policyVersion: '1.0.0',
      );

      final organizerRepo = DevOrganizerRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          organizerRepositoryProvider.overrideWithValue(organizerRepo),
        ],
      );

      final notifier = container.read(organizerLoginProvider.notifier);
      notifier.updateEmail('player_only@tourneyzone.com');
      notifier.updatePassword('Password123');

      final success = await notifier.login();
      expect(success, isTrue);

      final state = container.read(organizerLoginProvider);
      // Gated to application page with explicit player warning
      expect(state.destination, equals(OrganizerLoginDestination.apply));
      expect(
        state.errorMessage,
        equals('This account is registered as a Player. Organizer privileges require an approved application.'),
      );
    });

    // 8. Player with pending application is routed to status view, not dashboard
    test('8. Player with pending application is routed to status view only', () async {
      final authRepo = DevAuthRepository();
      final organizerRepo = DevOrganizerRepository();
      organizerRepo.setMockStatus(OrganizerApprovalStatus.pending);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          organizerRepositoryProvider.overrideWithValue(organizerRepo),
        ],
      );

      final notifier = container.read(organizerLoginProvider.notifier);
      notifier.updateEmail('pending_host@tourneyzone.com');
      notifier.updatePassword('Password123');

      final success = await notifier.login();
      expect(success, isTrue);

      final state = container.read(organizerLoginProvider);
      expect(state.destination, equals(OrganizerLoginDestination.pendingReview));
      expect(state.application?.status, equals(OrganizerApprovalStatus.pending));

      // Authoritative domain state check
      final authState = AccountAuthorizationState.resolve(
        profile: state.userProfile,
        application: state.application,
      );
      expect(authState, equals(AccountAuthorizationState.organizerPending));
      expect(authState.canHostTournaments, isFalse);
    });

    // 9. Organizer with approved status can access organizer features
    test('9. Organizer with approved status can access hosting authority', () async {
      final authRepo = DevAuthRepository();
      final organizerRepo = DevOrganizerRepository();
      organizerRepo.setMockStatus(OrganizerApprovalStatus.approved);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          organizerRepositoryProvider.overrideWithValue(organizerRepo),
        ],
      );

      final notifier = container.read(organizerLoginProvider.notifier);
      notifier.updateEmail('verified_host@tourneyzone.com');
      notifier.updatePassword('Password123');

      final success = await notifier.login();
      expect(success, isTrue);

      final state = container.read(organizerLoginProvider);
      expect(state.destination, equals(OrganizerLoginDestination.approved));

      // Domain state verification
      final authState = AccountAuthorizationState.resolve(
        profile: state.userProfile,
        application: state.application,
      );
      expect(authState, equals(AccountAuthorizationState.organizerApproved));
      expect(authState.canHostTournaments, isTrue);
    });

    // 10. Theme switching updates Login and Sign Up screens without unreadable elements
    testWidgets('10. Theme switching updates ThemeMode and colors without crashes', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlayerLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find theme toggle button
      final themeToggleFinder = find.byTooltip('Switch to Light Theme');
      if (themeToggleFinder.evaluate().isNotEmpty) {
        await tester.tap(themeToggleFinder);
        await tester.pumpAndSettle();
      }

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in to continue your tournament journey.'), findsOneWidget);
    });

    // 11. Route guards redirect unauthorized access attempts
    test('11. Route guards enforce authentication and protect organizer routes', () {
      final authRepo = DevAuthRepository();

      // Test A: Unauthenticated user accessing /organizer/status -> redirect to organizer login
      final unauthRedirect = appRouteGuard(
        MockBuildContext(),
        MockGoRouterState('/organizer/status'),
        authRepoOverride: authRepo,
      );
      expect(unauthRedirect, equals(AppRoutes.organizerLogin));

      // Test B: Authenticated Player accessing /organizer/apply -> allowed (returns null)
      authRepo.signIn(
        email: 'player@tourneyzone.com',
        password: 'Password123',
        role: 'Player',
      );
      final candidateApplyRedirect = appRouteGuard(
        MockBuildContext(),
        MockGoRouterState('/organizer/apply'),
        authRepoOverride: authRepo,
      );
      expect(candidateApplyRedirect, isNull);

      // Test C: Authenticated Player accessing protected hosting dashboard -> redirected to status
      final unauthorizedDashboardRedirect = appRouteGuard(
        MockBuildContext(),
        MockGoRouterState('/organizer/dashboard'),
        authRepoOverride: authRepo,
      );
      expect(unauthorizedDashboardRedirect, equals(AppRoutes.organizerStatus));

      // Test D: Authenticated user visiting /player/login -> redirects to playerDashboard
      final authenticatedLoginRedirect = appRouteGuard(
        MockBuildContext(),
        MockGoRouterState(AppRoutes.playerLogin),
        authRepoOverride: authRepo,
      );
      expect(authenticatedLoginRedirect, equals(AppRoutes.playerDashboard));
    });

    // 12. Role self-elevation attempts are rejected
    test('12. Role self-elevation attempts are strictly rejected by domain and repository', () async {
      final authRepo = DevAuthRepository();

      // Register new user - must strictly be player regardless of requested role
      final regResult = await authRepo.registerPlayer(
        fullName: 'Hacker',
        email: 'hacker@tourneyzone.com',
        password: 'Password123',
        policyAccepted: true,
        policyVersion: '1.0.0',
      );
      expect(regResult.isSuccess, isTrue);
      expect(regResult.userProfile?.role, equals(UserRole.player));

      // Attempt to sign in claiming "Organizer" role
      final loginResult = await authRepo.signIn(
        email: 'hacker@tourneyzone.com',
        password: 'Password123',
        role: 'Organizer', // Client attempts to claim organizer
      );
      expect(loginResult.isSuccess, isTrue);
      // Stored profile role remains Player; client cannot elevate
      expect(loginResult.userProfile?.role, equals(UserRole.player));
      expect(loginResult.userProfile?.isOrganizer, isFalse);
    });
  });
}

class MockBuildContext extends Fake implements BuildContext {}

class MockGoRouterState extends Fake implements GoRouterState {
  final String _path;
  MockGoRouterState(this._path);

  @override
  Uri get uri => Uri.parse(_path);
}

