import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class FirebaseNotificationRepository implements INotificationRepository {
  final FirebaseFirestore? _customFirestore;

  FirebaseNotificationRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  final List<AppNotification> _devSeed = [
    AppNotification(
      id: 'notif_welcome',
      title: 'Welcome to TourneyZone Arena!',
      body: 'Compete in community scrims and battle royale showdowns. Link your game UID in your profile to register.',
      type: NotificationType.announcement,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'notif_bgmi_open',
      title: 'BGMI Scrims Registration Open',
      body: 'Slots for BGMI Pro Invitational Scrims - Tier 1 are filling fast. Register your squad now.',
      type: NotificationType.schedule,
      referenceId: 'tz_tourney_bgmi_scrims_01',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<List<AppNotification>> fetchNotifications(String uid) async {
    if (!_isFirebaseReady) {
      return _devSeed;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      if (snapshot.docs.isEmpty) {
        return _devSeed;
      }

      return snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (_) {
      return _devSeed;
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String uid) {
    if (!_isFirebaseReady) {
      return Stream.value(_devSeed);
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return _devSeed;
      return snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  @override
  Future<void> markAsRead(String uid, String notificationId) async {
    if (!_isFirebaseReady) {
      final idx = _devSeed.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        _devSeed[idx] = _devSeed[idx].copyWith(isRead: true);
      }
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead(String uid) async {
    if (!_isFirebaseReady) {
      for (int i = 0; i < _devSeed.length; i++) {
        _devSeed[i] = _devSeed[i].copyWith(isRead: true);
      }
      return;
    }

    try {
      final batch = _firestore.batch();
      final docs = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var d in docs.docs) {
        batch.update(d.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }
}
