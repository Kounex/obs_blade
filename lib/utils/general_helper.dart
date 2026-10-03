import '../models/enums/log_level.dart';

class GeneralHelper {
  static void advLog(
    Object? obj, {
    LogLevel level = LogLevel.Info,
    bool includeInLogs = false,
  }) {
    String inLog = includeInLogs ? '[ON]' : '[OFF]';
    // ignore: avoid_print
    print(
      obj == null
          ? '${LogLevel.Warning.prefix}$inLog ${obj.runtimeType} is null!'
          : '${level.prefix}$inLog $obj',
    );
  }

  /// Last time each failure kind reached the app log ([logFailure])
  static final Map<String, DateTime> _lastFailureLog = {};

  /// One failure kind reaches the app log at most this often - poll loops
  /// and live checks retry on timers
  static const Duration kFailureLogInterval = Duration(minutes: 5);

  /// A failure the user (and whoever reads their exported log) should be
  /// able to see in Settings → Logs, not only in a debug console. Writes
  /// [what] plus a short, redacted description of [error]: the message and
  /// HTTP status of typed service errors, never their response bodies, and
  /// nothing that looks like a token. Each [what] at most once per
  /// [kFailureLogInterval].
  static void logFailure(String what, Object error, {DateTime? now}) {
    final moment = now ?? DateTime.now();
    final last = _lastFailureLog[what];
    if (last != null && moment.difference(last) < kFailureLogInterval) {
      advLog('$what - ${describeError(error)}');
      return;
    }
    _lastFailureLog[what] = moment;
    advLog(
      '$what - ${describeError(error)}',
      level: LogLevel.Warning,
      includeInLogs: true,
    );
  }

  /// Test seam: forget which failures were logged
  static void resetFailureLog() => _lastFailureLog.clear();

  /// Short, log-safe form of [error] (see [logFailure])
  static String describeError(Object error) {
    String text;
    try {
      final dynamic typed = error;
      final Object? message = typed.message;
      int? status;
      try {
        final Object? code = typed.statusCode;
        if (code is int) status = code;
      } catch (_) {}
      text = message is String && message.isNotEmpty
          ? '${error.runtimeType}: $message${status != null ? ' (HTTP $status)' : ''}'
          : error.toString();
    } catch (_) {
      text = error.toString();
    }
    text = text
        .replaceAll(
          RegExp(r'Bearer\s+\S+', caseSensitive: false),
          'Bearer <redacted>',
        )
        .replaceAll(RegExp(r'ya29\.[A-Za-z0-9._-]+'), '<redacted>')
        .replaceAllMapped(
          RegExp(
            r'((?:access|refresh|id)_?token|client_secret|code_verifier|api_?key|key)(["\x27]?\s*[:=]\s*["\x27]?)[^\s"\x27&,}]+',
            caseSensitive: false,
          ),
          (match) => '${match[1]}${match[2]}<redacted>',
        )
        .replaceAll(RegExp(r'[A-Za-z0-9_\-]{40,}'), '<redacted>');
    return text.length > 300 ? '${text.substring(0, 300)}…' : text;
  }
}
