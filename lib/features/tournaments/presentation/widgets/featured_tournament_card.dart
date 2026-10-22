import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/tournament.dart';
import 'tournament_status_badge.dart';

/// Featured hero tournament card displayed on the Player Dashboard.
/// Follows modern Liquid Glass styling with prominent rewards and slot tracking.
class FeaturedTournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const FeaturedTournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.surfaceOf(context);
    final primaryAccent = isDark ? AppColors.electricBlue : const Color(0xFF7C3AED);
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

    final fillPct = tournament.slotFillPercentage;
    final Color progressColor = tournament.isLobbyFull
        ? AppColors.warning
        : (fillPct >= 0.75 ? AppColors.neonOrange : AppColors.success);

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedLg,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppSpacing.roundedLg,
          border: Border.all(
            color: primaryAccent.withValues(alpha: isDark ? 0.45 : 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryAccent.withValues(alpha: isDark ? 0.18 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: primaryAccent),
                  const SizedBox(width: 6),
                  Text(
                    'FEATURED TOURNAMENT',
                    style: AppTypography.bodySmall.copyWith(
                      color: primaryAccent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      fontSize: 10,
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

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game Name + Mode
                  Row(
                    children: [
                      Text(
                        tournament.gameName,
                        style: AppTypography.bodySmall.copyWith(
                          color: primaryAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if (tournament.mode != null && tournament.mode!.isNotEmpty) ...[
                        Text(
                          ' • ${tournament.mode}',
                          style: AppTypography.bodySmall.copyWith(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Tournament Title
                  Text(
                    tournament.title,
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Organizer Details
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: secondaryTextColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tournament.displayOrganizerTeam,
                          style: AppTypography.bodySmall.copyWith(
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tournament.isOrganizerVerified) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified_rounded, size: 14, color: primaryAccent),
                      ],
                      if (tournament.organizerRating != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded, size: 13, color: AppColors.neonOrange),
                        const SizedBox(width: 2),
                        Text(
                          tournament.organizerRating!.toStringAsFixed(1),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.neonOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Prize Pool & Per-Kill Reward Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.neonOrange.withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.neonOrange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, size: 20, color: AppColors.neonOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL PRIZE POOL',
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
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (tournament.formattedPerKillReward != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: isDark ? 0.18 : 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tournament.formattedPerKillReward!,
                              style: AppTypography.bodySmall.copyWith(
                                color: primaryAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Slot Availability Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tournament.isLobbyFull
                            ? 'Lobby Full'
                            : '${tournament.availableSlots} slots remaining',
                        style: AppTypography.bodySmall.copyWith(
                          color: tournament.isLobbyFull ? AppColors.warning : secondaryTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${tournament.registeredCount}/${tournament.maxParticipants} Slots',
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

                  const SizedBox(height: 14),

                  // Match Schedule & Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: secondaryTextColor),
                          const SizedBox(width: 5),
                          Text(
                            formattedTime,
                            style: AppTypography.bodySmall.copyWith(
                              color: secondaryTextColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onTap,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10),
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
  }
}
