import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/tournament.dart';

class TournamentStatusBadge extends StatelessWidget {
  final TournamentStatus status;

  const TournamentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
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
        bg = AppColors.electricBlueDim;
        border = AppColors.electricBlue.withValues(alpha: 0.4);
        text = AppColors.electricBlue;
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
        bg = AppColors.darkSurfaceBorderSubtle;
        border = AppColors.textMuted.withValues(alpha: 0.3);
        text = AppColors.textSecondary;
        icon = Icons.emoji_events_rounded;
        break;
      case TournamentStatus.cancelled:
        bg = AppColors.errorDim;
        border = AppColors.error.withValues(alpha: 0.3);
        text = AppColors.textMuted;
        icon = Icons.cancel_outlined;
        break;
      case TournamentStatus.registrationClosed:
        bg = AppColors.darkSurfaceBorder;
        border = AppColors.textMuted.withValues(alpha: 0.3);
        text = AppColors.textSecondary;
        icon = Icons.lock_clock_rounded;
        break;
      case TournamentStatus.draft:
        bg = AppColors.darkSurfaceBorder;
        border = AppColors.darkSurfaceBorder;
        text = AppColors.textMuted;
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
    final isFree = entryType == EntryType.free || entryFee == 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFree
            ? AppColors.electricBlueDim
            : AppColors.neonOrangeDim,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isFree
              ? AppColors.electricBlue.withValues(alpha: 0.4)
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
            color: isFree ? AppColors.electricBlue : AppColors.neonOrange,
          ),
          const SizedBox(width: 4),
          Text(
            isFree ? 'FREE ENTRY' : 'PAID (COMING SOON)',
            style: AppTypography.bodySmall.copyWith(
              color: isFree ? AppColors.electricBlue : AppColors.neonOrange,
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
