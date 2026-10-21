import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model capturing explicit policy acceptance record in Cloud Firestore.
///
/// Prepares a clean data contract stored under `/users/{uid}/policy_acceptances/{policyType}`.
class PolicyAcceptanceRecord {
  final String userId;
  final String policyType; // 'player_terms' | 'organizer_terms' | 'privacy_policy'
  final String policyVersion;
  final DateTime acceptedAtLocal;
  final bool accepted;

  const PolicyAcceptanceRecord({
    required this.userId,
    required this.policyType,
    required this.policyVersion,
    required this.acceptedAtLocal,
    this.accepted = true,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'policyType': policyType,
      'policyVersion': policyVersion,
      'acceptedAt': FieldValue.serverTimestamp(),
      'acceptedAtClient': acceptedAtLocal.toIso8601String(),
      'accepted': accepted,
    };
  }

  factory PolicyAcceptanceRecord.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return PolicyAcceptanceRecord(
      userId: map['userId'] as String? ?? '',
      policyType: map['policyType'] as String? ?? '',
      policyVersion: map['policyVersion'] as String? ?? '',
      acceptedAtLocal: parseDate(map['acceptedAt'] ?? map['acceptedAtClient']),
      accepted: map['accepted'] as bool? ?? false,
    );
  }
}

/// Abstract contract for policy acceptance persistence.
abstract class IPolicyAcceptanceRepository {
  Future<bool> recordAcceptance(PolicyAcceptanceRecord record);
  Future<bool> hasAcceptedPolicy({
    required String userId,
    required String policyType,
    required String minVersion,
  });
}
