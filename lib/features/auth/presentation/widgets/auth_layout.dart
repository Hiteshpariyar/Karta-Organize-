import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_logo.dart';

/// Unified, responsive layout for authentication screens.
///
/// Features:
/// - Karta Organize trophy brand identity
/// - Theme mode toggle (Light / Dark) in the top-right
/// - Optional back button navigation
/// - Centered, responsive constraint box (max 440px)
/// - Clean typography and balanced spacing
class AuthLayout extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBackButton;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final backgroundColor = context.themeBackground;
    final surfaceColor = context.themeSurface;
    final borderColor = context.themeBorder;
    final textPrimary = context.themeTextPrimary;
    final textSecondary = context.themeTextSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar row with Back & Theme Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showBackButton && Navigator.of(context).canPop())
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: textPrimary,
                      ),
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  else
                    const SizedBox(width: 48),
                  // Theme Mode Switcher Button
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: isDark ? const Color(0xFFFBBF24) : AppColors.primaryPurple,
                      size: 22,
                    ),
                    tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
                    onPressed: () {
                      final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                      ref.read(themeModeProvider.notifier).setThemeMode(newMode);
                    },
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Karta Organize Brand Mark
                        const AppLogo(
                          size: 64,
                          showText: true,
                          appName: 'Karta Organize',
                        ),
                        const SizedBox(height: 24),

                        // Form Container / Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: borderColor.withValues(alpha: isDark ? 0.6 : 0.8),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Heading
                              Text(
                                title,
                                style: AppTypography.displayMedium.copyWith(
                                  color: textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Subtitle
                              Text(
                                subtitle,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Form & Content
                              child,
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

