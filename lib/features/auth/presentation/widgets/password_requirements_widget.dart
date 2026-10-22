import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Interactive password requirements checklist and strength meter.
///
/// Validates:
/// 1. At least 8 characters
/// 2. Contains uppercase letter (A-Z)
/// 3. Contains lowercase letter (a-z)
/// 4. Contains a numeric digit (0-9)
/// 5. Contains a special character (!@#$%^&*...)
class PasswordRequirementsWidget extends StatelessWidget {
  final String password;

  const PasswordRequirementsWidget({
    super.key,
    required this.password,
  });

  bool get hasMinLength => password.length >= 8;
  bool get hasUppercase => RegExp(r'[A-Z]').hasMatch(password);
  bool get hasLowercase => RegExp(r'[a-z]').hasMatch(password);
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(password);
  bool get hasSpecialChar => RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password);

  int get metCount {
    int count = 0;
    if (hasMinLength) count++;
    if (hasUppercase) count++;
    if (hasLowercase) count++;
    if (hasNumber) count++;
    if (hasSpecialChar) count++;
    return count;
  }

  double get strengthFraction => metCount / 5.0;

  String get strengthLabel {
    if (password.isEmpty) return 'Enter a password';
    if (metCount <= 2) return 'Weak';
    if (metCount <= 4) return 'Medium';
    return 'Strong';
  }

  Color get strengthColor {
    if (password.isEmpty) return Colors.grey;
    if (metCount <= 2) return AppColors.error;
    if (metCount <= 4) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final mutedColor = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar & label
        if (password.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password strength:',
                style: AppTypography.bodySmall.copyWith(
                  color: mutedColor,
                  fontSize: 12,
                ),
              ),
              Text(
                strengthLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: strengthColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strengthFraction,
              minHeight: 4,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Requirements list
        _buildRequirementItem(
          label: 'At least 8 characters',
          isMet: hasMinLength,
          context: context,
        ),
        const SizedBox(height: 4),
        _buildRequirementItem(
          label: 'At least one uppercase letter (A-Z)',
          isMet: hasUppercase,
          context: context,
        ),
        const SizedBox(height: 4),
        _buildRequirementItem(
          label: 'At least one lowercase letter (a-z)',
          isMet: hasLowercase,
          context: context,
        ),
        const SizedBox(height: 4),
        _buildRequirementItem(
          label: 'At least one number (0-9)',
          isMet: hasNumber,
          context: context,
        ),
        const SizedBox(height: 4),
        _buildRequirementItem(
          label: 'At least one special symbol (!@#\$%^&*)',
          isMet: hasSpecialChar,
          context: context,
        ),
      ],
    );
  }

  Widget _buildRequirementItem({
    required String label,
    required bool isMet,
    required BuildContext context,
  }) {
    final isDark = context.isDarkMode;
    final color = isMet
        ? AppColors.success
        : (isDark ? AppColors.textMuted : AppColors.lightTextMuted);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMet ? AppColors.successDim : Colors.transparent,
            border: Border.all(
              color: isMet ? AppColors.success : color.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Icon(
              isMet ? Icons.check_rounded : Icons.circle,
              size: isMet ? 12 : 5,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

