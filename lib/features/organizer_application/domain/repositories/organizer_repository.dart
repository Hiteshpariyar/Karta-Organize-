import '../models/organizer_application.dart';

class ApplicationSubmissionResult {
  final bool isSuccess;
  final String? referenceId;
  final String? message;

  const ApplicationSubmissionResult({
    required this.isSuccess,
    this.referenceId,
    this.message,
  });
}

abstract class IOrganizerRepository {
  /// Submits an organizer credential application linked to the authenticated UID.
  Future<ApplicationSubmissionResult> submitApplication(OrganizerApplication application);

  /// Retrieves the current organizer application for a user UID.
  Future<OrganizerApplication?> fetchApplicationStatus({required String applicationId});

  /// Streams real-time updates for an organizer application.
  Stream<OrganizerApplication?> watchApplicationStatus(String uid);

  /// For testing/development switcher.
  void setMockStatus(OrganizerApprovalStatus status);
}
