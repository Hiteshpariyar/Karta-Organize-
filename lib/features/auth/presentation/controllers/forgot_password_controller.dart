import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/form_validators.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordState {
  final String email;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ForgotPasswordState({
    this.email = '',
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get isFormValid => FormValidators.email(email) == null;

  ForgotPasswordState copyWith({
    String? email,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ForgotPasswordNotifier extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() {
    return const ForgotPasswordState();
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value, clearError: true);
  }

  Future<bool> sendResetLink() async {
    if (state.isLoading) return false;

    if (!state.isFormValid) {
      state = state.copyWith(errorMessage: 'Please enter a valid registered email address.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.sendPasswordResetEmail(email: state.email);
      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          successMessage: result.message,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.message ?? 'Failed to send password reset link.',
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
}

final forgotPasswordProvider =
    NotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
  ForgotPasswordNotifier.new,
);
