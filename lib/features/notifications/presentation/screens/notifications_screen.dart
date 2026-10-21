import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/app_notification.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider);
    final uid = user?.uid ?? '';

    if (uid.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Sign in to view notifications')),
      );
    }

    final notifsAsync = ref.watch(notificationsStreamProvider(uid));
    final repo = ref.read(notificationRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          TextButton(
            onPressed: () => repo.markAllAsRead(uid),
            child: Text(
              'Mark all read',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.electricBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: EmptyStateWidget(
                icon: Icons.notifications_none_rounded,
                title: 'No Notifications Yet',
                description: 'You are all caught up! Match alerts, schedules, and announcements will appear here.',
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _buildNotificationCard(context, n, () => repo.markAsRead(uid, n.id));
            },
          );
        },
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading notifications...'),
        ),
        error: (e, _) => Center(
          child: EmptyStateWidget(
            icon: Icons.error_outline_rounded,
            title: 'Error Loading Notifications',
            description: e.toString(),
            actionText: 'Retry',
            onAction: () => ref.invalidate(notificationsStreamProvider(uid)),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notification,
    VoidCallback onMarkRead,
  ) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.registration:
        icon = Icons.verified_user_rounded;
        iconColor = AppColors.success;
        break;
      case NotificationType.schedule:
        icon = Icons.access_time_rounded;
        iconColor = AppColors.electricBlue;
        break;
      case NotificationType.cancellation:
        icon = Icons.cancel_outlined;
        iconColor = AppColors.error;
        break;
      case NotificationType.announcement:
        icon = Icons.campaign_rounded;
        iconColor = AppColors.neonOrange;
        break;
    }

    final localTime = notification.createdAt.toLocal();
    final timeStr =
        '${localTime.day}/${localTime.month} at ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () {
        onMarkRead();
        if (notification.referenceId != null && notification.referenceId!.isNotEmpty) {
          context.push('/tournaments/${notification.referenceId}');
        }
      },
      borderRadius: AppSpacing.roundedMd,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.darkSurface : const Color(0xFF131D31),
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: notification.isRead
                ? AppColors.darkSurfaceBorder
                : AppColors.electricBlue.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTypography.bodySmall.copyWith(
                      color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
