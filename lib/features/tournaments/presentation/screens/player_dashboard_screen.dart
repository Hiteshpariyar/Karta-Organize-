import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../providers/tournament_providers.dart';
import '../widgets/featured_tournament_card.dart';
import '../widgets/game_selector_bar.dart';
import '../widgets/tournament_card.dart';

/// Central Player Dashboard / Home Screen.
class PlayerDashboardScreen extends ConsumerStatefulWidget {
  const PlayerDashboardScreen({super.key});

  @override
  ConsumerState<PlayerDashboardScreen> createState() => _PlayerDashboardScreenState();
}

class _PlayerDashboardScreenState extends ConsumerState<PlayerDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final selectedGameId = ref.watch(selectedDashboardGameProvider);
    final featuredAsync = ref.watch(featuredTournamentsProvider);
    final openAsync = ref.watch(openTournamentsProvider(selectedGameId));
    final upcomingAsync = ref.watch(upcomingTournamentsProvider(selectedGameId));

    final currentUid = userProfile?.uid ?? '';
    final unreadCount = currentUid.isNotEmpty
        ? ref.watch(unreadNotificationsCountProvider(currentUid))
        : 0;

    final myRegistrationsAsync = currentUid.isNotEmpty
        ? ref.watch(playerRegistrationsStreamProvider(currentUid))
        : null;

    final playerName = userProfile?.displayName.isNotEmpty == true
        ? userProfile!.displayName
        : (userProfile?.email.isNotEmpty == true
            ? userProfile!.email.split('@').first
            : 'Player');

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => context.push(AppRoutes.playerProfile),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.electricBlue.withValues(alpha: 0.2),
                child: Text(
                  playerName.isNotEmpty ? playerName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: AppColors.electricBlue,
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
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    playerName,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Notifications Action with Unread Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 24),
                tooltip: 'Notifications',
                onPressed: () => context.push(AppRoutes.notifications),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, size: 24),
            tooltip: 'Profile',
            onPressed: () => context.push(AppRoutes.playerProfile),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.electricBlue,
          backgroundColor: AppColors.darkSurface,
          onRefresh: () async {
            ref.invalidate(featuredTournamentsProvider);
            ref.invalidate(openTournamentsProvider);
            ref.invalidate(upcomingTournamentsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Search Bar Shortcut
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    readOnly: true,
                    onTap: () => context.push(AppRoutes.tournaments),
                    decoration: InputDecoration(
                      hintText: 'Search tournaments, scrims, games...',
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.electricBlueDim,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: AppColors.electricBlue,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.darkSurface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.roundedMd,
                        borderSide: const BorderSide(color: AppColors.darkSurfaceBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppSpacing.roundedMd,
                        borderSide: const BorderSide(color: AppColors.darkSurfaceBorder),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // 2. Horizontal Game Categories
                GameSelectorBar(
                  selectedGameId: selectedGameId,
                  onGameSelected: (gameId) {
                    ref.read(selectedDashboardGameProvider.notifier).select(gameId);
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // 3. Featured Tournament Spotlight
                featuredAsync.when(
                  data: (featuredList) {
                    if (featuredList.isEmpty) return const SizedBox.shrink();
                    final topFeatured = featuredList.first;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FeaturedTournamentCard(
                        tournament: topFeatured,
                        onTap: () => context.push('/tournaments/${topFeatured.id}'),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: AppLoadingIndicator(message: 'Loading featured matches...'),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 4. "My Registered Tournaments" Banner (if active)
                if (myRegistrationsAsync != null)
                  myRegistrationsAsync.when(
                    data: (regs) {
                      if (regs.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.electricBlueDim,
                            borderRadius: AppSpacing.roundedMd,
                            border: Border.all(
                              color: AppColors.electricBlue.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.darkSurface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  color: AppColors.electricBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'You have ${regs.length} active registration${regs.length > 1 ? 's' : ''}',
                                      style: AppTypography.titleSmall.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Next match: ${regs.first.tournamentTitle}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push(AppRoutes.myTournaments),
                                child: const Text(
                                  'View Pass',
                                  style: TextStyle(
                                    color: AppColors.electricBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),

                // 5. Registration Open Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Registration Open',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.tournaments),
                        child: Text(
                          'See All',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.electricBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                openAsync.when(
                  data: (openTourneys) {
                    if (openTourneys.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'No open registrations right now for this category.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: openTourneys.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final t = openTourneys[index];
                        return TournamentCard(
                          tournament: t,
                          onTap: () => context.push('/tournaments/${t.id}'),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: AppColors.electricBlue),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 6. Upcoming Tournaments Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.electricBlue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Upcoming Tournaments',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.tournaments),
                        child: Text(
                          'View Calendar',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.electricBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                upcomingAsync.when(
                  data: (upcomingList) {
                    if (upcomingList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'No upcoming scheduled tournaments in this section.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: upcomingList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final t = upcomingList[index];
                        return TournamentCard(
                          tournament: t,
                          onTap: () => context.push('/tournaments/${t.id}'),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: AppColors.electricBlue),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.electricBlue,
        unselectedItemColor: AppColors.textMuted,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              context.push(AppRoutes.tournaments);
              break;
            case 2:
              context.push(AppRoutes.myTournaments);
              break;
            case 3:
              context.push(AppRoutes.playerProfile);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            label: 'My Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
