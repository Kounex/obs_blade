import 'base.dart';

/// Gets the audio monitor type of an input.
class GetInputAudioMonitorTypeResponse extends BaseResponse {
  GetInputAudioMonitorTypeResponse(super.json);

  /// `OBS_MONITORING_TYPE_NONE` / `_MONITOR_ONLY` / `_MONITOR_AND_OUTPUT`
  String get monitorType => this.json['monitorType'];
}
