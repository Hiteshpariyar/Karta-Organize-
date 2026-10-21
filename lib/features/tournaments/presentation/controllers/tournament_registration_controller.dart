import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tournament_providers.dart';

class TournamentRegistrationState {
  final String gameUid;
  final bool rulesAccepted;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final bool isSuccess;
  final bool isDuplicate;
  final bool isFull;
  final bool isDeadlinePassed;
  final bool isSuspended;

  const TournamentRegistrationState({
    this.gameUid = '',
    this.rulesAccepted = false,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.isSuccess = false,
    this.isDuplicate = false,
    this.isFull = false,
    this.isDeadlinePassed = false,
    this.isSuspended = false,
  });

  bool get isFormValid => gameUid.trim().isNotEmpty && rulesAccepted;

  TournamentRegistrationState copyWith({
    String? gameUid,
    bool? rulesAccepted,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? isSuccess,
    bool? isDuplicate,
    bool? isFull,
    bool? isDeadlinePassed,
    bool? isSuspended,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TournamentRegistrationState(
      gameUid: gameUid ?? this.gameUid,
      rulesAccepted: rulesAccepted ?? this.rulesAccepted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      isFull: isFull ?? this.isFull,
      isDeadlinePassed: isDeadlinePassed ?? this.isDeadlinePassed,
      isSuspended: isSuspended ?? this.isSuspended,
    );
  }
}

class TournamentRegistrationNotifier extends Notifier<TournamentRegistrationState> {
  @override
  TournamentRegistrationState build() {
    return const TournamentRegistrationState();
  }

  void updateGameUid(String value) {
    state = state.copyWith(gameUid: value, clearError: true);
  }

  void toggleRulesAccepted(bool? value) {
    state = state.copyWith(rulesAccepted: value ?? false, clearError: true);
  }

  Future<bool> registerForTournament(String tournamentId) async {
    if (state.isLoading) return false;

    if (!state.isFormValid) {
      if (state.gameUid.trim().isEmpty) {
        state = state.copyWith(errorMessage: 'Please enter your in-game Character ID / UID.');
      } else if (!state.rulesAccepted) {
        state = state.copyWith(errorMessage: 'You must confirm and accept the tournament rules.');
      }
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final repo = ref.read(tournamentRepositoryProvider);
      final result = await repo.registerForFreeTournament(
        tournamentId: tournamentId,
        gameUid: state.gameUid.trim(),
      );

      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          successMessage: result.message ?? 'Registration confirmed!',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: result.message ?? 'Registration could not be completed.',
          isDuplicate: result.isDuplicate,
          isFull: result.isFull,
          isDeadlinePassed: result.isDeadlinePassed,
          isSuspended: result.isSuspended,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
      return false;
    }
  }

  void reset() {
    state = const TournamentRegistrationState();
  }
}

final tournamentRegistrationProvider =
    NotifierProvider<TournamentRegistrationNotifier, TournamentRegistrationState>(
  TournamentRegistrationNotifier.new,
);
