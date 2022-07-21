import 'package:obs_blade/types/enums/request_type.dart';

enum RequestBatchType {
  /// Get the joint information about volume and mute of all inputs. This batch
  /// will have multiple of these results and we can filter based on uuid.
  ///
  /// RequestType.GetInputVolume
  /// RequestType.GetInputMute
  Input,

  /// Joint request to get the current status of stream and record as well
  /// as the current performance overview
  ///
  /// RequestType.GetStreamStatus
  /// RequestType.GetRecordStatus
  /// RequestType.GetStats
  Stats;

  List<RequestType> get requestTypes => {
        RequestBatchType.Input: [
          RequestType.GetInputVolume,
          RequestType.GetInputMute,
        ],
        RequestBatchType.Stats: [
          RequestType.GetStreamStatus,
          RequestType.GetRecordStatus,
          RequestType.GetStats,
        ],
      }[this]!;

  /// Indicates whether we need to persist this request to get the
  /// body of the request once we received the response and mix and match
  /// request + reponse (for example we want to get the volume of a source
  /// where the response will have the volume but not the name of the source -
  /// the name of the source is defined in the request payload)
  bool get lookup => {
        RequestBatchType.Input: true,
        RequestBatchType.Stats: false,
      }[this]!;
}
