import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/role_card.dart';

/// Modal bottom sheet allowing new visitors to choose their registration destination.
class RoleSelectionBottomSheet extends StatelessWidget {
  const RoleSelectionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.darkSurfaceBorder, width: 1),
      ),
      builder: (context) => const RoleSelectionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Your Role',
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select an onboarding path to continue',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            RoleCard(
              title: 'Create Player Account',
              subtitle: 'Join tournaments, track scrim stats, and earn rewards',
              icon: Icons.person_outline_rounded,
              isPrimary: true,
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.playerRegister);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            RoleCard(
              title: 'Apply as Tournament Host',
              subtitle: 'Create tournaments, manage brackets, and host scrims',
              icon: Icons.shield_outlined,
              isPrimary: false,
              badge: 'ADMIN APPROVAL REQ.',
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.organizerApply);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'Note: Role selection is an onboarding choice. Organizer privileges are subject to administrator verification.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

