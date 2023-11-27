import 'package:obs_blade/types/enums/request_type.dart';

enum RequestBatchType {
  /// Get the joint information about volume and mute of all inputs. This batch
  /// will have multiple of these results and we can filter based on uuid.
  ///
  /// RequestType.GetInputVolume
  /// RequestType.GetInputMute
  /// RequestType.GetInputAudioSyncOffset
  Input,

  /// Joint request to get the current status of stream and record as well
  /// as the current performance overview
  ///
  /// RequestType.GetStreamStatus
  /// RequestType.GetRecordStatus
  /// RequestType.GetStats
  Stats,

  /// Joint request to trigger a screenshot of the current OBS scene which
  /// should be saved on the filesystem where OBS is running and getting the
  /// current screenshot to display on the app. [SaveSourceScreenshot], at least
  /// from the docs, should also return the screenshot but in reality it does
  /// not so we have to get one manually
  Screenshot,

  /// [RequestType.GetSourceFilterList] needs to be called for each scene item
  /// which would mean I have to set the [currentSceneItems] property in dashboard
  /// store for each request. To make it smarter, we will send out a batch
  /// of these requests in one go and handle them at once!
  ///
  /// RequestType.GetSourceFilterList
  FilterList;

  List<RequestType> get requestTypes => {
        RequestBatchType.Input: [
          RequestType.GetInputVolume,
          RequestType.GetInputMute,
          RequestType.GetInputAudioSyncOffset,
        ],
        RequestBatchType.Stats: [
          RequestType.GetStreamStatus,
          RequestType.GetRecordStatus,
          RequestType.GetStats,
        ],
        RequestBatchType.Screenshot: [
          RequestType.SaveSourceScreenshot,
          RequestType.GetSourceScreenshot,
        ],
        RequestBatchType.FilterList: [
          RequestType.GetSourceFilterList,
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
        RequestBatchType.Screenshot: false,
        RequestBatchType.FilterList: true,
      }[this]!;
}
