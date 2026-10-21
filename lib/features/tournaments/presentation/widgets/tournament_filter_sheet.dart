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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
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
    final games = SupportedGamesConfig.games;

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
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
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
                      style: AppTypography.bodySmall.copyWith(color: AppColors.electricBlue),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.darkSurfaceBorder),
              const SizedBox(height: AppSpacing.sm),

              // Game filter
              Text('GAME', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip('All Games', _selectedGameId == 'all', () {
                    setState(() => _selectedGameId = 'all');
                  }),
                  ...games.map((g) => _buildChoiceChip(
                        g.name.split('(').first.trim(),
                        _selectedGameId == g.id,
                        () => setState(() => _selectedGameId = g.id),
                      )),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Status filter
              Text('STATUS', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip('All Statuses', _selectedStatus == null, () {
                    setState(() => _selectedStatus = null);
                  }),
                  _buildChoiceChip('Registration Open', _selectedStatus == TournamentStatus.registrationOpen, () {
                    setState(() => _selectedStatus = TournamentStatus.registrationOpen);
                  }),
                  _buildChoiceChip('Upcoming', _selectedStatus == TournamentStatus.upcoming, () {
                    setState(() => _selectedStatus = TournamentStatus.upcoming);
                  }),
                  _buildChoiceChip('Lobby Full', _selectedStatus == TournamentStatus.full, () {
                    setState(() => _selectedStatus = TournamentStatus.full);
                  }),
                  _buildChoiceChip('Live Now', _selectedStatus == TournamentStatus.live, () {
                    setState(() => _selectedStatus = TournamentStatus.live);
                  }),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Entry Fee filter
              Text('ENTRY TYPE', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip('All Formats', _selectedEntryType == null, () {
                    setState(() => _selectedEntryType = null);
                  }),
                  _buildChoiceChip('Free Entry Only', _selectedEntryType == EntryType.free, () {
                    setState(() => _selectedEntryType = EntryType.free);
                  }),
                  _buildChoiceChip('Paid (Coming Soon)', _selectedEntryType == EntryType.paid, () {
                    setState(() => _selectedEntryType = EntryType.paid);
                  }),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: Colors.black,
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

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.electricBlueDim,
      backgroundColor: AppColors.darkBackground,
      labelStyle: AppTypography.bodySmall.copyWith(
        color: isSelected ? AppColors.electricBlue : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.electricBlue : AppColors.darkSurfaceBorder,
      ),
    );
  }
}
