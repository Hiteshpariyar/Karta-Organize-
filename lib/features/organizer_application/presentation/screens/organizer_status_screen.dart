import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/dev_notice_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/status_banner.dart';
import '../../domain/models/organizer_application.dart';
import '../controllers/organizer_status_controller.dart';

/// Screen displaying the verification state of an organizer application.
///
/// Supports distinct rendering for:
/// - Pending Review
/// - Approved
/// - Rejected
/// - Loading / Verification Failure
class OrganizerStatusScreen extends ConsumerStatefulWidget {
  const OrganizerStatusScreen({super.key});

  @override
  ConsumerState<OrganizerStatusScreen> createState() => _OrganizerStatusScreenState();
}

class _OrganizerStatusScreenState extends ConsumerState<OrganizerStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(organizerStatusProvider.notifier).fetchStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(organizerStatusProvider);
    final notifier = ref.read(organizerStatusProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Application Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => context.go(AppRoutes.welcome),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  const DevNoticeBanner(
                    featureName: 'Organizer Approval State Verification',
                    note:
                        'Phase 1 UI Sandbox: Approval privileges require trusted backend verification. Use the test switcher below to preview all UI states.',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Main Status View Card
                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60.0),
                      child: AppLoadingIndicator(
                        message: 'Checking application status with backend...',
                      ),
                    )
                  else if (state.status == OrganizerApprovalStatus.error)
                    _buildErrorState(state, notifier)
                  else
                    _buildStatusCard(state, notifier),

                  const SizedBox(height: AppSpacing.xxl),

                  // Interactive Dev State Switcher (for QA / Reviewers)
                  _buildDevStateSwitcher(state, notifier),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(OrganizerStatusState state, OrganizerStatusNotifier notifier) {
    switch (state.status) {
      case OrganizerApprovalStatus.pending:
        return _buildPendingState(state, notifier);
      case OrganizerApprovalStatus.approved:
        return _buildApprovedState(state);
      case OrganizerApprovalStatus.rejected:
        return _buildRejectedState(state);
      case OrganizerApprovalStatus.loading:
      case OrganizerApprovalStatus.error:
        return const SizedBox.shrink();
    }
  }

  /// 1. Pending Review State
  Widget _buildPendingState(OrganizerStatusState state, OrganizerStatusNotifier notifier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: AppColors.statusPending.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.statusPending.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningDim,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.statusPending.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              size: 40,
              color: AppColors.statusPending,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your Application Is Under Review',
            style: AppTypography.titleLarge.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your organizer application is awaiting administrator review. You will be able to access organizer features after approval.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.darkSurfaceBorder),
          const SizedBox(height: AppSpacing.md),

          // Status Metadata
          _buildInfoRow('Application Status', 'Pending', color: AppColors.statusPending),
          if (state.referenceId != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildInfoRow('Submission Reference', state.referenceId!),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Actions
          AppButton(
            text: 'Refresh Status',
            icon: Icons.refresh_rounded,
            isLoading: state.isLoading,
            onPressed: () => notifier.fetchStatus(),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            text: 'Return to Login',
            icon: Icons.login_rounded,
            onPressed: () => context.go(AppRoutes.organizerLogin),
          ),
        ],
      ),
    );
  }

  /// 2. Approved State
  Widget _buildApprovedState(OrganizerStatusState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: AppColors.statusApproved.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.statusApproved.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successDim,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.statusApproved.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.verified_rounded,
              size: 40,
              color: AppColors.statusApproved,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Organizer Application Approved',
            style: AppTypography.titleLarge.copyWith(
              fontSize: 20,
              color: AppColors.statusApproved,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Congratulations! Your organization has been verified. You now have permission to create brackets, host match rooms, and manage tournaments.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.darkSurfaceBorder),
          const SizedBox(height: AppSpacing.md),

          _buildInfoRow('Application Status', 'Approved', color: AppColors.statusApproved),
          if (state.referenceId != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildInfoRow('Verified Reference', state.referenceId!),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Dashboard Placeholder Button
          AppButton(
            text: 'Continue to Organizer Dashboard',
            icon: Icons.dashboard_customize_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Organizer Dashboard is scheduled for Phase 2 development after Firebase Firestore integration.',
                  ),
                  backgroundColor: AppColors.darkSurfaceElevated,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 3. Rejected State
  Widget _buildRejectedState(OrganizerStatusState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: AppColors.statusRejected.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.statusRejected.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.errorDim,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.statusRejected.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.cancel_outlined,
              size: 40,
              color: AppColors.statusRejected,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Application Not Approved',
            style: AppTypography.titleLarge.copyWith(
              fontSize: 20,
              color: AppColors.statusRejected,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your organizer application did not pass verification at this time.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          if (state.rejectionReason != null) ...[
            StatusBanner(
              title: 'Reason for Decision',
              message: state.rejectionReason,
              type: StatusBannerType.error,
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          _buildInfoRow('Application Status', 'Not Approved', color: AppColors.statusRejected),
          if (state.referenceId != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildInfoRow('Reference ID', state.referenceId!),
          ],

          const SizedBox(height: AppSpacing.xl),

          AppButton(
            text: 'Edit and Resubmit Application',
            icon: Icons.edit_note_rounded,
            onPressed: () => context.go(AppRoutes.organizerApply),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            text: 'Return to Login',
            onPressed: () => context.go(AppRoutes.organizerLogin),
          ),
        ],
      ),
    );
  }

  /// 4. Loading or Verification Failure State
  Widget _buildErrorState(OrganizerStatusState state, OrganizerStatusNotifier notifier) {
    return EmptyStateWidget(
      icon: Icons.cloud_off_rounded,
      iconColor: AppColors.error,
      title: 'Verification Server Error',
      description: state.errorMessage ??
          'Unable to reach the organizer verification service. Never assume privileges are granted when verification cannot be completed.',
      actionText: 'Retry Verification',
      onAction: () => notifier.fetchStatus(),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Development State Switcher to demonstrate and inspect all required UI states
  Widget _buildDevStateSwitcher(OrganizerStatusState state, OrganizerStatusNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2E),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.darkSurfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 16, color: AppColors.electricBlue),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Phase 1 Reviewer UI State Switcher',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.electricBlue,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Switch between the four mandated states to inspect layout, messages, and action buttons:',
            style: AppTypography.bodySmall.copyWith(fontSize: 11),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8.0,
            runSpacing: 6.0,
            children: [
              _buildStateChip(
                label: 'Pending',
                isSelected: state.status == OrganizerApprovalStatus.pending,
                onTap: () => notifier.switchDemoStatus(OrganizerApprovalStatus.pending),
                color: AppColors.statusPending,
              ),
              _buildStateChip(
                label: 'Approved',
                isSelected: state.status == OrganizerApprovalStatus.approved,
                onTap: () => notifier.switchDemoStatus(OrganizerApprovalStatus.approved),
                color: AppColors.statusApproved,
              ),
              _buildStateChip(
                label: 'Rejected',
                isSelected: state.status == OrganizerApprovalStatus.rejected,
                onTap: () => notifier.switchDemoStatus(OrganizerApprovalStatus.rejected),
                color: AppColors.statusRejected,
              ),
              _buildStateChip(
                label: 'Error / Failure',
                isSelected: state.status == OrganizerApprovalStatus.error,
                onTap: () => notifier.switchDemoStatus(OrganizerApprovalStatus.error),
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isSelected ? color.withValues(alpha: 0.2) : AppColors.darkSurface,
      labelStyle: AppTypography.bodySmall.copyWith(
        color: isSelected ? color : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        fontSize: 11,
      ),
      side: BorderSide(
        color: isSelected ? color : AppColors.darkSurfaceBorder,
        width: 1.0,
      ),
    );
  }
}
