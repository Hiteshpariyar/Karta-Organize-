import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/tournament.dart';
import '../providers/tournament_providers.dart';
import '../widgets/tournament_status_badge.dart';

class TournamentDetailsScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentDetailsScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(tournamentDetailsStreamProvider(tournamentId));
    final userProfile = ref.watch(currentUserProfileProvider);
    final currentUid = userProfile?.uid ?? '';

    final isRegisteredAsync = currentUid.isNotEmpty
        ? ref.watch(isTournamentRegisteredProvider((
            tournamentId: tournamentId,
            uid: currentUid,
          )))
        : const AsyncData(false);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Tournament Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: tournamentAsync.when(
        data: (tournament) {
          if (tournament == null) {
            return Center(
              child: EmptyStateWidget(
                icon: Icons.search_off_rounded,
                title: 'Tournament Not Found',
                description: 'The requested tournament does not exist or has been removed.',
                actionText: 'Return to Discovery',
                onAction: () => context.go(AppRoutes.tournaments),
              ),
            );
          }

          final isAlreadyRegistered = isRegisteredAsync.value ?? false;
          final localStartsAt = tournament.startsAt.toLocal();
          final localClosesAt = tournament.registrationClosesAt.toLocal();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Entry Type Row
                      Row(
                        children: [
                          EntryTypeBadge(
                            entryType: tournament.entryType,
                            entryFee: tournament.entryFee,
                          ),
                          const SizedBox(width: 8),
                          TournamentStatusBadge(status: tournament.status),
                          const Spacer(),
                          Text(
                            tournament.gameName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.electricBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Title
                      Text(
                        tournament.title,
                        style: AppTypography.displayMedium.copyWith(fontSize: 24),
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Organizer Display Name
                      Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hosted by: ${tournament.organizerDisplayName}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Quick Info Stat Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: AppSpacing.roundedLg,
                          border: Border.all(color: AppColors.darkSurfaceBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatItem(
                                    label: 'Slots Available',
                                    value: tournament.isLobbyFull
                                        ? 'Full'
                                        : '${tournament.availableSlots} remaining',
                                    valueColor: tournament.isLobbyFull
                                        ? AppColors.warning
                                        : AppColors.success,
                                    icon: Icons.people_alt_outlined,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: AppColors.darkSurfaceBorder,
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    label: 'Lobby Capacity',
                                    value: '${tournament.registeredCount}/${tournament.maxParticipants}',
                                    valueColor: AppColors.textPrimary,
                                    icon: Icons.groups_rounded,
                                  ),
                                ),
                              ],
                            ),
                            if (tournament.prizeDescription != null) ...[
                              const SizedBox(height: 12),
                              const Divider(color: AppColors.darkSurfaceBorderSubtle, height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    color: AppColors.neonOrange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Prize Information',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          tournament.prizeDescription!,
                                          style: AppTypography.titleSmall.copyWith(
                                            color: AppColors.neonOrange,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Description
                      _buildSectionHeader('Overview & Description'),
                      Text(
                        tournament.description,
                        style: AppTypography.bodyMedium.copyWith(height: 1.5),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Match Schedule Details
                      _buildSectionHeader('Schedule & Local Timestamps'),
                      _buildInfoTile(
                        icon: Icons.calendar_today_rounded,
                        title: 'Match Start Time',
                        subtitle:
                            '${localStartsAt.day}/${localStartsAt.month}/${localStartsAt.year} at ${localStartsAt.hour.toString().padLeft(2, '0')}:${localStartsAt.minute.toString().padLeft(2, '0')} (${localStartsAt.timeZoneName})',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoTile(
                        icon: Icons.timer_outlined,
                        title: 'Registration Closes',
                        subtitle:
                            '${localClosesAt.day}/${localClosesAt.month}/${localClosesAt.year} at ${localClosesAt.hour.toString().padLeft(2, '0')}:${localClosesAt.minute.toString().padLeft(2, '0')} (${localClosesAt.timeZoneName})',
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Format & Eligibility
                      _buildSectionHeader('Match Format & Eligibility'),
                      _buildDetailRow('Match Format', tournament.matchFormat),
                      _buildDetailRow('Eligibility', tournament.eligibility),

                      const SizedBox(height: AppSpacing.lg),

                      // Rules
                      _buildSectionHeader('Tournament Rules'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: AppColors.darkSurfaceBorder),
                        ),
                        child: Text(
                          tournament.rules,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Cancellation Policy
                      _buildSectionHeader('Cancellation Policy Reference'),
                      Text(
                        tournament.cancellationPolicy,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.darkSurface,
                  border: Border(
                    top: BorderSide(color: AppColors.darkSurfaceBorder),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: _buildBottomCTA(
                    context: context,
                    tournament: tournament,
                    isAlreadyRegistered: isAlreadyRegistered,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading tournament details...'),
        ),
        error: (e, _) => Center(
          child: EmptyStateWidget(
            icon: Icons.error_outline_rounded,
            title: 'Error Loading Details',
            description: e.toString(),
            actionText: 'Retry',
            onAction: () => ref.invalidate(tournamentDetailsStreamProvider(tournamentId)),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCTA({
    required BuildContext context,
    required Tournament tournament,
    required bool isAlreadyRegistered,
  }) {
    if (isAlreadyRegistered) {
      return AppButton.secondary(
        text: 'You Are Registered (View Pass)',
        icon: Icons.verified_user_rounded,
        onPressed: () => context.push(AppRoutes.myTournaments),
      );
    }

    if (tournament.isPaid) {
      return const AppButton(
        text: 'Paid Registration Unavailable (Coming Soon)',
        icon: Icons.lock_outline_rounded,
        onPressed: null, // Strictly disabled in Phase 3
      );
    }

    if (tournament.isLobbyFull) {
      return const AppButton(
        text: 'Tournament Lobby Full',
        icon: Icons.people_outline_rounded,
        onPressed: null,
      );
    }

    if (tournament.status == TournamentStatus.registrationClosed ||
        DateTime.now().isAfter(tournament.registrationClosesAt)) {
      return const AppButton(
        text: 'Registration Closed',
        icon: Icons.lock_clock_rounded,
        onPressed: null,
      );
    }

    if (tournament.status != TournamentStatus.registrationOpen) {
      return AppButton(
        text: 'Registration Not Open (${tournament.status.label})',
        onPressed: null,
      );
    }

    return AppButton(
      text: 'Register for Free Tournament',
      icon: Icons.how_to_reg_rounded,
      onPressed: () => context.push('/tournaments/${tournament.id}/register'),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: valueColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: AppTypography.titleSmall.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.darkSurfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.electricBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
