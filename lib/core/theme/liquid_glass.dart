import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable iOS 26-inspired Liquid Glass components.
/// Provides frosted translucent surfaces, subtle gradients, and glowing accents
/// dynamically adapting to both Light and Dark themes.
class LiquidGlass {
  LiquidGlass._();

  /// Primary glass container with backdrop blur and translucent border.
  /// Automatically adapts its translucency, border, and shadows to the active theme.
  static Widget container({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 20.0,
    double blur = 14.0,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 1.0,
    List<BoxShadow>? shadows,
    VoidCallback? onTap,
    Gradient? gradient,
  }) {
    return LiquidGlassContainer(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blur: blur,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      shadows: shadows,
      onTap: onTap,
      gradient: gradient,
      child: child,
    );
  }

  /// Podiums for 1st, 2nd, 3rd ranks in Leaderboard
  static Widget podiumCard({
    required int rank,
    required String name,
    required int score,
    String? avatarUrl,
    required BuildContext context,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color crownColor;
    Color glowColor;
    String rankLabel;

    switch (rank) {
      case 1:
        crownColor = const Color(0xFFFFD700); // Gold
        glowColor = const Color(0xFFFFD700).withValues(alpha: isDark ? 0.35 : 0.20);
        rankLabel = '1st';
        break;
      case 2:
        crownColor = const Color(0xFFC0C0C0); // Silver
        glowColor = const Color(0xFF94A3B8).withValues(alpha: isDark ? 0.30 : 0.18);
        rankLabel = '2nd';
        break;
      case 3:
      default:
        crownColor = const Color(0xFFCD7F32); // Bronze
        glowColor = const Color(0xFFED8936).withValues(alpha: isDark ? 0.30 : 0.18);
        rankLabel = '3rd';
        break;
    }

    final height = rank == 1 ? 160.0 : (rank == 2 ? 140.0 : 130.0);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            glowColor,
                            const Color(0xFF1E1438).withValues(alpha: 0.85),
                          ]
                        : [
                            glowColor,
                            Colors.white.withValues(alpha: 0.95),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: crownColor.withValues(alpha: isDark ? 0.6 : 0.8),
                    width: rank == 1 ? 2.0 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor,
                      blurRadius: rank == 1 ? 18 : 10,
                      spreadRadius: rank == 1 ? 1 : 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: crownColor, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: rank == 1 ? 22 : 18,
                        backgroundColor: crownColor.withValues(alpha: 0.2),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'P',
                          style: TextStyle(
                            color: crownColor,
                            fontWeight: FontWeight.bold,
                            fontSize: rank == 1 ? 18 : 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '$score pts',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: crownColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: crownColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        rankLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: crownColor,
                        ),
                      ),
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

/// Dynamic widget implementation of LiquidGlass container ensuring
/// reactive Light and Dark theme adaptation across the widget hierarchy.
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.blur = 14.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.shadows,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = backgroundColor ??
        (isDark
            ? const Color(0xFF1E1735).withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.85));

    final defaultBorder = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : const Color(0xFF7C3AED).withValues(alpha: 0.18));

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: defaultBg,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: defaultBorder, width: borderWidth),
            boxShadow: shadows ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            child: content,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      child: content,
    );
  }
}
