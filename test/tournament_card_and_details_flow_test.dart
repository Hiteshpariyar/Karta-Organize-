import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tourney_zone/core/theme/app_theme.dart';
import 'package:tourney_zone/features/auth/domain/models/user_profile.dart';
import 'package:tourney_zone/features/auth/presentation/providers/auth_providers.dart';
import 'package:tourney_zone/features/tournaments/data/repositories/dev_tournament_repository.dart';
import 'package:tourney_zone/features/tournaments/domain/models/room_credentials.dart';
import 'package:tourney_zone/features/tournaments/domain/models/tournament.dart';
import 'package:tourney_zone/features/tournaments/domain/models/tournament_registration.dart';
import 'package:tourney_zone/features/tournaments/presentation/providers/tournament_providers.dart';
import 'package:tourney_zone/features/tournaments/presentation/screens/tournament_details_screen.dart';
import 'package:tourney_zone/features/tournaments/presentation/widgets/tournament_card.dart';

void main() {
  group('A. Tournament Card Redesign Unit & Widget Tests', () {
    final testTournament = Tournament(
      id: 't_card_redesign_01',
      title: 'BGMI Elite Pro Series - Season 4',
      description: 'Competitive 4-match lobby with official scoring.',
      gameId: 'bgmi',
      gameName: 'Battlegrounds Mobile India (BGMI)',
      organizerUid: 'org_zone_01',
      organizerDisplayName: 'Hitesh (Admin)',
      organizerTeamName: 'Zone Esports India',
      organizerRating: 4.9,
      organizerReviewCount: 142,
      isOrganizerVerified: true,
      organizerCompletedTournaments: 36,
      status: TournamentStatus.registrationOpen,
      entryType: EntryType.free,
      entryFee: 0.0,
      currency: '₹',
      prizePool: '₹25,000 Glory Pool',
      prizeDescription: 'Rs. 25,000 Glory Pool',
      prizeDistribution: {
        '1st Place': '₹12,000',
        '2nd Place': '₹8,000',
        '3rd Place': '₹5,000',
      },
      perKillReward: 25.0,
      maxParticipants: 25,
      registeredCount: 18,
      startsAt: DateTime(2026, 11, 15, 18, 0),
      registrationOpensAt: DateTime(2026, 11, 1, 10, 0),
      registrationClosesAt: DateTime(2026, 11, 15, 16, 0),
      mode: 'Squad TPP',
      mapName: 'Erangel & Miramar',
      teamSize: 4,
    );

    testWidgets('TournamentCard displays all 12 required elements and hides room credentials',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentCard(
                tournament: testTournament,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // 1. Tournament Name
      expect(find.text('BGMI Elite Pro Series - Season 4'), findsOneWidget);

      // 2. Game Name
      expect(find.text('Battlegrounds Mobile India (BGMI)'), findsOneWidget);

      // 3. Status Badge
      expect(find.text('Open'), findsOneWidget);

      // 4. Start Date & Time
      expect(find.textContaining('Nov'), findsOneWidget);

      // 5. Organizer Team Name
      expect(find.text('Zone Esports India'), findsOneWidget);

      // 6. Organizer Rating & Review Count
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text(' (142)'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);

      // 7. Available slots vs total slots
      expect(find.text('7 of 25 slots available'), findsOneWidget);
      expect(find.text('18/25'), findsOneWidget);

      // 8. Progress Indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // 9. Entry Fee (FREE label)
      expect(find.text('FREE'), findsOneWidget);

      // 10. Total Prize Pool
      expect(find.text('₹25,000 Glory Pool'), findsOneWidget);

      // 11. Per-Kill Reward
      expect(find.text('+₹25 / kill'), findsOneWidget);

      // 12. More Details Action
      expect(find.text('More Details'), findsOneWidget);

      // SECURITY CRITICAL: Room credentials MUST NEVER appear on the tournament card
      expect(find.textContaining('Room ID:'), findsNothing);
      expect(find.textContaining('Password:'), findsNothing);
    });

    testWidgets('TournamentCard adapts gracefully in Light Theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentCard(
                tournament: testTournament,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('BGMI Elite Pro Series - Season 4'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('Zone Esports India'), findsOneWidget);
    });
  });

  group('B. Tournament Details Screen & Four Core Sections', () {
    late DevTournamentRepository devRepo;

    setUp(() {
      devRepo = DevTournamentRepository();
    });

    testWidgets('Displays Overview, Rewards, and Organizer sections cleanly',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          tournamentRepositoryProvider.overrideWithValue(devRepo),
          currentUserProfileProvider.overrideWithValue(null), // Unauthenticated
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TournamentDetailsScreen(tournamentId: 'tz_tourney_bgmi_scrims_01'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Section 1: Overview
      expect(find.text('Tournament Overview'), findsOneWidget);
      expect(find.text('BGMI Pro Invitational Scrims - Tier 1'), findsOneWidget);
      expect(find.text('Squad (4 Players)'), findsOneWidget);

      // Section 2: Entry and Rewards
      expect(find.text('Entry Fee & Prize Pool'), findsOneWidget);
      expect(find.text('₹25,000 Glory Pool'), findsOneWidget);
      expect(find.text('Prize Distribution Breakdown'), findsOneWidget);
      expect(find.text('1st Place'), findsOneWidget);
      expect(find.text('₹12,000 + Champion Trophy'), findsOneWidget);

      // Section 3: Organizer Information
      expect(find.text('Organizer Information'), findsOneWidget);
      expect(find.text('Zone Esports India'), findsWidgets);
      expect(find.text('Host: Hitesh (Admin)'), findsOneWidget);
      expect(find.text('48 Tournaments Hosted'), findsOneWidget);

      // Section 4: Room Credentials for Unregistered User (Protected State)
      expect(find.text('Custom Room Credentials'), findsOneWidget);
      expect(find.text('Room Credentials Protected'), findsOneWidget);
      expect(find.textContaining('only to confirmed tournament participants'), findsOneWidget);
      expect(find.text('Sign In to Register'), findsOneWidget);
    });

    testWidgets('Shows Room Credentials copy buttons when user is registered and credentials unlocked',
        (tester) async {
      const testUid = 'verified_player_101';
      final container = ProviderContainer(
        overrides: [
          tournamentRepositoryProvider.overrideWithValue(devRepo),
          currentUserProfileProvider.overrideWithValue(
            const UserProfile(
              uid: testUid,
              displayName: 'Pro Player One',
              email: 'pro@tourneyzone.com',
            ),
          ),
          isTournamentRegisteredProvider((
            tournamentId: 'tz_tourney_codm_showdown_03',
            uid: testUid,
          )).overrideWith((ref) => true),
          playerRegistrationForTournamentProvider((
            tournamentId: 'tz_tourney_codm_showdown_03',
            uid: testUid,
          )).overrideWith((ref) => TournamentRegistration(
                id: 'reg_101',
                tournamentId: 'tz_tourney_codm_showdown_03',
                uid: testUid,
                tournamentTitle: 'CODM Hardpoint & Search and Destroy Cup',
                gameId: 'codm',
                gameName: 'Call of Duty: Mobile (CODM)',
                gameUid: '6748392019485',
                assignedSlot: 4,
                registeredAt: DateTime(2026, 10, 20),
              )),
          tournamentRoomCredentialsStreamProvider('tz_tourney_codm_showdown_03')
              .overrideWith((ref) => Stream.value(
                    RoomCredentials(
                      tournamentId: 'tz_tourney_codm_showdown_03',
                      roomId: '948271',
                      roomPassword: 'ZONE@CODM9',
                      isReleased: true,
                    ),
                  )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TournamentDetailsScreen(tournamentId: 'tz_tourney_codm_showdown_03'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify custom room credentials card is visible with copy actions
      expect(find.text('Custom Room Access Released'), findsOneWidget);
      expect(find.text('948271'), findsOneWidget);
      expect(find.text('ZONE@CODM9'), findsOneWidget);
      expect(find.text('Copy'), findsNWidgets(2));
    });
  });

  group('C. Application and Atomic Slot Allocation Tests', () {
    late DevTournamentRepository repo;

    setUp(() {
      repo = DevTournamentRepository();
    });

    test('Assigns unique sequential slot upon registration', () async {
      final t = await repo.fetchTournamentById('tz_tourney_bgmi_scrims_01');
      final currentRegistered = t!.registeredCount;

      final res = await repo.registerForFreeTournament(
        tournamentId: t.id,
        gameUid: '5192837412',
        teamName: 'Team Alpha',
        currentUserId: 'player_seq_01',
      );

      expect(res.isSuccess, isTrue);
      expect(res.assignedSlot, equals(currentRegistered + 1));

      final reg = await repo.fetchPlayerRegistrationForTournament(
        tournamentId: t.id,
        uid: 'player_seq_01',
      );
      expect(reg, isNotNull);
      expect(reg!.assignedSlot, equals(currentRegistered + 1));
      expect(reg.teamName, equals('Team Alpha'));
    });
  });
}
