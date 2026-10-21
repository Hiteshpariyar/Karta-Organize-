import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/tournament.dart';
import '../providers/tournament_providers.dart';

class TournamentDiscoveryState {
  final String query;
  final String selectedGameId;
  final TournamentStatus? selectedStatus;
  final EntryType? selectedEntryType;
  final List<Tournament> tournaments;
  final bool isLoading;
  final String? errorMessage;

  const TournamentDiscoveryState({
    this.query = '',
    this.selectedGameId = 'all',
    this.selectedStatus,
    this.selectedEntryType,
    this.tournaments = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TournamentDiscoveryState copyWith({
    String? query,
    String? selectedGameId,
    TournamentStatus? selectedStatus,
    bool clearStatus = false,
    EntryType? selectedEntryType,
    bool clearEntryType = false,
    List<Tournament>? tournaments,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TournamentDiscoveryState(
      query: query ?? this.query,
      selectedGameId: selectedGameId ?? this.selectedGameId,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      selectedEntryType: clearEntryType ? null : (selectedEntryType ?? this.selectedEntryType),
      tournaments: tournaments ?? this.tournaments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TournamentDiscoveryNotifier extends Notifier<TournamentDiscoveryState> {
  @override
  TournamentDiscoveryState build() {
    // Initial fetch on build
    Future.microtask(() => loadTournaments());
    return const TournamentDiscoveryState(isLoading: true);
  }

  void updateQuery(String value) {
    state = state.copyWith(query: value);
    loadTournaments();
  }

  void selectGame(String gameId) {
    state = state.copyWith(selectedGameId: gameId);
    loadTournaments();
  }

  void selectStatus(TournamentStatus? status) {
    if (status == null) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(selectedStatus: status);
    }
    loadTournaments();
  }

  void selectEntryType(EntryType? entryType) {
    if (entryType == null) {
      state = state.copyWith(clearEntryType: true);
    } else {
      state = state.copyWith(selectedEntryType: entryType);
    }
    loadTournaments();
  }

  void resetFilters() {
    state = state.copyWith(
      query: '',
      selectedGameId: 'all',
      clearStatus: true,
      clearEntryType: true,
    );
    loadTournaments();
  }

  Future<void> loadTournaments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(tournamentRepositoryProvider);
      final results = await repo.searchTournaments(
        query: state.query,
        gameId: state.selectedGameId,
        status: state.selectedStatus,
        entryType: state.selectedEntryType,
      );
      state = state.copyWith(
        tournaments: results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load tournaments: ${e.toString()}',
      );
    }
  }
}

final tournamentDiscoveryProvider =
    NotifierProvider<TournamentDiscoveryNotifier, TournamentDiscoveryState>(
  TournamentDiscoveryNotifier.new,
);
