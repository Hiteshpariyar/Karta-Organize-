import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/models/organizer_application.dart';
import '../../domain/repositories/organizer_repository.dart';

/// Real Cloud Firestore implementation for tournament organizer applications.
class FirebaseOrganizerRepository implements IOrganizerRepository {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  OrganizerApprovalStatus? _mockStatusOverride;

  FirebaseOrganizerRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _customFirestore = firestore,
        _customAuth = auth;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  @override
  void setMockStatus(OrganizerApprovalStatus status) {
    _mockStatusOverride = status;
  }

  @override
  Future<ApplicationSubmissionResult> submitApplication(OrganizerApplication application) async {
    // 1. Mandatory policy acceptance verification
    if (!application.policyAccepted) {
      return const ApplicationSubmissionResult(
        isSuccess: false,
        message: 'Security validation failed: Organizer Terms & Conditions must be accepted.',
      );
    }

    if (!_isFirebaseReady) {
      return const ApplicationSubmissionResult(
        isSuccess: false,
        message: 'Firebase is not configured. Please link your project via "flutterfire configure".',
      );
    }

    final currentUser = _auth.currentUser;
    final uid = application.uid.isNotEmpty ? application.uid : currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      return const ApplicationSubmissionResult(
        isSuccess: false,
        message: 'Authentication session expired. Please sign in to submit your organizer application.',
      );
    }

    try {
      final docRef = _firestore.collection('organizer_applications').doc(uid);
      final existingDoc = await docRef.get();

      if (existingDoc.exists && existingDoc.data() != null) {
        final existing = OrganizerApplication.fromMap(existingDoc.data()!, docId: existingDoc.id);

        if (existing.status == OrganizerApprovalStatus.pending) {
          return ApplicationSubmissionResult(
            isSuccess: false,
            referenceId: existing.referenceId,
            message:
                'You already have an application under review (Reference: ${existing.referenceId}). Please wait for administrator verification.',
          );
        }

        if (existing.status == OrganizerApprovalStatus.approved) {
          return ApplicationSubmissionResult(
            isSuccess: false,
            referenceId: existing.referenceId,
            message: 'Your organizer account has already been approved.',
          );
        }
      }

      final refId = 'TZ-ORG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final appToSave = application.copyWith(
        applicationId: uid,
        uid: uid,
        referenceId: refId,
        status: OrganizerApprovalStatus.pending,
        submittedAt: DateTime.now(),
        reviewedAt: null,
        reviewedBy: null,
        rejectionReason: null,
      );

      final batch = _firestore.batch();
      batch.set(docRef, appToSave.toFirestoreMap(), SetOptions(merge: true));

      // Record Organizer Terms Acceptance in subcollection
      final policyDocRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('policy_acceptances')
          .doc('organizer_terms');

      batch.set(
        policyDocRef,
        {
          'userId': uid,
          'policyType': 'organizer_terms',
          'policyVersion': application.policyVersion ?? '1.0.0',
          'accepted': true,
          'acceptedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      return ApplicationSubmissionResult(
        isSuccess: true,
        referenceId: refId,
        message: 'Organizer application submitted successfully with reference $refId.',
      );
    } on FirebaseException catch (e) {
      return ApplicationSubmissionResult(
        isSuccess: false,
        message: 'Failed to submit application: ${e.message}',
      );
    } catch (e) {
      return ApplicationSubmissionResult(
        isSuccess: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  @override
  Future<OrganizerApplication?> fetchApplicationStatus({required String applicationId}) async {
    if (_mockStatusOverride != null) {
      return OrganizerApplication(
        applicationId: applicationId,
        uid: applicationId,
        applicantName: 'Tournament Host',
        organizationName: 'Zone Esports India',
        email: 'organizer@tourneyzone.com',
        phoneNumber: '9876543210',
        inGameUid: '5123456789',
        games: const ['Battlegrounds Mobile India (BGMI)'],
        referenceId: 'TZ-ORG-92841',
        status: _mockStatusOverride!,
        rejectionReason: _mockStatusOverride == OrganizerApprovalStatus.rejected
            ? 'In-game UID could not be verified against official game servers.'
            : null,
      );
    }

    if (!_isFirebaseReady) return null;

    final doc = await _firestore.collection('organizer_applications').doc(applicationId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return OrganizerApplication.fromMap(doc.data()!, docId: doc.id);
  }

  @override
  Stream<OrganizerApplication?> watchApplicationStatus(String uid) {
    if (!_isFirebaseReady) {
      return Stream.value(null);
    }

    return _firestore.collection('organizer_applications').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return OrganizerApplication.fromMap(doc.data()!, docId: doc.id);
    });
  }
}

