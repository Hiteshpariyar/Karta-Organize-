import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported friend request states
enum FriendRequestStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  cancelled('cancelled');

  final String value;
  const FriendRequestStatus(this.value);

  static FriendRequestStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'rejected':
        return FriendRequestStatus.rejected;
      case 'cancelled':
        return FriendRequestStatus.cancelled;
      case 'pending':
      default:
        return FriendRequestStatus.pending;
    }
  }
}

/// Represents a peer-to-peer friend request
class FriendRequest {
  final String id;
  final String senderUid;
  final String senderDisplayName;
  final String? senderAvatarUrl;
  final String receiverUid;
  final String receiverDisplayName;
  final String? receiverAvatarUrl;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.senderUid,
    required this.senderDisplayName,
    this.senderAvatarUrl,
    required this.receiverUid,
    required this.receiverDisplayName,
    this.receiverAvatarUrl,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> data, {String? docId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return FriendRequest(
      id: data['id'] as String? ?? docId ?? '',
      senderUid: data['senderUid'] as String? ?? '',
      senderDisplayName: data['senderDisplayName'] as String? ?? 'Player',
      senderAvatarUrl: data['senderAvatarUrl'] as String?,
      receiverUid: data['receiverUid'] as String? ?? '',
      receiverDisplayName: data['receiverDisplayName'] as String? ?? 'Player',
      receiverAvatarUrl: data['receiverAvatarUrl'] as String?,
      status: FriendRequestStatus.fromString(data['status'] as String?),
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderUid': senderUid,
      'senderDisplayName': senderDisplayName,
      'senderAvatarUrl': senderAvatarUrl,
      'receiverUid': receiverUid,
      'receiverDisplayName': receiverDisplayName,
      'receiverAvatarUrl': receiverAvatarUrl,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Represents an established friendship
class FriendItem {
  final String id;
  final String friendUid;
  final String friendDisplayName;
  final String? friendAvatarUrl;
  final String? inGameName;
  final DateTime createdAt;

  const FriendItem({
    required this.id,
    required this.friendUid,
    required this.friendDisplayName,
    this.friendAvatarUrl,
    this.inGameName,
    required this.createdAt,
  });

  factory FriendItem.fromMap(Map<String, dynamic> data, {String? docId, required String currentUid}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    String fUid = '';
    String fName = 'Friend';
    String? fAvatar;

    if (data.containsKey('users') && data['users'] is List) {
      final users = List<String>.from(data['users'] as List);
      fUid = users.firstWhere((u) => u != currentUid, orElse: () => '');
      if (data['user1Id'] == fUid) {
        fName = data['user1DisplayName'] as String? ?? 'Friend';
        fAvatar = data['user1AvatarUrl'] as String?;
      } else {
        fName = data['user2DisplayName'] as String? ?? 'Friend';
        fAvatar = data['user2AvatarUrl'] as String?;
      }
    } else {
      fUid = data['friendUid'] as String? ?? '';
      fName = data['friendDisplayName'] as String? ?? 'Friend';
      fAvatar = data['friendAvatarUrl'] as String?;
    }

    return FriendItem(
      id: data['id'] as String? ?? docId ?? '',
      friendUid: fUid,
      friendDisplayName: fName,
      friendAvatarUrl: fAvatar,
      inGameName: data['friendInGameName'] as String?,
      createdAt: parseDate(data['createdAt']),
    );
  }
}

