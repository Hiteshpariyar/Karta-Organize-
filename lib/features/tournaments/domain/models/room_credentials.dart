import 'package:cloud_firestore/cloud_firestore.dart';

/// Secure room credentials model for approved participants and organizers.
/// Stored in protected subcollection `/tournaments/{id}/room_credentials/details`.
class RoomCredentials {
  final String tournamentId;
  final String roomId;
  final String roomPassword;
  final DateTime? releaseAt;
  final DateTime? releasedAt;
  final String? instructions;
  final bool isReleased;

  const RoomCredentials({
    required this.tournamentId,
    required this.roomId,
    required this.roomPassword,
    this.releaseAt,
    this.releasedAt,
    this.instructions,
    this.isReleased = true,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'tournamentId': tournamentId,
      'roomId': roomId,
      'roomPassword': roomPassword,
      'releaseAt': releaseAt != null ? Timestamp.fromDate(releaseAt!) : null,
      'releasedAt': releasedAt != null ? Timestamp.fromDate(releasedAt!) : FieldValue.serverTimestamp(),
      'instructions': instructions,
      'isReleased': isReleased,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory RoomCredentials.fromMap(Map<String, dynamic> data, {required String tournamentId}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return RoomCredentials(
      tournamentId: tournamentId,
      roomId: data['roomId'] as String? ?? '',
      roomPassword: data['roomPassword'] as String? ?? '',
      releaseAt: parseDate(data['releaseAt']),
      releasedAt: parseDate(data['releasedAt']),
      instructions: data['instructions'] as String?,
      isReleased: data['isReleased'] as bool? ?? true,
    );
  }
}

