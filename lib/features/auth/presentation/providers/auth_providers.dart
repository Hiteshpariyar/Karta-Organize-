import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/auth_security_service.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../policy/data/repositories/firebase_policy_repository.dart';
import '../../../policy/domain/models/policy_acceptance.dart';

/// Centralized provider for Authentication Security & Rate Limiting.
final authSecurityServiceProvider = Provider<AuthSecurityService>((ref) {
  return AuthSecurityService();
});

/// Centralized provider for Authentication and Profile operations.
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return FirebaseAuthRepository(
    securityService: ref.watch(authSecurityServiceProvider),
  );
});


/// Centralized provider for Policy Acceptance tracking.
final policyRepositoryProvider = Provider<IPolicyAcceptanceRepository>((ref) {
  return FirebasePolicyRepository();
});

/// Stream provider for real-time authentication state and verified profile changes.
final authStateProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Current authenticated user profile provider.
final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  final asyncState = ref.watch(authStateProvider);
  if (asyncState.hasValue) {
    return asyncState.value;
  }
  return ref.watch(authRepositoryProvider).currentUserProfile;
});
