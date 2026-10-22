import 'package:flutter/material.dart';
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
    this.appName = 'Karta Organize',
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
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset(
              'assets/icons/app_logo.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(size * 0.28),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: size * 0.55,
                  color: Colors.white,
                ),
              ),
            ),
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

