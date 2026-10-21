import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/role_card.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/role_selection_dialog.dart';

/// The initial welcome / entry screen for TourneyZone.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  void _checkAndRedirect(UserProfile? user) {
    if (user != null && mounted) {
      if (user.isOrganizer) {
        context.go(AppRoutes.organizerStatus);
      } else {
        context.go(AppRoutes.playerDashboard);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.playerTerms);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.privacyPolicy);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProfileProvider);
      _checkAndRedirect(user);
    });
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserProfile?>(currentUserProfileProvider, (prev, next) {
      if (prev == null && next != null) {
        _checkAndRedirect(next);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // App Logo & Branding
                  const AppLogo(
                    size: 80,
                    showText: true,
                    appName: AppConfig.appName,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Heading & Subtitle
                  Text(
                    'Welcome Back',
                    style: AppTypography.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppConfig.appTagline,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Authenticated Session Bar (Phase 2 Session Management)
                  Builder(
                    builder: (context) {
                      final currentUser = ref.watch(currentUserProfileProvider);
                      if (currentUser == null) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: AppColors.electricBlueBorder),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.electricBlue.withValues(alpha: 0.2),
                              child: Text(
                                currentUser.displayName.isNotEmpty
                                    ? currentUser.displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: AppColors.electricBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentUser.displayName.isNotEmpty
                                        ? currentUser.displayName
                                        : currentUser.email,
                                    style: AppTypography.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Role: ${currentUser.role.value.toUpperCase()} • ${currentUser.accountStatus.value}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.logout_rounded,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              tooltip: 'Sign Out',
                              onPressed: () async {
                                await ref.read(authRepositoryProvider).signOut();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Signed out successfully.'),
                                      backgroundColor: AppColors.darkSurfaceElevated,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Primary Card: Continue as Player
                  RoleCard(
                    title: 'Continue as Player',
                    subtitle: 'Access tournaments, custom rooms, and stats',
                    icon: Icons.sports_esports_outlined,
                    isPrimary: true,
                    onTap: () {
                      final user = ref.read(currentUserProfileProvider);
                      if (user != null && user.isPlayer) {
                        context.push(AppRoutes.playerDashboard);
                      } else {
                        context.push(AppRoutes.playerLogin);
                      }
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Secondary Card: Continue as Organizer
                  RoleCard(
                    title: 'Continue as Organizer',
                    subtitle: 'Manage scrims, publish brackets, and view status',
                    icon: Icons.shield_outlined,
                    isPrimary: false,
                    badge: 'HOST',
                    onTap: () => context.push(AppRoutes.organizerLogin),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // New here? Create an account link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New here? ',
                        style: AppTypography.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => RoleSelectionBottomSheet.show(context),
                        child: Text(
                          'Create an account',
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

                  const SizedBox(height: AppSpacing.xxl),

                  // Legal Links Footer
                  Text.rich(
                    TextSpan(
                      text: 'By continuing, you acknowledge our\n',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: _termsRecognizer,
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: _privacyRecognizer,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

