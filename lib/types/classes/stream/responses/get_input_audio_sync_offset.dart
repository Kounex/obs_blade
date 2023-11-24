import 'base.dart';

/// Gets the audio sync offset of an input.
///
/// Note: The audio sync offset can be negative too!
class GetInputAudioSyncOffsetResponse extends BaseResponse {
  GetInputAudioSyncOffsetResponse(super.json);

  /// Audio sync offset in milliseconds
  int get inputAudioSyncOffset => this.json['inputAudioSyncOffset'];
}
