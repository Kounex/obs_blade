import 'package:http/http.dart' as http;

import 'log.dart';
import 'youtube_rest.dart';

/// Result counters from a poll-mode run.
class PollStats {
  int calls = 0;
  int messages = 0;
  int errors = 0;
  bool endedByStream = false;

  /// Community-verified cost of `liveChatMessages.list`.
  static const unitsPerCall = 5;

  int get estimatedUnits => calls * unitsPerCall;
}

/// REST polling spike: loops `liveChatMessages.list`, honoring the
/// server-provided `pollingIntervalMillis` exactly and logging the drift
/// between the requested interval and the actual call-to-call gap.
Future<PollStats> runPollSpike({
  required http.Client client,
  required String apiKey,
  required String liveChatId,
  required Duration duration,
  required bool Function() stopRequested,
}) async {
  final stats = PollStats();
  final startedAt = DateTime.now();
  String? pageToken;
  DateTime? lastCallStart;

  log('poll: starting for ${duration.inMinutes} min (chat $liveChatId)');

  while (true) {
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed >= duration || stopRequested()) break;

    final callStart = DateTime.now();
    if (lastCallStart != null) {
      final gap = callStart.difference(lastCallStart);
      log('poll: call-to-call gap ${gap.inMilliseconds} ms');
    }
    lastCallStart = callStart;

    final ChatPage page;
    try {
      page = await fetchChatPage(client, apiKey, liveChatId,
          pageToken: pageToken);
    } on YouTubeApiException catch (e) {
      stats.errors++;
      log('poll: error: $e');
      if (e.isQuotaExceeded) {
        log('poll: quotaExceeded — stopping');
        break;
      }
      // Transient error: wait a fixed interval and retry (same pageToken).
      await Future<void>.delayed(const Duration(seconds: 5));
      continue;
    }

    stats.calls++;
    stats.messages += page.messageCount;
    pageToken = page.nextPageToken;

    final interval = Duration(milliseconds: page.pollingIntervalMillis);
    final callDuration = DateTime.now().difference(callStart);
    log('poll: call #${stats.calls}: ${page.messageCount} msgs, '
        'server interval ${interval.inMilliseconds} ms, '
        'call took ${callDuration.inMilliseconds} ms, '
        'units so far ~${stats.estimatedUnits}');

    if (page.offlineAt != null || page.chatEnded) {
      log('poll: stream ended '
          '(offlineAt=${page.offlineAt}, chatEndedEvent=${page.chatEnded}) — '
          'clean stop');
      stats.endedByStream = true;
      break;
    }

    // Honor pollingIntervalMillis exactly, minus the time the call itself
    // took; log the drift if we ended up later than the server asked for.
    final sleepFor = interval - callDuration;
    if (sleepFor.isNegative) {
      log('poll: DRIFT +${(-sleepFor).inMilliseconds} ms — call outlasted '
          'the server interval');
    } else {
      await Future<void>.delayed(sleepFor);
      final actualGap = DateTime.now().difference(callStart);
      final drift = actualGap - interval;
      if (drift.inMilliseconds.abs() > 50) {
        log('poll: DRIFT ${drift.inMilliseconds} ms vs requested '
            '${interval.inMilliseconds} ms');
      }
    }
  }

  log('poll: done — ${stats.calls} calls, ${stats.messages} messages, '
      '~${stats.estimatedUnits} units, ${stats.errors} errors');
  return stats;
}
