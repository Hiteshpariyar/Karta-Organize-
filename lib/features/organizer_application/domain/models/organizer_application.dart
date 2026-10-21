import 'package:cloud_firestore/cloud_firestore.dart';

/// Enumeration of tournament format preferences.
enum TournamentPreference {
  freeOnly('Free Tournaments', 'Organize community and scrim tournaments with zero entry fee.'),
  paidOnly('Paid Tournaments', 'Organize prize-pool tournaments with entry fees (Currently inactive in Phase 4).'),
  both('Both Free and Paid Tournaments', 'Organize a hybrid mix of community scrims and paid prize-pool events.');

  final String label;
  final String description;
  const TournamentPreference(this.label, this.description);

  static TournamentPreference fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'paidonly':
      case 'paid':
        return TournamentPreference.paidOnly;
      case 'both':
        return TournamentPreference.both;
      case 'freeonly':
      case 'free':
      default:
        return TournamentPreference.freeOnly;
    }
  }
}

/// Enumeration of organizer application approval states.
enum OrganizerApprovalStatus {
  pending('Under Review', 'Pending administrative verification'),
  approved('Approved', 'Verified organizer privileges granted'),
  rejected('Not Approved', 'Application requires modification or failed criteria'),
  loading('Checking Status', 'Querying backend verification service'),
  error('Verification Error', 'Unable to reach verification service');

  final String title;
  final String subtitle;
  const OrganizerApprovalStatus(this.title, this.subtitle);

  static OrganizerApprovalStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'approved':
        return OrganizerApprovalStatus.approved;
      case 'rejected':
        return OrganizerApprovalStatus.rejected;
      case 'pending':
      default:
        return OrganizerApprovalStatus.pending;
    }
  }
}

/// Data model representing an organizer candidate's application in Cloud Firestore.
class OrganizerApplication {
  final String applicationId;
  final String uid;
  final String applicantName;
  final String organizationName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final String inGameUid;
  final List<String> games;
  final Map<String, String> gameUids;
  final TournamentPreference tournamentPreference;
  final OrganizerApprovalStatus status;
  final bool policyAccepted;
  final String? policyVersion;
  final DateTime? policyAcceptedAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? referenceId;
  final DateTime? updatedAt;

  const OrganizerApplication({
    this.applicationId = '',
    this.uid = '',
    this.applicantName = '',
    this.organizationName = '',
    this.email = '',
    this.phoneNumber = '',
    this.countryCode = '+91',
    this.inGameUid = '',
    this.games = const [],
    this.gameUids = const {},
    this.tournamentPreference = TournamentPreference.freeOnly,
    this.status = OrganizerApprovalStatus.pending,
    this.policyAccepted = false,
    this.policyVersion,
    this.policyAcceptedAt,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.referenceId,
    this.updatedAt,
  });

  // Aliases for UI compatibility
  String get name => applicantName;
  String get phone => phoneNumber;
  List<String> get selectedGames => games;

  bool get isPending => status == OrganizerApprovalStatus.pending;
  bool get isApproved => status == OrganizerApprovalStatus.approved;
  bool get isRejected => status == OrganizerApprovalStatus.rejected;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'applicationId': applicationId.isNotEmpty ? applicationId : uid,
      'uid': uid,
      'applicantName': applicantName,
      'organizationName': organizationName,
      'email': email,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'inGameUid': inGameUid,
      'games': games,
      'gameUids': gameUids,
      'tournamentPreference': tournamentPreference.name,
      'status': status.name,
      'policyAccepted': policyAccepted,
      'policyVersion': policyVersion,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : FieldValue.serverTimestamp(),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'referenceId': referenceId ?? 'TZ-ORG-${uid.length >= 6 ? uid.substring(0, 6) : uid}',
    };
  }

  factory OrganizerApplication.fromMap(Map<String, dynamic> data, {String? docId}) {
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

    return OrganizerApplication(
      applicationId: data['applicationId'] as String? ?? docId ?? '',
      uid: data['uid'] as String? ?? '',
      applicantName: (data['applicantName'] ?? data['name']) as String? ?? '',
      organizationName: data['organizationName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: (data['phoneNumber'] ?? data['phone']) as String? ?? '',
      countryCode: data['countryCode'] as String? ?? '+91',
      inGameUid: data['inGameUid'] as String? ?? '',
      games: (data['games'] as List?)?.map((e) => e.toString()).toList() ??
          (data['selectedGames'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      gameUids: parseGameUids(data['gameUids']),
      tournamentPreference: TournamentPreference.fromString(
        data['tournamentPreference'] as String?,
      ),
      status: OrganizerApprovalStatus.fromString(data['status'] as String?),
      policyAccepted: data['policyAccepted'] as bool? ?? false,
      policyVersion: data['policyVersion'] as String?,
      policyAcceptedAt: parseDate(data['policyAcceptedAt']),
      submittedAt: parseDate(data['submittedAt']),
      reviewedAt: parseDate(data['reviewedAt']),
      reviewedBy: data['reviewedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      referenceId: data['referenceId'] as String?,
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  OrganizerApplication copyWith({
    String? applicationId,
    String? uid,
    String? applicantName,
    String? name,
    String? organizationName,
    String? email,
    String? phoneNumber,
    String? phone,
    String? countryCode,
    String? inGameUid,
    List<String>? games,
    List<String>? selectedGames,
    Map<String, String>? gameUids,
    TournamentPreference? tournamentPreference,
    OrganizerApprovalStatus? status,
    bool? policyAccepted,
    String? policyVersion,
    DateTime? policyAcceptedAt,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? referenceId,
    DateTime? updatedAt,
  }) {
    return OrganizerApplication(
      applicationId: applicationId ?? this.applicationId,
      uid: uid ?? this.uid,
      applicantName: applicantName ?? name ?? this.applicantName,
      organizationName: organizationName ?? this.organizationName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? phone ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      inGameUid: inGameUid ?? this.inGameUid,
      games: games ?? selectedGames ?? this.games,
      gameUids: gameUids ?? this.gameUids,
      tournamentPreference: tournamentPreference ?? this.tournamentPreference,
      status: status ?? this.status,
      policyAccepted: policyAccepted ?? this.policyAccepted,
      policyVersion: policyVersion ?? this.policyVersion,
      policyAcceptedAt: policyAcceptedAt ?? this.policyAcceptedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      referenceId: referenceId ?? this.referenceId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
