import 'package:flutter/foundation.dart';

/// Security event types for audit logging and monitoring.
enum SecurityEventType {
  loginSuccess,
  loginFailure,
  loginThrottled,
  passwordResetRequested,
  passwordResetThrottled,
  privilegeEscalationAttempt,
  sensitiveActionReauthRequired,
  accountDeletionInitiated,
  accountDeleted,
}

/// Security audit log entry.
class SecurityLogEntry {
  final String id;
  final SecurityEventType eventType;
  final String accountIdentifier;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const SecurityLogEntry({
    required this.id,
    required this.eventType,
    required this.accountIdentifier,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventType': eventType.name,
      'accountIdentifier': accountIdentifier,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Result of an authentication or rate-limit security evaluation.
class SecurityCheckResult {
  final bool isAllowed;
  final String? errorMessage;
  final Duration? retryAfter;
  final int currentAttemptCount;

  const SecurityCheckResult({
    required this.isAllowed,
    this.errorMessage,
    this.retryAfter,
    this.currentAttemptCount = 0,
  });

  factory SecurityCheckResult.allowed({int attemptCount = 0}) {
    return SecurityCheckResult(isAllowed: true, currentAttemptCount: attemptCount);
  }

  factory SecurityCheckResult.throttled({
    required Duration retryAfter,
    required String errorMessage,
    int attemptCount = 0,
  }) {
    return SecurityCheckResult(
      isAllowed: false,
      retryAfter: retryAfter,
      errorMessage: errorMessage,
      currentAttemptCount: attemptCount,
    );
  }
}

/// Core Security Service enforcing:
/// 1. Password-reset rate limiting: Max 4 requests per account within a rolling 90-second window.
/// 2. Configurable failed-login attempt throttling without permanent account lockout.
/// 3. Account enumeration prevention via generic messages.
/// 4. Re-authentication validation for sensitive account operations.
class AuthSecurityService {
  AuthSecurityService({
    this.maxPasswordResetsPerWindow = 4,
    this.passwordResetWindow = const Duration(seconds: 90),
    this.failedLoginThreshold = 5,
    this.failedLoginCooldown = const Duration(seconds: 60),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int maxPasswordResetsPerWindow;
  final Duration passwordResetWindow;
  final int failedLoginThreshold;
  final Duration failedLoginCooldown;
  final DateTime Function() _clock;

  // In-memory timestamps of password resets: accountKey -> list of DateTime
  final Map<String, List<DateTime>> _passwordResetHistory = {};

  // In-memory failed login tracking: accountKey -> list of failed attempt timestamps
  final Map<String, List<DateTime>> _failedLoginHistory = {};

  // In-memory security audit event buffer
  final List<SecurityLogEntry> _auditLogs = [];

  List<SecurityLogEntry> get auditLogs => List.unmodifiable(_auditLogs);

  String _normalizeKey(String identifier) => identifier.trim().toLowerCase();

  /// Evaluates and registers a password-reset request for an account.
  /// Enforces: Maximum [maxPasswordResetsPerWindow] (4) requests within [passwordResetWindow] (90s).
  SecurityCheckResult checkAndRecordPasswordReset(String email) {
    final key = _normalizeKey(email);
    final now = _clock();

    final timestamps = _passwordResetHistory.putIfAbsent(key, () => []);

    // Remove timestamps outside the rolling 90-second window
    timestamps.removeWhere((t) => now.difference(t) > passwordResetWindow);

    if (timestamps.length >= maxPasswordResetsPerWindow) {
      final oldestInWindow = timestamps.first;
      final timeRemaining = passwordResetWindow - now.difference(oldestInWindow);
      final waitSeconds = (timeRemaining.inSeconds > 0) ? timeRemaining.inSeconds : 1;

      _recordLog(
        SecurityEventType.passwordResetThrottled,
        key,
        {
          'attemptCount': timestamps.length + 1,
          'waitSeconds': waitSeconds,
        },
      );

      return SecurityCheckResult.throttled(
        retryAfter: Duration(seconds: waitSeconds),
        errorMessage:
            'Too many password reset requests. For security, please wait $waitSeconds seconds before requesting another link.',
        attemptCount: timestamps.length + 1,
      );
    }

    // Record this attempt
    timestamps.add(now);

    _recordLog(
      SecurityEventType.passwordResetRequested,
      key,
      {'attemptInWindow': timestamps.length},
    );

    return SecurityCheckResult.allowed(attemptCount: timestamps.length);
  }

  /// Checks if an account is currently throttled due to repeated failed login attempts.
  SecurityCheckResult checkLoginAllowed(String email) {
    final key = _normalizeKey(email);
    final now = _clock();

    final timestamps = _failedLoginHistory[key];
    if (timestamps == null || timestamps.isEmpty) {
      return SecurityCheckResult.allowed();
    }

    // Remove attempts older than the cooldown
    timestamps.removeWhere((t) => now.difference(t) > failedLoginCooldown);

    if (timestamps.length >= failedLoginThreshold) {
      final latest = timestamps.last;
      final elapsed = now.difference(latest);
      if (elapsed < failedLoginCooldown) {
        final remaining = failedLoginCooldown - elapsed;
        final waitSeconds = remaining.inSeconds > 0 ? remaining.inSeconds : 1;

        _recordLog(
          SecurityEventType.loginThrottled,
          key,
          {
            'failedCount': timestamps.length,
            'waitSeconds': waitSeconds,
          },
        );

        return SecurityCheckResult.throttled(
          retryAfter: Duration(seconds: waitSeconds),
          errorMessage:
              'Too many failed login attempts. For security, please wait $waitSeconds seconds before trying again.',
          attemptCount: timestamps.length,
        );
      }
    }

    return SecurityCheckResult.allowed(attemptCount: timestamps.length);
  }

  /// Records a failed login attempt for the account.
  void recordFailedLogin(String email) {
    final key = _normalizeKey(email);
    final now = _clock();
    final timestamps = _failedLoginHistory.putIfAbsent(key, () => []);
    timestamps.add(now);

    _recordLog(
      SecurityEventType.loginFailure,
      key,
      {'consecutiveFailures': timestamps.length},
    );
  }

  /// Clears failed login counter on successful authentication.
  void recordSuccessfulLogin(String email) {
    final key = _normalizeKey(email);
    _failedLoginHistory.remove(key);

    _recordLog(
      SecurityEventType.loginSuccess,
      key,
      {},
    );
  }

  /// Logs a privilege escalation attempt (e.g. client attempting to submit admin role).
  void recordPrivilegeEscalationAttempt({
    required String uid,
    required String attemptedRole,
    required String endpoint,
  }) {
    _recordLog(
      SecurityEventType.privilegeEscalationAttempt,
      uid,
      {
        'attemptedRole': attemptedRole,
        'endpoint': endpoint,
      },
    );
  }

  /// Logs account deletion.
  void recordAccountDeletion({required String uid}) {
    _recordLog(
      SecurityEventType.accountDeleted,
      uid,
      {'action': 'account_purged'},
    );
  }

  void _recordLog(SecurityEventType eventType, String accountIdentifier, Map<String, dynamic> metadata) {
    final log = SecurityLogEntry(
      id: 'sec_${_clock().millisecondsSinceEpoch}_${_auditLogs.length}',
      eventType: eventType,
      accountIdentifier: accountIdentifier,
      timestamp: _clock(),
      metadata: metadata,
    );
    _auditLogs.add(log);
    debugPrint('[SECURITY AUDIT] ${log.eventType.name} for ${log.accountIdentifier}: ${log.metadata}');
  }

  /// Clears in-memory history (useful for test resets).
  void reset() {
    _passwordResetHistory.clear;
    _failedLoginHistory.clear;
    _auditLogs.clear;
  }
}

