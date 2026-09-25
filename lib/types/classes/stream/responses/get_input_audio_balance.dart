import 'base.dart';

/// Gets the audio balance of an input.
class GetInputAudioBalanceResponse extends BaseResponse {
  GetInputAudioBalanceResponse(super.json);

  /// Audio balance value from 0.0 (left) to 1.0 (right), 0.5 is centered
  double get inputAudioBalance =>
      (this.json['inputAudioBalance'] as num).toDouble();
}
