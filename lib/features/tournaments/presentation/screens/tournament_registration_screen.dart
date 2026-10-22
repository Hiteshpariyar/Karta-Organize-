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
  late final TextEditingController _teamNameController;

  @override
  void initState() {
    super.initState();
    _gameUidController = TextEditingController();
    _teamNameController = TextEditingController();

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
    _teamNameController.dispose();
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

        final state = ref.read(tournamentRegistrationProvider);
        _showSuccessDialog(state.assignedSlot);
      }
    }
  }

  void _showSuccessDialog(int? assignedSlot) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.success, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
            const SizedBox(width: 10),
            Text(
              'Entry Confirmed!',
              style: AppTypography.titleLarge.copyWith(color: textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your tournament slot has been securely allocated.',
              style: AppTypography.bodyMedium.copyWith(color: textPrimary),
            ),
            const SizedBox(height: 12),
            if (assignedSlot != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tag_rounded, size: 20, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      'Assigned Slot: #$assignedSlot',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161F30) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 16, color: AppColors.electricBlue),
                      const SizedBox(width: 8),
                      Text(
                        'In-Game ID: ${_gameUidController.text.trim()}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.electricBlue : const Color(0xFF7C3AED),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_teamNameController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Team: ${_teamNameController.text.trim()}',
                          style: AppTypography.bodySmall.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Custom Room ID and Password will unlock in Tournament Details 15 minutes before match start.',
                    style: AppTypography.bodySmall.copyWith(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.electricBlue : const Color(0xFF7C3AED),
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.myTournaments);
            },
            child: const Text('View in My Tournaments'),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.surfaceOf(context);
    final cardBorder = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primaryAccent = isDark ? AppColors.electricBlue : const Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tournament Entry'),
        elevation: 0,
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
                        // Summary Banner Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: AppSpacing.roundedLg,
                            border: Border.all(color: cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    tournament.gameName,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: primaryAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tournament.formattedEntryFee,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tournament.title,
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Host: ${tournament.displayOrganizerTeam}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${tournament.availableSlots} of ${tournament.maxParticipants} slots left',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: tournament.availableSlots <= 3
                                          ? AppColors.warning
                                          : AppColors.success,
                                      fontWeight: FontWeight.w600,
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
                            message: regState.errorMessage!,
                            type: StatusBannerType.error,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Game-Specific UID Field
                        Text(
                          'Player Verification & In-Game UID',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Provide your verified character ID for custom room lobby whitelist.',
                          style: AppTypography.bodySmall.copyWith(
                            color: textSecondary,
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

                        // Optional Team / Squad Name if tournament team size > 1
                        if (tournament.teamSize > 1) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Squad / Team Information',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter your squad/clan name for scoreboard allocation.',
                            style: AppTypography.bodySmall.copyWith(
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppTextField(
                            controller: _teamNameController,
                            label: 'Squad / Clan Name (Optional)',
                            hint: 'e.g. Soul Gaming / Team Elite',
                            prefixIcon: Icons.shield_outlined,
                            onChanged: regNotifier.updateTeamName,
                          ),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        // Tournament Rules Confirmation
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: AppSpacing.roundedMd,
                            border: Border.all(
                              color: regState.rulesAccepted
                                  ? primaryAccent
                                  : cardBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tournament Rules Summary',
                                style: AppTypography.titleSmall.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tournament.rules,
                                style: AppTypography.bodySmall.copyWith(
                                  color: textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Divider(color: cardBorder, height: 1),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () =>
                                    regNotifier.toggleRulesAccepted(!regState.rulesAccepted),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: regState.rulesAccepted,
                                        onChanged: regNotifier.toggleRulesAccepted,
                                        activeColor: primaryAccent,
                                        checkColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'I agree to the Tournament Rules, Fair Play policy, and confirm my lobby attendance.',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: regState.rulesAccepted
                                              ? textPrimary
                                              : textSecondary,
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
                              color: textSecondary,
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
