import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/liquid_glass.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/friends_providers.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showReportDialog(BuildContext context, String reportedUid, String name) {
    String category = 'cheating';
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1738) : Colors.white,
          title: Text(
            'Report $name',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Reason Category'),
                items: const [
                  DropdownMenuItem(value: 'cheating', child: Text('Cheating / Hack')),
                  DropdownMenuItem(value: 'harassment', child: Text('Harassment')),
                  DropdownMenuItem(value: 'abusive_chat', child: Text('Abusive Chat')),
                  DropdownMenuItem(value: 'fake_results', child: Text('Fake Results')),
                  DropdownMenuItem(value: 'other', child: Text('Other Violation')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => category = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  labelText: 'Details / Description',
                  hintText: 'Describe the violation...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                final user = ref.read(currentUserProfileProvider);
                if (user != null && reasonController.text.trim().isNotEmpty) {
                  await ref.read(friendsRepositoryProvider).reportUser(
                        reporterUid: user.uid,
                        reportedUid: reportedUid,
                        reportedDisplayName: name,
                        category: category,
                        reason: reasonController.text.trim(),
                      );
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted for review.')),
                    );
                  }
                }
              },
              child: const Text('Submit Report', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(BuildContext context, String blockedUid, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1738) : Colors.white,
        title: Text(
          'Block $name?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Blocked users cannot send you friend requests or message you.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final user = ref.read(currentUserProfileProvider);
              if (user != null) {
                await ref.read(friendsRepositoryProvider).blockUser(
                      blockerUid: user.uid,
                      blockedUid: blockedUid,
                      blockedDisplayName: name,
                    );
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Blocked $name.')),
                  );
                }
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final friendsAsync = ref.watch(friendsListStreamProvider);
    final incomingAsync = ref.watch(incomingRequestsStreamProvider);
    final sentAsync = ref.watch(sentRequestsStreamProvider);
    final searchResultsAsync = ref.watch(playerSearchResultsProvider);
    final currentUser = ref.watch(currentUserProfileProvider);
    final primaryAccent = const Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Friends & Connections',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryAccent,
          indicatorWeight: 3,
          labelColor: primaryAccent,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Friends'),
                  friendsAsync.maybeWhen(
                    data: (list) => list.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: primaryAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${list.length}',
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Requests'),
                  incomingAsync.maybeWhen(
                    data: (list) => list.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${list.length}',
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Tab(text: 'Sent'),
            const Tab(text: 'Find'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Friends List Tab
          friendsAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
            error: (e, _) => Center(
              child: Text(
                'Error loading friends: $e',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            data: (friends) {
              if (friends.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 64, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(height: 16),
                      Text(
                        'No friends added yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
                        onPressed: () => _tabController.animateTo(3),
                        child: const Text('Find Players', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: friends.length,
                itemBuilder: (context, i) {
                  final f = friends[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: LiquidGlass.container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      borderRadius: 16,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: primaryAccent.withValues(alpha: 0.2),
                            child: Text(
                              f.friendDisplayName.isNotEmpty ? f.friendDisplayName[0].toUpperCase() : 'F',
                              style: const TextStyle(color: Color(0xFF9F7AEA), fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.friendDisplayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  f.inGameName?.isNotEmpty == true ? 'IGN: ${f.inGameName}' : 'Connected Friend',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: isDark ? Colors.white54 : Colors.black54),
                            onSelected: (val) {
                              if (val == 'remove') {
                                ref.read(friendsRepositoryProvider).removeFriend(f.id);
                              } else if (val == 'block') {
                                _showBlockDialog(context, f.friendUid, f.friendDisplayName);
                              } else if (val == 'report') {
                                _showReportDialog(context, f.friendUid, f.friendDisplayName);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'remove', child: Text('Remove Friend')),
                              const PopupMenuItem(value: 'block', child: Text('Block Player')),
                              const PopupMenuItem(value: 'report', child: Text('Report Player')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // 2. Incoming Requests Tab
          incomingAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
            error: (e, _) => Center(
              child: Text('Error: $e', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            ),
            data: (reqs) {
              if (reqs.isEmpty) {
                return Center(
                  child: Text(
                    'No pending incoming friend requests',
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: reqs.length,
                itemBuilder: (context, i) {
                  final r = reqs[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: LiquidGlass.container(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 16,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: primaryAccent.withValues(alpha: 0.2),
                            child: Text(
                              r.senderDisplayName.isNotEmpty ? r.senderDisplayName[0].toUpperCase() : 'P',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r.senderDisplayName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                            tooltip: 'Accept',
                            onPressed: () {
                              ref.read(friendsRepositoryProvider).acceptFriendRequest(r);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            tooltip: 'Decline',
                            onPressed: () {
                              ref.read(friendsRepositoryProvider).rejectFriendRequest(r.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // 3. Sent Requests Tab
          sentAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
            error: (e, _) => Center(
              child: Text('Error: $e', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            ),
            data: (reqs) {
              if (reqs.isEmpty) {
                return Center(
                  child: Text(
                    'No outgoing friend requests sent',
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: reqs.length,
                itemBuilder: (context, i) {
                  final r = reqs[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: LiquidGlass.container(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 16,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: primaryAccent.withValues(alpha: 0.2),
                            child: Text(
                              r.receiverDisplayName.isNotEmpty ? r.receiverDisplayName[0].toUpperCase() : 'P',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r.receiverDisplayName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(friendsRepositoryProvider).cancelFriendRequest(r.id);
                            },
                            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // 4. Find Players Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search by Player Name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(playerSearchQueryProvider.notifier).setQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    ref.read(playerSearchQueryProvider.notifier).setQuery(val.trim());
                  },
                ),
              ),
              Expanded(
                child: searchResultsAsync.when(
                  loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
                  error: (e, _) => Center(
                    child: Text('Error: $e', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                  ),
                  data: (results) {
                    if (_searchController.text.trim().isEmpty) {
                      return Center(
                        child: Text(
                          'Type a player name to search',
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                        ),
                      );
                    }
                    if (results.isEmpty) {
                      return Center(
                        child: Text(
                          'No players found matching "${_searchController.text.trim()}"',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final p = results[i];
                        final targetUid = p['uid'] as String? ?? '';
                        final targetName = p['displayName'] as String? ?? 'Player';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: LiquidGlass.container(
                            padding: const EdgeInsets.all(12),
                            borderRadius: 16,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: primaryAccent.withValues(alpha: 0.2),
                                  child: Text(
                                    targetName.isNotEmpty ? targetName[0].toUpperCase() : 'P',
                                    style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    targetName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryAccent,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.person_add, size: 16, color: Colors.white),
                                  label: const Text('Connect', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  onPressed: () async {
                                    if (currentUser != null) {
                                      try {
                                        await ref.read(friendsRepositoryProvider).sendFriendRequest(
                                              senderUid: currentUser.uid,
                                              senderDisplayName: currentUser.displayName,
                                              receiverUid: targetUid,
                                              receiverDisplayName: targetName,
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Friend request sent to $targetName')),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
