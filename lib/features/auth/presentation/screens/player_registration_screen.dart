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
import '../../../../core/widgets/policy_checkbox.dart';
import '../../../../core/widgets/status_banner.dart';
import '../controllers/player_registration_controller.dart';
import '../widgets/auth_layout.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/password_requirements_widget.dart';

/// Redesigned Registration Screen with Karta Organize esports branding.
///
/// Implements:
/// - Heading: "Create your account" & "Join the arena and compete in community tournaments."
/// - Full Name, Email, Password & Confirm Password
/// - Live password strength / requirements indicator checklist
/// - Account Type / Role explainer (Player vs Organizer application gating)
/// - Mandatory Terms & Conditions + Privacy Policy consent
/// - Primary "Create Account" button
/// - "OR CONTINUE WITH" divider
/// - Official Google Sign-In button
/// - "Already have an account? Log In" navigation
class PlayerRegistrationScreen extends ConsumerStatefulWidget {
  const PlayerRegistrationScreen({super.key});

  @override
  ConsumerState<PlayerRegistrationScreen> createState() =>
      _PlayerRegistrationScreenState();
}

class _PlayerRegistrationScreenState
    extends ConsumerState<PlayerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(playerRegistrationProvider);
    _nameController = TextEditingController(text: state.fullName);
    _emailController = TextEditingController(text: state.email);
    _passwordController = TextEditingController(text: state.password);
    _confirmPasswordController = TextEditingController(text: state.confirmPassword);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      final notifier = ref.read(playerRegistrationProvider.notifier);
      final success = await notifier.register();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account registered successfully! A verification email has been dispatched.',
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
        context.go(AppRoutes.playerLogin);
      }
    }
  }

  void _handleGoogleSignUp() async {
    final notifier = ref.read(playerRegistrationProvider.notifier);
    final success = await notifier.signInWithGoogle();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created with Google! Welcome to Karta Organize.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      context.go(AppRoutes.playerDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerRegistrationProvider);
    final notifier = ref.read(playerRegistrationProvider.notifier);
    final isDark = context.isDarkMode;
    final dividerColor = isDark ? AppColors.darkSurfaceBorder : const Color(0xFFE2E8F0);
    final mutedTextColor = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final surfaceElevated = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9);

    return AuthLayout(
      title: 'Create your account',
      subtitle: 'Join the arena and compete in community tournaments.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner
            if (state.errorMessage != null) ...[
              StatusBanner(
                title: 'Registration Error',
                message: state.errorMessage,
                type: StatusBannerType.error,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Success banner
            if (state.successMessage != null && state.errorMessage == null) ...[
              StatusBanner(
                title: 'Success',
                message: state.successMessage,
                type: StatusBannerType.success,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Account Type Informational Box (Player vs Organizer)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryPurple.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.sports_esports_rounded,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Player Account',
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.themeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Want to host tournaments? Create your player account first, then submit an Organizer Application for administrative verification.',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: mutedTextColor,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Full Name Field
            AppTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'John Doe',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (val) => FormValidators.required(val, fieldName: 'Full Name'),
              onChanged: notifier.updateFullName,
            ),
            const SizedBox(height: AppSpacing.md),

            // Email Address Field
            AppTextField(
              controller: _emailController,
              label: 'Email address',
              hint: 'player@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: FormValidators.email,
              onChanged: notifier.updateEmail,
            ),
            const SizedBox(height: AppSpacing.md),

            // Password Field
            AppTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Create a strong password',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              textInputAction: TextInputAction.next,
              validator: FormValidators.password,
              onChanged: (val) {
                notifier.updatePassword(val);
                setState(() {}); // Trigger live requirements update
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Live Password Requirements Checklist
            PasswordRequirementsWidget(
              password: state.password,
            ),
            const SizedBox(height: AppSpacing.md),

            // Confirm Password Field
            AppTextField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              hint: 'Re-enter your password',
              prefixIcon: Icons.lock_reset_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: (val) => FormValidators.confirmPassword(val, state.password),
              onChanged: notifier.updateConfirmPassword,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Mandatory Policy Acceptance Checkbox
            PolicyAcceptanceCheckbox(
              value: state.policyAccepted,
              onChanged: notifier.togglePolicyAccepted,
              termsTitle: 'Player Terms & Conditions',
              onTermsTap: () => context.push(AppRoutes.playerTerms),
              onPrivacyTap: () => context.push(AppRoutes.privacyPolicy),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Primary Create Account Button
            AppButton(
              text: 'Create Account',
              isLoading: state.isLoading,
              onPressed: state.isFormValid ? _handleRegister : null,
            ),

            if (state.requiresProfileSetup) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(
                text: 'Retry Profile Initialization',
                icon: Icons.refresh_rounded,
                isLoading: state.isLoading,
                onPressed: () async {
                  final recovered = await notifier.retryProfileCreation();
                  if (recovered && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Profile successfully initialized. You can now sign in.',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.go(AppRoutes.playerLogin);
                  }
                },
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Divider: OR CONTINUE WITH
            Row(
              children: [
                Expanded(child: Divider(color: dividerColor, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: AppTypography.bodySmall.copyWith(
                      color: mutedTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: dividerColor, thickness: 1)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Google Sign-In Button with Official Google Brand Asset
            GoogleSignInButton(
              onPressed: _handleGoogleSignUp,
              isLoading: state.isGoogleLoading,
              text: 'Sign up with Google',
            ),
            const SizedBox(height: AppSpacing.xl),

            // Link: Already have an account? Log In
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTypography.bodyMedium.copyWith(
                      color: mutedTextColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.playerLogin),
                    child: Text(
                      'Log In',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                'v2.0 • Karta Organize',
                style: TextStyle(
                  color: mutedTextColor.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
