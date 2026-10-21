import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/dev_notice_banner.dart';
import '../../../../core/widgets/status_banner.dart';
import '../controllers/forgot_password_controller.dart';

/// Password Reset Request Screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(forgotPasswordProvider);
    _emailController = TextEditingController(text: state.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(forgotPasswordProvider.notifier).sendResetLink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);
    final notifier = ref.read(forgotPasswordProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Reset Password'),
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
                      featureName: 'Password Recovery',
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Recover Your Account',
                      style: AppTypography.displayMedium.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Enter your registered email address and we will dispatch a secure password reset link.',
                      style: AppTypography.bodyMedium,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    if (state.errorMessage != null) ...[
                      StatusBanner(
                        title: 'Reset Error',
                        message: state.errorMessage,
                        type: StatusBannerType.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (state.successMessage != null) ...[
                      StatusBanner(
                        title: 'Request Dispatched',
                        message: state.successMessage,
                        type: StatusBannerType.success,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    AppTextField(
                      controller: _emailController,
                      label: 'Registered Email Address',
                      hint: 'name@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: FormValidators.email,
                      onChanged: notifier.updateEmail,
                      onEditingComplete: _handleSubmit,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    AppButton(
                      text: 'Send Reset Link',
                      isLoading: state.isLoading,
                      onPressed: _handleSubmit,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    AppButton.secondary(
                      text: 'Return to Login',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
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

