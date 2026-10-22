import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported tournament lifecycle statuses.
enum TournamentStatus {
  draft('draft', 'Draft'),
  upcoming('upcoming', 'Upcoming'),
  registrationOpen('registration_open', 'Open'),
  registrationClosed('registration_closed', 'Closed'),
  full('full', 'Full'),
  live('live', 'Live'),
  completed('completed', 'Finished'),
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
      case 'ongoing':
        return TournamentStatus.live;
      case 'completed':
      case 'finished':
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
  bool get isUpcoming => this == TournamentStatus.upcoming;
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
  final String? organizerTeamName;
  final double? organizerRating;
  final int? organizerReviewCount;
  final bool isOrganizerVerified;
  final int? organizerCompletedTournaments;
  final TournamentStatus status;
  final EntryType entryType;
  final double entryFee;
  final String currency;
  final String? prizePool;
  final String? prizeDescription;
  final Map<String, dynamic>? prizeDistribution;
  final double? perKillReward;
  final int maxParticipants;
  final int registeredCount;
  final DateTime registrationOpensAt;
  final DateTime registrationClosesAt;
  final DateTime startsAt;
  final DateTime? reportingAt;
  final String rules;
  final String eligibility;
  final String matchFormat;
  final String? mode;
  final String? mapName;
  final int teamSize;
  final String cancellationPolicy;
  final bool isFeatured;
  final DateTime? credentialsReleaseAt;
  final bool credentialsReleased;
  final String? roomId;
  final String? roomPassword;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Tournament({
    required this.id,
    required this.title,
    this.description = '',
    required this.gameId,
    required this.gameName,
    this.bannerUrl,
    required this.organizerUid,
    required this.organizerDisplayName,
    this.organizerTeamName,
    this.organizerRating,
    this.organizerReviewCount,
    this.isOrganizerVerified = false,
    this.organizerCompletedTournaments,
    required this.status,
    required this.entryType,
    this.entryFee = 0.0,
    this.currency = '₹',
    this.prizePool,
    this.prizeDescription,
    this.prizeDistribution,
    this.perKillReward,
    required this.maxParticipants,
    this.registeredCount = 0,
    DateTime? registrationOpensAt,
    DateTime? registrationClosesAt,
    required this.startsAt,
    this.reportingAt,
    this.rules = 'Standard competitive esports rules apply.',
    this.eligibility = 'Open to all verified registered players.',
    this.matchFormat = 'Battle Royale / Elimination Format',
    this.mode,
    this.mapName,
    this.teamSize = 1,
    this.cancellationPolicy =
        'Tournaments may be rescheduled if minimum lobby capacity is not met.',
    this.isFeatured = false,
    this.credentialsReleaseAt,
    this.credentialsReleased = false,
    this.roomId,
    this.roomPassword,
    this.createdAt,
    this.updatedAt,
  })  : registrationOpensAt = registrationOpensAt ?? startsAt,
        registrationClosesAt = registrationClosesAt ?? startsAt;

  /// Available participant slots remaining.
  int get availableSlots => (maxParticipants - registeredCount).clamp(0, maxParticipants);

  /// Alias for availableSlots for backward and test compatibility.
  int get slotsRemaining => availableSlots;

  /// Alias for maxParticipants.
  int get totalSlots => maxParticipants;

  /// Alias for registeredCount.
  int get allocatedSlots => registeredCount;

  /// Alias for registrationClosesAt.
  DateTime get registrationDeadline => registrationClosesAt;

  /// Effective reporting time (defaults to 15 minutes before startsAt if unspecified).
  DateTime get effectiveReportingTime =>
      reportingAt ?? startsAt.subtract(const Duration(minutes: 15));

  /// Effective credentials release time (defaults to 15 minutes before startsAt if unspecified).
  DateTime get effectiveCredentialsReleaseTime =>
      credentialsReleaseAt ?? startsAt.subtract(const Duration(minutes: 15));

  /// Whether credentials should be unlocked (either marked released or current time past release).
  bool get areCredentialsUnlocked {
    if (credentialsReleased) return true;
    if (credentialsReleaseAt != null && DateTime.now().isAfter(credentialsReleaseAt!)) {
      return true;
    }
    return false;
  }

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

  /// Alias for isLobbyFull.
  bool get isFull => isLobbyFull;

  /// Whether the tournament is live / ongoing.
  bool get isOngoing => status == TournamentStatus.live;

  /// Whether the tournament is completed.
  bool get isCompleted => status == TournamentStatus.completed;

  /// Whether the tournament is upcoming.
  bool get isUpcoming => status == TournamentStatus.upcoming;

  /// Whether the tournament is cancelled.
  bool get isCancelled => status == TournamentStatus.cancelled;

  /// Whether the tournament is free of charge.
  bool get isFree => entryType == EntryType.free || entryFee == 0.0;

  /// Whether the tournament is a paid event (booking disabled in Phase 3).
  bool get isPaid => entryType == EntryType.paid || entryFee > 0.0;

  /// Slot capacity fill percentage (0.0 to 1.0).
  double get slotFillPercentage =>
      maxParticipants > 0 ? (registeredCount / maxParticipants).clamp(0.0, 1.0) : 0.0;

  /// Display organizer organization / team name.
  String get displayOrganizerTeam =>
      (organizerTeamName != null && organizerTeamName!.trim().isNotEmpty)
          ? organizerTeamName!
          : organizerDisplayName;

  /// Display organizer personal display name.
  String get displayOrganizerHost => organizerDisplayName;

  /// Formatted total prize pool display string.
  String get formattedPrizePool {
    if (prizePool != null && prizePool!.trim().isNotEmpty) {
      return prizePool!.trim();
    }
    if (prizeDescription != null && prizeDescription!.trim().isNotEmpty) {
      return prizeDescription!.trim();
    }
    return 'Glory & Prestige';
  }

  /// Formatted entry fee string.
  String get formattedEntryFee {
    if (isFree) return 'FREE';
    final amount = entryFee % 1 == 0 ? entryFee.toInt().toString() : entryFee.toStringAsFixed(2);
    return '$currency$amount';
  }

  /// Formatted per-kill reward string if configured.
  String? get formattedPerKillReward {
    if (perKillReward == null || perKillReward! <= 0) return null;
    final amount = perKillReward! % 1 == 0
        ? perKillReward!.toInt().toString()
        : perKillReward!.toStringAsFixed(2);
    return '+$currency$amount / kill';
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'description': description,
      'gameId': gameId,
      'gameName': gameName,
      'bannerUrl': bannerUrl,
      'organizerUid': organizerUid,
      'organizerDisplayName': organizerDisplayName,
      'organizerTeamName': organizerTeamName,
      'organizerRating': organizerRating,
      'organizerReviewCount': organizerReviewCount,
      'isOrganizerVerified': isOrganizerVerified,
      'organizerCompletedTournaments': organizerCompletedTournaments,
      'status': status.value,
      'entryType': entryType.value,
      'entryFee': entryFee,
      'currency': currency,
      'prizePool': prizePool ?? prizeDescription,
      'prizeDescription': prizeDescription ?? prizePool,
      'prizeDistribution': prizeDistribution,
      'perKillReward': perKillReward,
      'maxParticipants': maxParticipants,
      'registeredCount': registeredCount,
      'registrationOpensAt': Timestamp.fromDate(registrationOpensAt),
      'registrationClosesAt': Timestamp.fromDate(registrationClosesAt),
      'startsAt': Timestamp.fromDate(startsAt),
      'reportingAt': reportingAt != null ? Timestamp.fromDate(reportingAt!) : null,
      'rules': rules,
      'eligibility': eligibility,
      'matchFormat': matchFormat,
      'mode': mode,
      'mapName': mapName,
      'teamSize': teamSize,
      'cancellationPolicy': cancellationPolicy,
      'isFeatured': isFeatured,
      'credentialsReleaseAt':
          credentialsReleaseAt != null ? Timestamp.fromDate(credentialsReleaseAt!) : null,
      'credentialsReleased': credentialsReleased,
      // Note: Plaintext roomId and roomPassword are NEVER written here to protect public security.
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
    final startsAtDate = parseDate(data['startsAt'], now.add(const Duration(days: 3)));

    Map<String, dynamic>? parseDistribution(dynamic val) {
      if (val is Map) {
        return Map<String, dynamic>.from(val);
      }
      return null;
    }

    return Tournament(
      id: id,
      title: data['title'] as String? ?? 'Untitled Tournament',
      description: data['description'] as String? ?? '',
      gameId: data['gameId'] as String? ?? 'bgmi',
      gameName: data['gameName'] as String? ?? 'Battlegrounds Mobile India (BGMI)',
      bannerUrl: data['bannerUrl'] as String?,
      organizerUid: data['organizerUid'] as String? ?? '',
      organizerDisplayName: data['organizerDisplayName'] as String? ?? 'Zone Host',
      organizerTeamName: data['organizerTeamName'] as String?,
      organizerRating: (data['organizerRating'] as num?)?.toDouble(),
      organizerReviewCount: (data['organizerReviewCount'] as num?)?.toInt(),
      isOrganizerVerified: data['isOrganizerVerified'] as bool? ?? false,
      organizerCompletedTournaments: (data['organizerCompletedTournaments'] as num?)?.toInt(),
      status: TournamentStatus.fromString(data['status'] as String?),
      entryType: EntryType.fromString(data['entryType'] as String?),
      entryFee: (data['entryFee'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? '₹',
      prizePool: data['prizePool'] as String? ?? data['prizeDescription'] as String?,
      prizeDescription: data['prizeDescription'] as String? ?? data['prizePool'] as String?,
      prizeDistribution: parseDistribution(data['prizeDistribution']),
      perKillReward: (data['perKillReward'] as num?)?.toDouble(),
      maxParticipants: (data['maxParticipants'] as num?)?.toInt() ?? 100,
      registeredCount: (data['registeredCount'] as num?)?.toInt() ?? 0,
      registrationOpensAt: parseDate(
        data['registrationOpensAt'],
        now.subtract(const Duration(days: 1)),
      ),
      registrationClosesAt: parseDate(
        data['registrationClosesAt'],
        startsAtDate.subtract(const Duration(hours: 2)),
      ),
      startsAt: startsAtDate,
      reportingAt: parseNullableDate(data['reportingAt']),
      rules: data['rules'] as String? ?? 'Standard competitive esports rules apply.',
      eligibility: data['eligibility'] as String? ?? 'Open to all verified registered players.',
      matchFormat: data['matchFormat'] as String? ?? 'Battle Royale / Elimination Format',
      mode: data['mode'] as String?,
      mapName: data['mapName'] as String?,
      teamSize: (data['teamSize'] as num?)?.toInt() ?? 1,
      cancellationPolicy: data['cancellationPolicy'] as String? ??
          'Tournaments may be rescheduled if minimum lobby capacity is not met.',
      isFeatured: data['isFeatured'] as bool? ?? false,
      credentialsReleaseAt: parseNullableDate(data['credentialsReleaseAt']),
      credentialsReleased: data['credentialsReleased'] as bool? ?? false,
      roomId: data['roomId'] as String?,
      roomPassword: data['roomPassword'] as String?,
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
    String? organizerTeamName,
    double? organizerRating,
    int? organizerReviewCount,
    bool? isOrganizerVerified,
    int? organizerCompletedTournaments,
    TournamentStatus? status,
    EntryType? entryType,
    double? entryFee,
    String? currency,
    String? prizePool,
    String? prizeDescription,
    Map<String, dynamic>? prizeDistribution,
    double? perKillReward,
    int? maxParticipants,
    int? registeredCount,
    DateTime? registrationOpensAt,
    DateTime? registrationClosesAt,
    DateTime? startsAt,
    DateTime? reportingAt,
    String? rules,
    String? eligibility,
    String? matchFormat,
    String? mode,
    String? mapName,
    int? teamSize,
    String? cancellationPolicy,
    bool? isFeatured,
    DateTime? credentialsReleaseAt,
    bool? credentialsReleased,
    String? roomId,
    String? roomPassword,
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
      organizerTeamName: organizerTeamName ?? this.organizerTeamName,
      organizerRating: organizerRating ?? this.organizerRating,
      organizerReviewCount: organizerReviewCount ?? this.organizerReviewCount,
      isOrganizerVerified: isOrganizerVerified ?? this.isOrganizerVerified,
      organizerCompletedTournaments:
          organizerCompletedTournaments ?? this.organizerCompletedTournaments,
      status: status ?? this.status,
      entryType: entryType ?? this.entryType,
      entryFee: entryFee ?? this.entryFee,
      currency: currency ?? this.currency,
      prizePool: prizePool ?? this.prizePool,
      prizeDescription: prizeDescription ?? this.prizeDescription,
      prizeDistribution: prizeDistribution ?? this.prizeDistribution,
      perKillReward: perKillReward ?? this.perKillReward,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registeredCount: registeredCount ?? this.registeredCount,
      registrationOpensAt: registrationOpensAt ?? this.registrationOpensAt,
      registrationClosesAt: registrationClosesAt ?? this.registrationClosesAt,
      startsAt: startsAt ?? this.startsAt,
      reportingAt: reportingAt ?? this.reportingAt,
      rules: rules ?? this.rules,
      eligibility: eligibility ?? this.eligibility,
      matchFormat: matchFormat ?? this.matchFormat,
      mode: mode ?? this.mode,
      mapName: mapName ?? this.mapName,
      teamSize: teamSize ?? this.teamSize,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      isFeatured: isFeatured ?? this.isFeatured,
      credentialsReleaseAt: credentialsReleaseAt ?? this.credentialsReleaseAt,
      credentialsReleased: credentialsReleased ?? this.credentialsReleased,
      roomId: roomId ?? this.roomId,
      roomPassword: roomPassword ?? this.roomPassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
