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
import '../../features/tournaments/presentation/screens/game_details_screen.dart';
import '../../features/tournaments/presentation/screens/my_tournaments_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_details_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_registration_screen.dart';
import '../../features/welcome/presentation/screens/welcome_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../widgets/main_scaffold.dart';
import 'app_routes.dart';

/// Top-level route guard enforcing authentication and authorization across routes.
String? appRouteGuard(BuildContext context, GoRouterState state, {IAuthRepository? authRepoOverride}) {
  IAuthRepository? authRepo = authRepoOverride;
  if (authRepo == null) {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      authRepo = container.read(authRepositoryProvider);
    } catch (_) {
      // In standalone tests or pre-scope evaluations
    }
  }

  final path = state.uri.path;
  final isAuthenticated = authRepo?.isAuthenticated ?? false;
  final profile = authRepo?.currentUserProfile;
  final isOrganizerApproved = (profile?.isOrganizer ?? false) || (profile?.isAdmin ?? false);

  // Protect /organizer/* routes
  if (path.startsWith('/organizer')) {
    // 1. Organizer login is public for sign-in
    if (path == AppRoutes.organizerLogin) {
      return null;
    }

    // 2. Unauthenticated access to any organizer route redirects to organizer login
    if (!isAuthenticated) {
      return AppRoutes.organizerLogin;
    }

    // 3. Player accounts without approved organizer status can only access apply and status views
    final isAllowedCandidateRoute = path == AppRoutes.organizerApply ||
        path == AppRoutes.organizerReview ||
        path == AppRoutes.organizerStatus;

    if (!isAllowedCandidateRoute && !isOrganizerApproved) {
      return AppRoutes.organizerStatus;
    }
  }

  // 4. Authenticated users with active profiles visiting entry or auth routes redirect to dashboard
  final isAuthEntryRoute = path == AppRoutes.playerLogin ||
      path == AppRoutes.playerRegister ||
      path == AppRoutes.welcome;

  if (isAuthenticated && profile != null && isAuthEntryRoute) {
    if (isOrganizerApproved) {
      return AppRoutes.organizerStatus;
    } else {
      return AppRoutes.playerDashboard;
    }
  }

  return null;
}

/// Centralized GoRouter navigation configuration.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.playerLogin,
  debugLogDiagnostics: false,
  redirect: (context, state) => appRouteGuard(context, state),
  routes: [
    // Welcome / Entry Screen
    GoRoute(
      path: AppRoutes.welcome,
      name: AppRoutes.welcomeName,
      builder: (context, state) => const WelcomeScreen(),
    ),

    // Main 5-Tab Navigation Root
    GoRoute(
      path: AppRoutes.mainScaffold,
      name: AppRoutes.mainScaffoldName,
      builder: (context, state) => const MainScaffold(),
    ),

    // Player Dashboard maps directly into the 5-Tab MainScaffold
    GoRoute(
      path: AppRoutes.playerDashboard,
      name: AppRoutes.playerDashboardName,
      builder: (context, state) => const MainScaffold(initialIndex: 0),
    ),
    GoRoute(
      path: AppRoutes.tournaments,
      name: AppRoutes.tournamentsName,
      builder: (context, state) => const MainScaffold(initialIndex: 1),
    ),
    GoRoute(
      path: AppRoutes.leaderboard,
      name: AppRoutes.leaderboardName,
      builder: (context, state) => const MainScaffold(initialIndex: 2),
    ),
    GoRoute(
      path: AppRoutes.friends,
      name: AppRoutes.friendsName,
      builder: (context, state) => const MainScaffold(initialIndex: 3),
    ),
    GoRoute(
      path: AppRoutes.playerProfile,
      name: AppRoutes.playerProfileName,
      builder: (context, state) => const MainScaffold(initialIndex: 4),
    ),

    // Game Details Screen
    GoRoute(
      path: AppRoutes.gameDetails,
      name: AppRoutes.gameDetailsName,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return GameDetailsScreen(
          gameId: extra['gameId'] ?? 'freefire',
          gameName: extra['gameName'] ?? 'Free Fire',
        );
      },
    ),

    // Tournaments Subscreens
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
      path: AppRoutes.notifications,
      name: AppRoutes.notificationsName,
      builder: (context, state) => const NotificationsScreen(),
    ),

    // Player Auth Flow
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

    // Policies
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
