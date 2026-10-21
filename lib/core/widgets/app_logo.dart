import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Stylized esports logo badge for TourneyZone.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String appName;

  const AppLogo({
    super.key,
    this.size = 64.0,
    this.showText = true,
    this.appName = 'TourneyZone',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF0052D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricBlue.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer border ring
              Container(
                margin: EdgeInsets.all(size * 0.08),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              Icon(
                Icons.sports_esports_rounded,
                size: size * 0.55,
                color: Colors.white,
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            appName,
            style: AppTypography.displayLarge.copyWith(
              fontSize: 28,
              letterSpacing: -0.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

