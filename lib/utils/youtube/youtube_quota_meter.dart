import 'package:http/http.dart' as http;

import '../../models/enums/log_level.dart';
import '../general_helper.dart';

/// What the app spent of the API key's daily quota, for Settings → Logs.
/// A Pro user's "quota used up after 2 h" (2026-10-19) could only be
/// worked out from their Cloud console chart - the log now says which
/// calls went out and what they cost: one line per [kInterval] while
/// calls go out, and one when the quota ran out ([logNow]).
///
/// Costs are Google's table (developers.google.com/youtube/v3/
/// determine_quota_cost, 2026-10-20); `liveChatMessages.list` and
/// `streamList` at 5 measured on the obs-blade key (2026-10-19).
/// `search.list` has its own daily bucket now (Cloud Monitoring shows it
/// as `search_list`) - counted, not added to the key's units. An
/// estimate: every answered request is counted, a refusal included.
class YouTubeQuotaMeter {
  YouTubeQuotaMeter._();

  static const Duration kInterval = Duration(hours: 1);

  /// Test seam
  static DateTime Function() now = DateTime.now;

  static DateTime? _since;
  static final Map<String, int> _calls = {};
  static final Map<String, int> _costs = {};

  /// `METHOD path` under `/youtube/v3/` → name + units
  static const Map<String, (String, int)> _rest = {
    'GET liveChat/messages': ('liveChatMessages.list', 5),
    'POST liveChat/messages': ('liveChatMessages.insert', 20),
    'DELETE liveChat/messages': ('liveChatMessages.delete', 20),
    'POST liveChat/messages/transition': ('liveChatMessages.transition', 20),
    'POST liveChat/bans': ('liveChatBans.insert', 200),
    'DELETE liveChat/bans': ('liveChatBans.delete', 200),
    'GET liveChat/moderators': ('liveChatModerators.list', 50),
    'POST liveChat/moderators': ('liveChatModerators.insert', 200),
    'DELETE liveChat/moderators': ('liveChatModerators.delete', 200),
    'GET videos': ('videos.list', 1),
    'GET channels': ('channels.list', 1),
    'GET subscriptions': ('subscriptions.list', 1),
    'GET search': ('search.list (own bucket)', 0),
  };

  /// A REST request got an answer
  static void recordRequest(http.BaseRequest request) {
    final url = request.url;
    if (url.host != 'www.googleapis.com' ||
        !url.path.startsWith('/youtube/v3/')) {
      return;
    }
    final path = url.path.substring('/youtube/v3/'.length);
    final known = _rest['${request.method} $path'];
    record(
      known?.$1 ?? '${request.method} $path (cost unknown)',
      known?.$2 ?? 0,
    );
  }

  /// One call of [name] costing [units]
  static void record(String name, int units) {
    final moment = now();
    final since = _since;
    if (since != null && moment.difference(since) >= kInterval) {
      logNow();
    }
    _since ??= moment;
    _calls[name] = (_calls[name] ?? 0) + 1;
    _costs[name] = units;
  }

  /// Writes what was counted since the last line (if anything) to the
  /// app log and starts over; [reason] says why now
  static void logNow({String? reason}) {
    final line = summary(reason: reason);
    _since = null;
    _calls.clear();
    _costs.clear();
    if (line != null) {
      GeneralHelper.advLog(line, level: LogLevel.Info, includeInLogs: true);
    }
  }

  /// The line [logNow] writes (null: nothing counted)
  static String? summary({String? reason}) {
    final since = _since;
    if (since == null || _calls.isEmpty) return null;
    final minutes = now().difference(since).inMinutes;
    var units = 0;
    final parts = <String>[];
    final names = _calls.keys.toList()
      ..sort(
        (a, b) => (_calls[b]! * _costs[b]!).compareTo(_calls[a]! * _costs[a]!),
      );
    for (final name in names) {
      final calls = _calls[name]!;
      final cost = _costs[name]!;
      units += calls * cost;
      parts.add('$name $calls×$cost');
    }
    final at = '${_two(since.hour)}:${_two(since.minute)}';
    return 'YouTube API${reason != null ? ' ($reason)' : ''}: ≈$units units '
        'in $minutes min since $at - ${parts.join(', ')}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// Test seam
  static void reset() {
    _since = null;
    _calls.clear();
    _costs.clear();
  }
}

/// A YouTube service's HTTP client that counts its calls
/// ([YouTubeQuotaMeter])
class YouTubeMeteredClient extends http.BaseClient {
  final http.Client _inner;

  YouTubeMeteredClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await this._inner.send(request);
    YouTubeQuotaMeter.recordRequest(request);
    return response;
  }

  @override
  void close() => this._inner.close();
}
