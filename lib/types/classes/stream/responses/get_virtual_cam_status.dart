import 'base.dart';

/// Gets the status of the virtualcam output.
class GetVirtualCamStatusResponse extends BaseResponse {
  GetVirtualCamStatusResponse(super.json);

  /// Whether the output is active
  bool get outputActive => this.json['outputActive'];
}
