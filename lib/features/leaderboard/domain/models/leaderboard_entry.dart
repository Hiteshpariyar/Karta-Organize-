import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a ranked player entry on the global or game-specific leaderboard.
class LeaderboardEntry {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? inGameName;
  final String gameId;
  final int score;
  final int rank;
  final int wins;
  final int matchesPlayed;
  final double winRate;
  final DateTime updatedAt;

  const LeaderboardEntry({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.inGameName,
    required this.gameId,
    required this.score,
    required this.rank,
    required this.wins,
    required this.matchesPlayed,
    required this.winRate,
    required this.updatedAt,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> data, {String? docId, int defaultRank = 0}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final wins = (data['wins'] as num?)?.toInt() ?? 0;
    final matches = (data['matchesPlayed'] as num?)?.toInt() ?? 0;
    final winRate = matches > 0 ? (wins / matches) * 100.0 : 0.0;

    return LeaderboardEntry(
      id: data['id'] as String? ?? docId ?? '',
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Player',
      avatarUrl: data['avatarUrl'] as String?,
      inGameName: data['inGameName'] as String?,
      gameId: data['gameId'] as String? ?? 'all',
      score: (data['score'] as num?)?.toInt() ?? 0,
      rank: (data['rank'] as num?)?.toInt() ?? defaultRank,
      wins: wins,
      matchesPlayed: matches,
      winRate: (data['winRate'] as num?)?.toDouble() ?? winRate,
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'inGameName': inGameName,
      'gameId': gameId,
      'score': score,
      'rank': rank,
      'wins': wins,
      'matchesPlayed': matchesPlayed,
      'winRate': winRate,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

