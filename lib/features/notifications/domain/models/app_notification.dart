import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  registration('registration', 'Registration'),
  schedule('schedule', 'Schedule Update'),
  cancellation('cancellation', 'Cancellation'),
  announcement('announcement', 'Announcement');

  final String value;
  final String label;
  const NotificationType(this.value, this.label);

  static NotificationType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'registration':
        return NotificationType.registration;
      case 'schedule':
        return NotificationType.schedule;
      case 'cancellation':
        return NotificationType.cancellation;
      case 'announcement':
      default:
        return NotificationType.announcement;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = NotificationType.announcement,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'body': body,
      'type': type.value,
      'referenceId': referenceId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> data, {required String id}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AppNotification(
      id: id,
      title: data['title'] as String? ?? 'Notification',
      body: data['body'] as String? ?? '',
      type: NotificationType.fromString(data['type'] as String?),
      referenceId: data['referenceId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: parseDate(data['createdAt']),
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? referenceId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
