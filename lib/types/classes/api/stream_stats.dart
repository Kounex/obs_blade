import 'package:flutter/material.dart';

class StreamStats {
  /// Current streaming state
  bool streaming;

  /// Current recording state
  bool recording;

  /// Replay Buffer status
  bool replayBufferActive;

  /// Amount of data per second (in bytes) transmitted by the stream encoder
  int bytesPerSec;

  /// Amount of data per second (in kilobits) transmitted by the stream encoder
  int kbitsPerSec;

  /// Percentage of dropped frames
  double strain;

  /// Total time (in seconds) since the stream started
  int totalStreamTime;

  /// Total number of frames transmitted since the stream started
  int numTotalFrames;

  /// Number of frames dropped by the encoder since the stream started
  int numDroppedFrames;

  /// Current framerate
  double fps;

  /// Number of frames rendered
  int renderTotalFrames;

  /// Number of frames missed due to rendering lag
  int renderMissedFrames;

  /// Number of frames outputted
  int outputTotalFrames;

  /// Number of frames skipped due to encoding lag
  int outputSkippedFrames;

  /// Average frame time (in milliseconds)
  double averageFrameTime;

  /// Current CPU usage (percentage)
  double cpuUsage;

  /// Current RAM usage (in megabytes)
  double memoryUsage;

  /// Free recording disk space (in megabytes)
  double freeDiskSpace;

  StreamStats(
      {@required this.streaming,
      @required this.recording,
      @required this.replayBufferActive,
      @required this.bytesPerSec,
      @required this.kbitsPerSec,
      @required this.strain,
      @required this.totalStreamTime,
      @required this.numTotalFrames,
      @required this.numDroppedFrames,
      @required this.fps,
      @required this.renderTotalFrames,
      @required this.renderMissedFrames,
      @required this.outputTotalFrames,
      @required this.outputSkippedFrames,
      @required this.averageFrameTime,
      @required this.cpuUsage,
      @required this.memoryUsage,
      @required this.freeDiskSpace});

  static StreamStats fromJSON(Map<String, dynamic> json) {
    return StreamStats(
      averageFrameTime: json['average-frame-time'],
      bytesPerSec: json['bytes-per-sec'],
      cpuUsage: json['cpu-usage'],
      fps: json['fps'],
      freeDiskSpace: json['free-disk-space'],
      kbitsPerSec: json['kbits-per-sec'],
      memoryUsage: json['memory-usage'],
      numDroppedFrames: json['num-dropped-frames'],
      numTotalFrames: json['num-total-frames'],
      outputSkippedFrames: json['output-skipped-frames'],
      outputTotalFrames: json['output-total-frames'],
      recording: json['recording'],
      renderMissedFrames: json['render-missed-frames'],
      renderTotalFrames: json['render-total-frames'],
      replayBufferActive: json['replay-buffer-active'],
      strain: json['strain'],
      streaming: json['streaming'],
      totalStreamTime: json['total-stream-time'],
    );
  }
}
