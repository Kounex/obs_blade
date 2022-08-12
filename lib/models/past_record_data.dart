import 'dart:math';

import 'package:hive/hive.dart';
import 'package:obs_blade/types/classes/api/record_stats.dart';
import 'package:obs_blade/types/interfaces/stats_data.dart';

import 'type_ids.dart';

part 'past_record_data.g.dart';

/// We are polling the status for streaming and recording periodically
/// (by the time of writing this, every second). If we persist every status,
/// we will end up in a lot of entries since streaming / recording can
/// easily last hours - example:
///
///   Streaming for 4 hours = 240 minutes = 14400 seconds: amount of entries
///
/// Doing this multiple times would lead to way too many entries. What we
/// do for now is collect a fixed amount, [kAmountRecordStatsForAverage], of
/// stats before creating an actual entry which will be persisted. After
/// collecting this amount of stats, we calculate the averages (or min / max)
/// of those and persist it into an actual entry. This will ensure that we
/// get a mix of reliable data and a less amount of entries
const int kAmountRecordStatsForAverage = 10;

@HiveType(typeId: TypeIDs.PastRecordData)
class PastRecordData extends HiveObject implements StatsData {
  /// Single values for the duration of the stream - won't consist
  /// of every value from the StreamStats event (too many) but will
  /// consist of a realistic subset (see explanation above)
  @HiveField(0)
  @override
  List<int> kbitsPerSecList = [];
  @HiveField(1)
  @override
  List<double> fpsList = [];
  @HiveField(2)
  @override
  List<double> cpuUsageList = [];

  /// RAM usage (in megabytes)
  @HiveField(3)
  @override
  List<double> memoryUsageList = [];

  /// For every entry we make in our lists (which will be used for charts)
  /// we will save the DateTime in milliseconds so we know when this entry
  /// has been done. Since the user could connect to OBS while already recording
  /// or disconnect / connect multiple times, the charts would be wrong
  /// since we could not represent the "holes"
  ///
  /// Also used to calculate when the record started together with
  /// [totalTime]
  @HiveField(4)
  @override
  List<int> listEntryDateMS = [];

  /// Total time (in seconds) since the stream started
  @HiveField(5)
  @override
  int? totalTime;

  /// Number of frames rendered
  @HiveField(6)
  @override
  int? renderTotalFrames;

  /// Number of frames missed due to rendering lag
  @HiveField(7)
  @override
  int? renderMissedFrames;

  /// Average frame time (in milliseconds)
  @HiveField(8)
  @override
  double? averageFrameTime;

  /// Custom properties which will not be set / transmitted by OBS but set
  /// by the user or internally for checks

  /// Name of this [PastStreamData] to find it later / filtering etc.
  @HiveField(9)
  @override
  String? name;

  /// If this [PastStreamData] has been starred by the user (like favourite).
  /// Also suitable for filtering etc.
  @HiveField(10)
  @override
  bool? starred;

  /// Notes a user can write down for this [PastStreamData] for additional
  /// information on the stream or whatever
  @HiveField(11)
  @override
  String? notes;

  /// List of current [RecordStats] which will be used to fill the
  /// list of stats (see above). As soon as we reach [kAmountStreamStatsForAverage]
  /// amount of elements, the lists will get filled and [cacheStreamStats] gets
  /// cleared
  final List<RecordStats> _cacheRecordStats = [];

  void addRecordStats(RecordStats recordStats) {
    if (_cacheRecordStats.length >= kAmountRecordStatsForAverage) {
      _setListsFromRecordStats();
      _cacheRecordStats.clear();
    }
    _cacheRecordStats.add(recordStats);

    /// If one of our lists (could be any) is empty, we want to
    /// fill in the first values directly from our first [StreamStats]
    /// so we have initial values at the beginning of our statistic
    if (this.fpsList.isEmpty) {
      _setListsFromRecordStats();
    }
    _updateAbsoluteStats();
  }

  /// Update all our statistics values (which are absolute). Will be
  /// called every time we get a new [RecordStats] instance through
  /// [addRecordStats]
  void _updateAbsoluteStats() {
    this.totalTime = _cacheRecordStats.last.totalTime;
    this.renderTotalFrames = _cacheRecordStats.last.renderTotalFrames;
    this.renderMissedFrames = _cacheRecordStats.last.renderMissedFrames;
    this.averageFrameTime = _cacheRecordStats.last.averageFrameTime;
  }

  /// Update our lists (to see the changes of those values over time)
  /// according to our interval set by [kAmountStreamStatsForAverage]
  void _setListsFromRecordStats() {
    RecordStats relevantRecordStats =
        _cacheRecordStats.reduce((master, current) => master
          ..kbitsPerSec = min(master.kbitsPerSec, current.kbitsPerSec)
          ..fps = min(master.fps, current.fps)
          ..cpuUsage = max(master.cpuUsage, current.cpuUsage)
          ..memoryUsage = max(master.memoryUsage, current.memoryUsage));
    this.kbitsPerSecList.add(relevantRecordStats.kbitsPerSec);
    this.fpsList.add(relevantRecordStats.fps);
    this.cpuUsageList.add(relevantRecordStats.cpuUsage);
    this.memoryUsageList.add(relevantRecordStats.memoryUsage);
    this.listEntryDateMS.add(DateTime.now().millisecondsSinceEpoch);
  }
}
