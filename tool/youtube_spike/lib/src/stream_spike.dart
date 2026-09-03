import 'package:grpc/grpc.dart';

import 'generated/stream_list.pbgrpc.dart';
import 'log.dart';

/// Result counters from a stream-mode run.
class StreamStats {
  int connections = 0;
  int eofCount = 0;
  int errors = 0;
  int messages = 0;
  bool endedByStream = false;
  final List<Duration> connectionLifetimes = [];
}

/// gRPC server-streaming spike: opens
/// `V3DataLiveChatMessageService.StreamList` against
/// `youtube.googleapis.com:443` with the API key in `x-goog-api-key`
/// metadata. Streams can EOF after seconds — on EOF or error we resume from
/// the last `nextPageToken` with exponential backoff.
Future<StreamStats> runStreamSpike({
  required String apiKey,
  required String liveChatId,
  required Duration duration,
  required bool Function() stopRequested,
}) async {
  final stats = StreamStats();
  final startedAt = DateTime.now();
  String? pageToken;
  var backoff = const Duration(seconds: 1);
  const maxBackoff = Duration(seconds: 60);
  // A connection that survived this long counts as healthy → reset backoff.
  const healthyThreshold = Duration(seconds: 30);

  log('stream: starting for ${duration.inMinutes} min (chat $liveChatId)');

  final channel = ClientChannel(
    'youtube.googleapis.com',
    port: 443,
    options: const ChannelOptions(credentials: ChannelCredentials.secure()),
  );
  final client = V3DataLiveChatMessageServiceClient(
    channel,
    options: CallOptions(metadata: {'x-goog-api-key': apiKey}),
  );

  try {
    while (true) {
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed >= duration || stopRequested()) break;

      stats.connections++;
      final connectedAt = DateTime.now();
      log('stream: connection #${stats.connections} opened'
          '${pageToken != null ? ' (resuming with pageToken)' : ''}');

      var ended = false;
      DateTime? lastBatchAt;
      try {
        final request = LiveChatMessageListRequest(
          liveChatId: liveChatId,
          part: ['id', 'snippet', 'authorDetails'],
          profileImageSize: 88,
        );
        if (pageToken != null) request.pageToken = pageToken;

        await for (final response in client.streamList(request)) {
          stats.messages += response.items.length;
          if (response.hasNextPageToken()) {
            pageToken = response.nextPageToken;
          }
          final now = DateTime.now();
          final cadence = lastBatchAt == null
              ? 'first batch'
              : '${now.difference(lastBatchAt).inMilliseconds} ms since last';
          lastBatchAt = now;
          log('stream: batch ${response.items.length} msgs ($cadence), '
              'total ${stats.messages}');

          final chatEnded = response.items.any((m) =>
              m.hasSnippet() &&
              m.snippet.type ==
                  LiveChatMessageSnippet_TypeWrapper_Type.CHAT_ENDED_EVENT);
          if (response.hasOfflineAt() || chatEnded) {
            log('stream: stream ended (offlineAt='
                '${response.hasOfflineAt() ? response.offlineAt : '-'}, '
                'chatEndedEvent=$chatEnded) — clean stop');
            stats.endedByStream = true;
            ended = true;
            break;
          }
          if (DateTime.now().difference(startedAt) >= duration ||
              stopRequested()) {
            ended = true;
            break;
          }
        }
        if (!ended) {
          stats.eofCount++;
          log('stream: EOF — server closed the stream');
        }
      } catch (e) {
        stats.errors++;
        log('stream: error: $e');
      }

      if (stats.endedByStream) break;

      final lifetime = DateTime.now().difference(connectedAt);
      stats.connectionLifetimes.add(lifetime);
      log('stream: connection #${stats.connections} lived '
          '${lifetime.inSeconds} s');
      if (lifetime >= healthyThreshold) backoff = const Duration(seconds: 1);

      if (DateTime.now().difference(startedAt) >= duration ||
          stopRequested()) {
        break;
      }
      log('stream: reconnecting in ${backoff.inSeconds} s');
      await Future<void>.delayed(backoff);
      backoff *= 2;
      if (backoff > maxBackoff) backoff = maxBackoff;
    }
  } finally {
    await channel.shutdown();
  }

  final lifetimes = stats.connectionLifetimes
      .map((d) => '${d.inSeconds}s')
      .join(', ');
  log('stream: done — ${stats.connections} connections '
      '(lifetimes: $lifetimes), ${stats.eofCount} EOFs, '
      '${stats.messages} messages, ${stats.errors} errors');
  return stats;
}
