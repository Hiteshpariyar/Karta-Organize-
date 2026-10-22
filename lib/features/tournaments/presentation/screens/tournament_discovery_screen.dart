import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../controllers/tournament_discovery_controller.dart';
import '../widgets/game_selector_bar.dart';
import '../widgets/tournament_card.dart';
import '../widgets/tournament_filter_sheet.dart';

class TournamentDiscoveryScreen extends ConsumerStatefulWidget {
  const TournamentDiscoveryScreen({super.key});

  @override
  ConsumerState<TournamentDiscoveryScreen> createState() => _TournamentDiscoveryScreenState();
}

class _TournamentDiscoveryScreenState extends ConsumerState<TournamentDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(tournamentDiscoveryProvider);
    _searchController.text = state.query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? AppColors.electricBlue : const Color(0xFF7C3AED);
    final state = ref.watch(tournamentDiscoveryProvider);
    final notifier = ref.read(tournamentDiscoveryProvider.notifier);

    final hasActiveFilters = state.selectedGameId != 'all' ||
        state.selectedStatus != null ||
        state.selectedEntryType != null;

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('All Tournaments'),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune_rounded, size: 22),
                if (hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter Tournaments',
            onPressed: () {
              TournamentFilterSheet.show(
                context: context,
                initialGameId: state.selectedGameId,
                initialStatus: state.selectedStatus,
                initialEntryType: state.selectedEntryType,
                onApply: (gameId, status, entryType) {
                  notifier.selectGame(gameId);
                  notifier.selectStatus(status);
                  notifier.selectEntryType(entryType);
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: notifier.updateQuery,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by tournament or game title...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            notifier.updateQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.roundedMd,
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.roundedMd,
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.roundedMd,
                    borderSide: BorderSide(color: primaryAccent, width: 1.5),
                  ),
                ),
              ),
            ),

            // Game Selector Horizontal Bar
            GameSelectorBar(
              selectedGameId: state.selectedGameId,
              onGameSelected: notifier.selectGame,
            ),

            const SizedBox(height: 8),

            // Active Filters Row (if any active)
            if (hasActiveFilters)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Filtering: ',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (state.selectedGameId != 'all') ...[
                      _buildFilterBadge('${state.selectedGameId.toUpperCase()} Game', primaryAccent),
                      const SizedBox(width: 4),
                    ],
                    if (state.selectedStatus != null) ...[
                      _buildFilterBadge(state.selectedStatus!.label, primaryAccent),
                      const SizedBox(width: 4),
                    ],
                    if (state.selectedEntryType != null) ...[
                      _buildFilterBadge(state.selectedEntryType!.label, primaryAccent),
                      const SizedBox(width: 4),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: notifier.resetFilters,
                      child: Text(
                        'Clear',
                        style: AppTypography.bodySmall.copyWith(
                          color: primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // Tournament List or Status States
            Expanded(
              child: RefreshIndicator(
                color: primaryAccent,
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                onRefresh: notifier.loadTournaments,
                child: state.isLoading
                    ? const Center(
                        child: AppLoadingIndicator(
                          message: 'Discovering live and upcoming tournaments...',
                        ),
                      )
                    : state.errorMessage != null
                        ? Center(
                            child: EmptyStateWidget(
                              icon: Icons.error_outline_rounded,
                              iconColor: AppColors.error,
                              title: 'Failed to Load Tournaments',
                              description: state.errorMessage!,
                              actionText: 'Retry',
                              onAction: notifier.loadTournaments,
                            ),
                          )
                        : state.tournaments.isEmpty
                            ? Center(
                                child: EmptyStateWidget(
                                  icon: Icons.search_off_rounded,
                                  title: 'No Tournaments Found',
                                  description:
                                      'No tournaments match your current search or category filters. Try resetting filters.',
                                  actionText: hasActiveFilters ? 'Reset Filters' : null,
                                  onAction: hasActiveFilters ? notifier.resetFilters : null,
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                itemCount: state.tournaments.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final tournament = state.tournaments[index];
                                  return TournamentCard(
                                    tournament: tournament,
                                    onTap: () => context.push('/tournaments/${tournament.id}'),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBadge(String label, Color primaryAccent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primaryAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primaryAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
