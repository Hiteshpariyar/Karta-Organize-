import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../organizer_application/domain/models/organizer_application.dart';
import '../../../organizer_application/presentation/providers/organizer_providers.dart';
import '../../domain/models/user_profile.dart';
import '../providers/auth_providers.dart';

enum OrganizerLoginDestination {
  apply,
  pendingReview,
  approved,
  rejected,
  error,
}

class OrganizerLoginState {
  final String email;
  final String password;
  final bool isLoading;
  final String? errorMessage;
  final String? statusNotice;
  final UserProfile? userProfile;
  final OrganizerApplication? application;
  final OrganizerLoginDestination? destination;

  const OrganizerLoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.errorMessage,
    this.statusNotice,
    this.userProfile,
    this.application,
    this.destination,
  });

  bool get isFormValid {
    return FormValidators.email(email) == null && password.isNotEmpty;
  }

  OrganizerLoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    String? errorMessage,
    String? statusNotice,
    UserProfile? userProfile,
    OrganizerApplication? application,
    OrganizerLoginDestination? destination,
    bool clearError = false,
    bool clearNotice = false,
  }) {
    return OrganizerLoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusNotice: clearNotice ? null : (statusNotice ?? this.statusNotice),
      userProfile: userProfile ?? this.userProfile,
      application: application ?? this.application,
      destination: destination ?? this.destination,
    );
  }
}

class OrganizerLoginNotifier extends Notifier<OrganizerLoginState> {
  @override
  OrganizerLoginState build() {
    return const OrganizerLoginState();
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value, clearError: true);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value, clearError: true);
  }

  Future<bool> login() async {
    if (state.isLoading) return false;

    if (!state.isFormValid) {
      state = state.copyWith(errorMessage: 'Please enter a valid email and password.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearNotice: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final organizerRepo = ref.read(organizerRepositoryProvider);

      // 1. Authenticate with Firebase Auth
      final authResult = await authRepo.signIn(
        email: state.email,
        password: state.password,
        role: 'Organizer',
      );

      if (!authResult.isSuccess || authResult.userId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: authResult.message ?? 'Login failed. Please check credentials.',
        );
        return false;
      }

      final uid = authResult.userId!;
      final profile = authResult.userProfile;

      // 2. Enforce account status check
      if (profile != null && profile.isSuspended) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Account suspended: Organizer privileges are revoked due to policy violations.',
        );
        return false;
      }

      // 3. Query trusted backend for organizer application linked to UID
      OrganizerApplication? application;
      try {
        application = await organizerRepo.fetchApplicationStatus(applicationId: uid);
      } catch (e) {
        // Fail closed on verification failure
        state = state.copyWith(
          isLoading: false,
          destination: OrganizerLoginDestination.error,
          errorMessage:
              'Could not reach the organizer verification service. Privileges cannot be verified.',
        );
        return false;
      }

      OrganizerLoginDestination destination;
      String notice;

      if (application == null) {
        destination = OrganizerLoginDestination.apply;
        notice = 'No application found. Please complete the organizer credential application.';
      } else {
        switch (application.status) {
          case OrganizerApprovalStatus.pending:
            destination = OrganizerLoginDestination.pendingReview;
            notice = 'Your application is awaiting administrator review.';
            break;
          case OrganizerApprovalStatus.approved:
            destination = OrganizerLoginDestination.approved;
            notice = 'Organizer credentials verified.';
            break;
          case OrganizerApprovalStatus.rejected:
            destination = OrganizerLoginDestination.rejected;
            notice = 'Application not approved. You may edit and resubmit.';
            break;
          case OrganizerApprovalStatus.error:
          case OrganizerApprovalStatus.loading:
            destination = OrganizerLoginDestination.error;
            notice = 'Unable to verify status. Please retry.';
            break;
        }
      }

      state = state.copyWith(
        isLoading: false,
        userProfile: profile,
        application: application,
        destination: destination,
        statusNotice: notice,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
      return false;
    }
  }
}

final organizerLoginProvider =
    NotifierProvider<OrganizerLoginNotifier, OrganizerLoginState>(
  OrganizerLoginNotifier.new,
);
