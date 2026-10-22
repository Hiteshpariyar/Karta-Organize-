import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/tournament.dart';
import 'tournament_status_badge.dart';

/// Clean, minimal, mobile-first tournament card presenting essential information
/// without visual clutter. Fully responsive for both light and dark themes.
/// Room ID and Password are intentionally excluded to protect private room credentials.
class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  IconData _getGameIcon(String gameId) {
    switch (gameId.toLowerCase()) {
      case 'bgmi':
        return Icons.military_tech_rounded;
      case 'freefire':
        return Icons.local_fire_department_rounded;
      case 'codm':
        return Icons.gps_fixed_rounded;
      case 'valorant':
        return Icons.shield_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? AppColors.electricBlue : const Color(0xFF7C3AED);

    final cardBg = AppColors.surfaceOf(context);
    final cardBorder = AppColors.borderOf(context);
    final dividerColor = isDark ? AppColors.darkSurfaceBorderSubtle : AppColors.lightSurfaceBorderSubtle;
    final titleColor = AppColors.textPrimaryOf(context);
    final secondaryTextColor = AppColors.textSecondaryOf(context);

    // Format start time with local timezone code
    final localTime = tournament.startsAt.toLocal();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = monthNames[localTime.month - 1];
    final hour = localTime.hour > 12 ? localTime.hour - 12 : (localTime.hour == 0 ? 12 : localTime.hour);
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    final minute = localTime.minute.toString().padLeft(2, '0');
    final formattedTime =
        '${localTime.day} $month • $hour:$minute $period ${localTime.timeZoneName}';

    // Progress bar color calculation
    final fillPct = tournament.slotFillPercentage;
    final Color progressColor = tournament.isLobbyFull
        ? AppColors.warning
        : (fillPct >= 0.75 ? AppColors.neonOrange : AppColors.success);

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedLg,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppSpacing.roundedLg,
          border: Border.all(color: cardBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Game Pill + Entry Badge + Status Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryAccent.withValues(alpha: isDark ? 0.14 : 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getGameIcon(tournament.gameId),
                          size: 13,
                          color: primaryAccent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          tournament.gameName,
                          style: AppTypography.bodySmall.copyWith(
                            color: primaryAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  EntryTypeBadge(
                    entryType: tournament.entryType,
                    entryFee: tournament.entryFee,
                  ),
                  const SizedBox(width: 6),
                  TournamentStatusBadge(status: tournament.status),
                ],
              ),
            ),

            // Middle Section: Tournament Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                tournament.title,
                style: AppTypography.titleMedium.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 8),

            // Organizer Row (Team Name + Verified + Rating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      tournament.displayOrganizerTeam,
                      style: AppTypography.bodySmall.copyWith(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (tournament.isOrganizerVerified) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: primaryAccent,
                    ),
                  ],
                  if (tournament.organizerRating != null &&
                      tournament.organizerRating! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.neonOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppColors.neonOrange,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            tournament.organizerRating!.toStringAsFixed(1),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.neonOrange,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                          if (tournament.organizerReviewCount != null) ...[
                            Text(
                              ' (${tournament.organizerReviewCount})',
                              style: AppTypography.bodySmall.copyWith(
                                color: secondaryTextColor,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Rewards Row: Prize Pool + Optional Per-Kill Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Prize Pool Badge
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.neonOrange.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.neonOrange.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            size: 16,
                            color: AppColors.neonOrange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PRIZE POOL',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.neonOrange,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  tournament.formattedPrizePool,
                                  style: AppTypography.titleSmall.copyWith(
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Per-Kill Reward pill if configured
                  if (tournament.formattedPerKillReward != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primaryAccent.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PER KILL',
                            style: AppTypography.bodySmall.copyWith(
                              color: primaryAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            tournament.formattedPerKillReward!,
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Compact Slot Availability Bar & Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tournament.isLobbyFull
                            ? 'Lobby Full'
                            : '${tournament.availableSlots} of ${tournament.maxParticipants} slots available',
                        style: AppTypography.bodySmall.copyWith(
                          color: tournament.isLobbyFull
                              ? AppColors.warning
                              : secondaryTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${tournament.registeredCount}/${tournament.maxParticipants}',
                        style: AppTypography.bodySmall.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fillPct,
                      minHeight: 5,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceBorder
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Divider(color: dividerColor, height: 1),

            // Bottom Footer: Match Schedule Time + "More Details" Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      formattedTime,
                      style: AppTypography.bodySmall.copyWith(
                        color: secondaryTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // More Details Action Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryAccent.withValues(alpha: isDark ? 0.14 : 0.09),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: primaryAccent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'More Details',
                          style: AppTypography.bodySmall.copyWith(
                            color: primaryAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: primaryAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
