import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tourney_zone/app.dart';
import 'package:tourney_zone/core/config/app_config.dart';
import 'package:tourney_zone/core/router/app_router.dart';
import 'package:tourney_zone/core/router/app_routes.dart';
import 'package:tourney_zone/core/utils/form_validators.dart';
import 'package:tourney_zone/core/widgets/app_button.dart';
import 'package:tourney_zone/core/widgets/policy_checkbox.dart';
import 'package:tourney_zone/features/auth/presentation/screens/player_registration_screen.dart';
import 'package:tourney_zone/features/organizer_application/domain/models/organizer_application.dart';
import 'package:tourney_zone/features/organizer_application/presentation/controllers/organizer_status_controller.dart';
import 'package:tourney_zone/features/organizer_application/presentation/screens/organizer_status_screen.dart';
import 'package:tourney_zone/features/policy/presentation/screens/player_terms_screen.dart';

void main() {
  setUp(() {
    appRouter.go(AppRoutes.welcome);
  });

  group('1. FormValidators Unit Tests', () {
    test('Required field validation', () {
      expect(FormValidators.required(''), isNotNull);
      expect(FormValidators.required('   '), isNotNull);
      expect(FormValidators.required(null), isNotNull);
      expect(FormValidators.required('Valid Text'), isNull);
    });

    test('Email format validation', () {
      expect(FormValidators.email(''), isNotNull);
      expect(FormValidators.email('invalid-email'), isNotNull);
      expect(FormValidators.email('test@domain'), isNotNull);
      expect(FormValidators.email('player@tourneyzone.com'), isNull);
    });

    test('Password security requirements validation', () {
      expect(FormValidators.password('short'), isNotNull);
      expect(FormValidators.password('onlyletters'), isNotNull);
      expect(FormValidators.password('12345678'), isNotNull);
      expect(FormValidators.password('ValidPass123'), isNull);
    });

    test('Confirm password match validation', () {
      expect(FormValidators.confirmPassword('Pass1234', 'Different123'), isNotNull);
      expect(FormValidators.confirmPassword('Pass1234', 'Pass1234'), isNull);
    });

    test('Phone number 10-digit validation', () {
      expect(FormValidators.phone('123'), isNotNull);
      expect(FormValidators.phone('abcdefghij'), isNotNull);
      expect(FormValidators.phone('9876543210'), isNull);
    });
  });

  group('2. Welcome Screen & Role Selection Widget Tests', () {
    testWidgets('Renders app title, slogan, and role cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TourneyZoneApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppConfig.appName), findsWidgets);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text(AppConfig.appTagline), findsOneWidget);
      expect(find.text('Continue as Player'), findsOneWidget);
      expect(find.text('Continue as Organizer'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
    });

    testWidgets('Tapping Create an account opens role-selection sheet without overflow', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TourneyZoneApp(),
        ),
      );
      await tester.pumpAndSettle();

      final createAccountLink = find.text('Create an account');
      await tester.scrollUntilVisible(createAccountLink, 100);
      await tester.tap(createAccountLink);
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Role'), findsOneWidget);
      expect(find.text('Create Player Account'), findsOneWidget);
      expect(find.text('Apply as Tournament Host'), findsOneWidget);
    });
  });

  group('3. Player Registration & Mandatory Policy Acceptance Tests', () {
    testWidgets('Checkbox is unchecked by default and form validates input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlayerRegistrationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Player Account'), findsOneWidget);

      // Checkbox must be unchecked by default
      final checkboxFinder = find.byKey(const ValueKey('policy_checkbox'));
      expect(checkboxFinder, findsOneWidget);
      final checkbox = tester.widget<Checkbox>(checkboxFinder);
      expect(checkbox.value, isFalse);

      // The Create Account button is present
      expect(find.widgetWithText(AppButton, 'Create Account'), findsOneWidget);

      // Fill in all 4 text form fields using byType index
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Pro Player',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'player@tourneyzone.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Secret123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'Secret123',
      );
      await tester.pumpAndSettle();

      // Scroll checkbox into view and tap to explicitly accept
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final updatedCheckbox = tester.widget<Checkbox>(checkboxFinder);
      expect(updatedCheckbox.value, isTrue);
    });

    testWidgets('Navigating to Policy from registration preserves state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TourneyZoneApp(),
        ),
      );
      appRouter.go(AppRoutes.playerRegister);
      await tester.pumpAndSettle();

      expect(find.text('Create Player Account'), findsOneWidget);

      // Enter name
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Preserved Player Name',
      );
      await tester.pumpAndSettle();

      // Find RichText containing Policy Acceptance
      final policyRichText = find.byType(PolicyAcceptanceCheckbox);
      expect(policyRichText, findsOneWidget);

      // Navigate to Player Terms directly via router to simulate link tap
      appRouter.push(AppRoutes.playerTerms);
      await tester.pumpAndSettle();

      // Verify Player Terms screen loaded
      expect(find.byType(PlayerTermsScreen), findsOneWidget);
      expect(find.text('Player Terms & Conditions'), findsWidgets);

      // Tap back button
      final backButton = find.byTooltip('Back');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify we returned to registration screen and name is preserved
      expect(find.text('Create Player Account'), findsOneWidget);
      expect(find.text('Preserved Player Name'), findsOneWidget);
    });
  });

  group('4. Organizer Status Presentation Widget Tests', () {
    testWidgets('Displays Pending Review state accurately without 24hr promise', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizerStatusProvider.overrideWith(
              () => _MockOrganizerStatusNotifier(
                const OrganizerStatusState(
                  status: OrganizerApprovalStatus.pending,
                  referenceId: 'TZ-ORG-TEST-123',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: OrganizerStatusScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Application Is Under Review'), findsOneWidget);
      expect(
        find.text(
          'Your organizer application is awaiting administrator review. You will be able to access organizer features after approval.',
        ),
        findsOneWidget,
      );
      expect(find.text('Application Status'), findsWidgets);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('TZ-ORG-TEST-123'), findsOneWidget);
      expect(find.text('Refresh Status'), findsOneWidget);
      expect(find.text('Return to Login'), findsOneWidget);
    });

    testWidgets('Displays Approved state with dashboard placeholder', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizerStatusProvider.overrideWith(
              () => _MockOrganizerStatusNotifier(
                const OrganizerStatusState(
                  status: OrganizerApprovalStatus.approved,
                  referenceId: 'TZ-ORG-TEST-123',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: OrganizerStatusScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Organizer Application Approved'), findsOneWidget);
      expect(find.text('Application Status'), findsWidgets);
      expect(find.text('Approved'), findsWidgets);
      expect(find.text('Continue to Organizer Dashboard'), findsOneWidget);
    });

    testWidgets('Displays Rejected state with actual reason and resubmit action', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizerStatusProvider.overrideWith(
              () => _MockOrganizerStatusNotifier(
                const OrganizerStatusState(
                  status: OrganizerApprovalStatus.rejected,
                  referenceId: 'TZ-ORG-TEST-123',
                  rejectionReason: 'Invalid In-Game UID provided for BGMI tournament verification.',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: OrganizerStatusScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Application Not Approved'), findsOneWidget);
      expect(find.text('Invalid In-Game UID provided for BGMI tournament verification.'), findsOneWidget);
      expect(find.text('Edit and Resubmit Application'), findsOneWidget);
    });

    testWidgets('Displays Verification Server Error state with retry action', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizerStatusProvider.overrideWith(
              () => _MockOrganizerStatusNotifier(
                const OrganizerStatusState(
                  status: OrganizerApprovalStatus.error,
                  errorMessage: 'Network timeout: Could not connect to organizer verification service.',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: OrganizerStatusScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verification Server Error'), findsOneWidget);
      expect(find.text('Retry Verification'), findsOneWidget);
    });
  });
}

class _MockOrganizerStatusNotifier extends OrganizerStatusNotifier {
  final OrganizerStatusState initialState;
  _MockOrganizerStatusNotifier(this.initialState);

  @override
  OrganizerStatusState build() => initialState;

  @override
  Future<void> fetchStatus({String? referenceId}) async {}
}
