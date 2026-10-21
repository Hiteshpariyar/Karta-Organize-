/// Centralized application configuration.
///
/// Easily modify the application title, version, policy versions, and defaults
/// without modifying UI code directly.
class AppConfig {
  AppConfig._();

  /// The working application name.
  static const String appName = 'TourneyZone';

  /// Application tagline / slogan.
  static const String appTagline = 'Compete. Connect. Conquer.';

  /// Application version for Phase 1.
  static const String appVersion = '1.0.0-phase1';

  /// Default country calling code for phone number inputs.
  static const String defaultCountryCode = '+91';

  /// Active version of Player Terms & Conditions.
  static const String playerTermsVersion = '1.0.0';

  /// Active version of Organizer Terms & Conditions.
  static const String organizerTermsVersion = '1.0.0';

  /// Active version of Privacy Policy.
  static const String privacyPolicyVersion = '0.1.0-draft';

  /// Standard proposed platform commission rate percentage.
  static const double standardCommissionPercentage = 10.0;

  /// Flag indicating if backend services (Firebase) are connected.
  /// Kept false for Phase 1 UI delivery.
  static const bool isBackendConnected = false;

  /// Placeholder organization / entity name for draft legal policies.
  static const String legalEntityPlaceholder = '[Platform Legal Entity Name]';

  /// Placeholder support email for draft legal policies.
  static const String supportEmailPlaceholder = '[support@tourneyzone.com]';

  /// Placeholder grievance officer details for draft legal policies.
  static const String grievanceOfficerPlaceholder = '[Grievance Officer Name & Contact]';
}

