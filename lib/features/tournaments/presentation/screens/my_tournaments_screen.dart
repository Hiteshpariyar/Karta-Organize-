import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/tournament_registration.dart';
import '../providers/tournament_providers.dart';

class MyTournamentsScreen extends ConsumerStatefulWidget {
  const MyTournamentsScreen({super.key});

  @override
  ConsumerState<MyTournamentsScreen> createState() => _MyTournamentsScreenState();
}

class _MyTournamentsScreenState extends ConsumerState<MyTournamentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final uid = user?.uid ?? '';

    if (uid.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(title: const Text('My Tournaments')),
        body: Center(
          child: EmptyStateWidget(
            icon: Icons.lock_outline_rounded,
            title: 'Authentication Required',
            description: 'Please sign in to view your registered tournaments and match passes.',
            actionText: 'Sign In',
            onAction: () => context.go(AppRoutes.playerLogin),
          ),
        ),
      );
    }

    final registrationsAsync = ref.watch(playerRegistrationsStreamProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('My Tournaments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.electricBlue,
          labelColor: AppColors.electricBlue,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'All Passes'),
          ],
        ),
      ),
      body: registrationsAsync.when(
        data: (allRegistrations) {
          if (allRegistrations.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                icon: Icons.confirmation_number_outlined,
                title: 'No Registrations Found',
                description:
                    'You have not registered for any tournaments yet. Discover and join competitive lobbies today!',
                actionText: 'Explore Tournaments',
                onAction: () => context.push(AppRoutes.tournaments),
              ),
            );
          }

          final now = DateTime.now();
          final upcoming = allRegistrations.where((r) {
            if (r.tournamentStartsAt == null) return true;
            return r.tournamentStartsAt!.isAfter(now);
          }).toList();

          final completed = allRegistrations.where((r) {
            if (r.tournamentStartsAt == null) return false;
            return r.tournamentStartsAt!.isBefore(now);
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRegistrationList(upcoming, 'No upcoming matches scheduled.'),
              _buildRegistrationList(completed, 'No completed tournaments yet.'),
              _buildRegistrationList(allRegistrations, 'No registrations found.'),
            ],
          );
        },
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading match passes...'),
        ),
        error: (e, _) => Center(
          child: EmptyStateWidget(
            icon: Icons.error_outline_rounded,
            title: 'Error Loading Passes',
            description: e.toString(),
            actionText: 'Retry',
            onAction: () => ref.invalidate(playerRegistrationsStreamProvider(uid)),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationList(List<TournamentRegistration> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            emptyMessage,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reg = list[index];
        final matchDate = reg.tournamentStartsAt?.toLocal();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.darkSurfaceBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reg.gameName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.electricBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.successDim,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      reg.status.label.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reg.tournamentTitle,
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'In-Game UID: ${reg.gameUid}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (matchDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Starts: ${matchDate.day}/${matchDate.month}/${matchDate.year} at ${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              const Divider(color: AppColors.darkSurfaceBorderSubtle, height: 1),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('View Tournament'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.electricBlue,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => context.push('/tournaments/${reg.tournamentId}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
