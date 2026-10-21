import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum StatusBannerType {
  info,
  warning,
  error,
  success,
}

/// A clean status banner widget to display operational notices, warnings,
/// and approval messages.
class StatusBanner extends StatelessWidget {
  final String title;
  final String? message;
  final StatusBannerType type;
  final IconData? icon;

  const StatusBanner({
    super.key,
    required this.title,
    this.message,
    this.type = StatusBannerType.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color primaryColor;
    Color backgroundColor;
    IconData defaultIcon;

    switch (type) {
      case StatusBannerType.info:
        primaryColor = AppColors.info;
        backgroundColor = AppColors.infoDim;
        defaultIcon = Icons.info_outline_rounded;
        break;
      case StatusBannerType.warning:
        primaryColor = AppColors.warning;
        backgroundColor = AppColors.warningDim;
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case StatusBannerType.error:
        primaryColor = AppColors.error;
        backgroundColor = AppColors.errorDim;
        defaultIcon = Icons.error_outline_rounded;
        break;
      case StatusBannerType.success:
        primaryColor = AppColors.success;
        backgroundColor = AppColors.successDim;
        defaultIcon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? defaultIcon,
            color: primaryColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    message!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

