import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Interactive role card used on the Welcome screen for selecting
/// between Player and Organizer paths.
class RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final String? badge;

  const RoleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isPrimary = true,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isPrimary ? AppColors.electricBlue : AppColors.fieryOrange;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.roundedLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedLg,
          splashColor: accentColor.withValues(alpha: 0.12),
          highlightColor: accentColor.withValues(alpha: 0.06),
          child: Ink(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? const LinearGradient(
                      colors: [Color(0xFF132238), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF24181B), Color(0xFF161824)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(
                color: isPrimary ? AppColors.electricBlueBorder : AppColors.fieryOrangeBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.fieryOrangeDim,
                                borderRadius: AppSpacing.roundedXs,
                                border: Border.all(
                                  color: AppColors.fieryOrangeBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                badge!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.fieryOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

