import 'base.dart';

/// Get the status of the OBS replay buffer
class GetReplayBufferStatusResponse extends BaseResponse {
  GetReplayBufferStatusResponse(super.json);

  /// Whether the replay buffer output is active
  bool? get isReplayBufferActive => this.json['outputActive'];
}
