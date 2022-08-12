class RecordStats {
  /// Total time (in seconds) since the record started
  int totalTime;

  /// Current framerate
  double fps;

  /// Amount of data per second (in kilobits) transmitted by the output
  int kbitsPerSec;

  /// Number of frames rendered
  int renderTotalFrames;

  /// Number of frames missed due to rendering lag
  int renderMissedFrames;

  /// Average frame time (in milliseconds)
  double averageFrameTime;

  /// Current CPU usage (percentage)
  double cpuUsage;

  /// Current RAM usage (in megabytes)
  double memoryUsage;

  /// Free recording disk space (in megabytes)
  double freeDiskSpace;

  RecordStats({
    required this.kbitsPerSec,
    required this.totalTime,
    required this.fps,
    required this.renderTotalFrames,
    required this.renderMissedFrames,
    required this.averageFrameTime,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.freeDiskSpace,
  });
}
