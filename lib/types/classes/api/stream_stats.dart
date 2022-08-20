class StreamStats {
  /// Current streaming state
  @Deprecated('Not used in protocol > 5.X')
  bool? streaming;

  /// Current recording state
  @Deprecated('Not used in protocol > 5.X')
  bool? recording;

  /// Replay Buffer status
  @Deprecated('Not used in protocol > 5.X')
  bool? replayBufferActive;

  /// Amount of data per second (in bytes) transmitted by the stream encoder
  @Deprecated('Not used in protocol > 5.X')
  int? bytesPerSec;

  /// Amount of data per second (in kilobits) transmitted by the stream encoder
  int kbitsPerSec;

  /// Percentage of dropped frames
  ///
  @Deprecated('Not used in protocol > 5.X')
  double? strain;

  /// Total time (in seconds) since the stream started
  int totalTime;

  /// Total number of frames transmitted since the stream started
  @Deprecated('Not used in protocol > 5.X')
  int? numTotalFrames;

  /// Number of frames dropped by the encoder since the stream started
  @Deprecated('Not used in protocol > 5.X')
  int? numDroppedFrames;

  /// Current framerate
  double fps;

  /// Number of frames rendered
  int renderTotalFrames;

  /// Number of frames skipped due to rendering lag
  int renderSkippedFrames;

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

  StreamStats({
    this.streaming,
    this.recording,
    this.replayBufferActive,
    this.bytesPerSec,
    required this.kbitsPerSec,
    this.strain,
    required this.totalTime,
    this.numTotalFrames,
    this.numDroppedFrames,
    required this.fps,
    required this.renderTotalFrames,
    required this.renderSkippedFrames,
    required this.outputTotalFrames,
    required this.outputSkippedFrames,
    required this.averageFrameTime,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.freeDiskSpace,
  });
}
