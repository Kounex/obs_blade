import 'base.dart';

/// Get the status of the OBS replay buffer
class GetReplayBufferStatusResponse extends BaseResponse {
  GetReplayBufferStatusResponse(Map<String, dynamic> json) : super(json);

  /// Current recording status
  bool get isReplayBufferActive => this.json['isReplayBufferActive'];
}
