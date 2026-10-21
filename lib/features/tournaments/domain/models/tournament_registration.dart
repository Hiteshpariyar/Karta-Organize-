import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of an individual player's registration.
enum RegistrationStatus {
  confirmed('confirmed', 'Confirmed'),
  waitlist('waitlist', 'Waitlisted'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String label;
  const RegistrationStatus(this.value, this.label);

  static RegistrationStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'waitlist':
      case 'waitlisted':
        return RegistrationStatus.waitlist;
      case 'cancelled':
        return RegistrationStatus.cancelled;
      case 'confirmed':
      default:
        return RegistrationStatus.confirmed;
    }
  }

  bool get isConfirmed => this == RegistrationStatus.confirmed;
  bool get isCancelled => this == RegistrationStatus.cancelled;
}

/// Data model representing a player's entry registration in a tournament.
class TournamentRegistration {
  final String id;
  final String tournamentId;
  final String uid;
  final String tournamentTitle;
  final String gameId;
  final String gameName;
  final String gameUid;
  final RegistrationStatus status;
  final DateTime registeredAt;
  final DateTime? tournamentStartsAt;
  final String? bannerUrl;

  const TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.uid,
    required this.tournamentTitle,
    required this.gameId,
    required this.gameName,
    required this.gameUid,
    this.status = RegistrationStatus.confirmed,
    required this.registeredAt,
    this.tournamentStartsAt,
    this.bannerUrl,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'tournamentId': tournamentId,
      'uid': uid,
      'tournamentTitle': tournamentTitle,
      'gameId': gameId,
      'gameName': gameName,
      'gameUid': gameUid,
      'status': status.value,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'tournamentStartsAt':
          tournamentStartsAt != null ? Timestamp.fromDate(tournamentStartsAt!) : null,
      'bannerUrl': bannerUrl,
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

    return TournamentRegistration(
      id: id,
      tournamentId: data['tournamentId'] as String? ?? id,
      uid: data['uid'] as String? ?? '',
      tournamentTitle: data['tournamentTitle'] as String? ?? 'Tournament Registration',
      gameId: data['gameId'] as String? ?? '',
      gameName: data['gameName'] as String? ?? '',
      gameUid: data['gameUid'] as String? ?? '',
      status: RegistrationStatus.fromString(data['status'] as String?),
      registeredAt: parseDate(data['registeredAt'], DateTime.now()),
      tournamentStartsAt: parseNullableDate(data['tournamentStartsAt']),
      bannerUrl: data['bannerUrl'] as String?,
    );
  }
}
