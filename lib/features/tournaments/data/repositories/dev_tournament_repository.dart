import 'dart:async';
import '../../domain/models/tournament.dart';
import '../../domain/models/tournament_registration.dart';
import '../../domain/repositories/tournament_repository.dart';

/// Seeded, in-memory tournament repository for automated testing and offline development sandbox.
class DevTournamentRepository implements ITournamentRepository {
  final List<Tournament> _tournaments = [];
  final Map<String, List<TournamentRegistration>> _registrationsByUser = {};
  final _tournamentStreamController = StreamController<List<Tournament>>.broadcast();

  DevTournamentRepository() {
    _seedDefaultTournaments();
  }

  void _seedDefaultTournaments() {
    final now = DateTime.now();

    _tournaments.addAll([
      Tournament(
        id: 'tz_tourney_bgmi_scrims_01',
        title: 'BGMI Pro Invitational Scrims - Tier 1',
        description:
            'Join the elite BGMI lobby! 4 custom matches across Erangel and Miramar. Real-time slot confirmation and competitive point table scoring.',
        gameId: 'bgmi',
        gameName: 'Battlegrounds Mobile India (BGMI)',
        organizerUid: 'org_host_01',
        organizerDisplayName: 'Zone Esports India',
        status: TournamentStatus.registrationOpen,
        entryType: EntryType.free,
        entryFee: 0.0,
        prizeDescription: 'Rs. 25,000 Glory Pool (Community Scrims)',
        maxParticipants: 25, // 25 squads
        registeredCount: 18,
        registrationOpensAt: now.subtract(const Duration(days: 2)),
        registrationClosesAt: now.add(const Duration(days: 1, hours: 6)),
        startsAt: now.add(const Duration(days: 1, hours: 8)),
        rules: 'Emulators strictly banned. iPad view / third-party configs strictly prohibited. M416 + DP28 allowed.',
        eligibility: 'Level 40+ BGMI account. Platinum V or higher in Squad TPP.',
        matchFormat: '4 Matches (Erangel, Miramar, Erangel, Sanhok)',
        isFeatured: true,
      ),
      Tournament(
        id: 'tz_tourney_freefire_clash_02',
        title: 'Free Fire MAX - Clash Squad Championship',
        description:
            'High-voltage 4v4 Clash Squad tournament. Single elimination bracket. Prove your squad dominance in Bermuda.',
        gameId: 'freefire',
        gameName: 'Free Fire MAX',
        organizerUid: 'org_host_02',
        organizerDisplayName: 'Garena Arena Central',
        status: TournamentStatus.registrationOpen,
        entryType: EntryType.free,
        entryFee: 0.0,
        prizeDescription: '5,000 Diamonds & Exclusive In-Game Badges',
        maxParticipants: 32,
        registeredCount: 12,
        registrationOpensAt: now.subtract(const Duration(days: 1)),
        registrationClosesAt: now.add(const Duration(days: 2)),
        startsAt: now.add(const Duration(days: 2, hours: 4)),
        rules: 'Standard Clash Squad competitive preset. Character skills allowed. Gun properties off.',
        eligibility: 'Heroic rank in CS Ranked Season.',
        matchFormat: 'Best of 3 Maps (Bermuda, Kalahari, Purgatory)',
        isFeatured: true,
      ),
      Tournament(
        id: 'tz_tourney_codm_showdown_03',
        title: 'CODM Hardpoint & Search and Destroy Cup',
        description:
            'Official 5v5 competitive format with weapon bans. Standings determine qualification for Major Series.',
        gameId: 'codm',
        gameName: 'Call of Duty: Mobile (CODM)',
        organizerUid: 'org_host_01',
        organizerDisplayName: 'Zone Esports India',
        status: TournamentStatus.registrationOpen,
        entryType: EntryType.free,
        entryFee: 0.0,
        prizeDescription: '10,000 CP + Merchandise Pack',
        maxParticipants: 16,
        registeredCount: 16, // FULL TOURNAMENT
        registrationOpensAt: now.subtract(const Duration(days: 3)),
        registrationClosesAt: now.add(const Duration(hours: 12)),
        startsAt: now.add(const Duration(days: 1)),
        rules: 'CODM World Championship Ruleset. Selected scorestreaks and lethal equipment restricted.',
        eligibility: 'Master Tier or above.',
        matchFormat: '5v5 Hardpoint & SnD',
        isFeatured: false,
      ),
      Tournament(
        id: 'tz_tourney_valorant_masters_04',
        title: 'Valorant Community Spike Rush Cup',
        description:
            'Quick-fire community showdown. High tempo 5v5 Spike Rush matches for weekend warriors.',
        gameId: 'valorant',
        gameName: 'Valorant',
        organizerUid: 'org_host_03',
        organizerDisplayName: 'Apex Gaming League',
        status: TournamentStatus.upcoming,
        entryType: EntryType.free,
        entryFee: 0.0,
        prizeDescription: 'Radiant Points & TourneyZone Trophy',
        maxParticipants: 16,
        registeredCount: 0,
        registrationOpensAt: now.add(const Duration(days: 1)),
        registrationClosesAt: now.add(const Duration(days: 4)),
        startsAt: now.add(const Duration(days: 5)),
        rules: 'Spike Rush standard mode. Random loadouts every round.',
        eligibility: 'Open to all Indian subcontinent servers (Mumbai).',
        matchFormat: 'Single Elimination BO1, Finals BO3',
        isFeatured: false,
      ),
      Tournament(
        id: 'tz_tourney_bgmi_paid_preview_05',
        title: 'BGMI Mega Prize Pool Scrims [PREVIEW]',
        description:
            'Upcoming cash prize pool tournament series. Paid booking is currently inactive during Phase 3 compliance.',
        gameId: 'bgmi',
        gameName: 'Battlegrounds Mobile India (BGMI)',
        organizerUid: 'org_host_01',
        organizerDisplayName: 'Zone Esports India',
        status: TournamentStatus.upcoming,
        entryType: EntryType.paid,
        entryFee: 150.0,
        prizeDescription: 'Rs. 1,00,000 Guaranteed Prize Pool',
        maxParticipants: 50,
        registeredCount: 0,
        registrationOpensAt: now.add(const Duration(days: 7)),
        registrationClosesAt: now.add(const Duration(days: 10)),
        startsAt: now.add(const Duration(days: 11)),
        rules: 'Paid tournaments subject to national esports regulatory approvals.',
        eligibility: 'Ages 18+. KYC required when active.',
        matchFormat: 'Squad 6 Matches Finals',
        isFeatured: false,
      ),
    ]);
  }

  @override
  Future<List<Tournament>> fetchFeaturedTournaments() async {
    return _tournaments.where((t) => t.isFeatured).toList();
  }

  @override
  Future<List<Tournament>> fetchUpcomingTournaments({String? gameId, int limit = 20}) async {
    var list = _tournaments.where((t) {
      if (t.status == TournamentStatus.draft || t.status == TournamentStatus.cancelled) {
        return false;
      }
      if (gameId != null && gameId.isNotEmpty && gameId != 'all') {
        return t.gameId == gameId;
      }
      return true;
    }).toList();

    list.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return list.take(limit).toList();
  }

  @override
  Future<List<Tournament>> fetchOpenTournaments({String? gameId, int limit = 20}) async {
    return _tournaments.where((t) {
      if (!t.isRegistrationOpen) return false;
      if (gameId != null && gameId.isNotEmpty && gameId != 'all') {
        return t.gameId == gameId;
      }
      return true;
    }).take(limit).toList();
  }

  @override
  Future<List<Tournament>> searchTournaments({
    String query = '',
    String? gameId,
    TournamentStatus? status,
    EntryType? entryType,
    int limit = 30,
  }) async {
    final cleanQuery = query.trim().toLowerCase();

    var results = _tournaments.where((t) {
      if (cleanQuery.isNotEmpty) {
        final matchesTitle = t.title.toLowerCase().contains(cleanQuery);
        final matchesGame = t.gameName.toLowerCase().contains(cleanQuery);
        final matchesDesc = t.description.toLowerCase().contains(cleanQuery);
        if (!matchesTitle && !matchesGame && !matchesDesc) return false;
      }
      if (gameId != null && gameId.isNotEmpty && gameId != 'all') {
        if (t.gameId != gameId) return false;
      }
      if (status != null && t.status != status) {
        return false;
      }
      if (entryType != null && t.entryType != entryType) {
        return false;
      }
      return true;
    }).toList();

    results.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return results.take(limit).toList();
  }

  @override
  Future<Tournament?> fetchTournamentById(String tournamentId) async {
    try {
      return _tournaments.firstWhere((t) => t.id == tournamentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Tournament?> watchTournament(String tournamentId) {
    return _tournamentStreamController.stream.map((list) {
      try {
        return list.firstWhere((t) => t.id == tournamentId);
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<RegistrationResult> registerForFreeTournament({
    required String tournamentId,
    required String gameUid,
    String currentUserId = 'mock_player_uid',
    bool isUserSuspended = false,
  }) async {
    if (isUserSuspended) {
      return RegistrationResult.failure(
        message: 'Account suspended: Suspended players cannot register for tournaments.',
        isSuspended: true,
      );
    }

    final index = _tournaments.indexWhere((t) => t.id == tournamentId);
    if (index == -1) {
      return RegistrationResult.failure(message: 'Tournament not found.');
    }

    final tournament = _tournaments[index];

    // Check paid restriction
    if (tournament.isPaid) {
      return RegistrationResult.failure(
        message: 'Paid tournament booking is currently disabled. Coming soon in future phases.',
      );
    }

    // Check if open
    if (tournament.status != TournamentStatus.registrationOpen) {
      return RegistrationResult.failure(
        message: 'Registration is not open for this tournament (Status: ${tournament.status.label}).',
      );
    }

    // Check deadline
    if (DateTime.now().isAfter(tournament.registrationClosesAt)) {
      return RegistrationResult.failure(
        message: 'Registration deadline has passed.',
        isDeadlinePassed: true,
      );
    }

    // Check capacity
    if (tournament.registeredCount >= tournament.maxParticipants) {
      return RegistrationResult.failure(
        message: 'Tournament lobby is full. No slots remaining.',
        isFull: true,
      );
    }

    // Check duplicate
    final userRegs = _registrationsByUser[currentUserId] ?? [];
    if (userRegs.any((r) => r.tournamentId == tournamentId && r.status == RegistrationStatus.confirmed)) {
      return RegistrationResult.failure(
        message: 'You are already registered for this tournament.',
        isDuplicate: true,
      );
    }

    // Atomic increment
    final newCount = tournament.registeredCount + 1;
    final updatedTournament = tournament.copyWith(
      registeredCount: newCount,
      status: newCount >= tournament.maxParticipants ? TournamentStatus.full : tournament.status,
    );
    _tournaments[index] = updatedTournament;
    _tournamentStreamController.add(_tournaments);

    final regId = 'REG-${DateTime.now().millisecondsSinceEpoch}';
    final registration = TournamentRegistration(
      id: regId,
      tournamentId: tournament.id,
      uid: currentUserId,
      tournamentTitle: tournament.title,
      gameId: tournament.gameId,
      gameName: tournament.gameName,
      gameUid: gameUid,
      status: RegistrationStatus.confirmed,
      registeredAt: DateTime.now(),
      tournamentStartsAt: tournament.startsAt,
      bannerUrl: tournament.bannerUrl,
    );

    _registrationsByUser.putIfAbsent(currentUserId, () => []).add(registration);

    return RegistrationResult.success(
      registrationId: regId,
      message: 'Spot reserved! Your registration has been confirmed.',
    );
  }

  @override
  Future<List<TournamentRegistration>> fetchPlayerRegistrations({required String uid}) async {
    return _registrationsByUser[uid] ?? [];
  }

  @override
  Stream<List<TournamentRegistration>> watchPlayerRegistrations({required String uid}) {
    return Stream.value(_registrationsByUser[uid] ?? []);
  }

  @override
  Future<bool> isPlayerRegistered({required String tournamentId, required String uid}) async {
    final list = _registrationsByUser[uid] ?? [];
    return list.any((r) => r.tournamentId == tournamentId && r.status == RegistrationStatus.confirmed);
  }
}
