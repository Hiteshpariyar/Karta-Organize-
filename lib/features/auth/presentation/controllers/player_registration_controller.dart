import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/form_validators.dart';
import '../providers/auth_providers.dart';

class PlayerRegistrationState {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final bool policyAccepted; // Strictly unchecked by default
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final bool requiresProfileSetup;

  const PlayerRegistrationState({
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.policyAccepted = false,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.requiresProfileSetup = false,
  });

  bool get isFormValid {
    if (FormValidators.required(fullName) != null) return false;
    if (FormValidators.email(email) != null) return false;
    if (FormValidators.password(password) != null) return false;
    if (FormValidators.confirmPassword(confirmPassword, password) != null) return false;
    if (!policyAccepted) return false;
    return true;
  }

  PlayerRegistrationState copyWith({
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
    bool? policyAccepted,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? requiresProfileSetup,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PlayerRegistrationState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      policyAccepted: policyAccepted ?? this.policyAccepted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      requiresProfileSetup: requiresProfileSetup ?? this.requiresProfileSetup,
    );
  }
}

class PlayerRegistrationNotifier extends Notifier<PlayerRegistrationState> {
  @override
  PlayerRegistrationState build() {
    return const PlayerRegistrationState();
  }

  void updateFullName(String value) {
    state = state.copyWith(fullName: value, clearError: true);
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value, clearError: true);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value, clearError: true);
  }

  void updateConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value, clearError: true);
  }

  void togglePolicyAccepted(bool? value) {
    state = state.copyWith(policyAccepted: value ?? false, clearError: true);
  }

  Future<bool> register() async {
    if (state.isLoading) return false;

    if (!state.isFormValid) {
      if (!state.policyAccepted) {
        state = state.copyWith(
          errorMessage: 'You must accept the Player Terms & Conditions and Privacy Policy to create an account.',
        );
      } else {
        state = state.copyWith(
          errorMessage: 'Please fill in all required fields correctly.',
        );
      }
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.registerPlayer(
        fullName: state.fullName,
        email: state.email,
        password: state.password,
        policyAccepted: state.policyAccepted,
        policyVersion: AppConfig.playerTermsVersion,
        privacyVersion: AppConfig.privacyPolicyVersion,
      );

      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          successMessage: result.message,
          requiresProfileSetup: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.message ?? 'Registration failed. Please try again.',
          requiresProfileSetup: result.requiresProfileSetup,
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

  Future<bool> retryProfileCreation() async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.completeProfileCreation(
        fullName: state.fullName,
        policyAccepted: state.policyAccepted,
        policyVersion: AppConfig.playerTermsVersion,
        privacyVersion: AppConfig.privacyPolicyVersion,
      );

      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          requiresProfileSetup: false,
          successMessage: 'Profile initialized successfully.',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to complete profile: ${e.toString()}',
      );
      return false;
    }
  }

  void resetForm() {
    state = const PlayerRegistrationState();
  }
}

final playerRegistrationProvider =
    NotifierProvider<PlayerRegistrationNotifier, PlayerRegistrationState>(
  PlayerRegistrationNotifier.new,
);
