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
import '../../../../core/widgets/status_banner.dart';
import '../controllers/player_login_controller.dart';
import '../widgets/auth_layout.dart';
import '../widgets/google_sign_in_button.dart';

/// Redesigned Player Login Screen with Karta Organize esports branding.
///
/// Implements:
/// - Light & dark theme support with deep purple primary accent (#7C3AED)
/// - Responsive AuthLayout with theme toggle and trophy mark
/// - Heading: "Welcome back" & "Sign in to continue your tournament journey."
/// - Email & Password with show/hide toggle
/// - Forgot Password link
/// - Primary Log In button
/// - "OR CONTINUE WITH" divider
/// - Brand-compliant Google Sign-In with official 4-color Google G logo
/// - Link: "New to Karta? Create an account"
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

  void _onLoginSuccess() {
    if (!mounted) return;
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
      final name = state.userProfile?.displayName ?? 'Player';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, $name! Authenticated successfully.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    context.go(AppRoutes.playerDashboard);
  }

  void _handleEmailLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(playerLoginProvider.notifier).login();
      if (success && mounted) {
        _onLoginSuccess();
      }
    }
  }

  void _handleGoogleLogin() async {
    final success = await ref.read(playerLoginProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      _onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerLoginProvider);
    final notifier = ref.read(playerLoginProvider.notifier);
    final isDark = context.isDarkMode;
    final dividerColor = isDark ? AppColors.darkSurfaceBorder : const Color(0xFFE2E8F0);
    final mutedTextColor = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return AuthLayout(
      title: 'Welcome back',
      subtitle: 'Sign in to continue your tournament journey.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner
            if (state.errorMessage != null) ...[
              StatusBanner(
                title: 'Authentication Error',
                message: state.errorMessage,
                type: StatusBannerType.error,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Success / verification banner
            if (state.successMessage != null && state.errorMessage == null) ...[
              StatusBanner(
                title: 'Success',
                message: state.successMessage,
                type: StatusBannerType.success,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Email Field
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

            // Password Field with Show/Hide Toggle
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
              onEditingComplete: _handleEmailLogin,
            ),
            const SizedBox(height: AppSpacing.xs),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.forgotPassword),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Primary Log In Button
            AppButton(
              text: 'Log In',
              isLoading: state.isLoading,
              onPressed: _handleEmailLogin,
            ),
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
              onPressed: _handleGoogleLogin,
              isLoading: state.isGoogleLoading,
              text: 'Continue with Google',
            ),
            const SizedBox(height: AppSpacing.xl),

            // Link: New to Karta? Create an account
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'New to Karta? ',
                    style: AppTypography.bodyMedium.copyWith(
                      color: mutedTextColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.playerRegister),
                    child: Text(
                      'Create an account',
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
            const SizedBox(height: AppSpacing.md),

            // Organizer Link
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.shield_outlined, size: 16),
                label: const Text('Organizer Portal & Host Sign-In'),
                style: TextButton.styleFrom(
                  foregroundColor: mutedTextColor,
                  textStyle: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => context.push(AppRoutes.organizerLogin),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
