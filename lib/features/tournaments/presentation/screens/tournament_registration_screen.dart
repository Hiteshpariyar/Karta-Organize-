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
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/status_banner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../controllers/tournament_registration_controller.dart';
import '../providers/tournament_providers.dart';

class TournamentRegistrationScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentRegistrationScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentRegistrationScreen> createState() =>
      _TournamentRegistrationScreenState();
}

class _TournamentRegistrationScreenState
    extends ConsumerState<TournamentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _gameUidController;

  @override
  void initState() {
    super.initState();
    _gameUidController = TextEditingController();

    // Auto-populate game UID if stored in player profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProfileProvider);
      final tourney = ref.read(tournamentRepositoryProvider).fetchTournamentById(widget.tournamentId);
      tourney.then((t) {
        if (t != null && user != null) {
          final existingGameUid = user.gameUids[t.gameId];
          if (existingGameUid != null && existingGameUid.isNotEmpty) {
            _gameUidController.text = existingGameUid;
            ref.read(tournamentRegistrationProvider.notifier).updateGameUid(existingGameUid);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _gameUidController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final notifier = ref.read(tournamentRegistrationProvider.notifier);
      final success = await notifier.registerForTournament(widget.tournamentId);

      if (success && mounted) {
        // Invalidate tournament cache so details & discovery reflect incremented count
        ref.invalidate(tournamentDetailsStreamProvider(widget.tournamentId));
        ref.invalidate(openTournamentsProvider);
        ref.invalidate(upcomingTournamentsProvider);

        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.success, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
            const SizedBox(width: 10),
            Text('Entry Confirmed!', style: AppTypography.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your slot has been reserved. You can review your match schedule and check-in details from My Tournaments.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 16, color: AppColors.electricBlue),
                  const SizedBox(width: 8),
                  Text(
                    'In-Game ID: ${_gameUidController.text.trim()}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.myTournaments);
            },
            child: const Text('View My Tournaments'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tourneyAsync = ref.watch(tournamentDetailsStreamProvider(widget.tournamentId));
    final regState = ref.watch(tournamentRegistrationProvider);
    final regNotifier = ref.read(tournamentRegistrationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Tournament Entry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: tourneyAsync.when(
        data: (tournament) {
          if (tournament == null) {
            return const Center(child: Text('Tournament not found'));
          }

          final gameConfig = SupportedGamesConfig.findById(tournament.gameId);
          final uidLabel = gameConfig?.uidLabel ?? 'In-Game Character ID / UID';
          final uidPlaceholder = gameConfig?.placeholderUid ?? 'e.g. 5123456789';

          return SafeArea(
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
                        // Summary Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: AppSpacing.roundedLg,
                            border: Border.all(color: AppColors.darkSurfaceBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tournament.gameName,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.electricBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tournament.title,
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'FREE REGISTRATION',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${tournament.availableSlots} slots left',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        if (regState.errorMessage != null) ...[
                          StatusBanner(
                            title: 'Registration Error',
                            message: regState.errorMessage,
                            type: StatusBannerType.error,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Game-Specific UID Field
                        Text(
                          'Player Verification & In-Game UID',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Provide your verified in-game ID for lobby whitelist invite.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        AppTextField(
                          controller: _gameUidController,
                          label: uidLabel,
                          hint: uidPlaceholder,
                          prefixIcon: Icons.sports_esports_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'In-game UID is required for lobby placement.';
                            }
                            if (val.trim().length < 3) {
                              return 'UID must be at least 3 characters.';
                            }
                            return null;
                          },
                          onChanged: regNotifier.updateGameUid,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Tournament Rules Confirmation
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: AppSpacing.roundedMd,
                            border: Border.all(
                              color: regState.rulesAccepted
                                  ? AppColors.electricBlueBorder
                                  : AppColors.darkSurfaceBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tournament Rules Summary',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tournament.rules,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Divider(color: AppColors.darkSurfaceBorderSubtle),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => regNotifier.toggleRulesAccepted(!regState.rulesAccepted),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: regState.rulesAccepted,
                                        onChanged: regNotifier.toggleRulesAccepted,
                                        activeColor: AppColors.electricBlue,
                                        checkColor: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'I agree to the Tournament Rules, Fair Play policy, and confirm my lobby attendance.',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: regState.rulesAccepted
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                          fontWeight: regState.rulesAccepted
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Confirm Registration Button
                        AppButton(
                          text: 'Confirm Free Registration',
                          icon: Icons.how_to_reg_rounded,
                          isLoading: regState.isLoading,
                          onPressed: regState.isFormValid ? _handleSubmit : null,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        Center(
                          child: Text(
                            'Registration is 100% free with no hidden charges.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Verifying tournament eligibility...'),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
