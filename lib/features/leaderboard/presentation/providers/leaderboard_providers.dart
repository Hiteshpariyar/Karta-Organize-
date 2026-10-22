import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_leaderboard_repository.dart';
import '../../domain/models/leaderboard_entry.dart';

final leaderboardRepositoryProvider = Provider<FirebaseLeaderboardRepository>((ref) {
  return FirebaseLeaderboardRepository();
});

/// Currently selected game filter for the leaderboard ('all', 'freefire', 'bgmi', 'codm', 'valorant')
class SelectedLeaderboardGameNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setGame(String game) => state = game;
}

final selectedLeaderboardGameProvider =
    NotifierProvider<SelectedLeaderboardGameNotifier, String>(SelectedLeaderboardGameNotifier.new);

/// Stream provider for top 100 leaderboard entries
final topPlayersProvider = StreamProvider.autoDispose<List<LeaderboardEntry>>((ref) {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final gameId = ref.watch(selectedLeaderboardGameProvider);
  return repo.streamTopPlayers(gameId: gameId, limit: 100);
});
