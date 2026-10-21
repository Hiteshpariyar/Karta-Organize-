import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Reusable layout wrapper for legal policy documents.
class PolicyScaffold extends StatelessWidget {
  final String title;
  final String version;
  final String? subtitle;
  final bool isDraft;
  final List<Widget> children;

  const PolicyScaffold({
    super.key,
    required this.title,
    required this.version,
    this.subtitle,
    this.isDraft = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(title),
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
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header badge and version
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDraft ? AppColors.warningDim : AppColors.electricBlueDim,
                          borderRadius: AppSpacing.roundedXs,
                          border: Border.all(
                            color: isDraft ? AppColors.warning : AppColors.electricBlueBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isDraft ? 'DRAFT POLICY' : 'OFFICIAL POLICY',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDraft ? AppColors.warning : AppColors.electricBlue,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'v$version',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(title, style: AppTypography.displayMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: AppColors.darkSurfaceBorder),
                  const SizedBox(height: AppSpacing.md),

                  // Policy body sections
                  ...children,

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper section heading widget for policy documents.
class PolicySectionHeader extends StatelessWidget {
  final String number;
  final String title;

  const PolicySectionHeader({
    super.key,
    required this.number,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$number. ',
            style: AppTypography.policyHeading.copyWith(
              color: AppColors.electricBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: AppTypography.policyHeading,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper paragraph widget for policy documents.
class PolicyParagraph extends StatelessWidget {
  final String? leadIn;
  final String text;

  const PolicyParagraph({
    super.key,
    this.leadIn,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (leadIn == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(text, style: AppTypography.policyBody),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text.rich(
        TextSpan(
          text: '$leadIn: ',
          style: AppTypography.policyBody.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          children: [
            TextSpan(
              text: text,
              style: AppTypography.policyBody,
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper bullet point widget for policy documents.
class PolicyBulletPoint extends StatelessWidget {
  final String text;

  const PolicyBulletPoint({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0, right: 10.0),
            child: Icon(
              Icons.circle,
              size: 5,
              color: AppColors.electricBlue,
            ),
          ),
          Expanded(
            child: Text(text, style: AppTypography.policyBody),
          ),
        ],
      ),
    );
  }
}

