import 'package:flutter/material.dart';
import '../../../../core/config/supported_games.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/tournament.dart';

class TournamentFilterSheet extends StatefulWidget {
  final String initialGameId;
  final TournamentStatus? initialStatus;
  final EntryType? initialEntryType;
  final void Function(String gameId, TournamentStatus? status, EntryType? entryType) onApply;

  const TournamentFilterSheet({
    super.key,
    required this.initialGameId,
    required this.initialStatus,
    required this.initialEntryType,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialGameId,
    required TournamentStatus? initialStatus,
    required EntryType? initialEntryType,
    required void Function(String gameId, TournamentStatus? status, EntryType? entryType) onApply,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TournamentFilterSheet(
        initialGameId: initialGameId,
        initialStatus: initialStatus,
        initialEntryType: initialEntryType,
        onApply: onApply,
      ),
    );
  }

  @override
  State<TournamentFilterSheet> createState() => _TournamentFilterSheetState();
}

class _TournamentFilterSheetState extends State<TournamentFilterSheet> {
  late String _selectedGameId;
  late TournamentStatus? _selectedStatus;
  late EntryType? _selectedEntryType;

  @override
  void initState() {
    super.initState();
    _selectedGameId = widget.initialGameId;
    _selectedStatus = widget.initialStatus;
    _selectedEntryType = widget.initialEntryType;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final games = SupportedGamesConfig.games;
    final primaryColor = isDark ? AppColors.electricBlue : const Color(0xFF7C3AED);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Tournaments',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedGameId = 'all';
                        _selectedStatus = null;
                        _selectedEntryType = null;
                      });
                    },
                    child: Text(
                      'Reset All',
                      style: AppTypography.bodySmall.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
              const SizedBox(height: AppSpacing.sm),

              // Game filter
              Text(
                'GAME',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip('All Games', _selectedGameId == 'all', () {
                    setState(() => _selectedGameId = 'all');
                  }, isDark, primaryColor),
                  ...games.map((g) => _buildChoiceChip(
                        g.name.split('(').first.trim(),
                        _selectedGameId == g.id,
                        () => setState(() => _selectedGameId = g.id),
                        isDark,
                        primaryColor,
                      )),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Status filter
              Text(
                'STATUS',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip('All Statuses', _selectedStatus == null, () {
                    setState(() => _selectedStatus = null);
                  }, isDark, primaryColor),
                  _buildChoiceChip('Registration Open', _selectedStatus == TournamentStatus.registrationOpen, () {
                    setState(() => _selectedStatus = TournamentStatus.registrationOpen);
                  }, isDark, primaryColor),
                  _buildChoiceChip('Upcoming', _selectedStatus == TournamentStatus.upcoming, () {
                    setState(() => _selectedStatus = TournamentStatus.upcoming);
                  }, isDark, primaryColor),
                  _buildChoiceChip('Lobby Full', _selectedStatus == TournamentStatus.full, () {
                    setState(() => _selectedStatus = TournamentStatus.full);
                  }, isDark, primaryColor),
                  _buildChoiceChip('Live Now', _selectedStatus == TournamentStatus.live, () {
                    setState(() => _selectedStatus = TournamentStatus.live);
                  }, isDark, primaryColor),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Entry Fee filter
              Text(
                'ENTRY TYPE',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip('All Formats', _selectedEntryType == null, () {
                    setState(() => _selectedEntryType = null);
                  }, isDark, primaryColor),
                  _buildChoiceChip('Free Entry Only', _selectedEntryType == EntryType.free, () {
                    setState(() => _selectedEntryType = EntryType.free);
                  }, isDark, primaryColor),
                  _buildChoiceChip('Paid (Coming Soon)', _selectedEntryType == EntryType.paid, () {
                    setState(() => _selectedEntryType = EntryType.paid);
                  }, isDark, primaryColor),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    widget.onApply(_selectedGameId, _selectedStatus, _selectedEntryType);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
    Color primaryColor,
  ) {
    final chipBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final chipBorder = isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder;
    final unselectedText = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: primaryColor.withValues(alpha: isDark ? 0.2 : 0.15),
      backgroundColor: chipBg,
      labelStyle: AppTypography.bodySmall.copyWith(
        color: isSelected ? primaryColor : unselectedText,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? primaryColor : chipBorder,
      ),
    );
  }
}
