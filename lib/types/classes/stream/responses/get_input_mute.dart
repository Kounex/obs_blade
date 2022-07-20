import 'base.dart';

/// Gets the audio mute state of an input.
class GetInputMuteResponse extends BaseResponse {
  GetInputMuteResponse(super.json);

  /// Whether the input is muted
  bool get inputMuted => json['inputMuted'];
}
