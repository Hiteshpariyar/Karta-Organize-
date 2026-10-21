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
import '../../../../core/widgets/policy_checkbox.dart';
import '../../../../core/widgets/status_banner.dart';
import '../controllers/player_registration_controller.dart';

/// Player Account Registration Screen.
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
    // Retrieve preserved state from Riverpod
    final state = ref.read(playerRegistrationProvider);
    _nameController = TextEditingController(text: state.fullName);
    _emailController = TextEditingController(text: state.email);
    _passwordController = TextEditingController(text: state.password);
    _confirmPasswordController =
        TextEditingController(text: state.confirmPassword);
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerRegistrationProvider);
    final notifier = ref.read(playerRegistrationProvider.notifier);

    // Keep text controllers in sync with state if state changes
    if (_nameController.text != state.fullName) {
      _nameController.text = state.fullName;
    }
    if (_emailController.text != state.email) {
      _emailController.text = state.email;
    }
    if (_passwordController.text != state.password) {
      _passwordController.text = state.password;
    }
    if (_confirmPasswordController.text != state.confirmPassword) {
      _confirmPasswordController.text = state.confirmPassword;
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Create Player Account'),
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
                      featureName: 'Player Registration',
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Join the Tournament Arena',
                      style: AppTypography.displayMedium.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Compete against top players and claim tournament glory.',
                      style: AppTypography.bodyMedium,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    if (state.errorMessage != null) ...[
                      StatusBanner(
                        title: 'Registration Error',
                        message: state.errorMessage,
                        type: StatusBannerType.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (state.successMessage != null) ...[
                      StatusBanner(
                        title: 'Validation Successful',
                        message: state.successMessage,
                        type: StatusBannerType.success,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Full Name
                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your real name',
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (val) =>
                          FormValidators.required(val, fieldName: 'Full Name'),
                      onChanged: notifier.updateFullName,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Email Address
                    AppTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'name@example.com',
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
                      hint: 'Minimum 8 characters, letter and number',
                      helperText: 'Must contain at least 8 characters with letters & numbers',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.password,
                      onChanged: notifier.updatePassword,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Confirm Password
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      prefixIcon: Icons.lock_reset_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: (val) => FormValidators.confirmPassword(
                        val,
                        state.password,
                      ),
                      onChanged: notifier.updateConfirmPassword,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Mandatory Terms & Conditions Checkbox
                    PolicyAcceptanceCheckbox(
                      value: state.policyAccepted,
                      onChanged: notifier.togglePolicyAccepted,
                      termsTitle: 'Player Terms & Conditions',
                      onTermsTap: () => context.push(AppRoutes.playerTerms),
                      onPrivacyTap: () => context.push(AppRoutes.privacyPolicy),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Create Account Button (Disabled until form is valid AND checkbox is checked)
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

                    const SizedBox(height: AppSpacing.md),

                    // Already have an account link
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: AppTypography.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.playerLogin),
                            child: Text(
                              'Sign In',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.electricBlue,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.electricBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
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
