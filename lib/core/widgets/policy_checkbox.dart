import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A reusable mandatory policy acceptance widget with separately clickable links
/// for Terms & Conditions and Privacy Policy.
///
/// Designed to strictly enforce unchecked-by-default behavior and accessible hit testing.
class PolicyAcceptanceCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String termsTitle;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;
  final bool enabled;
  final String? errorText;

  const PolicyAcceptanceCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.termsTitle,
    required this.onTermsTap,
    required this.onPrivacyTap,
    this.enabled = true,
    this.errorText,
  });

  @override
  State<PolicyAcceptanceCheckbox> createState() => _PolicyAcceptanceCheckboxState();
}

class _PolicyAcceptanceCheckboxState extends State<PolicyAcceptanceCheckbox> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTermsTap;
    _privacyRecognizer = TapGestureRecognizer()..onTap = widget.onPrivacyTap;
  }

  @override
  void didUpdateWidget(covariant PolicyAcceptanceCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onTermsTap != widget.onTermsTap) {
      _termsRecognizer.onTap = widget.onTermsTap;
    }
    if (oldWidget.onPrivacyTap != widget.onPrivacyTap) {
      _privacyRecognizer.onTap = widget.onPrivacyTap;
    }
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24.0,
              width: 24.0,
              child: Checkbox(
                key: const ValueKey('policy_checkbox'),
                value: widget.value,
                onChanged: widget.enabled ? widget.onChanged : null,
                activeColor: AppColors.electricBlue,
                checkColor: AppColors.darkBackground,
                side: BorderSide(
                  color: widget.errorText != null
                      ? AppColors.error
                      : (widget.value ? AppColors.electricBlue : AppColors.textSecondary),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: widget.termsTitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.electricBlue,
                        ),
                        recognizer: _termsRecognizer,
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.electricBlue,
                        ),
                        recognizer: _privacyRecognizer,
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Padding(
            padding: const EdgeInsets.only(left: 36.0),
            child: Text(
              widget.errorText!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}

