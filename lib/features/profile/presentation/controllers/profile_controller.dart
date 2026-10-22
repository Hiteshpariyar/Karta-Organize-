import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileState {
  final String displayName;
  final String? phoneNumber;
  final String? phonePrivacy;
  final Map<String, String> gameUids;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.displayName = '',
    this.phoneNumber,
    this.phonePrivacy = 'friends_only',
    this.gameUids = const {},
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  ProfileState copyWith({
    String? displayName,
    String? phoneNumber,
    String? phonePrivacy,
    Map<String, String>? gameUids,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phonePrivacy: phonePrivacy ?? this.phonePrivacy,
      gameUids: gameUids ?? this.gameUids,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    final user = ref.watch(currentUserProfileProvider);
    return ProfileState(
      displayName: user?.displayName ?? '',
      phoneNumber: user?.phoneNumber,
      phonePrivacy: user?.phonePrivacy ?? 'friends_only',
      gameUids: Map<String, String>.from(user?.gameUids ?? {}),
    );
  }

  void updateDisplayName(String name) {
    state = state.copyWith(displayName: name, clearError: true);
  }

  void updatePhone(String phone) {
    state = state.copyWith(phoneNumber: phone, clearError: true);
  }

  void updatePhonePrivacy(String privacy) {
    state = state.copyWith(phonePrivacy: privacy, clearError: true);
  }

  void updateGameUid(String gameId, String uid) {
    final updated = Map<String, String>.from(state.gameUids);
    if (uid.trim().isEmpty) {
      updated.remove(gameId);
    } else {
      updated[gameId] = uid.trim();
    }
    state = state.copyWith(gameUids: updated, clearError: true);
  }

  Future<bool> saveProfile() async {
    if (state.isLoading) return false;

    if (state.displayName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Display name cannot be empty.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.updateProfile(
        displayName: state.displayName.trim(),
        gameUids: state.gameUids,
        phoneNumber: state.phoneNumber,
        phonePrivacy: state.phonePrivacy,
      );

      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Profile updated successfully.',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.message ?? 'Failed to update profile.',
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

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});
