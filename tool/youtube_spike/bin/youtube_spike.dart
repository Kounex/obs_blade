import 'dart:io';

import 'package:args/args.dart';
import 'package:youtube_spike/src/spike.dart';

/// Measures the two YouTube live chat read paths against a real chat.
/// See README.md for setup (generated pb stubs are gitignored — run
/// ./setup.sh first) and for the quota measurement protocol.
Future<void> main(List<String> args) async {
  // The generated gRPC stubs are gitignored; if they are missing the compile
  // of package:youtube_spike/src/stream_spike.dart fails before we get here,
  // but when running from a stale snapshot this catches it with a clear
  // message instead of a resolver error.
  final generated = File.fromUri(Platform.script
      .resolve('../lib/src/generated/stream_list.pbgrpc.dart'));
  if (!generated.existsSync()) {
    stderr.writeln('error: generated protobuf stubs not found at '
        'lib/src/generated/.');
    stderr.writeln('       run ./setup.sh first (see README.md).');
    exitCode = 64; // EX_USAGE
    return;
  }

  final parser = ArgParser()
    ..addOption('api-key',
        help: 'YouTube Data API key (charged for all calls).')
    ..addOption('video-id',
        help: 'YouTube video id — resolved to a live chat id via '
            'videos.list (1 unit).')
    ..addOption('live-chat-id', help: 'Skip resolution; use this chat id.')
    ..addOption('mode',
        allowed: ['poll', 'stream', 'both'],
        defaultsTo: 'both',
        help: 'Which read path(s) to exercise.')
    ..addOption('duration-minutes',
        defaultsTo: '30', help: 'How long each mode runs.')
    ..addFlag('help', negatable: false, help: 'Show this help.');

  final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('error: ${e.message}\n');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  if (results['help'] as bool) {
    stdout.writeln(parser.usage);
    return;
  }

  final apiKey = results['api-key'] as String?;
  final videoId = results['video-id'] as String?;
  final liveChatId = results['live-chat-id'] as String?;
  final durationMinutes = int.tryParse(results['duration-minutes'] as String);

  String? usageError;
  if (apiKey == null || apiKey.isEmpty) {
    usageError = '--api-key is required';
  } else if ((videoId == null) == (liveChatId == null)) {
    usageError = 'exactly one of --video-id / --live-chat-id is required';
  } else if (durationMinutes == null || durationMinutes <= 0) {
    usageError = '--duration-minutes must be a positive integer';
  }
  if (usageError != null) {
    stderr.writeln('error: $usageError\n');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  await runSpike(SpikeConfig(
    apiKey: apiKey!,
    videoId: videoId,
    liveChatId: liveChatId,
    mode: SpikeMode.values.byName(results['mode'] as String),
    duration: Duration(minutes: durationMinutes!),
  ));
}
