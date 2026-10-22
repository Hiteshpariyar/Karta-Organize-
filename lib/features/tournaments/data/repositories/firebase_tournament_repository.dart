import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/models/room_credentials.dart';
import '../../domain/models/tournament.dart';
import '../../domain/models/tournament_registration.dart';
import '../../domain/repositories/tournament_repository.dart';
import 'dev_tournament_repository.dart';

/// Production Cloud Firestore repository for tournaments and atomic registrations.
class FirebaseTournamentRepository implements ITournamentRepository {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;
  final DevTournamentRepository _devFallback = DevTournamentRepository();

  FirebaseTournamentRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _customFirestore = firestore,
        _customAuth = auth;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  @override
  Future<List<Tournament>> fetchFeaturedTournaments() async {
    if (!_isFirebaseReady) {
      return _devFallback.fetchFeaturedTournaments();
    }

    try {
      final snapshot = await _firestore
          .collection('tournaments')
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get();

      if (snapshot.docs.isEmpty) {
        return await _devFallback.fetchFeaturedTournaments();
      }

      return snapshot.docs.map((doc) => Tournament.fromMap(doc.data(), id: doc.id)).toList();
    } catch (_) {
      return await _devFallback.fetchFeaturedTournaments();
    }
  }

  @override
  Future<List<Tournament>> fetchUpcomingTournaments({String? gameId, int limit = 20}) async {
    if (!_isFirebaseReady) {
      return _devFallback.fetchUpcomingTournaments(gameId: gameId, limit: limit);
    }

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('tournaments');

      if (gameId != null && gameId.isNotEmpty && gameId != 'all') {
        query = query.where('gameId', isEqualTo: gameId);
      }

      final snapshot = await query
          .where('status', whereIn: ['registration_open', 'upcoming', 'full'])
          .orderBy('startsAt')
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) {
        return await _devFallback.fetchUpcomingTournaments(gameId: gameId, limit: limit);
      }

      return snapshot.docs.map((doc) => Tournament.fromMap(doc.data(), id: doc.id)).toList();
    } catch (_) {
      return await _devFallback.fetchUpcomingTournaments(gameId: gameId, limit: limit);
    }
  }

  @override
  Future<List<Tournament>> fetchOpenTournaments({String? gameId, int limit = 20}) async {
    if (!_isFirebaseReady) {
      return _devFallback.fetchOpenTournaments(gameId: gameId, limit: limit);
    }

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('tournaments')
          .where('status', isEqualTo: 'registration_open');

      if (gameId != null && gameId.isNotEmpty && gameId != 'all') {
        query = query.where('gameId', isEqualTo: gameId);
      }

      final snapshot = await query.orderBy('startsAt').limit(limit).get();
      return snapshot.docs.map((doc) => Tournament.fromMap(doc.data(), id: doc.id)).toList();
    } catch (_) {
      return await _devFallback.fetchOpenTournaments(gameId: gameId, limit: limit);
    }
  }

  @override
  Future<List<Tournament>> searchTournaments({
    String query = '',
    String? gameId,
    TournamentStatus? status,
    EntryType? entryType,
    int limit = 30,
  }) async {
    if (!_isFirebaseReady) {
      return _devFallback.searchTournaments(
        query: query,
        gameId: gameId,
        status: status,
        entryType: entryType,
        limit: limit,
      );
    }

    try {
      Query<Map<String, dynamic>> ref = _firestore.collection('tournaments');

      if (gameId != null && gameId.isNotEmpty && gameId != 'all') {
        ref = ref.where('gameId', isEqualTo: gameId);
      }

      if (status != null) {
        ref = ref.where('status', isEqualTo: status.value);
      }

      if (entryType != null) {
        ref = ref.where('entryType', isEqualTo: entryType.value);
      }

      final snapshot = await ref.limit(limit).get();
      var results = snapshot.docs.map((d) => Tournament.fromMap(d.data(), id: d.id)).toList();

      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        results = results.where((t) {
          return t.title.toLowerCase().contains(q) ||
              t.gameName.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q) ||
              t.displayOrganizerTeam.toLowerCase().contains(q);
        }).toList();
      }

      results.sort((a, b) => a.startsAt.compareTo(b.startsAt));
      return results;
    } catch (_) {
      return _devFallback.searchTournaments(
        query: query,
        gameId: gameId,
        status: status,
        entryType: entryType,
        limit: limit,
      );
    }
  }

  @override
  Future<Tournament?> fetchTournamentById(String tournamentId) async {
    if (!_isFirebaseReady) {
      return _devFallback.fetchTournamentById(tournamentId);
    }

    try {
      final doc = await _firestore.collection('tournaments').doc(tournamentId).get();
      if (!doc.exists || doc.data() == null) {
        return await _devFallback.fetchTournamentById(tournamentId);
      }
      return Tournament.fromMap(doc.data()!, id: doc.id);
    } catch (_) {
      return await _devFallback.fetchTournamentById(tournamentId);
    }
  }

  @override
  Stream<Tournament?> watchTournament(String tournamentId) {
    if (!_isFirebaseReady) {
      return _devFallback.watchTournament(tournamentId);
    }

    return _firestore.collection('tournaments').doc(tournamentId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Tournament.fromMap(doc.data()!, id: doc.id);
    });
  }

  @override
  Future<RegistrationResult> registerForFreeTournament({
    required String tournamentId,
    required String gameUid,
    String? teamName,
    List<String>? squadMembers,
  }) async {
    final user = _isFirebaseReady ? _auth.currentUser : null;
    final uid = user?.uid ?? 'offline_player_uid';

    if (!_isFirebaseReady) {
      return _devFallback.registerForFreeTournament(
        tournamentId: tournamentId,
        gameUid: gameUid,
        teamName: teamName,
        squadMembers: squadMembers,
        currentUserId: uid,
      );
    }

    if (user == null) {
      return RegistrationResult.failure(message: 'Authentication required to register.');
    }

    try {
      // 1. Check account suspension status first
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userStatus = userDoc.data()?['accountStatus'] as String?;
      if (userStatus == 'suspended') {
        return RegistrationResult.failure(
          message: 'Account suspended: Suspended players cannot enter tournament rooms.',
          isSuspended: true,
        );
      }

      // 2. Perform atomic Firestore transaction
      final tourneyDocRef = _firestore.collection('tournaments').doc(tournamentId);
      final regDocRef = tourneyDocRef.collection('registrations').doc(uid);
      final userRegDocRef =
          _firestore.collection('users').doc(uid).collection('registrations').doc(tournamentId);

      return await _firestore.runTransaction<RegistrationResult>((transaction) async {
        final tourneySnap = await transaction.get(tourneyDocRef);
        if (!tourneySnap.exists || tourneySnap.data() == null) {
          return RegistrationResult.failure(message: 'Tournament document not found.');
        }

        final tournament = Tournament.fromMap(tourneySnap.data()!, id: tourneySnap.id);

        if (tournament.isPaid) {
          return RegistrationResult.failure(
            message: 'Paid tournament booking is disabled in Phase 3. Coming soon.',
          );
        }

        if (tournament.status != TournamentStatus.registrationOpen) {
          return RegistrationResult.failure(
            message:
                'Registration is not open for this tournament (Status: ${tournament.status.label}).',
          );
        }

        if (DateTime.now().isAfter(tournament.registrationClosesAt)) {
          return RegistrationResult.failure(
            message: 'Registration deadline has expired.',
            isDeadlinePassed: true,
          );
        }

        if (tournament.registeredCount >= tournament.maxParticipants) {
          return RegistrationResult.failure(
            message: 'Tournament is full. No slots available.',
            isFull: true,
          );
        }

        // Check duplicate registration
        final existingRegSnap = await transaction.get(regDocRef);
        if (existingRegSnap.exists) {
          return RegistrationResult.failure(
            message: 'You are already registered for this tournament.',
            isDuplicate: true,
          );
        }

        final newCount = tournament.registeredCount + 1;
        final assignedSlot = newCount;
        final isNowFull = newCount >= tournament.maxParticipants;

        // Atomic update of tournament capacity
        transaction.update(tourneyDocRef, {
          'registeredCount': newCount,
          if (isNowFull) 'status': 'full',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Write tournament registration
        final regData = {
          'tournamentId': tournament.id,
          'uid': uid,
          'tournamentTitle': tournament.title,
          'gameId': tournament.gameId,
          'gameName': tournament.gameName,
          'gameUid': gameUid.trim(),
          'assignedSlot': assignedSlot,
          'teamName': teamName?.trim(),
          'squadMembers': squadMembers,
          'paymentStatus': 'free',
          'status': 'confirmed',
          'registeredAt': FieldValue.serverTimestamp(),
          'appliedAt': FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
          'tournamentStartsAt': Timestamp.fromDate(tournament.startsAt),
          'bannerUrl': tournament.bannerUrl,
        };

        transaction.set(regDocRef, regData);
        transaction.set(userRegDocRef, regData);

        // Record player notification
        final notifRef =
            _firestore.collection('users').doc(uid).collection('notifications').doc();

        transaction.set(notifRef, {
          'title': 'Tournament Slot #$assignedSlot Confirmed',
          'body':
              'You have secured Slot #$assignedSlot for ${tournament.title}. Matches begin at ${tournament.startsAt.toLocal()}. Check Room ID 15 minutes before start.',
          'type': 'registration',
          'referenceId': tournament.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return RegistrationResult.success(
          registrationId: uid,
          assignedSlot: assignedSlot,
          message:
              'Slot confirmed! Your registration for ${tournament.title} is successful at Slot #$assignedSlot.',
        );
      });
    } on FirebaseException catch (e) {
      return RegistrationResult.failure(message: 'Registration failed: ${e.message}');
    } catch (e) {
      return RegistrationResult.failure(message: 'Unexpected registration error: ${e.toString()}');
    }
  }

  @override
  Future<List<TournamentRegistration>> fetchPlayerRegistrations({required String uid}) async {
    if (!_isFirebaseReady) {
      return _devFallback.fetchPlayerRegistrations(uid: uid);
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('registrations')
          .orderBy('registeredAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TournamentRegistration.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (_) {
      return _devFallback.fetchPlayerRegistrations(uid: uid);
    }
  }

  @override
  Stream<List<TournamentRegistration>> watchPlayerRegistrations({required String uid}) {
    if (!_isFirebaseReady) {
      return _devFallback.watchPlayerRegistrations(uid: uid);
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('registrations')
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TournamentRegistration.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  @override
  Future<bool> isPlayerRegistered({required String tournamentId, required String uid}) async {
    if (!_isFirebaseReady) {
      return _devFallback.isPlayerRegistered(tournamentId: tournamentId, uid: uid);
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('registrations')
          .doc(tournamentId)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<TournamentRegistration?> fetchPlayerRegistrationForTournament({
    required String tournamentId,
    required String uid,
  }) async {
    if (!_isFirebaseReady) {
      return _devFallback.fetchPlayerRegistrationForTournament(
        tournamentId: tournamentId,
        uid: uid,
      );
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('registrations')
          .doc(tournamentId)
          .get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return TournamentRegistration.fromMap(doc.data()!, id: doc.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RoomCredentials?> fetchRoomCredentials(String tournamentId) async {
    if (!_isFirebaseReady) {
      return _devFallback.fetchRoomCredentials(tournamentId);
    }

    try {
      final doc = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('room_credentials')
          .doc('details')
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return RoomCredentials.fromMap(doc.data()!, tournamentId: tournamentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<RoomCredentials?> watchRoomCredentials(String tournamentId) {
    if (!_isFirebaseReady) {
      return _devFallback.watchRoomCredentials(tournamentId);
    }

    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('room_credentials')
        .doc('details')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RoomCredentials.fromMap(doc.data()!, tournamentId: tournamentId);
    });
  }
}
