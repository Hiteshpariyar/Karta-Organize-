import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  danger,
}

/// A high-performance, accessible esports-themed button supporting primary,
/// secondary, outline, and danger variants with inline loading spinners.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.width = double.infinity,
    this.height = AppSpacing.buttonHeight,
  });

  const AppButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = AppSpacing.buttonHeight,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = AppSpacing.buttonHeight,
  }) : variant = AppButtonVariant.outline;

  const AppButton.danger({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = AppSpacing.buttonHeight,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = isEnabled ? AppColors.electricBlue : AppColors.darkSurfaceBorder;
        foregroundColor = isEnabled ? AppColors.darkBackground : AppColors.textMuted;
        borderSide = null;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = isEnabled ? AppColors.darkSurfaceElevated : AppColors.darkSurface;
        foregroundColor = isEnabled ? AppColors.textPrimary : AppColors.textMuted;
        borderSide = BorderSide(
          color: isEnabled ? AppColors.darkSurfaceBorder : AppColors.darkSurfaceBorderSubtle,
        );
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? AppColors.electricBlue : AppColors.textMuted;
        borderSide = BorderSide(
          color: isEnabled ? AppColors.electricBlueBorder : AppColors.darkSurfaceBorder,
        );
        break;
      case AppButtonVariant.danger:
        backgroundColor = isEnabled ? AppColors.error : AppColors.darkSurfaceBorder;
        foregroundColor = Colors.white;
        borderSide = null;
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: AppTypography.button.copyWith(color: foregroundColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text(
          text,
          style: AppTypography.button.copyWith(color: foregroundColor),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: backgroundColor,
        borderRadius: AppSpacing.roundedMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          splashColor: AppColors.electricBlue.withValues(alpha: 0.15),
          highlightColor: AppColors.electricBlue.withValues(alpha: 0.08),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedMd,
              border: borderSide != null ? Border.fromBorderSide(borderSide) : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
