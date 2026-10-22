import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/liquid_glass.dart';
import '../../domain/models/tournament.dart';
import '../providers/tournament_providers.dart';
import '../widgets/tournament_card.dart';

class GameDetailsScreen extends ConsumerStatefulWidget {
  final String gameId;
  final String gameName;

  const GameDetailsScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  ConsumerState<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends ConsumerState<GameDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allTournamentsAsync = ref.watch(allTournamentsProvider);
    final primaryAccent = const Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.gameName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: allTournamentsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: primaryAccent),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
        ),
        data: (tournaments) {
          final gameTournaments = tournaments
              .where((t) => t.gameId.toLowerCase() == widget.gameId.toLowerCase())
              .toList();

          final totalCount = gameTournaments.length;
          final upcomingCount = gameTournaments
              .where((t) =>
                  t.status == TournamentStatus.upcoming ||
                  t.status == TournamentStatus.registrationOpen)
              .length;
          final ongoingCount = gameTournaments
              .where((t) =>
                  t.status == TournamentStatus.live ||
                  t.status == TournamentStatus.full)
              .length;
          final completedCount = gameTournaments
              .where((t) => t.status == TournamentStatus.completed)
              .length;

          final upcomingList = gameTournaments
              .where((t) =>
                  t.status == TournamentStatus.upcoming ||
                  t.status == TournamentStatus.registrationOpen)
              .toList();
          final ongoingList = gameTournaments
              .where((t) =>
                  t.status == TournamentStatus.live ||
                  t.status == TournamentStatus.full)
              .toList();
          final completedList = gameTournaments
              .where((t) => t.status == TournamentStatus.completed)
              .toList();

          return Column(
            children: [
              // 4 Summary Status Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildStatCard('Total', totalCount, primaryAccent, isDark),
                    const SizedBox(width: 8),
                    _buildStatCard('Upcoming', upcomingCount, Colors.blueAccent, isDark),
                    const SizedBox(width: 8),
                    _buildStatCard('Ongoing', ongoingCount, Colors.orangeAccent, isDark),
                    const SizedBox(width: 8),
                    _buildStatCard('Completed', completedCount, Colors.greenAccent, isDark),
                  ],
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: primaryAccent,
                indicatorWeight: 3,
                labelColor: primaryAccent,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Ongoing'),
                  Tab(text: 'Completed'),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTournamentList(gameTournaments, isDark),
                    _buildTournamentList(upcomingList, isDark),
                    _buildTournamentList(ongoingList, isDark),
                    _buildTournamentList(completedList, isDark),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color accent, bool isDark) {
    return Expanded(
      child: LiquidGlass.container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        borderRadius: 16,
        borderColor: accent.withValues(alpha: isDark ? 0.35 : 0.25),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentList(List<Tournament> list, bool isDark) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 54,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              'No tournaments found in this section',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final t = list[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: TournamentCard(
            tournament: t,
            onTap: () => context.push('/tournaments/${t.id}'),
          ),
        );
      },
    );
  }
}
