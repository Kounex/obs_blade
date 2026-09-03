import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'log.dart';
import 'poll_spike.dart';
import 'stream_spike.dart';
import 'youtube_rest.dart';

enum SpikeMode { poll, stream, both }

class SpikeConfig {
  SpikeConfig({
    required this.apiKey,
    required this.videoId,
    required this.liveChatId,
    required this.mode,
    required this.duration,
  });

  final String apiKey;
  final String? videoId;
  final String? liveChatId;
  final SpikeMode mode;
  final Duration duration;
}

/// Runs the configured spike modes and prints the final measurement summary.
Future<void> runSpike(SpikeConfig config) async {
  var stopRequested = false;
  final sigint = ProcessSignal.sigint.watch().listen((_) {
    if (!stopRequested) {
      log('SIGINT — finishing current step and printing summary');
      stopRequested = true;
    }
  });

  final client = http.Client();
  PollStats? pollStats;
  StreamStats? streamStats;
  var bindingUnits = 0;

  try {
    var liveChatId = config.liveChatId;
    if (liveChatId == null) {
      log('resolve: videos.list for video ${config.videoId} (1 unit)');
      liveChatId =
          await resolveLiveChatId(client, config.apiKey, config.videoId!);
      bindingUnits = 1;
      log('resolve: activeLiveChatId = $liveChatId');
    }

    if (config.mode == SpikeMode.poll || config.mode == SpikeMode.both) {
      pollStats = await runPollSpike(
        client: client,
        apiKey: config.apiKey,
        liveChatId: liveChatId,
        duration: config.duration,
        stopRequested: () => stopRequested,
      );
    }
    if (config.mode == SpikeMode.stream || config.mode == SpikeMode.both) {
      streamStats = await runStreamSpike(
        apiKey: config.apiKey,
        liveChatId: liveChatId,
        duration: config.duration,
        stopRequested: () => stopRequested,
      );
    }
  } finally {
    client.close();
    await sigint.cancel();
  }

  log('================ SUMMARY ================');
  if (bindingUnits > 0) {
    log('binding (videos.list):        $bindingUnits unit');
  }
  if (pollStats != null) {
    log('poll:  ${pollStats.calls} calls, ${pollStats.messages} messages, '
        '${pollStats.errors} errors, endedByStream=${pollStats.endedByStream}');
    log('poll:  estimated quota units = ${pollStats.estimatedUnits} '
        '(${PollStats.unitsPerCall}/call) over ~${config.duration.inMinutes} min');
  }
  if (streamStats != null) {
    log('stream: ${streamStats.connections} connections, '
        '${streamStats.eofCount} EOFs, ${streamStats.messages} messages, '
        '${streamStats.errors} errors, '
        'endedByStream=${streamStats.endedByStream}');
    log('stream: quota units UNKNOWN from client side — measure via GCP '
        'console delta (see README quota protocol)');
  }
}
