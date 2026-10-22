import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/form_validators.dart';
import '../../domain/models/user_profile.dart';
import '../providers/auth_providers.dart';

class PlayerLoginState {
  final String email;
  final String password;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final UserProfile? userProfile;
  final bool isEmailUnverified;

  final bool isGoogleLoading;

  const PlayerLoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.isGoogleLoading = false,
    this.errorMessage,
    this.successMessage,
    this.userProfile,
    this.isEmailUnverified = false,
  });

  bool get isFormValid {
    return FormValidators.email(email) == null && password.isNotEmpty;
  }

  PlayerLoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    bool? isGoogleLoading,
    String? errorMessage,
    String? successMessage,
    UserProfile? userProfile,
    bool? isEmailUnverified,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PlayerLoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      userProfile: userProfile ?? this.userProfile,
      isEmailUnverified: isEmailUnverified ?? this.isEmailUnverified,
    );
  }
}

class PlayerLoginNotifier extends Notifier<PlayerLoginState> {
  @override
  PlayerLoginState build() {
    return const PlayerLoginState();
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value, clearError: true);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value, clearError: true);
  }

  Future<bool> login() async {
    if (state.isLoading || state.isGoogleLoading) return false;

    if (!state.isFormValid) {
      state = state.copyWith(errorMessage: 'Please enter a valid email and password.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.signIn(
        email: state.email,
        password: state.password,
        role: 'Player',
      );

      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          successMessage: result.message,
          userProfile: result.userProfile,
          isEmailUnverified: result.isEmailUnverified,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.message ?? 'Login failed. Please check credentials.',
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

  Future<bool> signInWithGoogle() async {
    if (state.isLoading || state.isGoogleLoading) return false;

    state = state.copyWith(isGoogleLoading: true, clearError: true, clearSuccess: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.signInWithGoogle();

      if (result.isSuccess) {
        state = state.copyWith(
          isGoogleLoading: false,
          successMessage: result.message,
          userProfile: result.userProfile,
          isEmailUnverified: result.isEmailUnverified,
        );
        return true;
      } else {
        state = state.copyWith(
          isGoogleLoading: false,
          errorMessage: result.message ?? 'Google Sign-In failed.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isGoogleLoading: false,
        errorMessage: 'An unexpected error occurred during Google Sign-In: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> sendVerificationEmail() async {
    final authRepo = ref.read(authRepositoryProvider);
    final res = await authRepo.sendEmailVerification();
    if (res.isSuccess) {
      state = state.copyWith(successMessage: res.message);
    } else {
      state = state.copyWith(errorMessage: res.message);
    }
  }
}

final playerLoginProvider =
    NotifierProvider<PlayerLoginNotifier, PlayerLoginState>(
  PlayerLoginNotifier.new,
);
