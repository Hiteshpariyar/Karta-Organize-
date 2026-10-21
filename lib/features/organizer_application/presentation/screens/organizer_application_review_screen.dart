import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/dev_notice_banner.dart';
import '../../../../core/widgets/policy_checkbox.dart';
import '../../../../core/widgets/status_banner.dart';
import '../controllers/organizer_application_controller.dart';
import '../controllers/organizer_status_controller.dart';

/// Screen allowing applicants to review all entered data and provide mandatory
/// policy acceptance before application submission.
class OrganizerApplicationReviewScreen extends ConsumerWidget {
  const OrganizerApplicationReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(organizerApplicationProvider);
    final notifier = ref.read(organizerApplicationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Review Application'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DevNoticeBanner(
                    featureName: 'Organizer Review & Policy Acceptance',
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    'Review & Submit Application',
                    style: AppTypography.displayMedium.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Please verify your personal, organization, and gaming details. Once submitted, administrator approval will be required.',
                    style: AppTypography.bodyMedium,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  if (state.errorMessage != null) ...[
                    StatusBanner(
                      title: 'Submission Error',
                      message: state.errorMessage,
                      type: StatusBannerType.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  if (state.devNoticeMessage != null) ...[
                    StatusBanner(
                      title: 'Application Staged',
                      message: state.devNoticeMessage,
                      type: StatusBannerType.success,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // SUMMARY CARD 1: Personal & Organization
                  _buildSummaryCard(
                    title: 'Personal & Organization Details',
                    icon: Icons.person_outline_rounded,
                    onEdit: () => Navigator.of(context).maybePop(),
                    items: [
                      _SummaryRow(label: 'Applicant Name', value: state.name),
                      _SummaryRow(label: 'Organization', value: state.organizationName),
                      _SummaryRow(label: 'Contact Email', value: state.email),
                      _SummaryRow(
                        label: 'Phone Number',
                        value: '${state.countryCode} ${state.phone}',
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // SUMMARY CARD 2: Gaming Information
                  _buildSummaryCard(
                    title: 'Gaming & Identity Details',
                    icon: Icons.sports_esports_outlined,
                    onEdit: () => Navigator.of(context).maybePop(),
                    items: [
                      _SummaryRow(label: 'In-Game UID', value: state.inGameUid),
                      _SummaryRow(
                        label: 'Games You Host',
                        value: state.selectedGames.isEmpty
                            ? 'None Selected'
                            : state.selectedGames.join(', '),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // SUMMARY CARD 3: Tournament Preferences
                  _buildSummaryCard(
                    title: 'Tournament Preference',
                    icon: Icons.tune_rounded,
                    onEdit: () => Navigator.of(context).maybePop(),
                    items: [
                      _SummaryRow(
                        label: 'Tournament Format',
                        value: state.tournamentPreference.label,
                      ),
                      const _SummaryRow(
                        label: 'Paid Tournament Status',
                        value: 'Inactive in Phase 1 (Subject to legal compliance)',
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Mandatory Organizer Policy Checkbox
                  Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(
                        color: state.policyAccepted
                            ? AppColors.electricBlueBorder
                            : AppColors.darkSurfaceBorder,
                      ),
                    ),
                    child: PolicyAcceptanceCheckbox(
                      value: state.policyAccepted,
                      onChanged: notifier.togglePolicyAccepted,
                      termsTitle: 'Organizer Terms & Conditions',
                      onTermsTap: () => context.push(AppRoutes.organizerTerms),
                      onPrivacyTap: () => context.push(AppRoutes.privacyPolicy),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Submit Application Button (Disabled until valid & checkbox checked)
                  AppButton(
                    text: 'Submit Application',
                    icon: Icons.send_rounded,
                    isLoading: state.isLoading,
                    onPressed: state.isReviewSubmissionValid
                        ? () async {
                            final success = await notifier.submitApplication();
                            if (success && context.mounted) {
                              // Navigate to Status Screen with reference
                              ref.read(organizerStatusProvider.notifier).fetchStatus(
                                    referenceId: state.submissionReferenceId,
                                  );
                              context.go(AppRoutes.organizerStatus);
                            }
                          }
                        : null,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Edit Application Secondary Button
                  AppButton.secondary(
                    text: 'Edit Application Details',
                    icon: Icons.edit_note_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<_SummaryRow> items,
  }) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.darkSurfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.electricBlue, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                color: AppColors.electricBlue,
                tooltip: 'Edit section',
                onPressed: onEdit,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.darkSurfaceBorderSubtle),
          const SizedBox(height: AppSpacing.sm),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      item.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      item.value.isEmpty ? '—' : item.value,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
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

class _SummaryRow {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});
}

