import 'dart:math';

import 'package:obs_station/types/classes/api/stream_stats.dart';

class StreamStatsMocker {
  static StreamStats random() => StreamStats(
      streaming: true,
      recording: false,
      replayBufferActive: true,
      bytesPerSec: Random().nextInt(70000),
      kbitsPerSec: Random().nextInt(6000),
      strain: Random().nextDouble() * 100,
      totalStreamTime: Random().nextInt(14400),
      numTotalFrames: Random().nextInt(70000),
      numDroppedFrames: Random().nextInt(100),
      fps: Random().nextDouble() * 60,
      renderTotalFrames: Random().nextInt(70000),
      renderMissedFrames: Random().nextInt(100),
      outputTotalFrames: Random().nextInt(70000),
      outputSkippedFrames: Random().nextInt(70000),
      averageFrameTime: Random().nextDouble() * 60,
      cpuUsage: Random().nextDouble() * 100,
      memoryUsage: Random().nextDouble() * 1000000,
      freeDiskSpace: Random().nextDouble() * 1000000);
}
