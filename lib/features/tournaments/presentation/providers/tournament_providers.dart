import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_tournament_repository.dart';
import '../../domain/models/room_credentials.dart';
import '../../domain/models/tournament.dart';
import '../../domain/models/tournament_registration.dart';
import '../../domain/repositories/tournament_repository.dart';

/// Centralized provider for tournament data access.
final tournamentRepositoryProvider = Provider<ITournamentRepository>((ref) {
  return FirebaseTournamentRepository();
});

/// Controller for currently selected game filter on the player dashboard ('all' or gameId).
class SelectedDashboardGameNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void select(String gameId) => state = gameId;
}

/// Currently selected game filter on the player dashboard ('all' or gameId).
final selectedDashboardGameProvider =
    NotifierProvider<SelectedDashboardGameNotifier, String>(SelectedDashboardGameNotifier.new);

/// Featured tournaments for the top hero banner carousel.
final featuredTournamentsProvider = FutureProvider<List<Tournament>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.fetchFeaturedTournaments();
});

/// All discoverable tournaments.
final allTournamentsProvider = FutureProvider<List<Tournament>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.searchTournaments(limit: 50);
});

/// Tournaments with registration actively open.
final openTournamentsProvider = FutureProvider.family<List<Tournament>, String?>((ref, gameId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.fetchOpenTournaments(gameId: gameId);
});

/// Upcoming tournaments sorted chronologically.
final upcomingTournamentsProvider = FutureProvider.family<List<Tournament>, String?>((ref, gameId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.fetchUpcomingTournaments(gameId: gameId);
});

/// Live stream provider for a single tournament's details and real-time slot counter.
final tournamentDetailsStreamProvider = StreamProvider.family<Tournament?, String>((ref, id) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.watchTournament(id);
});

/// Live stream provider for an authenticated player's tournament registrations.
final playerRegistrationsStreamProvider =
    StreamProvider.family<List<TournamentRegistration>, String>((ref, uid) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.watchPlayerRegistrations(uid: uid);
});

/// Checks if a player has already confirmed a registration for a tournament.
final isTournamentRegisteredProvider =
    FutureProvider.family<bool, ({String tournamentId, String uid})>((ref, params) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.isPlayerRegistered(
    tournamentId: params.tournamentId,
    uid: params.uid,
  );
});

/// Fetches the authenticated player's specific registration object for a tournament.
final playerRegistrationForTournamentProvider =
    FutureProvider.family<TournamentRegistration?, ({String tournamentId, String uid})>(
        (ref, params) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.fetchPlayerRegistrationForTournament(
    tournamentId: params.tournamentId,
    uid: params.uid,
  );
});

/// Live stream provider for room credentials of a tournament.
final tournamentRoomCredentialsStreamProvider =
    StreamProvider.family<RoomCredentials?, String>((ref, id) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.watchRoomCredentials(id);
});
