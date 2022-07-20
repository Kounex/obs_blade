import 'base.dart';

/// Gets the current volume setting of an input.
class GetInputVolumeResponse extends BaseResponse {
  GetInputVolumeResponse(super.json);

  /// Volume setting in mul
  double get inputVolumeMul => this.json['inputVolumeMul'];

  /// Volume setting in dB
  double get inputVolumeDb => this.json['inputVolumeDb'];
}
