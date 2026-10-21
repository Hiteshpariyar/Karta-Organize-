import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_notification_repository.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return FirebaseNotificationRepository();
});

final notificationsStreamProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, uid) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications(uid);
});

final unreadNotificationsCountProvider = Provider.family<int, String>((ref, uid) {
  final asyncNotifs = ref.watch(notificationsStreamProvider(uid));
  final list = asyncNotifs.value ?? [];
  return list.where((n) => !n.isRead).length;
});
