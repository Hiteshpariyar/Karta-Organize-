import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../domain/models/room_credentials.dart';
import '../../domain/models/tournament.dart';
import '../../domain/models/tournament_registration.dart';
import '../providers/tournament_providers.dart';
import '../widgets/tournament_status_badge.dart';

/// Comprehensive, responsive tournament details screen.
/// Divided into Overview, Entry & Rewards, Organizer Details, and Secure Room Credentials.
class TournamentDetailsScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentDetailsScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? AppColors.electricBlue : const Color(0xFF7C3AED);
    final cardBg = AppColors.surfaceOf(context);
    final cardBorder = AppColors.borderOf(context);
    final dividerColor = isDark ? AppColors.darkSurfaceBorderSubtle : AppColors.lightSurfaceBorderSubtle;
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    final tournamentAsync = ref.watch(tournamentDetailsStreamProvider(tournamentId));
    final userProfile = ref.watch(currentUserProfileProvider);
    final currentUid = userProfile?.uid ?? '';

    // Watch registration status
    final isRegisteredAsync = currentUid.isNotEmpty
        ? ref.watch(isTournamentRegisteredProvider((
            tournamentId: tournamentId,
            uid: currentUid,
          )))
        : const AsyncData(false);

    // Watch player's specific registration (to get assignedSlot)
    final playerRegAsync = currentUid.isNotEmpty
        ? ref.watch(playerRegistrationForTournamentProvider((
            tournamentId: tournamentId,
            uid: currentUid,
          )))
        : const AsyncData<TournamentRegistration?>(null);

    // Watch room credentials
    final roomCredsAsync = ref.watch(tournamentRoomCredentialsStreamProvider(tournamentId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tournament Details'),
        elevation: 0,
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
          final playerRegistration = playerRegAsync.value;
          final roomCredentials = roomCredsAsync.value;

          final localStartsAt = tournament.startsAt.toLocal();
          final localClosesAt = tournament.registrationClosesAt.toLocal();
          final localReportingAt = tournament.effectiveReportingTime.toLocal();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Entry Badges Row
                      Row(
                        children: [
                          EntryTypeBadge(
                            entryType: tournament.entryType,
                            entryFee: tournament.entryFee,
                          ),
                          const SizedBox(width: 8),
                          TournamentStatusBadge(status: tournament.status),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: isDark ? 0.14 : 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tournament.gameName,
                              style: AppTypography.bodySmall.copyWith(
                                color: primaryAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Tournament Title
                      Text(
                        tournament.title,
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Organizer Team byline
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            'Organized by: ${tournament.displayOrganizerTeam}',
                            style: AppTypography.bodySmall.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (tournament.isOrganizerVerified) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified_rounded, size: 14, color: primaryAccent),
                          ],
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Section: Slot Capacity Stat Card
                      _buildSlotCapacityCard(
                        context: context,
                        tournament: tournament,
                        playerRegistration: playerRegistration,
                        isAlreadyRegistered: isAlreadyRegistered,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        primaryAccent: primaryAccent,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // =========================================================
                      // SECTION 1: TOURNAMENT OVERVIEW
                      // =========================================================
                      _buildSectionHeader('Tournament Overview', textPrimary),
                      const SizedBox(height: 8),

                      // Description
                      if (tournament.description.isNotEmpty) ...[
                        Text(
                          tournament.description,
                          style: AppTypography.bodyMedium.copyWith(
                            height: 1.5,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Match Specifications Grid
                      _buildSpecificationsCard(
                        tournament: tournament,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        dividerColor: dividerColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        primaryAccent: primaryAccent,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Schedule & Timestamps Card
                      _buildScheduleCard(
                        startsAt: localStartsAt,
                        reportingAt: localReportingAt,
                        closesAt: localClosesAt,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        primaryAccent: primaryAccent,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // =========================================================
                      // SECTION 2: ENTRY AND REWARDS
                      // =========================================================
                      _buildSectionHeader('Entry Fee & Prize Pool', textPrimary),
                      const SizedBox(height: 8),

                      _buildRewardsCard(
                        context: context,
                        tournament: tournament,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        dividerColor: dividerColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        primaryAccent: primaryAccent,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // =========================================================
                      // SECTION 3: ORGANIZER DETAILS
                      // =========================================================
                      _buildSectionHeader('Organizer Information', textPrimary),
                      const SizedBox(height: 8),

                      _buildOrganizerCard(
                        tournament: tournament,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        primaryAccent: primaryAccent,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // =========================================================
                      // SECTION 4: ROOM CREDENTIALS (SECURITY PROTECTED)
                      // =========================================================
                      _buildSectionHeader('Custom Room Credentials', textPrimary),
                      const SizedBox(height: 8),

                      _buildRoomCredentialsCard(
                        context: context,
                        tournament: tournament,
                        isAlreadyRegistered: isAlreadyRegistered,
                        roomCredentials: roomCredentials,
                        playerRegistration: playerRegistration,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        primaryAccent: primaryAccent,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Rules, Eligibility & Policies
                      _buildSectionHeader('Rules & Fair Play Guidelines', textPrimary),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tournament.rules,
                              style: AppTypography.bodySmall.copyWith(
                                color: textPrimary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Divider(color: dividerColor, height: 1),
                            const SizedBox(height: 10),
                            Text(
                              'Eligibility: ${tournament.eligibility}',
                              style: AppTypography.bodySmall.copyWith(
                                color: textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
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
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(
                    top: BorderSide(color: cardBorder),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: _buildBottomCTA(
                    context: context,
                    tournament: tournament,
                    isAlreadyRegistered: isAlreadyRegistered,
                    playerRegistration: playerRegistration,
                    isSignedIn: currentUid.isNotEmpty,
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

  // ---------------------------------------------------------------------------
  // Widget Builders
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: AppTypography.titleSmall.copyWith(
        color: textColor,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildSlotCapacityCard({
    required BuildContext context,
    required Tournament tournament,
    required TournamentRegistration? playerRegistration,
    required bool isAlreadyRegistered,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryAccent,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final fillPct = tournament.slotFillPercentage;
    final Color progressColor = tournament.isLobbyFull
        ? AppColors.warning
        : (fillPct >= 0.75 ? AppColors.neonOrange : AppColors.success);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE SLOTS',
                      style: AppTypography.bodySmall.copyWith(
                        color: textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tournament.isLobbyFull ? 'Full' : '${tournament.availableSlots} remaining',
                      style: AppTypography.titleMedium.copyWith(
                        color: tournament.isLobbyFull ? AppColors.warning : AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: cardBorder),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL CAPACITY',
                      style: AppTypography.bodySmall.copyWith(
                        color: textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tournament.registeredCount} / ${tournament.maxParticipants} Slots',
                      style: AppTypography.titleMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fillPct,
              minHeight: 6,
              backgroundColor: cardBorder.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          if (isAlreadyRegistered && playerRegistration?.assignedSlot != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    'Your Assigned Slot: #${playerRegistration!.assignedSlot}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecificationsCard({
    required Tournament tournament,
    required Color cardBg,
    required Color cardBorder,
    required Color dividerColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryAccent,
  }) {
    String teamSizeLabel = 'Solo (1 Player)';
    if (tournament.teamSize == 2) teamSizeLabel = 'Duo (2 Players)';
    if (tournament.teamSize == 4) teamSizeLabel = 'Squad (4 Players)';
    if (tournament.teamSize > 4) teamSizeLabel = '${tournament.teamSize} Players';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          _buildSpecRow('Game', tournament.gameName, textSecondary, textPrimary),
          Divider(color: dividerColor, height: 16),
          _buildSpecRow('Mode', tournament.mode ?? 'Battle Royale', textSecondary, textPrimary),
          Divider(color: dividerColor, height: 16),
          _buildSpecRow('Map', tournament.mapName ?? 'Erangel / Bermuda', textSecondary, textPrimary),
          Divider(color: dividerColor, height: 16),
          _buildSpecRow('Team Size', teamSizeLabel, textSecondary, textPrimary),
          Divider(color: dividerColor, height: 16),
          _buildSpecRow('Match Format', tournament.matchFormat, textSecondary, textPrimary),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: labelColor, fontSize: 12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodySmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard({
    required DateTime startsAt,
    required DateTime reportingAt,
    required DateTime closesAt,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryAccent,
  }) {
    String formatTime(DateTime dt) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month}/${dt.year} at $hour:$min $period (${dt.timeZoneName})';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          _buildScheduleItem(
            icon: Icons.play_circle_outline_rounded,
            title: 'Match Start Time',
            timestamp: formatTime(startsAt),
            accentColor: primaryAccent,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          _buildScheduleItem(
            icon: Icons.timer_outlined,
            title: 'Reporting Time (Check-In)',
            timestamp: formatTime(reportingAt),
            accentColor: AppColors.warning,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          _buildScheduleItem(
            icon: Icons.lock_clock_outlined,
            title: 'Registration Deadline',
            timestamp: formatTime(closesAt),
            accentColor: AppColors.error,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required IconData icon,
    required String title,
    required String timestamp,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                timestamp,
                style: AppTypography.bodySmall.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsCard({
    required BuildContext context,
    required Tournament tournament,
    required Color cardBg,
    required Color cardBorder,
    required Color dividerColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryAccent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Prize Pool Banner
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, size: 24, color: AppColors.neonOrange),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PRIZE POOL',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neonOrange,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      tournament.formattedPrizePool,
                      style: AppTypography.titleMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tournament.isFree
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.neonOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: tournament.isFree
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.neonOrange.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  tournament.formattedEntryFee,
                  style: AppTypography.bodySmall.copyWith(
                    color: tournament.isFree ? AppColors.success : AppColors.neonOrange,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          // Per-Kill Reward pill
          if (tournament.formattedPerKillReward != null) ...[
            const SizedBox(height: 12),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.electricBlue),
                const SizedBox(width: 6),
                Text(
                  'Per-Kill Reward: ',
                  style: AppTypography.bodySmall.copyWith(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  tournament.formattedPerKillReward!,
                  style: AppTypography.bodySmall.copyWith(
                    color: primaryAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          // Prize Distribution by Rank (Explicitly defined only!)
          if (tournament.prizeDistribution != null &&
              tournament.prizeDistribution!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 10),
            Text(
              'Prize Distribution Breakdown',
              style: AppTypography.bodySmall.copyWith(
                color: textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            ...tournament.prizeDistribution!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: AppTypography.bodySmall.copyWith(
                        color: textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neonOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildOrganizerCard({
    required Tournament tournament,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryAccent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryAccent.withValues(alpha: 0.15),
                child: Icon(Icons.shield_rounded, color: primaryAccent, size: 20),
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
                            tournament.displayOrganizerTeam,
                            style: AppTypography.titleSmall.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tournament.isOrganizerVerified) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified_rounded, size: 15, color: primaryAccent),
                        ],
                      ],
                    ),
                    Text(
                      'Host: ${tournament.displayOrganizerHost}',
                      style: AppTypography.bodySmall.copyWith(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (tournament.organizerRating != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neonOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.neonOrange),
                      const SizedBox(width: 3),
                      Text(
                        tournament.organizerRating!.toStringAsFixed(1),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.neonOrange,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (tournament.organizerReviewCount != null ||
              tournament.organizerCompletedTournaments != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (tournament.organizerCompletedTournaments != null)
                  Text(
                    '${tournament.organizerCompletedTournaments} Tournaments Hosted',
                    style: AppTypography.bodySmall.copyWith(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                  ),
                if (tournament.organizerReviewCount != null)
                  Text(
                    '${tournament.organizerReviewCount} Verified Reviews',
                    style: AppTypography.bodySmall.copyWith(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomCredentialsCard({
    required BuildContext context,
    required Tournament tournament,
    required bool isAlreadyRegistered,
    required RoomCredentials? roomCredentials,
    required TournamentRegistration? playerRegistration,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryAccent,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    // Case 1: Player is not registered
    if (!isAlreadyRegistered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 24, color: textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room Credentials Protected',
                    style: AppTypography.titleSmall.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Custom Room ID and Password are disclosed only to confirmed tournament participants once approved.',
                    style: AppTypography.bodySmall.copyWith(
                      color: textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Case 2: Player is registered, but credentials not released yet
    final areCredsReleased = tournament.areCredentialsUnlocked ||
        (roomCredentials != null && roomCredentials.isReleased);

    if (!areCredsReleased) {
      final releaseTime = tournament.effectiveCredentialsReleaseTime.toLocal();
      final minStr = releaseTime.minute.toString().padLeft(2, '0');
      final hour = releaseTime.hour > 12 ? releaseTime.hour - 12 : (releaseTime.hour == 0 ? 12 : releaseTime.hour);
      final period = releaseTime.hour >= 12 ? 'PM' : 'AM';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryAccent.withValues(alpha: 0.08),
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_clock_rounded, size: 20, color: primaryAccent),
                const SizedBox(width: 8),
                Text(
                  'Credentials Locked Until Release Time',
                  style: AppTypography.titleSmall.copyWith(
                    color: primaryAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'The organizer will publish the Room ID and Password 15 minutes before the match start time (Scheduled: $hour:$minStr $period). Please check back then.',
              style: AppTypography.bodySmall.copyWith(
                color: textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    // Case 3: Player is registered and credentials ARE released
    final roomId = roomCredentials?.roomId ?? tournament.roomId ?? '948271';
    final roomPassword = roomCredentials?.roomPassword ?? tournament.roomPassword ?? 'ZONE@9';

    void copyToClipboard(String label, String value) {
      Clipboard.setData(ClipboardData(text: value));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_rounded, size: 20, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'Custom Room Access Released',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Room ID Row
          _buildCredentialRow(
            label: 'Room ID',
            value: roomId,
            onCopy: () => copyToClipboard('Room ID', roomId),
            primaryAccent: primaryAccent,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 8),

          // Password Row
          _buildCredentialRow(
            label: 'Password',
            value: roomPassword,
            onCopy: () => copyToClipboard('Password', roomPassword),
            primaryAccent: primaryAccent,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          if (roomCredentials?.instructions != null &&
              roomCredentials!.instructions!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              roomCredentials.instructions!,
              style: AppTypography.bodySmall.copyWith(
                color: textSecondary,
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCredentialRow({
    required String label,
    required String value,
    required VoidCallback onCopy,
    required Color primaryAccent,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            icon: const Icon(Icons.copy_rounded, size: 14),
            label: const Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA({
    required BuildContext context,
    required Tournament tournament,
    required bool isAlreadyRegistered,
    required TournamentRegistration? playerRegistration,
    required bool isSignedIn,
  }) {
    if (!isSignedIn) {
      return AppButton(
        text: 'Sign In to Register',
        icon: Icons.login_rounded,
        onPressed: () => context.push(AppRoutes.playerLogin),
      );
    }

    if (isAlreadyRegistered) {
      final slotStr = playerRegistration?.assignedSlot != null
          ? ' (Slot #${playerRegistration!.assignedSlot})'
          : '';
      return AppButton.secondary(
        text: 'Registered$slotStr — View My Pass',
        icon: Icons.verified_user_rounded,
        onPressed: () => context.push(AppRoutes.myTournaments),
      );
    }

    if (tournament.isPaid) {
      return const AppButton(
        text: 'Paid Registration Disabled (Phase 3)',
        icon: Icons.lock_outline_rounded,
        onPressed: null,
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
        text: 'Registration Deadline Passed',
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
}
