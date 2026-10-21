import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/models/policy_acceptance.dart';

/// Real Cloud Firestore implementation for legal policy acceptance logging.
class FirebasePolicyRepository implements IPolicyAcceptanceRepository {
  final FirebaseFirestore? _customFirestore;

  FirebasePolicyRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<bool> recordAcceptance(PolicyAcceptanceRecord record) async {
    if (!_isFirebaseReady) return false;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(record.userId)
          .collection('policy_acceptances')
          .doc(record.policyType);

      await docRef.set(record.toFirestoreMap(), SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasAcceptedPolicy({
    required String userId,
    required String policyType,
    required String minVersion,
  }) async {
    if (!_isFirebaseReady) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('policy_acceptances')
          .doc(policyType)
          .get();

      if (!doc.exists || doc.data() == null) return false;
      final isAccepted = doc.data()!['accepted'] as bool? ?? false;
      return isAccepted;
    } catch (_) {
      return false;
    }
  }
}

