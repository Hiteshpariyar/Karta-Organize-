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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? AppColors.electricBlue : const Color(0xFF7C3AED);
    final user = ref.watch(currentUserProfileProvider);
    final uid = user?.uid ?? '';

    if (uid.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Tournaments'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryAccent,
          labelColor: primaryAccent,
          unselectedLabelColor: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.surfaceOf(context);
    final cardBorder = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primaryAccent = isDark ? AppColors.electricBlue : const Color(0xFF7C3AED);

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            emptyMessage,
            style: AppTypography.bodyMedium.copyWith(color: textSecondary),
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
            color: cardBg,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
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
                        color: primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (reg.assignedSlot != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'SLOT #${reg.assignedSlot}',
                        style: TextStyle(
                          color: primaryAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
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
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.badge_outlined, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'In-Game ID: ${reg.gameUid}',
                    style: AppTypography.bodySmall.copyWith(
                      color: textSecondary,
                    ),
                  ),
                  if (reg.teamName != null && reg.teamName!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.shield_outlined, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Team: ${reg.teamName}',
                      style: AppTypography.bodySmall.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (matchDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Starts: ${matchDate.day}/${matchDate.month}/${matchDate.year} at ${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')} (${matchDate.timeZoneName})',
                      style: AppTypography.bodySmall.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Divider(color: cardBorder, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.vpn_key_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Room ID in Details',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('View Pass & Room ID'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryAccent,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => context.push('/tournaments/${reg.tournamentId}'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
