/// Constants for all route names and paths in TourneyZone / Karta Organize.
class AppRoutes {
  AppRoutes._();

  // Route paths
  static const String welcome = '/';
  static const String playerLogin = '/player/login';
  static const String playerRegister = '/player/register';
  static const String forgotPassword = '/forgot-password';
  static const String organizerLogin = '/organizer/login';
  static const String organizerApply = '/organizer/apply';
  static const String organizerReview = '/organizer/apply/review';
  static const String organizerStatus = '/organizer/status';
  static const String playerTerms = '/policy/player-terms';
  static const String organizerTerms = '/policy/organizer-terms';
  static const String privacyPolicy = '/policy/privacy';

  // Player Navigation & Features
  static const String mainScaffold = '/main';
  static const String playerDashboard = '/player/dashboard';
  static const String tournaments = '/tournaments';
  static const String tournamentDetails = '/tournaments/:id';
  static const String tournamentRegister = '/tournaments/:id/register';
  static const String myTournaments = '/player/my-tournaments';
  static const String playerProfile = '/player/profile';
  static const String notifications = '/notifications';
  static const String leaderboard = '/leaderboard';
  static const String friends = '/friends';
  static const String gameDetails = '/game-details';

  // Route names (for pushNamed/goNamed)
  static const String welcomeName = 'welcome';
  static const String playerLoginName = 'player-login';
  static const String playerRegisterName = 'player-register';
  static const String forgotPasswordName = 'forgot-password';
  static const String organizerLoginName = 'organizer-login';
  static const String organizerApplyName = 'organizer-apply';
  static const String organizerReviewName = 'organizer-review';
  static const String organizerStatusName = 'organizer-status';
  static const String playerTermsName = 'player-terms';
  static const String organizerTermsName = 'organizer-terms';
  static const String privacyPolicyName = 'privacy-policy';

  static const String mainScaffoldName = 'main-scaffold';
  static const String playerDashboardName = 'player-dashboard';
  static const String tournamentsName = 'tournaments';
  static const String tournamentDetailsName = 'tournament-details';
  static const String tournamentRegisterName = 'tournament-register';
  static const String myTournamentsName = 'my-tournaments';
  static const String playerProfileName = 'player-profile';
  static const String notificationsName = 'notifications';
  static const String leaderboardName = 'leaderboard';
  static const String friendsName = 'friends';
  static const String gameDetailsName = 'game-details';
}
