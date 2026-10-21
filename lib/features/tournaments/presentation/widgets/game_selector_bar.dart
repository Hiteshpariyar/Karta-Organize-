import 'package:flutter/material.dart';
import '../../../../core/config/supported_games.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class GameSelectorBar extends StatelessWidget {
  final String selectedGameId;
  final ValueChanged<String> onGameSelected;

  const GameSelectorBar({
    super.key,
    required this.selectedGameId,
    required this.onGameSelected,
  });

  @override
  Widget build(BuildContext context) {
    final games = SupportedGamesConfig.games;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: games.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedGameId == 'all';
            return _buildChip(
              context: context,
              label: 'All Games',
              icon: Icons.grid_view_rounded,
              isSelected: isSelected,
              onTap: () => onGameSelected('all'),
            );
          }

          final game = games[index - 1];
          final isSelected = selectedGameId == game.id;

          return _buildChip(
            context: context,
            label: game.name.split('(').first.trim(),
            icon: Icons.sports_esports_rounded,
            isSelected: isSelected,
            onTap: () => onGameSelected(game.id),
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricBlueDim : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.electricBlue : AppColors.darkSurfaceBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.electricBlue.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.electricBlue : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.electricBlue : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
