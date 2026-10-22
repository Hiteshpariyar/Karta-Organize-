import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supported_games.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/liquid_glass.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_banner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../leaderboard/data/repositories/firebase_leaderboard_repository.dart';
import '../../../leaderboard/domain/models/leaderboard_entry.dart';
import '../../../tournaments/presentation/providers/tournament_providers.dart';
import '../controllers/profile_controller.dart';

final _userRankFutureProvider = FutureProvider.family<LeaderboardEntry?, String>((ref, uid) async {
  return FirebaseLeaderboardRepository().getUserRank(uid);
});

class PlayerProfileScreen extends ConsumerStatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  ConsumerState<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.displayName);
    _phoneController = TextEditingController(
      text: (profile.phoneNumber ?? '').replaceAll('+91', ''),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showEditGameUidDialog(String gameId, String gameName, String currentVal) {
    final controller = TextEditingController(text: currentVal);
    final gameConfig = SupportedGamesConfig.findById(gameId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
          ),
        ),
        title: Text(
          'Edit $gameName UID',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gameConfig?.uidLabel ?? 'In-Game Character ID / UID',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: gameConfig?.placeholderUid ?? 'e.g. 5123456789',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(profileProvider.notifier).updateGameUid(gameId, controller.text.trim());
              ref.read(profileProvider.notifier).saveProfile();
              Navigator.of(ctx).pop();
            },
            child: const Text('Save UID'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF7C3AED), size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Karta Organize',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version: 1.0.0+1 (Production Release)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TourneyZone / Karta Organize is a premier esports tournament platform engineered for seamless competitive gaming, transparent leaderboards, and instant player registrations.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '© 2026 Karta Organize. All rights reserved.',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of Karta Organize?',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              ),
            ),
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
                context.go(AppRoutes.playerLogin);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    final passwordController = TextEditingController();
    bool isSubmitting = false;
    String? localError;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Delete Account', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action is irreversible. All your tournament history, ranking stats, and profile records will be permanently erased.',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm password to verify identity:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter account password',
                  errorText: localError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final pwd = passwordController.text.trim();
                      if (pwd.isEmpty) {
                        setDialogState(() => localError = 'Password is required');
                        return;
                      }
                      setDialogState(() {
                        isSubmitting = true;
                        localError = null;
                      });

                      final result = await ref.read(authRepositoryProvider).deleteAccount(password: pwd);

                      if (result.isSuccess) {
                        if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account permanently deleted.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          context.go(AppRoutes.welcome);
                        }
                      } else {
                        setDialogState(() {
                          isSubmitting = false;
                          localError = result.message ?? 'Authentication failed.';
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Permanently Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = const Color(0xFF7C3AED);
    final user = ref.watch(currentUserProfileProvider);
    final profileState = ref.watch(profileProvider);
    final profileNotifier = ref.read(profileProvider.notifier);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: AppButton(
            text: 'Sign In to View Profile',
            onPressed: () => context.go(AppRoutes.playerLogin),
          ),
        ),
      );
    }

    if (_nameController.text != profileState.displayName && !profileState.isLoading && !_isEditingName) {
      _nameController.text = profileState.displayName;
    }

    final registrationsAsync = ref.watch(playerRegistrationsStreamProvider(user.uid));
    final rankAsync = ref.watch(_userRankFutureProvider(user.uid));

    final games = SupportedGamesConfig.games;
    final initials = user.displayName.isNotEmpty
        ? user.displayName.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'P';

    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBorder = isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Player Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About',
            onPressed: _showAboutDialog,
          ),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. PROFILE HEADER
                    LiquidGlass.container(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 22,
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: primaryAccent.withValues(alpha: 0.2),
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: primaryAccent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 26,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: user.isActive ? AppColors.success : AppColors.warning,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkSurface : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    user.isActive ? Icons.check : Icons.hourglass_top,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user.displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isEditingName ? Icons.close : Icons.edit_outlined,
                                        size: 18,
                                        color: primaryAccent,
                                      ),
                                      tooltip: _isEditingName ? 'Cancel' : 'Edit Name',
                                      onPressed: () {
                                        setState(() {
                                          _isEditingName = !_isEditingName;
                                          if (!_isEditingName) {
                                            _nameController.text = user.displayName;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  user.email,
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryAccent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        user.role.value.toUpperCase(),
                                        style: TextStyle(
                                          color: primaryAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (user.isSuspended ? AppColors.error : AppColors.success)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
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

                    if (profileState.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      StatusBanner(
                        title: 'Update Error',
                        message: profileState.errorMessage,
                        type: StatusBannerType.error,
                      ),
                    ],

                    if (profileState.successMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      StatusBanner(
                        title: 'Success',
                        message: profileState.successMessage,
                        type: StatusBannerType.success,
                      ),
                    ],

                    // Inline Edit Name Form (If editing active)
                    if (_isEditingName) ...[
                      const SizedBox(height: AppSpacing.md),
                      LiquidGlass.container(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Player Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppTextField(
                              controller: _nameController,
                              label: 'New Display Name',
                              prefixIcon: Icons.badge_outlined,
                              onChanged: profileNotifier.updateDisplayName,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => setState(() => _isEditingName = false),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    final ok = await profileNotifier.saveProfile();
                                    if (ok && mounted) {
                                      setState(() => _isEditingName = false);
                                    }
                                  },
                                  child: const Text('Save Name'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // B. PLAYER STATISTICS
                    Text(
                      'Competitive Statistics',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    rankAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                        ),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (entry) {
                        final totalTourneys = registrationsAsync.maybeWhen(
                          data: (r) => r.length,
                          orElse: () => 0,
                        );
                        final rankStr = entry != null && entry.rank > 0 ? '#${entry.rank}' : 'Unranked';
                        final wins = entry?.wins ?? 0;
                        final winRate = entry?.winRate ?? 0.0;
                        final points = entry?.score ?? 0;

                        return Row(
                          children: [
                            _buildMetricCard('Tournaments', '$totalTourneys', primaryAccent, isDark),
                            const SizedBox(width: 8),
                            _buildMetricCard('Global Rank', rankStr, Colors.orangeAccent, isDark),
                            const SizedBox(width: 8),
                            _buildMetricCard('Wins', '$wins', Colors.greenAccent, isDark),
                            const SizedBox(width: 8),
                            _buildMetricCard(
                              'Win Rate',
                              '${winRate.toStringAsFixed(0)}%',
                              Colors.blueAccent,
                              isDark,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // C. ACCOUNT INFORMATION & PHONE VERIFICATION
                    Text(
                      'Account & Contact',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Text(
                                  '🇮🇳 +91',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(color: textPrimary),
                                  decoration: InputDecoration(
                                    hintText: '10-digit Phone Number',
                                    filled: true,
                                    fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: cardBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: cardBorder),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    if (val.trim().length == 10) {
                                      profileNotifier.updatePhone('+91${val.trim()}');
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: profileState.phonePrivacy ?? user.phonePrivacy ?? 'friends_only',
                            dropdownColor: cardBg,
                            decoration: const InputDecoration(
                              labelText: 'Phone Visibility Privacy',
                            ),
                            items: const [
                              DropdownMenuItem(value: 'private', child: Text('Private (Only Me)')),
                              DropdownMenuItem(value: 'friends_only', child: Text('Visible to Friends Only')),
                              DropdownMenuItem(value: 'public', child: Text('Public to All Players')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                profileNotifier.updatePhonePrivacy(val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Save Contact & Privacy Settings'),
                              onPressed: () => profileNotifier.saveProfile(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // D. GAMING PROFILE (Linked Game UIDs)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Linked Game UIDs / In-Game Names',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Fast Auto-Registration',
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: games.map((game) {
                          final currentUid = profileState.gameUids[game.id] ?? '';
                          return ListTile(
                            leading: Icon(
                              Icons.sports_esports_rounded,
                              color: primaryAccent,
                              size: 20,
                            ),
                            title: Text(
                              game.name.split('(').first.trim(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              currentUid.isNotEmpty ? 'UID: $currentUid' : 'Not linked yet',
                              style: TextStyle(
                                color: currentUid.isNotEmpty ? textPrimary : textMuted,
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.edit_outlined, size: 18, color: primaryAccent),
                              tooltip: 'Edit UID',
                              onPressed: () => _showEditGameUidDialog(game.id, game.name, currentUid),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // E. APPEARANCE & THEME PREFERENCE
                    Text(
                      'Appearance & Display Theme',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, _) {
                        final currentTheme = ref.watch(themeModeProvider);
                        final themeNotifier = ref.read(themeModeProvider.notifier);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: AppSpacing.roundedMd,
                            border: Border.all(color: cardBorder),
                          ),
                          child: Column(
                            children: [
                              _buildThemeOption(
                                title: 'System Default',
                                subtitle: 'Matches your device operating system theme',
                                isSelected: currentTheme == ThemeMode.system,
                                icon: Icons.brightness_auto_rounded,
                                onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
                                isDark: isDark,
                                primaryAccent: primaryAccent,
                              ),
                              Divider(color: isDark ? AppColors.darkSurfaceBorderSubtle : AppColors.lightSurfaceBorderSubtle),
                              _buildThemeOption(
                                title: 'Light Theme',
                                subtitle: 'Crisp white surfaces with subtle royal violet gradients',
                                isSelected: currentTheme == ThemeMode.light,
                                icon: Icons.light_mode_rounded,
                                onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
                                isDark: isDark,
                                primaryAccent: primaryAccent,
                              ),
                              Divider(color: isDark ? AppColors.darkSurfaceBorderSubtle : AppColors.lightSurfaceBorderSubtle),
                              _buildThemeOption(
                                title: 'Dark Theme (Esports)',
                                subtitle: 'Midnight obsidian surfaces with glowing neon accents',
                                isSelected: currentTheme == ThemeMode.dark,
                                icon: Icons.dark_mode_rounded,
                                onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
                                isDark: isDark,
                                primaryAccent: primaryAccent,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // F. APP SHORTCUTS, POLICIES & SUPPORT
                    Text(
                      'Quick Shortcuts & Policies',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.confirmation_number_outlined, color: primaryAccent),
                            title: Text('My Registered Tournaments & Passes', style: TextStyle(color: textPrimary)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () => context.push(AppRoutes.myTournaments),
                          ),
                          Divider(color: isDark ? AppColors.darkSurfaceBorderSubtle : AppColors.lightSurfaceBorderSubtle),
                          ListTile(
                            leading: Icon(Icons.notifications_none_rounded, color: primaryAccent),
                            title: Text('Notifications & Match Alerts', style: TextStyle(color: textPrimary)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () => context.push(AppRoutes.notifications),
                          ),
                          Divider(color: isDark ? AppColors.darkSurfaceBorderSubtle : AppColors.lightSurfaceBorderSubtle),
                          ListTile(
                            leading: Icon(Icons.description_outlined, color: textSecondary),
                            title: Text('Player Terms & Conditions', style: TextStyle(color: textPrimary)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () => context.push(AppRoutes.playerTerms),
                          ),
                          Divider(color: isDark ? AppColors.darkSurfaceBorderSubtle : AppColors.lightSurfaceBorderSubtle),
                          ListTile(
                            leading: Icon(Icons.privacy_tip_outlined, color: textSecondary),
                            title: Text('Privacy Policy', style: TextStyle(color: textPrimary)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () => context.push(AppRoutes.privacyPolicy),
                          ),
                          Divider(color: isDark ? AppColors.darkSurfaceBorderSubtle : AppColors.lightSurfaceBorderSubtle),
                          ListTile(
                            leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                            title: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
                            subtitle: Text('Permanently remove profile and data', style: TextStyle(color: textMuted, fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.error),
                            onTap: _confirmDeleteAccount,
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

  Widget _buildMetricCard(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.1 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryAccent,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? primaryAccent.withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? primaryAccent : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryAccent, size: 20)
            else
              Icon(Icons.circle_outlined, color: isDark ? Colors.white24 : Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}
