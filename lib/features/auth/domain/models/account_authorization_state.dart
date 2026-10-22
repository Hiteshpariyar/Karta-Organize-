import 'user_profile.dart';
import '../../../organizer_application/domain/models/organizer_application.dart';

/// Server-verified authorization states for Karta Organize users.
///
/// Invariants:
/// - A valid login only verifies identity (authentication).
/// - An account is only authorized as an Organizer if explicitly approved by an administrator.
/// - Selecting 'Organizer' during onboarding places the account into [organizerPending],
///   which strictly forbids accessing tournament hosting and room creation features.
enum AccountAuthorizationState {
  /// Regular competitive player. Allowed ONLY in player-accessible routes.
  player('Player', 'Standard competitive player account'),

  /// Organizer candidate whose application is awaiting administrator verification.
  /// Allowed to view application status only; blocked from tournament hosting features.
  organizerPending('Organizer (Pending Review)', 'Application is under review by administrators'),

  /// Verified organizer with explicit administrative approval.
  /// Allowed to host tournaments, manage match rooms, and publish results.
  organizerApproved('Verified Organizer', 'Approved to host and manage competitive tournaments'),

  /// Organizer application was rejected or requires revisions.
  /// Allowed to view rejection reasons and resubmit; blocked from hosting features.
  organizerRejected('Organizer (Application Rejected)', 'Application was not approved'),

  /// Super-administrative user with complete platform authority.
  admin('Administrator', 'Platform administration privileges');

  final String displayLabel;
  final String description;

  const AccountAuthorizationState(this.displayLabel, this.description);

  /// Whether the user has verified administrative permission to host tournaments.
  bool get canHostTournaments => this == AccountAuthorizationState.organizerApproved || this == AccountAuthorizationState.admin;

  /// Whether the user can access standard player tournament features.
  bool get canAccessPlayerFeatures => this == AccountAuthorizationState.player || this == AccountAuthorizationState.organizerApproved || this == AccountAuthorizationState.admin;

  /// Resolves the authoritative state from user profile and organizer application records.
  static AccountAuthorizationState resolve({
    required UserProfile? profile,
    OrganizerApplication? application,
  }) {
    if (profile == null) return AccountAuthorizationState.player;

    // 1. Admin authority has highest precedence
    if (profile.isAdmin) return AccountAuthorizationState.admin;

    // 2. Check application status if present
    if (application != null) {
      switch (application.status) {
        case OrganizerApprovalStatus.approved:
          return AccountAuthorizationState.organizerApproved;
        case OrganizerApprovalStatus.rejected:
          return AccountAuthorizationState.organizerRejected;
        case OrganizerApprovalStatus.pending:
          return AccountAuthorizationState.organizerPending;
        case OrganizerApprovalStatus.error:
        case OrganizerApprovalStatus.loading:
          return AccountAuthorizationState.organizerPending;
      }
    }

    // 3. Fallback to server-assigned role on UserProfile
    if (profile.isOrganizer) {
      return AccountAuthorizationState.organizerApproved;
    }

    // 4. Default: Unprivileged player
    return AccountAuthorizationState.player;
  }
}
