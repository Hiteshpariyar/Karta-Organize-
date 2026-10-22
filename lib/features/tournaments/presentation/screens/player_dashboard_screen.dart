import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/liquid_glass.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../leaderboard/presentation/providers/leaderboard_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../providers/tournament_providers.dart';
import '../widgets/featured_tournament_card.dart';
import '../widgets/tournament_card.dart';

class PlayerDashboardScreen extends ConsumerWidget {
  const PlayerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfile = ref.watch(currentUserProfileProvider);
    final featuredAsync = ref.watch(featuredTournamentsProvider);
    final allTournamentsAsync = ref.watch(allTournamentsProvider);
    final topPlayersAsync = ref.watch(topPlayersProvider);

    final currentUid = userProfile?.uid ?? '';
    final unreadCount = currentUid.isNotEmpty
        ? ref.watch(unreadNotificationsCountProvider(currentUid))
        : 0;

    final playerName = userProfile?.displayName.isNotEmpty == true
        ? userProfile!.displayName
        : (userProfile?.email.isNotEmpty == true
            ? userProfile!.email.split('@').first
            : 'Player');

    final games = [
      {
        'id': 'freefire',
        'name': 'Free Fire',
        'tagline': 'Battle in Bermuda & Kalahari',
        'gradient': const [Color(0xFFFF5722), Color(0xFFFF9800), Color(0xFFD84315)],
        'icon': Icons.local_fire_department_rounded,
      },
      {
        'id': 'bgmi',
        'name': 'BGMI',
        'tagline': 'Classic Erangel & Miramar',
        'gradient': const [Color(0xFF2E7D32), Color(0xFF1B5E20), Color(0xFF004D40)],
        'icon': Icons.military_tech_rounded,
      },
      {
        'id': 'codm',
        'name': 'COD Mobile',
        'tagline': 'Search & Destroy / Hardpoint',
        'gradient': const [Color(0xFF0284C7), Color(0xFF1E3A8A), Color(0xFF0F172A)],
        'icon': Icons.shield_rounded,
      },
      {
        'id': 'valorant',
        'name': 'Valorant Mobile',
        'tagline': 'Defuse the Spike 5v5',
        'gradient': const [Color(0xFFE11D48), Color(0xFF881337), Color(0xFF4C0519)],
        'icon': Icons.flash_on_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => context.push(AppRoutes.playerProfile),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                child: Text(
                  playerName.isNotEmpty ? playerName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Color(0xFF9F7AEA),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    playerName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Notifications Bell
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  onPressed: () => context.push(AppRoutes.notifications),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF7C3AED),
        onRefresh: () async {
          ref.invalidate(allTournamentsProvider);
          ref.invalidate(featuredTournamentsProvider);
          ref.invalidate(topPlayersProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            // Game Banners Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Your Game',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Explore Hub',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Game Banners Carousel
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: games.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final g = games[index];
                  final gradientColors = g['gradient'] as List<Color>;

                  return GestureDetector(
                    onTap: () {
                      context.push(
                        AppRoutes.gameDetails,
                        extra: {
                          'gameId': g['id'],
                          'gameName': g['name'],
                        },
                      );
                    },
                    child: Container(
                      width: 240,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.first.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child: Icon(
                              g['icon'] as IconData,
                              size: 100,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(g['icon'] as IconData, color: Colors.white, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        g['name'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      g['tagline'] as String,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'View Hub & Tournaments',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Top Players Teaser
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Champions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.leaderboard),
                  child: const Text(
                    'Full Leaderboard >',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            topPlayersAsync.maybeWhen(
              data: (players) {
                if (players.isEmpty) {
                  return LiquidGlass.container(
                    padding: const EdgeInsets.all(14),
                    borderRadius: 18,
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Compete in tournaments to claim your rank on the leaderboard!',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final top3 = players.take(3).toList();
                return Row(
                  children: top3.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final player = entry.value;
                    return LiquidGlass.podiumCard(
                      rank: rank,
                      name: player.displayName,
                      score: player.score,
                      context: context,
                      onTap: () => context.push(AppRoutes.leaderboard),
                    );
                  }).toList(),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Featured Tournaments Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Tournaments',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.tournaments),
                  child: const Text(
                    'View All >',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            featuredAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                ),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (featuredList) {
                if (featuredList.isEmpty) {
                  return LiquidGlass.container(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 18,
                    child: Center(
                      child: Text(
                        'No featured tournaments right now. Check back soon!',
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: featuredList.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      final t = featuredList[i];
                      return SizedBox(
                        width: 280,
                        child: FeaturedTournamentCard(
                          tournament: t,
                          onTap: () => context.push('/tournaments/${t.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Tournaments
            Text(
              'Latest Open Registrations',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            allTournamentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (allList) {
                if (allList.isEmpty) {
                  return LiquidGlass.container(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 18,
                    child: Center(
                      child: Text(
                        'No tournaments available at the moment.',
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  );
                }

                final displayList = allList.take(5).toList();
                return Column(
                  children: displayList.map((t) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: TournamentCard(
                        tournament: t,
                        onTap: () => context.push('/tournaments/${t.id}'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
