import '../models/app_notification.dart';

abstract class INotificationRepository {
  Future<List<AppNotification>> fetchNotifications(String uid);
  Stream<List<AppNotification>> watchNotifications(String uid);
  Future<void> markAsRead(String uid, String notificationId);
  Future<void> markAllAsRead(String uid);
}
