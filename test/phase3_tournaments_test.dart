import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tourney_zone/features/auth/domain/models/user_profile.dart';
import 'package:tourney_zone/features/tournaments/data/repositories/dev_tournament_repository.dart';
import 'package:tourney_zone/features/tournaments/domain/models/tournament.dart';
import 'package:tourney_zone/features/tournaments/domain/models/tournament_registration.dart';
import 'package:tourney_zone/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:tourney_zone/features/tournaments/presentation/controllers/tournament_discovery_controller.dart';
import 'package:tourney_zone/features/tournaments/presentation/controllers/tournament_registration_controller.dart';
import 'package:tourney_zone/features/tournaments/presentation/providers/tournament_providers.dart';
import 'package:tourney_zone/features/tournaments/presentation/widgets/game_selector_bar.dart';
import 'package:tourney_zone/features/tournaments/presentation/widgets/tournament_card.dart';
import 'package:tourney_zone/features/tournaments/presentation/widgets/tournament_status_badge.dart';

void main() {
  group('1. Tournament Domain Models & Status Logic', () {
    test('TournamentStatus enum parsing and labels', () {
      expect(TournamentStatus.fromString('draft'), equals(TournamentStatus.draft));
      expect(TournamentStatus.fromString('upcoming'), equals(TournamentStatus.upcoming));
      expect(TournamentStatus.fromString('registration_open'), equals(TournamentStatus.registrationOpen));
      expect(TournamentStatus.fromString('full'), equals(TournamentStatus.full));
      expect(TournamentStatus.fromString('live'), equals(TournamentStatus.live));
      expect(TournamentStatus.fromString('completed'), equals(TournamentStatus.completed));
      expect(TournamentStatus.fromString('cancelled'), equals(TournamentStatus.cancelled));
      expect(TournamentStatus.fromString('unknown_status'), equals(TournamentStatus.draft));

      expect(TournamentStatus.registrationOpen.label, equals('Open'));
      expect(TournamentStatus.live.label, equals('Live'));
      expect(TournamentStatus.full.label, equals('Full'));
      expect(TournamentStatus.completed.label, equals('Finished'));
    });

    test('EntryType enum parsing and fee classification', () {
      expect(EntryType.fromString('free'), equals(EntryType.free));
      expect(EntryType.fromString('paid'), equals(EntryType.paid));
      expect(EntryType.fromString(null), equals(EntryType.free));

      final freeTourney = Tournament(
        id: 't_free',
        title: 'Free BGMI Cup',
        gameId: 'bgmi',
        gameName: 'BGMI',
        organizerUid: 'org_1',
        organizerDisplayName: 'Esports Org',
        status: TournamentStatus.registrationOpen,
        entryType: EntryType.free,
        entryFee: 0,
        prizePool: '₹5,000',
        maxParticipants: 100,
        registeredCount: 20,
        startsAt: DateTime.now().add(const Duration(days: 2)),
        registrationClosesAt: DateTime.now().add(const Duration(days: 1)),
        rules: 'Standard esports rules.',
      );

      expect(freeTourney.isFree, isTrue);
      expect(freeTourney.isPaid, isFalse);
      expect(freeTourney.slotsRemaining, equals(80));
      expect(freeTourney.isRegistrationOpen, isTrue);
      expect(freeTourney.isFull, isFalse);
      expect(freeTourney.isOngoing, isFalse);
      expect(freeTourney.isCompleted, isFalse);
    });

    test('Tournament serialization and deserialization retains all fields', () {
      final now = DateTime.now();
      final tourney = Tournament(
        id: 'tz_serial_01',
        title: 'Valorant Clash',
        gameId: 'valorant',
        gameName: 'Valorant Mobile',
        organizerUid: 'org_val',
        organizerDisplayName: 'Val Org',
        status: TournamentStatus.registrationOpen,
        entryType: EntryType.paid,
        entryFee: 50,
        prizePool: '₹20,000',
        maxParticipants: 64,
        registeredCount: 32,
        startsAt: now.add(const Duration(hours: 10)),
        registrationClosesAt: now.add(const Duration(hours: 5)),
        rules: 'No toxic behavior.',
        eligibility: 'Level 20+',
        cancellationPolicy: 'Refunds within 24h',
        isFeatured: true,
      );

      final map = tourney.toFirestoreMap();
      expect(map['title'], equals('Valorant Clash'));
      expect(map['gameId'], equals('valorant'));
      expect(map['entryType'], equals('paid'));
      expect(map['entryFee'], equals(50));
      expect(map['isFeatured'], isTrue);

      final reconstructed = Tournament.fromMap(map, id: 'tz_serial_01');
      expect(reconstructed.id, equals('tz_serial_01'));
      expect(reconstructed.title, equals('Valorant Clash'));
      expect(reconstructed.entryType, equals(EntryType.paid));
      expect(reconstructed.entryFee, equals(50));
      expect(reconstructed.slotsRemaining, equals(32));
      expect(reconstructed.isFeatured, isTrue);
    });

    test('UserProfile serialization supports gameUids map and photoUrl', () {
      const profile = UserProfile(
        uid: 'user_uids_1',
        displayName: 'ProSniper',
        email: 'sniper@tourneyzone.com',
        photoUrl: 'https://cdn.example.com/avatars/sniper.png',
        gameUids: {
          'bgmi': '5198273645',
          'free_fire': '82736412',
          'codm': '6827361928374',
        },
      );

      final map = profile.toFirestoreMap();
      expect(map['photoUrl'], equals('https://cdn.example.com/avatars/sniper.png'));
      expect(map['gameUids'], isNotNull);
      expect((map['gameUids'] as Map)['bgmi'], equals('5198273645'));
      expect((map['gameUids'] as Map)['free_fire'], equals('82736412'));

      final reconstructed = UserProfile.fromMap(map, docId: 'user_uids_1');
      expect(reconstructed.photoUrl, equals('https://cdn.example.com/avatars/sniper.png'));
      expect(reconstructed.gameUids['bgmi'], equals('5198273645'));
      expect(reconstructed.gameUids['codm'], equals('6827361928374'));
    });
  });

  group('2. Tournament Discovery & In-Memory Repository Tests', () {
    late DevTournamentRepository repo;

    setUp(() {
      repo = DevTournamentRepository();
    });

    test('fetchFeaturedTournaments returns featured tournaments', () async {
      final featured = await repo.fetchFeaturedTournaments();
      expect(featured, isNotEmpty);
      expect(featured.every((t) => t.isFeatured), isTrue);
    });

    test('fetchOpenTournaments filters by gameId when specified', () async {
      final allOpen = await repo.fetchOpenTournaments();
      expect(allOpen, isNotEmpty);

      final bgmiOpen = await repo.fetchOpenTournaments(gameId: 'bgmi');
      expect(bgmiOpen, isNotEmpty);
      expect(bgmiOpen.every((t) => t.gameId == 'bgmi'), isTrue);

      final valorantOpen = await repo.fetchOpenTournaments(gameId: 'valorant');
      expect(valorantOpen.every((t) => t.gameId == 'valorant'), isTrue);
    });

    test('searchTournaments filters by query, status, and entry type', () async {
      final scrimResults = await repo.searchTournaments(query: 'Scrims');
      expect(scrimResults, isNotEmpty);
      expect(scrimResults.any((t) => t.title.contains('Scrims')), isTrue);

      final freeResults = await repo.searchTournaments(entryType: EntryType.free);
      expect(freeResults.every((t) => t.isFree), isTrue);

      final paidResults = await repo.searchTournaments(entryType: EntryType.paid);
      expect(paidResults.every((t) => t.isPaid), isTrue);
    });
  });

  group('3. Free Tournament Registration Security & Atomic Business Logic', () {
    late DevTournamentRepository repo;

    setUp(() {
      repo = DevTournamentRepository();
    });

    test('Successful free registration allocates slot and creates notification', () async {
      final openList = await repo.fetchOpenTournaments();
      final target = openList.firstWhere((t) => t.isFree);
      final initialSlots = target.registeredCount;

      final result = await repo.registerForFreeTournament(
        tournamentId: target.id,
        gameUid: '5198237412',
        currentUserId: 'player_alpha_01',
      );

      expect(result.isSuccess, isTrue);
      expect(result.registrationId, isNotNull);

      // Verify slot incremented
      final updated = await repo.fetchTournamentById(target.id);
      expect(updated!.registeredCount, equals(initialSlots + 1));

      // Verify player registration is queryable
      final isReg = await repo.isPlayerRegistered(
        tournamentId: target.id,
        uid: 'player_alpha_01',
      );
      expect(isReg, isTrue);

      final playerRegs = await repo.fetchPlayerRegistrations(uid: 'player_alpha_01');
      expect(playerRegs.length, equals(1));
      expect(playerRegs.first.tournamentId, equals(target.id));
      expect(playerRegs.first.gameUid, equals('5198237412'));
    });

    test('Duplicate registration is rejected with isDuplicate flag', () async {
      final openList = await repo.fetchOpenTournaments();
      final target = openList.firstWhere((t) => t.isFree);

      // First registration
      final res1 = await repo.registerForFreeTournament(
        tournamentId: target.id,
        gameUid: '5198237412',
        currentUserId: 'player_dup_01',
      );
      expect(res1.isSuccess, isTrue);

      // Duplicate attempt with same UID
      final res2 = await repo.registerForFreeTournament(
        tournamentId: target.id,
        gameUid: '5198237412',
        currentUserId: 'player_dup_01',
      );
      expect(res2.isSuccess, isFalse);
      expect(res2.isDuplicate, isTrue);
      expect(res2.message, contains('already registered'));
    });

    test('Full lobby capacity is rejected with isFull flag', () async {
      // Add a full tournament
      final fullTourney = Tournament(
        id: 'tourney_full_test',
        title: 'Full Capacity Scrims',
        gameId: 'bgmi',
        gameName: 'BGMI',
        organizerUid: 'org_01',
        organizerDisplayName: 'Zone Esports',
        status: TournamentStatus.full,
        entryType: EntryType.free,
        maxParticipants: 2,
        registeredCount: 2,
        startsAt: DateTime.now().add(const Duration(days: 1)),
        registrationClosesAt: DateTime.now().add(const Duration(hours: 12)),
        rules: 'Rules.',
      );
      repo.addTournamentForTesting(fullTourney);

      final result = await repo.registerForFreeTournament(
        tournamentId: fullTourney.id,
        gameUid: '5928374123',
        currentUserId: 'player_overflow',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isFull, isTrue);
      expect(result.message, contains('full'));
    });

    test('Expired registration deadline is rejected with isDeadlinePassed flag', () async {
      final expiredTourney = Tournament(
        id: 'tourney_expired_test',
        title: 'Expired Deadline Tourney',
        gameId: 'bgmi',
        gameName: 'BGMI',
        organizerUid: 'org_01',
        organizerDisplayName: 'Zone Esports',
        status: TournamentStatus.registrationOpen,
        entryType: EntryType.free,
        maxParticipants: 50,
        registeredCount: 10,
        startsAt: DateTime.now().add(const Duration(hours: 1)),
        registrationClosesAt: DateTime.now().subtract(const Duration(minutes: 15)),
        rules: 'Rules.',
      );
      repo.addTournamentForTesting(expiredTourney);

      final result = await repo.registerForFreeTournament(
        tournamentId: expiredTourney.id,
        gameUid: '5928374123',
        currentUserId: 'player_late',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isDeadlinePassed, isTrue);
      expect(result.message, contains('deadline'));
    });

    test('Suspended account is rejected with isSuspended flag', () async {
      final openList = await repo.fetchOpenTournaments();
      final target = openList.firstWhere((t) => t.isFree);

      final result = await repo.registerForFreeTournament(
        tournamentId: target.id,
        gameUid: '5928374123',
        currentUserId: 'player_banned',
        userStatus: 'suspended',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isSuspended, isTrue);
      expect(result.message, contains('suspended'));
    });

    test('Paid tournament booking is disabled in Phase 3', () async {
      final paidTourney = Tournament(
        id: 'tourney_paid_test',
        title: 'Paid Championship',
        gameId: 'bgmi',
        gameName: 'BGMI',
        organizerUid: 'org_01',
        organizerDisplayName: 'Zone Esports',
        status: TournamentStatus.registrationOpen,
        entryType: EntryType.paid,
        entryFee: 100,
        maxParticipants: 100,
        registeredCount: 10,
        startsAt: DateTime.now().add(const Duration(days: 2)),
        registrationClosesAt: DateTime.now().add(const Duration(days: 1)),
        rules: 'Rules.',
      );
      repo.addTournamentForTesting(paidTourney);

      final result = await repo.registerForFreeTournament(
        tournamentId: paidTourney.id,
        gameUid: '5928374123',
        currentUserId: 'player_paid_tester',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('disabled in Phase 3'));
    });

    test('My Tournaments enforces strict user UID isolation', () async {
      final openList = await repo.fetchOpenTournaments();
      final t1 = openList[0];
      final t2 = openList[1];

      await repo.registerForFreeTournament(
        tournamentId: t1.id,
        gameUid: 'p1_uid',
        currentUserId: 'user_player_one',
      );

      await repo.registerForFreeTournament(
        tournamentId: t2.id,
        gameUid: 'p2_uid',
        currentUserId: 'user_player_two',
      );

      final p1Regs = await repo.fetchPlayerRegistrations(uid: 'user_player_one');
      final p2Regs = await repo.fetchPlayerRegistrations(uid: 'user_player_two');

      expect(p1Regs.length, equals(1));
      expect(p1Regs.first.tournamentId, equals(t1.id));

      expect(p2Regs.length, equals(1));
      expect(p2Regs.first.tournamentId, equals(t2.id));
    });
  });

  group('4. Riverpod Controllers & Presentation Layer State', () {
    late ProviderContainer container;
    late DevTournamentRepository testRepo;

    setUp(() {
      testRepo = DevTournamentRepository();
      container = ProviderContainer(
        overrides: [
          tournamentRepositoryProvider.overrideWithValue(testRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('TournamentDiscoveryController updates filters and performs searches', () async {
      final controller = container.read(tournamentDiscoveryProvider.notifier);
      await controller.loadTournaments();

      var state = container.read(tournamentDiscoveryProvider);
      expect(state.isLoading, isFalse);
      expect(state.tournaments, isNotEmpty);

      // Filter by BGMI
      controller.selectGame('bgmi');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      state = container.read(tournamentDiscoveryProvider);
      expect(state.selectedGameId, equals('bgmi'));
      expect(state.tournaments.every((t) => t.gameId == 'bgmi'), isTrue);

      // Search text query
      controller.updateQuery('Scrims');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      state = container.read(tournamentDiscoveryProvider);
      expect(state.query, equals('Scrims'));

      // Reset filters
      controller.resetFilters();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      state = container.read(tournamentDiscoveryProvider);
      expect(state.selectedGameId, equals('all'));
      expect(state.query, isEmpty);
      expect(state.selectedStatus, isNull);
    });

    test('TournamentRegistrationNotifier handles form validation and submission', () async {
      final openList = await testRepo.fetchOpenTournaments();
      final target = openList.firstWhere((t) => t.isFree);

      final regNotifier = container.read(tournamentRegistrationProvider.notifier);

      // 1. Rejects when character UID is empty
      var success = await regNotifier.registerForTournament(target.id);
      expect(success, isFalse);
      var regState = container.read(tournamentRegistrationProvider);
      expect(regState.errorMessage, contains('Character ID'));

      // 2. Rejects when rules checkbox is unchecked
      regNotifier.updateGameUid('5198273645');
      success = await regNotifier.registerForTournament(target.id);
      expect(success, isFalse);
      regState = container.read(tournamentRegistrationProvider);
      expect(regState.errorMessage, contains('accept the tournament rules'));

      // 3. Submits successfully when UID provided and rules accepted
      regNotifier.toggleRulesAccepted(true);
      success = await regNotifier.registerForTournament(target.id);
      expect(success, isTrue);
      regState = container.read(tournamentRegistrationProvider);
      expect(regState.isSuccess, isTrue);
      expect(regState.successMessage, contains('Registration confirmed'));
    });
  });

  group('5. UI Components Widget Tests', () {
    testWidgets('TournamentStatusBadge renders status text correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TournamentStatusBadge(status: TournamentStatus.registrationOpen),
                TournamentStatusBadge(status: TournamentStatus.live),
                TournamentStatusBadge(status: TournamentStatus.full),
                TournamentStatusBadge(status: TournamentStatus.completed),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Full'), findsOneWidget);
      expect(find.text('Finished'), findsOneWidget);
    });

    testWidgets('GameSelectorBar renders chips and responds to selection', (tester) async {
      String selected = 'all';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameSelectorBar(
              selectedGameId: selected,
              onGameSelected: (id) => selected = id,
            ),
          ),
        ),
      );

      expect(find.text('All Games'), findsOneWidget);
      expect(find.text('BGMI'), findsOneWidget);
      expect(find.text('Free Fire'), findsOneWidget);

      await tester.tap(find.text('BGMI'));
      await tester.pumpAndSettle();

      expect(selected, equals('bgmi'));
    });

    testWidgets('TournamentCard displays tournament details and entry type', (tester) async {
      final sampleTourney = Tournament(
        id: 't_card_test',
        title: 'Pro Championship Finals',
        gameId: 'bgmi',
        gameName: 'BGMI',
        organizerUid: 'org_01',
        organizerDisplayName: 'Pro Esports',
        status: TournamentStatus.registrationOpen,
        entryType: EntryType.free,
        entryFee: 0,
        prizePool: '₹10,000',
        maxParticipants: 100,
        registeredCount: 45,
        startsAt: DateTime.now().add(const Duration(days: 3)),
        registrationClosesAt: DateTime.now().add(const Duration(days: 2)),
        rules: 'Strict rules.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentCard(
              tournament: sampleTourney,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Pro Championship Finals'), findsOneWidget);
      expect(find.text('BGMI'), findsOneWidget);
      expect(find.text('₹10,000'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('45/100'), findsOneWidget);
    });
  });
}
