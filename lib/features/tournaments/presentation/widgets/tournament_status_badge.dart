import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/tournament.dart';

class TournamentStatusBadge extends StatelessWidget {
  final TournamentStatus status;

  const TournamentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? AppColors.electricBlue : const Color(0xFF7C3AED);

    Color bg;
    Color border;
    Color text;
    IconData icon;

    switch (status) {
      case TournamentStatus.registrationOpen:
        bg = AppColors.successDim;
        border = AppColors.success.withValues(alpha: 0.4);
        text = AppColors.success;
        icon = Icons.how_to_reg_rounded;
        break;
      case TournamentStatus.upcoming:
        bg = primaryAccent.withValues(alpha: 0.12);
        border = primaryAccent.withValues(alpha: 0.4);
        text = primaryAccent;
        icon = Icons.event_available_rounded;
        break;
      case TournamentStatus.full:
        bg = AppColors.warningDim;
        border = AppColors.warning.withValues(alpha: 0.4);
        text = AppColors.warning;
        icon = Icons.people_alt_rounded;
        break;
      case TournamentStatus.live:
        bg = AppColors.errorDim;
        border = AppColors.error.withValues(alpha: 0.5);
        text = AppColors.error;
        icon = Icons.sensors_rounded;
        break;
      case TournamentStatus.completed:
        bg = isDark ? AppColors.darkSurfaceBorderSubtle : const Color(0xFFF1F5F9);
        border = isDark ? AppColors.textMuted.withValues(alpha: 0.3) : const Color(0xFFCBD5E1);
        text = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
        icon = Icons.emoji_events_rounded;
        break;
      case TournamentStatus.cancelled:
        bg = AppColors.errorDim;
        border = AppColors.error.withValues(alpha: 0.3);
        text = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
        icon = Icons.cancel_outlined;
        break;
      case TournamentStatus.registrationClosed:
        bg = isDark ? AppColors.darkSurfaceBorder : const Color(0xFFF1F5F9);
        border = isDark ? AppColors.textMuted.withValues(alpha: 0.3) : const Color(0xFFCBD5E1);
        text = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
        icon = Icons.lock_clock_rounded;
        break;
      case TournamentStatus.draft:
        bg = isDark ? AppColors.darkSurfaceBorder : const Color(0xFFF1F5F9);
        border = isDark ? AppColors.darkSurfaceBorder : const Color(0xFFCBD5E1);
        text = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
        icon = Icons.edit_note_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: AppTypography.bodySmall.copyWith(
              color: text,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class EntryTypeBadge extends StatelessWidget {
  final EntryType entryType;
  final double entryFee;

  const EntryTypeBadge({
    super.key,
    required this.entryType,
    this.entryFee = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFree = entryType == EntryType.free || entryFee == 0.0;
    final primaryAccent = isDark ? AppColors.electricBlue : const Color(0xFF7C3AED);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFree
            ? primaryAccent.withValues(alpha: 0.12)
            : AppColors.neonOrangeDim,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isFree
              ? primaryAccent.withValues(alpha: 0.4)
              : AppColors.neonOrange.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFree ? Icons.loyalty_rounded : Icons.lock_outline_rounded,
            size: 11,
            color: isFree ? primaryAccent : AppColors.neonOrange,
          ),
          const SizedBox(width: 4),
          Text(
            isFree ? 'FREE' : (entryFee > 0 ? '₹${entryFee.toInt()}' : 'PAID'),
            style: AppTypography.bodySmall.copyWith(
              color: isFree ? primaryAccent : AppColors.neonOrange,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
