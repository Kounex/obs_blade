import 'dart:math';

import 'package:hive/hive.dart';
import 'package:obs_blade/models/type_ids.dart';

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

@HiveType(typeId: TypeIDs.PastStreamData)
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

  /// RAM usage (in megabytes)
  @HiveField(17)
  List<double> memoryUsageList = [];

  /// For every entry we make in our lists (which will be used for charts)
  /// we will save the DateTime in milliseconds so we know when this entry
  /// has been done. Since the user could connect to OBS while already streaming
  /// or disconnect / connect multiple times, the charts would be wrong
  /// since we could not represent the "holes"
  ///
  /// Also used to calculate when the stream started together with
  /// [totalStreamTime]
  @HiveField(18)
  List<int> listEntryDateMS = [];

  /// Percentage of dropped frames
  @HiveField(3)
  double? strain;

  /// Total time (in seconds) since the stream started
  @HiveField(4)
  int? totalStreamTime;

  /// Total number of frames transmitted since the stream started
  @HiveField(5)
  int? numTotalFrames;

  /// Number of frames dropped by the encoder since the stream started
  @HiveField(6)
  int? numDroppedFrames;

  /// Number of frames rendered
  @HiveField(7)
  int? renderTotalFrames;

  /// Number of frames missed due to rendering lag
  @HiveField(8)
  int? renderMissedFrames;

  /// Number of frames outputted
  @HiveField(9)
  int? outputTotalFrames;

  /// Number of frames skipped due to encoding lag
  @HiveField(10)
  int? outputSkippedFrames;

  /// Average frame time (in milliseconds)
  @HiveField(11)
  double? averageFrameTime;

  /// Custom properties which will not be set / transmitted by OBS but set
  /// by the user or internally for checks

  /// Name of this [PastStreamData] to find it later / filtering etc.
  @HiveField(13)
  String? name;

  /// If this [PastStreamData] has been starred by the user (like favourite).
  /// Also suitable for filtering etc.
  @HiveField(14)
  bool? starred;

  /// Notes a user can write down for this [PastStreamData] for additional
  /// information on the stream or whatever
  @HiveField(15)
  String? notes;

  /// List of current [StreamStats] which will be used to fill the
  /// list of stats (see above). As soon as we reach [kAmountStreamStatsForAverage]
  /// amount of elements, the lists will get filled and [cacheStreamStats] gets
  /// cleared
  final List<StreamStats> _cacheStreamStats = [];

  void addStreamStats(StreamStats streamStats) {
    if (_cacheStreamStats.length >= kAmountStreamStatsForAverage) {
      _setListsFromStreamStats();
      _cacheStreamStats.clear();
    }
    _cacheStreamStats.add(streamStats);

    /// If one of our lists (could be any) is empty, we want to
    /// fill in the first values directly from our first [StreamStats]
    /// so we have initial values at the beginning of our statistic
    if (this.fpsList.isEmpty) {
      _setListsFromStreamStats();
    }
    _updateAbsoluteStats();
  }

  /// Update all our statistics values (which are absolute). Will be
  /// called every time we get a new [StreamStats] instance through
  /// [addStreamStats]
  void _updateAbsoluteStats() {
    this.strain = _cacheStreamStats.last.strain;
    this.totalStreamTime = _cacheStreamStats.last.totalStreamTime;
    this.numTotalFrames = _cacheStreamStats.last.numTotalFrames;
    this.numDroppedFrames = _cacheStreamStats.last.numDroppedFrames;
    this.renderTotalFrames = _cacheStreamStats.last.renderTotalFrames;
    this.renderMissedFrames = _cacheStreamStats.last.renderMissedFrames;
    this.outputTotalFrames = _cacheStreamStats.last.outputTotalFrames;
    this.outputSkippedFrames = _cacheStreamStats.last.outputSkippedFrames;
    this.averageFrameTime = _cacheStreamStats.last.averageFrameTime;
  }

  /// Update our lists (to see the changes of those values over time)
  /// according to our interval set by [kAmountStreamStatsForAverage]
  void _setListsFromStreamStats() {
    StreamStats relevantStreamStats =
        _cacheStreamStats.reduce((master, current) => master
          ..kbitsPerSec = min(master.kbitsPerSec, current.kbitsPerSec)
          ..fps = min(master.fps, current.fps)
          ..cpuUsage = max(master.cpuUsage, current.cpuUsage)
          ..memoryUsage = max(master.memoryUsage, current.memoryUsage));
    this.kbitsPerSecList.add(relevantStreamStats.kbitsPerSec);
    this.fpsList.add(relevantStreamStats.fps);
    this.cpuUsageList.add(relevantStreamStats.cpuUsage);
    this.memoryUsageList.add(relevantStreamStats.memoryUsage);
    this.listEntryDateMS.add(DateTime.now().millisecondsSinceEpoch);
  }
}
