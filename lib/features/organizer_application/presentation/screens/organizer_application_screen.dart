import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/supported_games.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/dev_notice_banner.dart';
import '../../../../core/widgets/status_banner.dart';
import '../../domain/models/organizer_application.dart';
import '../controllers/organizer_application_controller.dart';

/// Screen presenting the multi-section Organizer Credential Application.
class OrganizerApplicationScreen extends ConsumerStatefulWidget {
  const OrganizerApplicationScreen({super.key});

  @override
  ConsumerState<OrganizerApplicationScreen> createState() =>
      _OrganizerApplicationScreenState();
}

class _OrganizerApplicationScreenState
    extends ConsumerState<OrganizerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _orgController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _uidController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(organizerApplicationProvider);
    _nameController = TextEditingController(text: state.name);
    _orgController = TextEditingController(text: state.organizationName);
    _emailController = TextEditingController(text: state.email);
    _phoneController = TextEditingController(text: state.phone);
    _uidController = TextEditingController(text: state.inGameUid);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orgController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _uidController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      final state = ref.read(organizerApplicationProvider);
      if (state.selectedGames.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one game you plan to organize.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      context.push(AppRoutes.organizerReview);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(organizerApplicationProvider);
    final notifier = ref.read(organizerApplicationProvider.notifier);

    // Keep text controllers synchronized with state
    if (_nameController.text != state.name) _nameController.text = state.name;
    if (_orgController.text != state.organizationName) {
      _orgController.text = state.organizationName;
    }
    if (_emailController.text != state.email) _emailController.text = state.email;
    if (_phoneController.text != state.phone) _phoneController.text = state.phone;
    if (_uidController.text != state.inGameUid) _uidController.text = state.inGameUid;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Organizer Application'),
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
              constraints: const BoxConstraints(maxWidth: 580),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DevNoticeBanner(
                      featureName: 'Organizer Application Workflow',
                      note:
                          'Phase 1 UI Sandbox: Form state is preserved in Riverpod. Backend verification occurs in Phase 2.',
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Host Esports Tournaments',
                      style: AppTypography.displayMedium.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Complete the multi-section form below to apply for organizer credentials. Administrator approval is required before hosting privileges are unlocked.',
                      style: AppTypography.bodyMedium,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // SECTION 1: Personal Information
                    _buildSectionCard(
                      icon: Icons.person_outline_rounded,
                      title: '1. Personal Information',
                      children: [
                        AppTextField(
                          controller: _nameController,
                          label: 'Your Name',
                          hint: 'Enter your legal name',
                          prefixIcon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              FormValidators.required(v, fieldName: 'Your Name'),
                          onChanged: notifier.updateName,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _orgController,
                          label: 'Organization Name',
                          hint: 'e.g. Apex Esports, Team Velocity',
                          prefixIcon: Icons.corporate_fare_rounded,
                          textInputAction: TextInputAction.next,
                          validator: (v) => FormValidators.required(
                            v,
                            fieldName: 'Organization Name',
                          ),
                          onChanged: notifier.updateOrganizationName,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'contact@organization.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: FormValidators.email,
                          onChanged: notifier.updateEmail,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: '9876543210',
                          prefixText: AppConfig.defaultCountryCode,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: FormValidators.phone,
                          onChanged: notifier.updatePhone,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // SECTION 2: Gaming Information
                    _buildSectionCard(
                      icon: Icons.sports_esports_outlined,
                      title: '2. Gaming Information',
                      children: [
                        AppTextField(
                          controller: _uidController,
                          label: 'Game-specific In-Game UID',
                          hint: 'e.g. 5123456789 or Player#1234',
                          helperText:
                              'Used by platform admins to verify your in-game identity and host standing.',
                          prefixIcon: Icons.tag_rounded,
                          textInputAction: TextInputAction.done,
                          validator: FormValidators.inGameUid,
                          onChanged: notifier.updateInGameUid,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Games You Organize',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Select all game titles you plan to host brackets or scrims for:',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: SupportedGamesConfig.games.map((game) {
                            final isSelected = state.selectedGames.contains(game.name);
                            return FilterChip(
                              label: Text(game.name),
                              selected: isSelected,
                              onSelected: (_) => notifier.toggleGame(game.name),
                              selectedColor: AppColors.electricBlueDim,
                              backgroundColor: AppColors.darkSurface,
                              checkmarkColor: AppColors.electricBlue,
                              labelStyle: AppTypography.bodySmall.copyWith(
                                color: isSelected
                                    ? AppColors.electricBlue
                                    : AppColors.textSecondary,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w400,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.electricBlue
                                    : AppColors.darkSurfaceBorder,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.roundedSm,
                              ),
                            );
                          }).toList(),
                        ),
                        if (state.selectedGames.isEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Please select at least one game',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // SECTION 3: Tournament Preferences
                    _buildSectionCard(
                      icon: Icons.tune_rounded,
                      title: '3. Tournament Preferences',
                      children: [
                        StatusBanner(
                          title: 'Phase 1 Operational Notice',
                          message:
                              'Paid tournament functionality remains inactive in Phase 1. The preference below only records your intended tournament format. Free scrims and community brackets are active.',
                          type: StatusBannerType.info,
                          icon: Icons.lightbulb_outline_rounded,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        ...TournamentPreference.values.map((pref) {
                          final isSelected = state.tournamentPreference == pref;
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.electricBlueDim
                                  : AppColors.darkSurfaceElevated,
                              borderRadius: AppSpacing.roundedMd,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.electricBlue
                                    : AppColors.darkSurfaceBorder,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: AppSpacing.roundedMd,
                              onTap: () => notifier.updateTournamentPreference(pref),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.only(top: 2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.electricBlue
                                              : AppColors.textSecondary,
                                          width: 2.0,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Center(
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppColors.electricBlue,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pref.label,
                                            style: AppTypography.titleSmall.copyWith(
                                              color: isSelected
                                                  ? AppColors.electricBlue
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.xxs),
                                          Text(
                                            pref.description,
                                            style: AppTypography.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Continue Button
                    AppButton(
                      text: 'Continue to Application Review',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _handleContinue,
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

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.darkSurfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.electricBlue, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.darkSurfaceBorderSubtle),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
