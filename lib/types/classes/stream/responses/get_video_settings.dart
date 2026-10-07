import 'base.dart';

/// Gets the current video settings.
class GetVideoSettingsResponse extends BaseResponse {
  GetVideoSettingsResponse(super.json);

  /// Width of the base (canvas) resolution in pixels
  int? get baseWidth => (this.json['baseWidth'] as num?)?.toInt();

  /// Output frame rate (numerator / denominator), null when not sent
  double? get fps {
    final num? numerator = this.json['fpsNumerator'] as num?;
    final num? denominator = this.json['fpsDenominator'] as num?;
    if (numerator == null || denominator == null || denominator == 0) {
      return null;
    }
    return numerator / denominator;
  }
}
