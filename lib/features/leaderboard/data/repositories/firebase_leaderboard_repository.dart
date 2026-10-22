import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/leaderboard_entry.dart';

class FirebaseLeaderboardRepository {
  final FirebaseFirestore _firestore;

  FirebaseLeaderboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of top 100 players, sorted by score descending, with robust tie-handling.
  Stream<List<LeaderboardEntry>> streamTopPlayers({String gameId = 'all', int limit = 100}) {
    Query<Map<String, dynamic>> query = _firestore.collection('leaderboards');

    if (gameId != 'all') {
      query = query.where('gameId', isEqualTo: gameId);
    }

    return query
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final entries = <LeaderboardEntry>[];
      int? previousScore;
      int currentRank = 1;

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        final score = (data['score'] as num?)?.toInt() ?? 0;

        // If score differs from previous, assign sequential index rank. Otherwise maintain tie.
        if (previousScore != null && score < previousScore) {
          currentRank = i + 1;
        }
        previousScore = score;

        entries.add(LeaderboardEntry.fromMap(data, docId: doc.id, defaultRank: currentRank));
      }
      return entries;
    });
  }

  /// Get current user's leaderboard entry
  Future<LeaderboardEntry?> getUserRank(String uid, {String gameId = 'all'}) async {
    try {
      final query = _firestore
          .collection('leaderboards')
          .where('userId', isEqualTo: uid);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return LeaderboardEntry.fromMap(doc.data(), docId: doc.id);
      }
    } catch (_) {}
    return null;
  }
}
