import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/organizer_application.dart';
import '../providers/organizer_providers.dart';

class OrganizerStatusState {
  final OrganizerApprovalStatus status;
  final String? referenceId;
  final String? rejectionReason;
  final bool isLoading;
  final String? errorMessage;
  final OrganizerApplication? application;

  const OrganizerStatusState({
    this.status = OrganizerApprovalStatus.pending,
    this.referenceId,
    this.rejectionReason,
    this.isLoading = false,
    this.errorMessage,
    this.application,
  });

  OrganizerStatusState copyWith({
    OrganizerApprovalStatus? status,
    String? referenceId,
    String? rejectionReason,
    bool? isLoading,
    String? errorMessage,
    OrganizerApplication? application,
    bool clearError = false,
  }) {
    return OrganizerStatusState(
      status: status ?? this.status,
      referenceId: referenceId ?? this.referenceId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      application: application ?? this.application,
    );
  }
}

class OrganizerStatusNotifier extends Notifier<OrganizerStatusState> {
  @override
  OrganizerStatusState build() {
    return const OrganizerStatusState();
  }

  Future<void> fetchStatus({String? referenceId}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(organizerRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);

      final queryId = referenceId ?? authRepo.currentUid ?? state.referenceId ?? 'demo_app_id';

      final app = await repository.fetchApplicationStatus(applicationId: queryId);

      if (app != null) {
        state = state.copyWith(
          status: app.status,
          referenceId: app.referenceId ?? app.applicationId,
          rejectionReason: app.rejectionReason,
          application: app,
          isLoading: false,
        );
      } else {
        // No application found for user
        state = state.copyWith(
          status: OrganizerApprovalStatus.pending,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: OrganizerApprovalStatus.error,
        isLoading: false,
        errorMessage: 'Unable to reach the verification server. Please check connection and retry.',
      );
    }
  }

  void switchDemoStatus(OrganizerApprovalStatus status) {
    final repository = ref.read(organizerRepositoryProvider);
    repository.setMockStatus(status);
    fetchStatus();
  }
}

final organizerStatusProvider =
    NotifierProvider<OrganizerStatusNotifier, OrganizerStatusState>(
  OrganizerStatusNotifier.new,
);
