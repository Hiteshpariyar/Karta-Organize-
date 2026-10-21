import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A transparent notice banner that accurately declares the Phase 1 development state.
///
/// Prevents false claims that live authentication or data persistence has occurred.
class DevNoticeBanner extends StatelessWidget {
  final String featureName;
  final String note;

  const DevNoticeBanner({
    super.key,
    required this.featureName,
    this.note = 'Phase 1 UI Sandbox: Validated locally. Backend services (Firebase Auth / Firestore) will be integrated in Phase 2.',
  });

  @override
  Widget build(BuildContext context) {
    if (AppConfig.isBackendConnected) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFF141F33),
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.developer_mode_rounded,
            color: AppColors.electricBlue,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '[$featureName] ',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.electricBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: note,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

