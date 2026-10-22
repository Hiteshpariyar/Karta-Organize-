import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported user roles in TourneyZone.
enum UserRole {
  player('player'),
  organizer('organizer'),
  admin('admin');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'organizer':
        return UserRole.organizer;
      case 'admin':
        return UserRole.admin;
      case 'player':
      default:
        return UserRole.player;
    }
  }
}

/// Account operational standing.
enum AccountStatus {
  active('active'),
  suspended('suspended'),
  pendingVerification('pending_verification');

  final String value;
  const AccountStatus(this.value);

  static AccountStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'suspended':
        return AccountStatus.suspended;
      case 'pending_verification':
        return AccountStatus.pendingVerification;
      case 'active':
      default:
        return AccountStatus.active;
    }
  }
}

/// Domain model representing a verified user profile in Cloud Firestore.
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final UserRole role;
  final AccountStatus accountStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String termsVersionAccepted;
  final String privacyVersionAccepted;
  final DateTime? policyAcceptedAt;
  final bool emailVerified;
  final Map<String, String> gameUids;
  final String? photoUrl;
  final String? phoneNumber;
  final String? phonePrivacy;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.role = UserRole.player,
    this.accountStatus = AccountStatus.active,
    this.createdAt,
    this.updatedAt,
    this.termsVersionAccepted = '1.0.0',
    this.privacyVersionAccepted = '0.1.0-draft',
    this.policyAcceptedAt,
    this.emailVerified = false,
    this.gameUids = const {},
    this.photoUrl,
    this.phoneNumber,
    this.phonePrivacy = 'friends_only',
  });

  bool get isActive => accountStatus == AccountStatus.active;
  bool get isSuspended => accountStatus == AccountStatus.suspended;
  bool get isOrganizer => role == UserRole.organizer;
  bool get isAdmin => role == UserRole.admin;
  bool get isPlayer => role == UserRole.player;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'role': role.value,
      'accountStatus': accountStatus.value,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'termsVersionAccepted': termsVersionAccepted,
      'privacyVersionAccepted': privacyVersionAccepted,
      'policyAcceptedAt': policyAcceptedAt != null
          ? Timestamp.fromDate(policyAcceptedAt!)
          : FieldValue.serverTimestamp(),
      'emailVerified': emailVerified,
      'gameUids': gameUids,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'phonePrivacy': phonePrivacy,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> data, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    Map<String, String> parseGameUids(dynamic value) {
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return const {};
    }

    return UserProfile(
      uid: data['uid'] as String? ?? docId ?? '',
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      accountStatus: AccountStatus.fromString(data['accountStatus'] as String?),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      termsVersionAccepted: data['termsVersionAccepted'] as String? ?? '1.0.0',
      privacyVersionAccepted: data['privacyVersionAccepted'] as String? ?? '0.1.0-draft',
      policyAcceptedAt: parseDate(data['policyAcceptedAt']),
      emailVerified: data['emailVerified'] as bool? ?? false,
      gameUids: parseGameUids(data['gameUids']),
      photoUrl: data['photoUrl'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      phonePrivacy: data['phonePrivacy'] as String? ?? 'friends_only',
    );
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    UserRole? role,
    AccountStatus? accountStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? termsVersionAccepted,
    String? privacyVersionAccepted,
    DateTime? policyAcceptedAt,
    bool? emailVerified,
    Map<String, String>? gameUids,
    String? photoUrl,
    String? phoneNumber,
    String? phonePrivacy,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      termsVersionAccepted: termsVersionAccepted ?? this.termsVersionAccepted,
      privacyVersionAccepted: privacyVersionAccepted ?? this.privacyVersionAccepted,
      policyAcceptedAt: policyAcceptedAt ?? this.policyAcceptedAt,
      emailVerified: emailVerified ?? this.emailVerified,
      gameUids: gameUids ?? this.gameUids,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phonePrivacy: phonePrivacy ?? this.phonePrivacy,
    );
  }
}
