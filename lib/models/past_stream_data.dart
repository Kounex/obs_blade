import 'dart:math';

import 'package:hive/hive.dart';

import '../types/classes/api/stream_stats.dart';

part 'past_stream_data.g.dart';

/// The OBS WebSocket emits the StreamStats event every 2
/// seconds. Persisting values like kbitsPerSec as a list
/// which holds every value that gets emitted every 2 seconds
/// would result in very large lists (for long streams). To
/// avoid this we will hold a reference of the last
/// [kAmountStreamStatsForAverage] StreamStats entries and take
/// the worst values into consideration to have a "more realistic"
/// view on the data
const int kAmountStreamStatsForAverage = 10;

@HiveType(typeId: 1)
class PastStreamData extends HiveObject {
  /// Single values for the duration of the stream - won't consist
  /// of every value from the StreamStats event (too many) but will
  /// consist of a realistic subset (see explanation above)
  @HiveField(0)
  List<int> kbitsPerSecList = [];
  @HiveField(1)
  List<double> fpsList = [];
  @HiveField(2)
  List<double> cpuUsageList = [];

  /// Percentage of dropped frames
  @HiveField(3)
  double strain;

  /// Total time (in seconds) since the stream started
  @HiveField(4)
  int totalStreamTime;

  /// Total number of frames transmitted since the stream started
  @HiveField(5)
  int numTotalFrames;

  /// Number of frames dropped by the encoder since the stream started
  @HiveField(6)
  int numDroppedFrames;

  /// Number of frames rendered
  @HiveField(7)
  int renderTotalFrames;

  /// Number of frames missed due to rendering lag
  @HiveField(8)
  int renderMissedFrames;

  /// Number of frames outputted
  @HiveField(9)
  int outputTotalFrames;

  /// Number of frames skipped due to encoding lag
  @HiveField(10)
  int outputSkippedFrames;

  /// Average frame time (in milliseconds)
  @HiveField(11)
  double averageFrameTime;

  /// Will be set once we create a instance of this class.
  /// Together with [totalStreamTime] to calculate range as well.
  ///
  /// We use end time instead of start time (which might be more common)
  /// since we create a new instance of [StreamStats] everytime (every 2 seconds)
  /// we receive a StreamStatus event from our OBS WebSocket connection
  @HiveField(12)
  int streamEndedMS;

  /// Custom properties which will not be set / transmitted by OBS but set
  /// by the user or internally for checks

  /// Name of this [PastStreamData] to find it later / filtering etc.
  @HiveField(13)
  String name;

  /// If this [PastStreamData] has been starred by the user (like favourite).
  /// Also suitable for filtering etc.
  @HiveField(14)
  bool starred;

  /// Notes a user can write down for this [PastStreamData] for additional
  /// information on the stream or whatever
  @HiveField(15)
  String notes;

  /// Will be set if the collection of [StreamStats] has anyhow been stopped
  /// by the user (seesion closed manually while streaming, app paused etc.)
  ///
  /// If [true] or [null]: stopped by user
  /// If [false]: stopped correctly by stopping OBS stream while app active
  @HiveField(16)
  bool stoppedByUser;

  /// List of current [StreamStats] which will be used to fill the
  /// list of stats (see above). As soon as we reach [kAmountStreamStatsForAverage]
  /// amount of elements, the lists will get filled and [cacheStreamStats] gets
  /// cleared
  List<StreamStats> _cacheStreamStats = [];

  bool hasBeenPopulated = false;

  addStreamStats(StreamStats streamStats) {
    this.hasBeenPopulated = true;
    if (_cacheStreamStats.length < kAmountStreamStatsForAverage) {
      _cacheStreamStats.add(streamStats);
    } else {
      _setListsFromStreamStats();
      _cacheStreamStats.clear();
      _cacheStreamStats.add(streamStats);
    }
  }

  /// Trigger finish up this class so it can be persisted. As long
  /// as the stream is live we will slowly add entries in our lists
  /// and as soon as we stop the stream we will call this method
  /// to set the value of the other properties according to the
  /// last [StreamStats] in [_cacheStreamStats]
  finishUpStats({bool finishManually = false}) {
    this.strain = _cacheStreamStats.last.strain;
    this.totalStreamTime = _cacheStreamStats.last.totalStreamTime;
    this.numTotalFrames = _cacheStreamStats.last.numTotalFrames;
    this.numDroppedFrames = _cacheStreamStats.last.numDroppedFrames;
    this.renderTotalFrames = _cacheStreamStats.last.renderTotalFrames;
    this.renderMissedFrames = _cacheStreamStats.last.renderMissedFrames;
    this.outputTotalFrames = _cacheStreamStats.last.outputTotalFrames;
    this.outputSkippedFrames = _cacheStreamStats.last.outputSkippedFrames;
    this.averageFrameTime = _cacheStreamStats.last.averageFrameTime;
    this.streamEndedMS = DateTime.now().millisecondsSinceEpoch;
    this.stoppedByUser = finishManually;
  }

  /// Update our lists (to see the changes of those values over time)
  /// according to our interval set by [kAmountStreamStatsForAverage]
  _setListsFromStreamStats() {
    StreamStats relevantStreamStats =
        _cacheStreamStats.reduce((master, current) => master
          ..kbitsPerSec = min(master.kbitsPerSec, current.kbitsPerSec)
          ..fps = min(master.fps, current.fps)
          ..cpuUsage = max(master.cpuUsage, current.cpuUsage));
    this.kbitsPerSecList.add(relevantStreamStats.kbitsPerSec);
    this.fpsList.add(relevantStreamStats.fps);
    this.cpuUsageList.add(relevantStreamStats.cpuUsage);
  }
}
