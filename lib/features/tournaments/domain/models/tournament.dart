import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported tournament lifecycle statuses.
enum TournamentStatus {
  draft('draft', 'Draft'),
  upcoming('upcoming', 'Upcoming'),
  registrationOpen('registration_open', 'Registration Open'),
  registrationClosed('registration_closed', 'Registration Closed'),
  full('full', 'Full'),
  live('live', 'Live'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String label;
  const TournamentStatus(this.value, this.label);

  static TournamentStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'registration_open':
      case 'registrationopen':
      case 'open':
        return TournamentStatus.registrationOpen;
      case 'registration_closed':
      case 'registrationclosed':
      case 'closed':
        return TournamentStatus.registrationClosed;
      case 'full':
        return TournamentStatus.full;
      case 'live':
        return TournamentStatus.live;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      case 'draft':
        return TournamentStatus.draft;
      case 'upcoming':
      default:
        return TournamentStatus.upcoming;
    }
  }

  bool get isOpen => this == TournamentStatus.registrationOpen;
  bool get isClosed => this == TournamentStatus.registrationClosed;
  bool get isFull => this == TournamentStatus.full;
  bool get isLive => this == TournamentStatus.live;
  bool get isCompleted => this == TournamentStatus.completed;
  bool get isCancelled => this == TournamentStatus.cancelled;
}

/// Tournament entry classification.
enum EntryType {
  free('free', 'Free Entry'),
  paid('paid', 'Paid Entry (Coming Soon)');

  final String value;
  final String label;
  const EntryType(this.value, this.label);

  static EntryType fromString(String? val) {
    if (val?.toLowerCase() == 'paid') return EntryType.paid;
    return EntryType.free;
  }

  bool get isFree => this == EntryType.free;
  bool get isPaid => this == EntryType.paid;
}

/// Production domain model representing a competitive tournament document in Cloud Firestore.
class Tournament {
  final String id;
  final String title;
  final String description;
  final String gameId;
  final String gameName;
  final String? bannerUrl;
  final String organizerUid;
  final String organizerDisplayName;
  final TournamentStatus status;
  final EntryType entryType;
  final double entryFee;
  final String? prizeDescription;
  final int maxParticipants;
  final int registeredCount;
  final DateTime registrationOpensAt;
  final DateTime registrationClosesAt;
  final DateTime startsAt;
  final String rules;
  final String eligibility;
  final String matchFormat;
  final String cancellationPolicy;
  final bool isFeatured;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Tournament({
    required this.id,
    required this.title,
    required this.description,
    required this.gameId,
    required this.gameName,
    this.bannerUrl,
    required this.organizerUid,
    required this.organizerDisplayName,
    required this.status,
    required this.entryType,
    this.entryFee = 0.0,
    this.prizeDescription,
    required this.maxParticipants,
    this.registeredCount = 0,
    required this.registrationOpensAt,
    required this.registrationClosesAt,
    required this.startsAt,
    this.rules = 'Standard competitive esports rules apply.',
    this.eligibility = 'Open to all verified registered players.',
    this.matchFormat = 'Battle Royale / Elimination Format',
    this.cancellationPolicy = 'Tournaments may be rescheduled if minimum lobby capacity is not met.',
    this.isFeatured = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Available participant slots remaining.
  int get availableSlots => (maxParticipants - registeredCount).clamp(0, maxParticipants);

  /// Whether registration is actively open and accepting new players.
  bool get isRegistrationOpen {
    if (status != TournamentStatus.registrationOpen) return false;
    final now = DateTime.now();
    if (now.isBefore(registrationOpensAt) || now.isAfter(registrationClosesAt)) return false;
    if (registeredCount >= maxParticipants) return false;
    return true;
  }

  /// Whether tournament has reached maximum allowed capacity.
  bool get isLobbyFull => registeredCount >= maxParticipants || status == TournamentStatus.full;

  /// Whether the tournament is free of charge.
  bool get isFree => entryType == EntryType.free || entryFee == 0.0;

  /// Whether the tournament is a paid event (booking disabled in Phase 3).
  bool get isPaid => entryType == EntryType.paid || entryFee > 0.0;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'description': description,
      'gameId': gameId,
      'gameName': gameName,
      'bannerUrl': bannerUrl,
      'organizerUid': organizerUid,
      'organizerDisplayName': organizerDisplayName,
      'status': status.value,
      'entryType': entryType.value,
      'entryFee': entryFee,
      'prizeDescription': prizeDescription,
      'maxParticipants': maxParticipants,
      'registeredCount': registeredCount,
      'registrationOpensAt': Timestamp.fromDate(registrationOpensAt),
      'registrationClosesAt': Timestamp.fromDate(registrationClosesAt),
      'startsAt': Timestamp.fromDate(startsAt),
      'rules': rules,
      'eligibility': eligibility,
      'matchFormat': matchFormat,
      'cancellationPolicy': cancellationPolicy,
      'isFeatured': isFeatured,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Tournament.fromMap(Map<String, dynamic> data, {required String id}) {
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

    final now = DateTime.now();

    return Tournament(
      id: id,
      title: data['title'] as String? ?? 'Untitled Tournament',
      description: data['description'] as String? ?? '',
      gameId: data['gameId'] as String? ?? 'bgmi',
      gameName: data['gameName'] as String? ?? 'Battlegrounds Mobile India (BGMI)',
      bannerUrl: data['bannerUrl'] as String?,
      organizerUid: data['organizerUid'] as String? ?? '',
      organizerDisplayName: data['organizerDisplayName'] as String? ?? 'Zone Host',
      status: TournamentStatus.fromString(data['status'] as String?),
      entryType: EntryType.fromString(data['entryType'] as String?),
      entryFee: (data['entryFee'] as num?)?.toDouble() ?? 0.0,
      prizeDescription: data['prizeDescription'] as String?,
      maxParticipants: (data['maxParticipants'] as num?)?.toInt() ?? 100,
      registeredCount: (data['registeredCount'] as num?)?.toInt() ?? 0,
      registrationOpensAt: parseDate(data['registrationOpensAt'], now.subtract(const Duration(days: 1))),
      registrationClosesAt: parseDate(data['registrationClosesAt'], now.add(const Duration(days: 2))),
      startsAt: parseDate(data['startsAt'], now.add(const Duration(days: 3))),
      rules: data['rules'] as String? ?? 'Standard competitive esports rules apply.',
      eligibility: data['eligibility'] as String? ?? 'Open to all verified registered players.',
      matchFormat: data['matchFormat'] as String? ?? 'Battle Royale / Elimination Format',
      cancellationPolicy: data['cancellationPolicy'] as String? ??
          'Tournaments may be rescheduled if minimum lobby capacity is not met.',
      isFeatured: data['isFeatured'] as bool? ?? false,
      createdAt: parseNullableDate(data['createdAt']),
      updatedAt: parseNullableDate(data['updatedAt']),
    );
  }

  Tournament copyWith({
    String? id,
    String? title,
    String? description,
    String? gameId,
    String? gameName,
    String? bannerUrl,
    String? organizerUid,
    String? organizerDisplayName,
    TournamentStatus? status,
    EntryType? entryType,
    double? entryFee,
    String? prizeDescription,
    int? maxParticipants,
    int? registeredCount,
    DateTime? registrationOpensAt,
    DateTime? registrationClosesAt,
    DateTime? startsAt,
    String? rules,
    String? eligibility,
    String? matchFormat,
    String? cancellationPolicy,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      organizerUid: organizerUid ?? this.organizerUid,
      organizerDisplayName: organizerDisplayName ?? this.organizerDisplayName,
      status: status ?? this.status,
      entryType: entryType ?? this.entryType,
      entryFee: entryFee ?? this.entryFee,
      prizeDescription: prizeDescription ?? this.prizeDescription,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registeredCount: registeredCount ?? this.registeredCount,
      registrationOpensAt: registrationOpensAt ?? this.registrationOpensAt,
      registrationClosesAt: registrationClosesAt ?? this.registrationClosesAt,
      startsAt: startsAt ?? this.startsAt,
      rules: rules ?? this.rules,
      eligibility: eligibility ?? this.eligibility,
      matchFormat: matchFormat ?? this.matchFormat,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
