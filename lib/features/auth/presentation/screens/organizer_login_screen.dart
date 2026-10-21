import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/dev_notice_banner.dart';
import '../../../../core/widgets/status_banner.dart';
import '../controllers/organizer_login_controller.dart';

/// Organizer Login Screen.
class OrganizerLoginScreen extends ConsumerStatefulWidget {
  const OrganizerLoginScreen({super.key});

  @override
  ConsumerState<OrganizerLoginScreen> createState() => _OrganizerLoginScreenState();
}

class _OrganizerLoginScreenState extends ConsumerState<OrganizerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(organizerLoginProvider);
    _emailController = TextEditingController(text: state.email);
    _passwordController = TextEditingController(text: state.password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(organizerLoginProvider.notifier).login();
      if (success && mounted) {
        final state = ref.read(organizerLoginProvider);
        switch (state.destination) {
          case OrganizerLoginDestination.apply:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No organizer application found. Please complete the application to become a verified host.',
                ),
                backgroundColor: AppColors.darkSurfaceElevated,
                duration: Duration(seconds: 4),
              ),
            );
            context.push(AppRoutes.organizerApply);
            break;
          case OrganizerLoginDestination.pendingReview:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Application under review. You can check current verification status here.',
                ),
                backgroundColor: AppColors.darkSurfaceElevated,
                duration: Duration(seconds: 3),
              ),
            );
            context.push(AppRoutes.organizerStatus);
            break;
          case OrganizerLoginDestination.rejected:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Application not approved. View the review notes to resubmit.',
                ),
                backgroundColor: AppColors.errorDim,
                duration: Duration(seconds: 4),
              ),
            );
            context.push(AppRoutes.organizerStatus);
            break;
          case OrganizerLoginDestination.approved:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Organizer credentials verified.'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );
            context.push(AppRoutes.organizerStatus);
            break;
          case OrganizerLoginDestination.error:
          case null:
            break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(organizerLoginProvider);
    final notifier = ref.read(organizerLoginProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Organizer Portal'),
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
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DevNoticeBanner(
                      featureName: 'Organizer Authentication',
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Tournament Organizer Portal',
                      style: AppTypography.displayMedium.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Host brackets, verify player submissions, and broadcast scrims',
                      style: AppTypography.bodyMedium,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    if (state.errorMessage != null) ...[
                      StatusBanner(
                        title: 'Authentication Error',
                        message: state.errorMessage,
                        type: StatusBannerType.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (state.statusNotice != null) ...[
                      StatusBanner(
                        title: 'Verification In Progress',
                        message: state.statusNotice,
                        type: StatusBannerType.info,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Email Address
                    AppTextField(
                      controller: _emailController,
                      label: 'Organizer Email',
                      hint: 'host@organization.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.email,
                      onChanged: notifier.updateEmail,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Password
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                      onChanged: notifier.updatePassword,
                      onEditingComplete: _handleLogin,
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        child: Text(
                          'Forgot Password?',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.electricBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Login Button
                    AppButton(
                      text: 'Sign In as Organizer',
                      isLoading: state.isLoading,
                      onPressed: _handleLogin,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Divider(color: AppColors.darkSurfaceBorder),

                    const SizedBox(height: AppSpacing.md),

                    // Apply to Become an Organizer Button
                    AppButton.secondary(
                      text: 'Apply to Become an Organizer',
                      icon: Icons.assignment_ind_outlined,
                      onPressed: () => context.push(AppRoutes.organizerApply),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Check Status Button (for applicants who already applied)
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.track_changes_rounded, size: 16),
                        label: const Text('Check Existing Application Status'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        onPressed: () => context.push(AppRoutes.organizerStatus),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

