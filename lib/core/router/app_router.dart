import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/organizer_login_screen.dart';
import '../../features/auth/presentation/screens/player_login_screen.dart';
import '../../features/auth/presentation/screens/player_registration_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/organizer_application/presentation/screens/organizer_application_review_screen.dart';
import '../../features/organizer_application/presentation/screens/organizer_application_screen.dart';
import '../../features/organizer_application/presentation/screens/organizer_status_screen.dart';
import '../../features/policy/presentation/screens/organizer_terms_screen.dart';
import '../../features/policy/presentation/screens/player_terms_screen.dart';
import '../../features/policy/presentation/screens/privacy_policy_screen.dart';
import '../../features/profile/presentation/screens/player_profile_screen.dart';
import '../../features/tournaments/presentation/screens/my_tournaments_screen.dart';
import '../../features/tournaments/presentation/screens/player_dashboard_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_details_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_discovery_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_registration_screen.dart';
import '../../features/welcome/presentation/screens/welcome_screen.dart';
import 'app_routes.dart';

/// Centralized GoRouter navigation configuration.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.welcome,
  debugLogDiagnostics: false,
  routes: [
    // Welcome / Entry Screen
    GoRoute(
      path: AppRoutes.welcome,
      name: AppRoutes.welcomeName,
      builder: (context, state) => const WelcomeScreen(),
    ),

    // Phase 3 Player Dashboard & Tournaments
    GoRoute(
      path: AppRoutes.playerDashboard,
      name: AppRoutes.playerDashboardName,
      builder: (context, state) => const PlayerDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.tournaments,
      name: AppRoutes.tournamentsName,
      builder: (context, state) => const TournamentDiscoveryScreen(),
    ),
    GoRoute(
      path: AppRoutes.tournamentDetails,
      name: AppRoutes.tournamentDetailsName,
      builder: (context, state) => TournamentDetailsScreen(
        tournamentId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.tournamentRegister,
      name: AppRoutes.tournamentRegisterName,
      builder: (context, state) => TournamentRegistrationScreen(
        tournamentId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.myTournaments,
      name: AppRoutes.myTournamentsName,
      builder: (context, state) => const MyTournamentsScreen(),
    ),
    GoRoute(
      path: AppRoutes.playerProfile,
      name: AppRoutes.playerProfileName,
      builder: (context, state) => const PlayerProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      name: AppRoutes.notificationsName,
      builder: (context, state) => const NotificationsScreen(),
    ),

    // Player Flow
    GoRoute(
      path: AppRoutes.playerLogin,
      name: AppRoutes.playerLoginName,
      builder: (context, state) => const PlayerLoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.playerRegister,
      name: AppRoutes.playerRegisterName,
      builder: (context, state) => const PlayerRegistrationScreen(),
    ),

    // Password Reset
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: AppRoutes.forgotPasswordName,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // Organizer Flow
    GoRoute(
      path: AppRoutes.organizerLogin,
      name: AppRoutes.organizerLoginName,
      builder: (context, state) => const OrganizerLoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.organizerApply,
      name: AppRoutes.organizerApplyName,
      builder: (context, state) => const OrganizerApplicationScreen(),
    ),
    GoRoute(
      path: AppRoutes.organizerReview,
      name: AppRoutes.organizerReviewName,
      builder: (context, state) => const OrganizerApplicationReviewScreen(),
    ),
    GoRoute(
      path: AppRoutes.organizerStatus,
      name: AppRoutes.organizerStatusName,
      builder: (context, state) => const OrganizerStatusScreen(),
    ),

    // Policy Flow
    GoRoute(
      path: AppRoutes.playerTerms,
      name: AppRoutes.playerTermsName,
      builder: (context, state) => const PlayerTermsScreen(),
    ),
    GoRoute(
      path: AppRoutes.organizerTerms,
      name: AppRoutes.organizerTermsName,
      builder: (context, state) => const OrganizerTermsScreen(),
    ),
    GoRoute(
      path: AppRoutes.privacyPolicy,
      name: AppRoutes.privacyPolicyName,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFF090D16),
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            'Route not found: ${state.uri}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.welcome),
            child: const Text('Return to Home'),
          ),
        ],
      ),
    ),
  ),
);

