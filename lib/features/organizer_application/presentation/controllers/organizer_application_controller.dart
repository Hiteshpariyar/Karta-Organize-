import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/organizer_application.dart';
import '../providers/organizer_providers.dart';

class OrganizerApplicationFormState {
  final String name;
  final String organizationName;
  final String email;
  final String phone;
  final String countryCode;
  final String inGameUid;
  final List<String> selectedGames;
  final TournamentPreference tournamentPreference;
  final bool policyAccepted; // Strictly unchecked by default
  final bool isLoading;
  final String? errorMessage;
  final String? submissionReferenceId;
  final String? devNoticeMessage;

  const OrganizerApplicationFormState({
    this.name = '',
    this.organizationName = '',
    this.email = '',
    this.phone = '',
    this.countryCode = AppConfig.defaultCountryCode,
    this.inGameUid = '',
    this.selectedGames = const [],
    this.tournamentPreference = TournamentPreference.freeOnly,
    this.policyAccepted = false,
    this.isLoading = false,
    this.errorMessage,
    this.submissionReferenceId,
    this.devNoticeMessage,
  });

  /// Validates personal, gaming, and tournament info before navigating to review.
  bool get isInitialFormValid {
    if (FormValidators.required(name) != null) return false;
    if (FormValidators.required(organizationName) != null) return false;
    if (FormValidators.email(email) != null) return false;
    if (FormValidators.phone(phone) != null) return false;
    if (FormValidators.inGameUid(inGameUid) != null) return false;
    if (selectedGames.isEmpty) return false;
    return true;
  }

  /// Full validation including mandatory legal policy acceptance.
  bool get isReviewSubmissionValid {
    return isInitialFormValid && policyAccepted;
  }

  OrganizerApplication toApplication({String? currentUid}) {
    return OrganizerApplication(
      uid: currentUid ?? '',
      applicationId: currentUid ?? '',
      applicantName: name,
      organizationName: organizationName,
      email: email,
      phoneNumber: phone,
      countryCode: countryCode,
      inGameUid: inGameUid,
      games: selectedGames,
      tournamentPreference: tournamentPreference,
      policyAccepted: policyAccepted,
      policyVersion: AppConfig.organizerTermsVersion,
      status: OrganizerApprovalStatus.pending,
    );
  }

  OrganizerApplicationFormState copyWith({
    String? name,
    String? organizationName,
    String? email,
    String? phone,
    String? countryCode,
    String? inGameUid,
    List<String>? selectedGames,
    TournamentPreference? tournamentPreference,
    bool? policyAccepted,
    bool? isLoading,
    String? errorMessage,
    String? submissionReferenceId,
    String? devNoticeMessage,
    bool clearError = false,
  }) {
    return OrganizerApplicationFormState(
      name: name ?? this.name,
      organizationName: organizationName ?? this.organizationName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
      inGameUid: inGameUid ?? this.inGameUid,
      selectedGames: selectedGames ?? this.selectedGames,
      tournamentPreference: tournamentPreference ?? this.tournamentPreference,
      policyAccepted: policyAccepted ?? this.policyAccepted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submissionReferenceId: submissionReferenceId ?? this.submissionReferenceId,
      devNoticeMessage: devNoticeMessage ?? this.devNoticeMessage,
    );
  }
}

class OrganizerApplicationNotifier extends Notifier<OrganizerApplicationFormState> {
  @override
  OrganizerApplicationFormState build() {
    return const OrganizerApplicationFormState();
  }

  void updateName(String val) => state = state.copyWith(name: val, clearError: true);
  void updateOrganizationName(String val) =>
      state = state.copyWith(organizationName: val, clearError: true);
  void updateEmail(String val) => state = state.copyWith(email: val, clearError: true);
  void updatePhone(String val) => state = state.copyWith(phone: val, clearError: true);
  void updateInGameUid(String val) => state = state.copyWith(inGameUid: val, clearError: true);

  void toggleGame(String gameName) {
    final current = List<String>.from(state.selectedGames);
    if (current.contains(gameName)) {
      current.remove(gameName);
    } else {
      current.add(gameName);
    }
    state = state.copyWith(selectedGames: current, clearError: true);
  }

  void updateTournamentPreference(TournamentPreference preference) {
    state = state.copyWith(tournamentPreference: preference, clearError: true);
  }

  void togglePolicyAccepted(bool? value) {
    state = state.copyWith(policyAccepted: value ?? false, clearError: true);
  }

  Future<bool> submitApplication() async {
    if (state.isLoading) return false;

    if (!state.isReviewSubmissionValid) {
      if (!state.policyAccepted) {
        state = state.copyWith(
          errorMessage:
              'You must accept the Organizer Terms & Conditions and Privacy Policy to submit your application.',
        );
      } else {
        state = state.copyWith(
          errorMessage: 'Please verify all application details before submission.',
        );
      }
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final repository = ref.read(organizerRepositoryProvider);
      final uid = authRepo.currentUid ?? '';

      final result = await repository.submitApplication(state.toApplication(currentUid: uid));

      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          submissionReferenceId: result.referenceId,
          devNoticeMessage: result.message,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.message ?? 'Application submission failed.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
      return false;
    }
  }

  void resetForm() {
    state = const OrganizerApplicationFormState();
  }
}

final organizerApplicationProvider =
    NotifierProvider<OrganizerApplicationNotifier, OrganizerApplicationFormState>(
  OrganizerApplicationNotifier.new,
);
