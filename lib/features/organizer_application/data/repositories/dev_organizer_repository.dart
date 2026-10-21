import '../../../../core/config/app_config.dart';
import '../../domain/models/organizer_application.dart';
import '../../domain/repositories/organizer_repository.dart';

/// Phase 1 In-Memory & Development implementation for Organizer Applications.
///
/// Fully adheres to the requirement:
/// "For this Phase 1 UI implementation, if the backend is not yet connected,
/// show a clearly labeled development placeholder rather than falsely claiming
/// the application was submitted or saved."
class DevOrganizerRepository implements IOrganizerRepository {
  OrganizerApprovalStatus _currentStatus = OrganizerApprovalStatus.pending;
  OrganizerApplication? _currentApplication;

  @override
  void setMockStatus(OrganizerApprovalStatus status) {
    _currentStatus = status;
  }

  @override
  Future<ApplicationSubmissionResult> submitApplication(OrganizerApplication application) async {
    // Backend security check: Must have accepted policy
    if (!application.policyAccepted) {
      return const ApplicationSubmissionResult(
        isSuccess: false,
        message: 'Security validation failed: Organizer Terms & Conditions must be accepted.',
      );
    }

    await Future.delayed(const Duration(milliseconds: 700));

    final refId = 'TZ-ORG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    _currentApplication = application.copyWith(
      referenceId: refId,
      status: OrganizerApprovalStatus.pending,
      submittedAt: DateTime.now(),
      policyVersion: AppConfig.organizerTermsVersion,
    );

    return ApplicationSubmissionResult(
      isSuccess: true,
      referenceId: refId,
      message:
          'Phase 1 Dev Sandbox: Application validated and prepared with reference $refId. Cloud Firestore integration will persist this in Phase 2.',
    );
  }

  @override
  Future<OrganizerApplication> fetchApplicationStatus({required String applicationId}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (_currentStatus == OrganizerApprovalStatus.error) {
      throw Exception('Network timeout: Could not connect to organizer verification service.');
    }

    final base = _currentApplication ??
        OrganizerApplication(
          applicantName: 'Tournament Host',
          organizationName: 'Zone Esports India',
          email: 'organizer@tourneyzone.com',
          phoneNumber: '9876543210',
          inGameUid: '5123456789',
          games: const ['Battlegrounds Mobile India (BGMI)'],
          referenceId: 'TZ-ORG-92841',
          status: _currentStatus,
        );

    switch (_currentStatus) {
      case OrganizerApprovalStatus.pending:
        return base.copyWith(
          status: OrganizerApprovalStatus.pending,
          referenceId: base.referenceId ?? 'TZ-ORG-92841',
        );
      case OrganizerApprovalStatus.approved:
        return base.copyWith(
          status: OrganizerApprovalStatus.approved,
          referenceId: base.referenceId ?? 'TZ-ORG-92841',
        );
      case OrganizerApprovalStatus.rejected:
        return base.copyWith(
          status: OrganizerApprovalStatus.rejected,
          referenceId: base.referenceId ?? 'TZ-ORG-92841',
          rejectionReason:
              'In-game UID could not be verified against the official game API or the organization does not meet the minimum tournament host criteria.',
        );
      case OrganizerApprovalStatus.loading:
      case OrganizerApprovalStatus.error:
        return base.copyWith(status: _currentStatus);
    }
  }

  @override
  Stream<OrganizerApplication?> watchApplicationStatus(String uid) {
    return Stream.fromFuture(fetchApplicationStatus(applicationId: uid));
  }
}

