import '../models/tournament.dart';
import '../models/tournament_registration.dart';

/// Result object for tournament registration attempts.
class RegistrationResult {
  final bool isSuccess;
  final String? registrationId;
  final String? message;
  final bool isFull;
  final bool isDuplicate;
  final bool isDeadlinePassed;
  final bool isSuspended;

  const RegistrationResult({
    required this.isSuccess,
    this.registrationId,
    this.message,
    this.isFull = false,
    this.isDuplicate = false,
    this.isDeadlinePassed = false,
    this.isSuspended = false,
  });

  factory RegistrationResult.success({
    required String registrationId,
    String message = 'Registration confirmed successfully!',
  }) {
    return RegistrationResult(
      isSuccess: true,
      registrationId: registrationId,
      message: message,
    );
  }

  factory RegistrationResult.failure({
    required String message,
    bool isFull = false,
    bool isDuplicate = false,
    bool isDeadlinePassed = false,
    bool isSuspended = false,
  }) {
    return RegistrationResult(
      isSuccess: false,
      message: message,
      isFull: isFull,
      isDuplicate: isDuplicate,
      isDeadlinePassed: isDeadlinePassed,
      isSuspended: isSuspended,
    );
  }
}

/// Abstract contract for tournament discovery, detail retrieval, and registration operations.
abstract class ITournamentRepository {
  /// Fetches featured tournaments for the player dashboard.
  Future<List<Tournament>> fetchFeaturedTournaments();

  /// Fetches upcoming tournaments optionally filtered by game ID.
  Future<List<Tournament>> fetchUpcomingTournaments({String? gameId, int limit = 20});

  /// Fetches tournaments with registration actively open.
  Future<List<Tournament>> fetchOpenTournaments({String? gameId, int limit = 20});

  /// Discovers tournaments matching search query, game category, status, and entry type.
  Future<List<Tournament>> searchTournaments({
    String query = '',
    String? gameId,
    TournamentStatus? status,
    EntryType? entryType,
    int limit = 30,
  });

  /// Retrieves a specific tournament by ID.
  Future<Tournament?> fetchTournamentById(String tournamentId);

  /// Streams real-time updates for a single tournament (for reactive slot count updates).
  Stream<Tournament?> watchTournament(String tournamentId);

  /// Securely registers the authenticated player for a free tournament.
  /// Enforces atomic slot allocation, deadline verification, and duplicate check.
  Future<RegistrationResult> registerForFreeTournament({
    required String tournamentId,
    required String gameUid,
  });

  /// Fetches all tournament registrations for a specific authenticated player.
  Future<List<TournamentRegistration>> fetchPlayerRegistrations({required String uid});

  /// Streams live registrations for a specific player.
  Stream<List<TournamentRegistration>> watchPlayerRegistrations({required String uid});

  /// Checks if a player is already registered for a specific tournament.
  Future<bool> isPlayerRegistered({required String tournamentId, required String uid});
}
