import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/liquid_glass.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../friends/presentation/providers/friends_providers.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../providers/leaderboard_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  void _showPlayerDetailsModal(
    BuildContext context,
    LeaderboardEntry player,
    bool isMe,
    WidgetRef ref,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = const Color(0xFF7C3AED);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161226) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 36,
              backgroundColor: primaryAccent.withValues(alpha: 0.2),
              child: Text(
                player.displayName.isNotEmpty ? player.displayName[0].toUpperCase() : 'P',
                style: TextStyle(
                  color: primaryAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (player.inGameName?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                'IGN: ${player.inGameName}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Metrics row
            Row(
              children: [
                _buildStatBox('Rank', '#${player.rank}', primaryAccent, isDark),
                const SizedBox(width: 8),
                _buildStatBox('Points', '${player.score}', Colors.orangeAccent, isDark),
                const SizedBox(width: 8),
                _buildStatBox('Wins', '${player.wins}', Colors.greenAccent, isDark),
                const SizedBox(width: 8),
                _buildStatBox(
                  'Win Rate',
                  '${player.winRate.toStringAsFixed(1)}%',
                  Colors.blueAccent,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (isMe)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.person_rounded, size: 18),
                  label: const Text('View Full Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.playerProfile);
                  },
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Add Friend', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final currentAuth = ref.read(currentUserProfileProvider);
                        if (currentAuth != null) {
                          await ref.read(friendsRepositoryProvider).sendFriendRequest(
                                senderUid: currentAuth.uid,
                                senderDisplayName: currentAuth.displayName,
                                receiverUid: player.userId,
                                receiverDisplayName: player.displayName,
                              );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Friend request sent to ${player.displayName}')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedGame = ref.watch(selectedLeaderboardGameProvider);
    final topPlayersAsync = ref.watch(topPlayersProvider);
    final currentUser = ref.watch(currentUserProfileProvider);
    final primaryAccent = const Color(0xFF7C3AED);

    final games = [
      {'id': 'all', 'name': 'All Games'},
      {'id': 'freefire', 'name': 'Free Fire'},
      {'id': 'bgmi', 'name': 'BGMI'},
      {'id': 'codm', 'name': 'COD Mobile'},
      {'id': 'valorant', 'name': 'Valorant'},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Global Leaderboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Game Selector Chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: games.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final game = games[index];
                final isSelected = game['id'] == selectedGame;
                return ChoiceChip(
                  label: Text(game['name']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(selectedLeaderboardGameProvider.notifier).setGame(game['id']!);
                    }
                  },
                  selectedColor: primaryAccent,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF9F7AEA)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Main Rankings Content
          Expanded(
            child: topPlayersAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: primaryAccent),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error loading leaderboard: $err',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 64,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ranked players yet for this game',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Compete in tournaments to earn points and claim your podium spot!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final top1 = entries.isNotEmpty ? entries[0] : null;
                final top2 = entries.length > 1 ? entries[1] : null;
                final top3 = entries.length > 2 ? entries[2] : null;
                final remaining = entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];

                return RefreshIndicator(
                  color: primaryAccent,
                  onRefresh: () async {
                    ref.invalidate(topPlayersProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    children: [
                      // Top 3 Podium
                      if (top1 != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (top2 != null)
                              LiquidGlass.podiumCard(
                                rank: 2,
                                name: top2.displayName,
                                score: top2.score,
                                context: context,
                                onTap: () => _showPlayerDetailsModal(
                                  context,
                                  top2,
                                  currentUser?.uid == top2.userId,
                                  ref,
                                ),
                              )
                            else
                              const Expanded(child: SizedBox()),
                            LiquidGlass.podiumCard(
                              rank: 1,
                              name: top1.displayName,
                              score: top1.score,
                              context: context,
                              onTap: () => _showPlayerDetailsModal(
                                context,
                                top1,
                                currentUser?.uid == top1.userId,
                                ref,
                              ),
                            ),
                            if (top3 != null)
                              LiquidGlass.podiumCard(
                                rank: 3,
                                name: top3.displayName,
                                score: top3.score,
                                context: context,
                                onTap: () => _showPlayerDetailsModal(
                                  context,
                                  top3,
                                  currentUser?.uid == top3.userId,
                                  ref,
                                ),
                              )
                            else
                              const Expanded(child: SizedBox()),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Positions 4 through 100
                      if (remaining.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Rankings 4 – 100',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        ...remaining.map((player) {
                          final isMe = currentUser?.uid == player.userId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: LiquidGlass.container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              borderRadius: 16,
                              onTap: () => _showPlayerDetailsModal(
                                context,
                                player,
                                isMe,
                                ref,
                              ),
                              borderColor: isMe
                                  ? primaryAccent
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.08)),
                              backgroundColor: isMe
                                  ? primaryAccent.withValues(alpha: isDark ? 0.2 : 0.1)
                                  : null,
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '#${player.rank}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isMe
                                            ? const Color(0xFF9F7AEA)
                                            : (isDark
                                                ? Colors.white54
                                                : Colors.black54),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: primaryAccent.withValues(alpha: 0.2),
                                    child: Text(
                                      player.displayName.isNotEmpty
                                          ? player.displayName[0].toUpperCase()
                                          : 'P',
                                      style: const TextStyle(
                                        color: Color(0xFF9F7AEA),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                player.displayName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            if (isMe) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: primaryAccent,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'YOU',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          '${player.wins} Wins • ${player.matchesPlayed} Matches',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${player.score}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: primaryAccent,
                                        ),
                                      ),
                                      Text(
                                        'pts',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
