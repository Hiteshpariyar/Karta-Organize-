import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of an individual player's registration or application.
enum RegistrationStatus {
  confirmed('confirmed', 'Confirmed'),
  pending('pending', 'Pending Approval'),
  waitlist('waitlist', 'Waitlisted'),
  rejected('rejected', 'Rejected'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String label;
  const RegistrationStatus(this.value, this.label);

  static RegistrationStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'pending':
        return RegistrationStatus.pending;
      case 'waitlist':
      case 'waitlisted':
        return RegistrationStatus.waitlist;
      case 'rejected':
        return RegistrationStatus.rejected;
      case 'cancelled':
        return RegistrationStatus.cancelled;
      case 'confirmed':
      case 'approved':
      default:
        return RegistrationStatus.confirmed;
    }
  }

  bool get isConfirmed => this == RegistrationStatus.confirmed;
  bool get isPending => this == RegistrationStatus.pending;
  bool get isRejected => this == RegistrationStatus.rejected;
  bool get isWaitlisted => this == RegistrationStatus.waitlist;
  bool get isCancelled => this == RegistrationStatus.cancelled;
}

/// Data model representing a player's entry application / registration in a tournament.
class TournamentRegistration {
  final String id;
  final String tournamentId;
  final String uid;
  final String tournamentTitle;
  final String gameId;
  final String gameName;
  final String gameUid;
  final RegistrationStatus status;
  final int? assignedSlot;
  final String? teamId;
  final String? teamName;
  final List<String>? squadMembers;
  final String paymentStatus;
  final DateTime registeredAt;
  final DateTime? appliedAt;
  final DateTime? approvedAt;
  final DateTime? tournamentStartsAt;
  final String? bannerUrl;
  final String? roomId;
  final String? roomPassword;
  final DateTime? credentialsReleaseAt;

  const TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.uid,
    required this.tournamentTitle,
    required this.gameId,
    required this.gameName,
    required this.gameUid,
    this.status = RegistrationStatus.confirmed,
    this.assignedSlot,
    this.teamId,
    this.teamName,
    this.squadMembers,
    this.paymentStatus = 'free',
    required this.registeredAt,
    this.appliedAt,
    this.approvedAt,
    this.tournamentStartsAt,
    this.bannerUrl,
    this.roomId,
    this.roomPassword,
    this.credentialsReleaseAt,
  });

  /// Whether the player is eligible to receive released room credentials.
  bool get isEligibleForCredentials =>
      status == RegistrationStatus.confirmed || status == RegistrationStatus.confirmed;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'tournamentId': tournamentId,
      'uid': uid,
      'tournamentTitle': tournamentTitle,
      'gameId': gameId,
      'gameName': gameName,
      'gameUid': gameUid,
      'status': status.value,
      'assignedSlot': assignedSlot,
      'teamId': teamId,
      'teamName': teamName,
      'squadMembers': squadMembers,
      'paymentStatus': paymentStatus,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'appliedAt': appliedAt != null ? Timestamp.fromDate(appliedAt!) : Timestamp.fromDate(registeredAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'tournamentStartsAt':
          tournamentStartsAt != null ? Timestamp.fromDate(tournamentStartsAt!) : null,
      'bannerUrl': bannerUrl,
      'credentialsReleaseAt':
          credentialsReleaseAt != null ? Timestamp.fromDate(credentialsReleaseAt!) : null,
      // Note: room credentials are read from dedicated subcollection or encrypted fields
    };
  }

  factory TournamentRegistration.fromMap(Map<String, dynamic> data, {required String id}) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final regDate = parseDate(data['registeredAt'], DateTime.now());

    List<String>? parseSquad(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return null;
    }

    return TournamentRegistration(
      id: id,
      tournamentId: data['tournamentId'] as String? ?? id,
      uid: data['uid'] as String? ?? '',
      tournamentTitle: data['tournamentTitle'] as String? ?? 'Tournament Registration',
      gameId: data['gameId'] as String? ?? '',
      gameName: data['gameName'] as String? ?? '',
      gameUid: data['gameUid'] as String? ?? '',
      status: RegistrationStatus.fromString(data['status'] as String?),
      assignedSlot: (data['assignedSlot'] as num?)?.toInt(),
      teamId: data['teamId'] as String?,
      teamName: data['teamName'] as String?,
      squadMembers: parseSquad(data['squadMembers']),
      paymentStatus: data['paymentStatus'] as String? ?? 'free',
      registeredAt: regDate,
      appliedAt: parseNullableDate(data['appliedAt']) ?? regDate,
      approvedAt: parseNullableDate(data['approvedAt']),
      tournamentStartsAt: parseNullableDate(data['tournamentStartsAt']),
      bannerUrl: data['bannerUrl'] as String?,
      roomId: data['roomId'] as String?,
      roomPassword: data['roomPassword'] as String?,
      credentialsReleaseAt: parseNullableDate(data['credentialsReleaseAt']),
    );
  }

  TournamentRegistration copyWith({
    String? id,
    String? tournamentId,
    String? uid,
    String? tournamentTitle,
    String? gameId,
    String? gameName,
    String? gameUid,
    RegistrationStatus? status,
    int? assignedSlot,
    String? teamId,
    String? teamName,
    List<String>? squadMembers,
    String? paymentStatus,
    DateTime? registeredAt,
    DateTime? appliedAt,
    DateTime? approvedAt,
    DateTime? tournamentStartsAt,
    String? bannerUrl,
    String? roomId,
    String? roomPassword,
    DateTime? credentialsReleaseAt,
  }) {
    return TournamentRegistration(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      uid: uid ?? this.uid,
      tournamentTitle: tournamentTitle ?? this.tournamentTitle,
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      gameUid: gameUid ?? this.gameUid,
      status: status ?? this.status,
      assignedSlot: assignedSlot ?? this.assignedSlot,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      squadMembers: squadMembers ?? this.squadMembers,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      registeredAt: registeredAt ?? this.registeredAt,
      appliedAt: appliedAt ?? this.appliedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      tournamentStartsAt: tournamentStartsAt ?? this.tournamentStartsAt,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      roomId: roomId ?? this.roomId,
      roomPassword: roomPassword ?? this.roomPassword,
      credentialsReleaseAt: credentialsReleaseAt ?? this.credentialsReleaseAt,
    );
  }
}
