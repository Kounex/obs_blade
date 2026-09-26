import 'base.dart';

/// Gets the current video settings.
class GetVideoSettingsResponse extends BaseResponse {
  GetVideoSettingsResponse(super.json);

  /// Width of the base (canvas) resolution in pixels
  int? get baseWidth => (this.json['baseWidth'] as num?)?.toInt();
}
