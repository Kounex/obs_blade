import 'base.dart';

/// Gets the default settings for a filter kind.
class GetSourceFilterDefaultSettingsResponse extends BaseResponse {
  GetSourceFilterDefaultSettingsResponse(super.json);

  /// Object of default settings for the filter kind
  Map<String, dynamic> get defaultFilterSettings =>
      this.json['defaultFilterSettings'];
}
