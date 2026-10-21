import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supported_games.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_banner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../controllers/profile_controller.dart';

class PlayerProfileScreen extends ConsumerStatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  ConsumerState<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showEditGameUidDialog(String gameId, String gameName, String currentVal) {
    final controller = TextEditingController(text: currentVal);
    final gameConfig = SupportedGamesConfig.findById(gameId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkSurfaceBorder),
        ),
        title: Text('Edit $gameName UID', style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gameConfig?.uidLabel ?? 'In-Game Character ID / UID',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: gameConfig?.placeholderUid ?? 'e.g. 5123456789',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.darkSurfaceBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              ref.read(profileProvider.notifier).updateGameUid(gameId, controller.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Save UID'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkSurfaceBorder),
        ),
        title: const Text('Confirm Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out of TourneyZone?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authRepositoryProvider).signOut();
              if (mounted) {
                context.go(AppRoutes.welcome);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final profileState = ref.watch(profileProvider);
    final profileNotifier = ref.read(profileProvider.notifier);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: AppButton(
            text: 'Sign In to View Profile',
            onPressed: () => context.go(AppRoutes.playerLogin),
          ),
        ),
      );
    }

    if (_nameController.text != profileState.displayName && !profileState.isLoading) {
      _nameController.text = profileState.displayName;
    }

    final games = SupportedGamesConfig.games;
    final initials = user.displayName.isNotEmpty
        ? user.displayName.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'P';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Player Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Sign Out',
            onPressed: _confirmSignOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar & Identity Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: AppSpacing.roundedLg,
                        border: Border.all(color: AppColors.darkSurfaceBorder),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.electricBlue.withValues(alpha: 0.2),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: AppColors.electricBlue,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName,
                                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.electricBlueDim,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        user.role.value.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.electricBlue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: user.isSuspended ? AppColors.errorDim : AppColors.successDim,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        user.accountStatus.value.toUpperCase(),
                                        style: TextStyle(
                                          color: user.isSuspended ? AppColors.error : AppColors.success,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    if (profileState.errorMessage != null) ...[
                      StatusBanner(
                        title: 'Update Error',
                        message: profileState.errorMessage,
                        type: StatusBannerType.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (profileState.successMessage != null) ...[
                      StatusBanner(
                        title: 'Success',
                        message: profileState.successMessage,
                        type: StatusBannerType.success,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Edit Display Name
                    Text(
                      'Player Name',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _nameController,
                      label: 'Display Name',
                      prefixIcon: Icons.badge_outlined,
                      onChanged: profileNotifier.updateDisplayName,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Registered In-Game UIDs Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Linked Game UIDs / Character IDs',
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'For Fast Registration',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.darkSurfaceBorder),
                      ),
                      child: Column(
                        children: games.map((game) {
                          final currentUid = profileState.gameUids[game.id] ?? '';
                          return ListTile(
                            leading: const Icon(Icons.sports_esports_rounded, color: AppColors.electricBlue, size: 20),
                            title: Text(
                              game.name.split('(').first.trim(),
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              currentUid.isNotEmpty ? currentUid : 'Not linked yet',
                              style: AppTypography.bodySmall.copyWith(
                                color: currentUid.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.electricBlue),
                              onPressed: () => _showEditGameUidDialog(game.id, game.name, currentUid),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Save Profile Button
                    AppButton(
                      text: 'Save Changes',
                      icon: Icons.check_rounded,
                      isLoading: profileState.isLoading,
                      onPressed: () => profileNotifier.saveProfile(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Shortcuts Section
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.darkSurfaceBorder),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.confirmation_number_outlined, color: AppColors.electricBlue),
                            title: const Text('My Tournaments & Match Passes'),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () => context.push(AppRoutes.myTournaments),
                          ),
                          const Divider(color: AppColors.darkSurfaceBorderSubtle, height: 1),
                          ListTile(
                            leading: const Icon(Icons.notifications_none_rounded, color: AppColors.electricBlue),
                            title: const Text('Notifications & Announcements'),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () => context.push(AppRoutes.notifications),
                          ),
                          const Divider(color: AppColors.darkSurfaceBorderSubtle, height: 1),
                          ListTile(
                            leading: const Icon(Icons.description_outlined, color: AppColors.textSecondary),
                            title: const Text('Player Terms & Conditions'),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () => context.push(AppRoutes.playerTerms),
                          ),
                          const Divider(color: AppColors.darkSurfaceBorderSubtle, height: 1),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondary),
                            title: const Text('Privacy Policy'),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () => context.push(AppRoutes.privacyPolicy),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
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
