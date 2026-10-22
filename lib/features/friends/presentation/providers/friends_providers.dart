import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/firebase_friends_repository.dart';
import '../../domain/models/friend_models.dart';

final friendsRepositoryProvider = Provider<FirebaseFriendsRepository>((ref) {
  return FirebaseFriendsRepository();
});

/// Stream of current user's friends
final friendsListStreamProvider = StreamProvider.autoDispose<List<FriendItem>>((ref) {
  final user = ref.watch(currentUserProfileProvider);
  if (user == null || user.uid.isEmpty) return Stream.value([]);
  return ref.watch(friendsRepositoryProvider).streamFriends(user.uid);
});

/// Stream of incoming pending friend requests
final incomingRequestsStreamProvider = StreamProvider.autoDispose<List<FriendRequest>>((ref) {
  final user = ref.watch(currentUserProfileProvider);
  if (user == null || user.uid.isEmpty) return Stream.value([]);
  return ref.watch(friendsRepositoryProvider).streamIncomingRequests(user.uid);
});

/// Stream of outgoing pending requests
final sentRequestsStreamProvider = StreamProvider.autoDispose<List<FriendRequest>>((ref) {
  final user = ref.watch(currentUserProfileProvider);
  if (user == null || user.uid.isEmpty) return Stream.value([]);
  return ref.watch(friendsRepositoryProvider).streamSentRequests(user.uid);
});

/// Player search query controller
class PlayerSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
}

final playerSearchQueryProvider =
    NotifierProvider.autoDispose<PlayerSearchQueryNotifier, String>(PlayerSearchQueryNotifier.new);

/// Player search results provider
final playerSearchResultsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(playerSearchQueryProvider);
  final user = ref.watch(currentUserProfileProvider);
  if (query.trim().isEmpty || user == null) return [];
  return ref.watch(friendsRepositoryProvider).searchPlayers(query, user.uid);
});
