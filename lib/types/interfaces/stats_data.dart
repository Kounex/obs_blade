abstract class StatsData {
  List<int> kbitsPerSecList = [];
  List<double> fpsList = [];
  List<double> cpuUsageList = [];

  /// RAM usage (in megabytes)
  List<double> memoryUsageList = [];

  /// For every entry we make in our lists (which will be used for charts)
  /// we will save the DateTime in milliseconds so we know when this entry
  /// has been done. Since the user could connect to OBS while already recording
  /// or disconnect / connect multiple times, the charts would be wrong
  /// since we could not represent the "holes"
  ///
  /// Also used to calculate when the record started together with
  /// [totalTime]
  List<int> listEntryDateMS = [];

  /// Total time (in seconds) since the stream started
  int? totalTime;

  /// Number of frames rendered
  int? renderTotalFrames;

  /// Number of frames missed due to rendering lag
  int? renderMissedFrames;

  /// Average frame time (in milliseconds)
  double? averageFrameTime;

  /// Custom properties which will not be set / transmitted by OBS but set
  /// by the user or internally for checks

  /// Name of this [StatsData] to find it later / filtering etc.
  String? name;

  /// If this [StatsData] has been starred by the user (like favourite).
  /// Also suitable for filtering etc.
  bool? starred;

  /// Notes a user can write down for this [StatsData] for additional
  /// information on the stream or whatever
  String? notes;
}
