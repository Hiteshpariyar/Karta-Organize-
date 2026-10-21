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
import '../controllers/player_login_controller.dart';

/// Player Login Screen for competitive participants.
class PlayerLoginScreen extends ConsumerStatefulWidget {
  const PlayerLoginScreen({super.key});

  @override
  ConsumerState<PlayerLoginScreen> createState() => _PlayerLoginScreenState();
}

class _PlayerLoginScreenState extends ConsumerState<PlayerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(playerLoginProvider);
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
      final success = await ref.read(playerLoginProvider.notifier).login();
      if (success && mounted) {
        final state = ref.read(playerLoginProvider);
        if (state.isEmailUnverified) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Please verify your email address to access competitive match rooms.',
              ),
              backgroundColor: AppColors.warning,
              action: SnackBarAction(
                label: 'Resend Link',
                textColor: Colors.white,
                onPressed: () {
                  ref.read(playerLoginProvider.notifier).sendVerificationEmail();
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome back, ${state.userProfile?.displayName ?? 'Player'}! Authenticated successfully.',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        context.go(AppRoutes.playerDashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerLoginProvider);
    final notifier = ref.read(playerLoginProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Player Login'),
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
                      featureName: 'Player Authentication',
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Welcome Back, Player',
                      style: AppTypography.displayMedium.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Sign in to join match rooms and tournaments',
                      style: AppTypography.bodyMedium,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    if (state.errorMessage != null) ...[
                      StatusBanner(
                        title: 'Login Error',
                        message: state.errorMessage,
                        type: StatusBannerType.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (state.successMessage != null) ...[
                      StatusBanner(
                        title: 'Validation Notice',
                        message: state.successMessage,
                        type: StatusBannerType.info,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

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
                      text: 'Sign In as Player',
                      isLoading: state.isLoading,
                      onPressed: _handleLogin,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Create Player Account Link
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: AppTypography.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.playerRegister),
                            child: Text(
                              'Register as Player',
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
