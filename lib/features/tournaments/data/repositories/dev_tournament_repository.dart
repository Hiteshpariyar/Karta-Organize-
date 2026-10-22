import 'dart:async';
import '../../domain/models/room_credentials.dart';
import '../../domain/models/tournament.dart';
import '../../domain/models/tournament_registration.dart';
import '../../domain/repositories/tournament_repository.dart';

/// Seeded, in-memory tournament repository for automated testing and offline development sandbox.
class DevTournamentRepository implements ITournamentRepository {
  final List<Tournament> _tournaments = [];
  final Map<String, List<TournamentRegistration>> _registrationsByUser = {};
  final Map<String, RoomCredentials> _roomCredentialsByTournament = {};
  final _tournamentStreamController = StreamController<List<Tournament>>.broadcast();

  DevTournamentRepository() {
    _seedDefaultTournaments();
  }

  void addTournamentForTesting(Tournament tournament) {
    _tournaments.removeWhere((t) => t.id == tournament.id);
    _tournaments.add(tournament);
    _tournamentStreamController.add(_tournaments);
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
        organizerDisplayName: 'Hitesh (Admin)',
        organizerTeamName: 'Zone Esports India',
        organizerRating: 4.9,
        organizerReviewCount: 238,
        isOrganizerVerified: true,
        organizerCompletedTournaments: 48,
        status: TournamentStatus.registrationOpen,
        entryType: EntryType.free,
        entryFee: 0.0,
        currency: '₹',
        prizePool: '₹25,000 Glory Pool',
        prizeDescription: 'Rs. 25,000 Glory Pool (Community Scrims)',
        prizeDistribution: {
          '1st Place': '₹12,000 + Champion Trophy',
          '2nd Place': '₹7,000 + Finalist Medal',
          '3rd Place': '₹4,000 + Bronze Medal',
          'MVP Award': '₹2,000',
        },
        perKillReward: 20.0,
        maxParticipants: 25, // 25 squads
        registeredCount: 18,
        registrationOpensAt: now.subtract(const Duration(days: 2)),
        registrationClosesAt: now.add(const Duration(days: 1, hours: 6)),
        startsAt: now.add(const Duration(days: 1, hours: 8)),
        reportingAt: now.add(const Duration(days: 1, hours: 7, minutes: 45)),
        rules:
            '1. Emulators strictly banned.\n2. iPad view / third-party configs strictly prohibited.\n3. M416 + DP28 allowed.\n4. Screen recording mandatory for top 3 squads.',
        eligibility:
            'Level 40+ BGMI account. Platinum V or higher in Squad TPP. All players must have active Discord check-in.',
        matchFormat: '4 Custom Matches (Erangel, Miramar, Erangel, Sanhok)',
        mode: 'Squad TPP',
        mapName: 'Erangel & Miramar',
        teamSize: 4,
        isFeatured: true,
        credentialsReleaseAt: now.add(const Duration(days: 1, hours: 7, minutes: 45)),
        credentialsReleased: false,
      ),
      Tournament(
        id: 'tz_tourney_freefire_clash_02',
        title: 'Free Fire MAX - Clash Squad Championship',
        description:
            'High-voltage 4v4 Clash Squad tournament. Single elimination bracket. Prove your squad dominance in Bermuda.',
        gameId: 'freefire',
        gameName: 'Free Fire MAX',
        organizerUid: 'org_host_02',
        organizerDisplayName: 'Vikram Joshi',
        organizerTeamName: 'Garena Arena Central',
        organizerRating: 4.7,
        organizerReviewCount: 112,
        isOrganizerVerified: true,
        organizerCompletedTournaments: 22,
        status: TournamentStatus.registrationOpen,
        entryType: EntryType.free,
        entryFee: 0.0,
        currency: '₹',
        prizePool: '5,000 Diamonds & Badges',
        prizeDescription: '5,000 Diamonds & Exclusive In-Game Badges',
        prizeDistribution: {
          '1st Place': '3,000 Diamonds + Hall of Fame Badge',
          '2nd Place': '1,500 Diamonds',
          '3rd Place': '500 Diamonds',
        },
        perKillReward: 10.0,
        maxParticipants: 32,
        registeredCount: 12,
        registrationOpensAt: now.subtract(const Duration(days: 1)),
        registrationClosesAt: now.add(const Duration(days: 2)),
        startsAt: now.add(const Duration(days: 2, hours: 4)),
        reportingAt: now.add(const Duration(days: 2, hours: 3, minutes: 45)),
        rules:
            'Standard Clash Squad competitive preset. Character skills allowed. Gun properties turned OFF. Emotes during knockdowns prohibited.',
        eligibility: 'Heroic rank in CS Ranked Season. South Asia regional servers.',
        matchFormat: 'Best of 3 Maps (Bermuda, Kalahari, Purgatory)',
        mode: 'Clash Squad (4v4)',
        mapName: 'Bermuda',
        teamSize: 4,
        isFeatured: true,
        credentialsReleaseAt: now.add(const Duration(days: 2, hours: 3, minutes: 45)),
        credentialsReleased: false,
      ),
      Tournament(
        id: 'tz_tourney_codm_showdown_03',
        title: 'CODM Hardpoint & Search and Destroy Cup',
        description:
            'Official 5v5 competitive format with weapon bans. Standings determine qualification for Major Series.',
        gameId: 'codm',
        gameName: 'Call of Duty: Mobile (CODM)',
        organizerUid: 'org_host_01',
        organizerDisplayName: 'Hitesh (Admin)',
        organizerTeamName: 'Zone Esports India',
        organizerRating: 4.9,
        organizerReviewCount: 238,
        isOrganizerVerified: true,
        organizerCompletedTournaments: 48,
        status: TournamentStatus.registrationOpen,
        entryType: EntryType.free,
        entryFee: 0.0,
        currency: '₹',
        prizePool: '10,000 CP + Merch',
        prizeDescription: '10,000 CP + Merchandise Pack',
        prizeDistribution: {
          '1st Place': '6,000 CP + Official TourneyZone Hoodie',
          '2nd Place': '3,000 CP + TourneyZone Cap',
          '3rd Place': '1,000 CP',
        },
        perKillReward: 15.0,
        maxParticipants: 16,
        registeredCount: 16, // FULL TOURNAMENT
        registrationOpensAt: now.subtract(const Duration(days: 3)),
        registrationClosesAt: now.add(const Duration(hours: 12)),
        startsAt: now.add(const Duration(days: 1)),
        reportingAt: now.add(const Duration(days: 1)).subtract(const Duration(minutes: 15)),
        rules:
            'CODM World Championship Ruleset. Selected scorestreaks and lethal equipment restricted. Device spec: phone only (no tablets).',
        eligibility: 'Master Tier or above.',
        matchFormat: '5v5 Hardpoint & SnD (Summit, Standoff, Raid)',
        mode: 'Hardpoint / SnD',
        mapName: 'Summit, Standoff, Raid',
        teamSize: 5,
        isFeatured: false,
        credentialsReleaseAt: now.subtract(const Duration(minutes: 5)),
        credentialsReleased: true, // Credentials already released for demonstration
      ),
      Tournament(
        id: 'tz_tourney_valorant_masters_04',
        title: 'Valorant Community Spike Rush Cup',
        description:
            'Quick-fire community showdown. High tempo 5v5 Spike Rush matches for weekend warriors.',
        gameId: 'valorant',
        gameName: 'Valorant',
        organizerUid: 'org_host_03',
        organizerDisplayName: 'Sarah Khan',
        organizerTeamName: 'Apex Gaming League',
        organizerRating: 4.6,
        organizerReviewCount: 74,
        isOrganizerVerified: false,
        organizerCompletedTournaments: 14,
        status: TournamentStatus.upcoming,
        entryType: EntryType.free,
        entryFee: 0.0,
        currency: '₹',
        prizePool: 'Radiant Points & Cup',
        prizeDescription: 'Radiant Points & TourneyZone Trophy',
        prizeDistribution: {
          '1st Place': '1,500 VP + Digital Trophy',
          '2nd Place': '750 VP',
        },
        maxParticipants: 16,
        registeredCount: 0,
        registrationOpensAt: now.add(const Duration(days: 1)),
        registrationClosesAt: now.add(const Duration(days: 4)),
        startsAt: now.add(const Duration(days: 5)),
        reportingAt: now.add(const Duration(days: 5)).subtract(const Duration(minutes: 15)),
        rules: 'Spike Rush standard mode. Random loadouts every round.',
        eligibility: 'Open to all Indian subcontinent servers (Mumbai).',
        matchFormat: 'Single Elimination BO1, Finals BO3',
        mode: 'Spike Rush (5v5)',
        mapName: 'Ascent / Bind',
        teamSize: 5,
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
        organizerDisplayName: 'Hitesh (Admin)',
        organizerTeamName: 'Zone Esports India',
        organizerRating: 4.9,
        organizerReviewCount: 238,
        isOrganizerVerified: true,
        organizerCompletedTournaments: 48,
        status: TournamentStatus.upcoming,
        entryType: EntryType.paid,
        entryFee: 150.0,
        currency: '₹',
        prizePool: '₹1,00,000 Guaranteed',
        prizeDescription: 'Rs. 1,00,000 Guaranteed Prize Pool',
        prizeDistribution: {
          '1st Place': '₹50,000',
          '2nd Place': '₹25,000',
          '3rd Place': '₹15,000',
          '4th-5th': '₹5,000 each',
        },
        perKillReward: 50.0,
        maxParticipants: 50,
        registeredCount: 0,
        registrationOpensAt: now.add(const Duration(days: 7)),
        registrationClosesAt: now.add(const Duration(days: 10)),
        startsAt: now.add(const Duration(days: 11)),
        reportingAt: now.add(const Duration(days: 11)).subtract(const Duration(minutes: 30)),
        rules: 'Paid tournaments subject to national esports regulatory approvals.',
        eligibility: 'Ages 18+. KYC verification required when active.',
        matchFormat: 'Squad 6 Matches Finals',
        mode: 'Squad TPP',
        mapName: 'Erangel, Miramar, Sanhok',
        teamSize: 4,
        isFeatured: false,
      ),
    ]);

    // Seed mock room credentials for CODM (which is already released)
    _roomCredentialsByTournament['tz_tourney_codm_showdown_03'] = RoomCredentials(
      tournamentId: 'tz_tourney_codm_showdown_03',
      roomId: '948271',
      roomPassword: 'ZONE@CODM9',
      releasedAt: now.subtract(const Duration(minutes: 5)),
      instructions: 'Join Custom Room #948271 promptly. Lobby locks 3 minutes prior to start.',
      isReleased: true,
    );
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
        final matchesOrg = t.displayOrganizerTeam.toLowerCase().contains(cleanQuery);
        if (!matchesTitle && !matchesGame && !matchesDesc && !matchesOrg) return false;
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
  Stream<Tournament?> watchTournament(String tournamentId) async* {
    yield await fetchTournamentById(tournamentId);
    yield* _tournamentStreamController.stream.map((list) {
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
    String? teamName,
    List<String>? squadMembers,
    String? currentUserId,
    String? userStatus,
    bool isUserSuspended = false,
  }) async {
    final uid = currentUserId ?? 'mock_player_uid';

    if (isUserSuspended || userStatus == 'suspended') {
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
        message: 'Paid tournament booking is currently disabled in Phase 3. Coming soon.',
      );
    }

    // Check if open
    if (tournament.status != TournamentStatus.registrationOpen) {
      return RegistrationResult.failure(
        message:
            'Registration is not open for this tournament (Status: ${tournament.status.label}).',
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
    final userRegs = _registrationsByUser[uid] ?? [];
    if (userRegs.any(
        (r) => r.tournamentId == tournamentId && r.status == RegistrationStatus.confirmed)) {
      return RegistrationResult.failure(
        message: 'You are already registered for this tournament.',
        isDuplicate: true,
      );
    }

    // Atomic slot assignment
    final assignedSlot = tournament.registeredCount + 1;
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
      uid: uid,
      tournamentTitle: tournament.title,
      gameId: tournament.gameId,
      gameName: tournament.gameName,
      gameUid: gameUid,
      assignedSlot: assignedSlot,
      teamName: teamName,
      squadMembers: squadMembers,
      status: RegistrationStatus.confirmed,
      paymentStatus: 'free',
      registeredAt: DateTime.now(),
      appliedAt: DateTime.now(),
      approvedAt: DateTime.now(),
      tournamentStartsAt: tournament.startsAt,
      bannerUrl: tournament.bannerUrl,
    );

    _registrationsByUser.putIfAbsent(uid, () => []).add(registration);

    return RegistrationResult.success(
      registrationId: regId,
      assignedSlot: assignedSlot,
      message: 'Spot reserved! Your registration has been confirmed at Slot #$assignedSlot.',
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
    return list.any(
        (r) => r.tournamentId == tournamentId && r.status == RegistrationStatus.confirmed);
  }

  @override
  Future<TournamentRegistration?> fetchPlayerRegistrationForTournament({
    required String tournamentId,
    required String uid,
  }) async {
    final list = _registrationsByUser[uid] ?? [];
    try {
      return list.firstWhere(
        (r) => r.tournamentId == tournamentId && r.status == RegistrationStatus.confirmed,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RoomCredentials?> fetchRoomCredentials(String tournamentId) async {
    return _roomCredentialsByTournament[tournamentId];
  }

  @override
  Stream<RoomCredentials?> watchRoomCredentials(String tournamentId) {
    return Stream.value(_roomCredentialsByTournament[tournamentId]);
  }
}
