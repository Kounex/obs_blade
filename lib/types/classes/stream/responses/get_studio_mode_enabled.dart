import 'base.dart';

/// Gets whether studio is enabled.
class GetStudioModeEnabledResponse extends BaseResponse {
  GetStudioModeEnabledResponse(super.json);

  /// Whether studio mode is enabled
  bool get studioModeEnabled => this.json['studioModeEnabled'];
}
