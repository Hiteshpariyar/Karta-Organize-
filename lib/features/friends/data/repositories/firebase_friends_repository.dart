import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/friend_models.dart';

class FirebaseFriendsRepository {
  final FirebaseFirestore _firestore;

  FirebaseFriendsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream active friends for the user
  Stream<List<FriendItem>> streamFriends(String currentUid) {
    return _firestore
        .collection('friends')
        .where('users', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FriendItem.fromMap(
          doc.data(),
          docId: doc.id,
          currentUid: currentUid,
        );
      }).toList();
    });
  }

  /// Stream incoming pending friend requests
  Stream<List<FriendRequest>> streamIncomingRequests(String currentUid) {
    return _firestore
        .collection('friend_requests')
        .where('receiverUid', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }

  /// Stream outgoing pending friend requests
  Stream<List<FriendRequest>> streamSentRequests(String currentUid) {
    return _firestore
        .collection('friend_requests')
        .where('senderUid', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }

  /// Search for players by display name with case tolerance
  Future<List<Map<String, dynamic>>> searchPlayers(String query, String currentUid) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('public_profiles')
          .where('displayName', isGreaterThanOrEqualTo: cleanQuery)
          .where('displayName', isLessThanOrEqualTo: '$cleanQuery\uf8ff')
          .limit(20)
          .get();

      var list = snapshot.docs
          .where((doc) => doc.id != currentUid)
          .map((doc) => doc.data())
          .toList();

      if (list.isEmpty && cleanQuery.isNotEmpty) {
        final capitalized = cleanQuery[0].toUpperCase() + cleanQuery.substring(1);
        final capSnapshot = await _firestore
            .collection('public_profiles')
            .where('displayName', isGreaterThanOrEqualTo: capitalized)
            .where('displayName', isLessThanOrEqualTo: '$capitalized\uf8ff')
            .limit(20)
            .get();

        list = capSnapshot.docs
            .where((doc) => doc.id != currentUid)
            .map((doc) => doc.data())
            .toList();
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  /// Send friend request with self-request, duplicate, and mutual request resolution
  Future<void> sendFriendRequest({
    required String senderUid,
    required String senderDisplayName,
    String? senderAvatarUrl,
    required String receiverUid,
    required String receiverDisplayName,
    String? receiverAvatarUrl,
  }) async {
    if (senderUid == receiverUid) {
      throw Exception('You cannot send a friend request to yourself');
    }

    // 1. Check if already friends
    final sorted = [senderUid, receiverUid]..sort();
    final friendshipId = '${sorted[0]}_${sorted[1]}';
    final existingFriend = await _firestore.collection('friends').doc(friendshipId).get();
    if (existingFriend.exists) {
      throw Exception('You are already friends with this player');
    }

    // 2. Check for existing pending request
    final docId = '${senderUid}_$receiverUid';
    final reverseDocId = '${receiverUid}_$senderUid';
    final req1 = await _firestore.collection('friend_requests').doc(docId).get();
    if (req1.exists && req1.data()?['status'] == 'pending') {
      throw Exception('A friend request has already been sent');
    }

    final req2 = await _firestore.collection('friend_requests').doc(reverseDocId).get();
    if (req2.exists && req2.data()?['status'] == 'pending') {
      // Mutual request resolution: accept existing reverse request
      await acceptFriendRequest(FriendRequest.fromMap(req2.data()!, docId: reverseDocId));
      return;
    }

    final requestDoc = _firestore.collection('friend_requests').doc(docId);
    await requestDoc.set({
      'id': docId,
      'senderUid': senderUid,
      'senderDisplayName': senderDisplayName,
      'senderAvatarUrl': senderAvatarUrl,
      'receiverUid': receiverUid,
      'receiverDisplayName': receiverDisplayName,
      'receiverAvatarUrl': receiverAvatarUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Accept friend request and establish friendship
  Future<void> acceptFriendRequest(FriendRequest request) async {
    final batch = _firestore.batch();

    // 1. Mark request accepted
    final reqRef = _firestore.collection('friend_requests').doc(request.id);
    batch.update(reqRef, {
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Create pair friendship
    final sorted = [request.senderUid, request.receiverUid]..sort();
    final friendshipId = '${sorted[0]}_${sorted[1]}';
    final friendRef = _firestore.collection('friends').doc(friendshipId);

    batch.set(friendRef, {
      'id': friendshipId,
      'users': [request.senderUid, request.receiverUid],
      'user1Id': request.senderUid,
      'user1DisplayName': request.senderDisplayName,
      'user1AvatarUrl': request.senderAvatarUrl,
      'user2Id': request.receiverUid,
      'user2DisplayName': request.receiverDisplayName,
      'user2AvatarUrl': request.receiverAvatarUrl,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cancel outgoing friend request
  Future<void> cancelFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a friend
  Future<void> removeFriend(String friendshipId) async {
    await _firestore.collection('friends').doc(friendshipId).delete();
  }

  /// Block a user
  Future<void> blockUser({
    required String blockerUid,
    required String blockedUid,
    String? blockedDisplayName,
    String? reason,
  }) async {
    final blockId = '${blockerUid}_$blockedUid';
    await _firestore.collection('user_blocks').doc(blockId).set({
      'id': blockId,
      'blockerUid': blockerUid,
      'blockedUid': blockedUid,
      'blockedDisplayName': blockedDisplayName,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Report a user
  Future<void> reportUser({
    required String reporterUid,
    required String reportedUid,
    String? reportedDisplayName,
    required String category,
    required String reason,
    String? details,
  }) async {
    final reportDoc = _firestore.collection('user_reports').doc();
    await reportDoc.set({
      'id': reportDoc.id,
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reportedDisplayName': reportedDisplayName,
      'category': category,
      'reason': reason,
      'details': details,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
