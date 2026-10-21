import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_organizer_repository.dart';
import '../../domain/models/organizer_application.dart';
import '../../domain/repositories/organizer_repository.dart';

/// Centralized provider for tournament organizer application operations.
final organizerRepositoryProvider = Provider<IOrganizerRepository>((ref) {
  return FirebaseOrganizerRepository();
});

/// Real-time stream provider for an organizer application by user UID.
final organizerApplicationStreamProvider =
    StreamProvider.family<OrganizerApplication?, String>((ref, uid) {
  final repo = ref.watch(organizerRepositoryProvider);
  return repo.watchApplicationStatus(uid);
});

