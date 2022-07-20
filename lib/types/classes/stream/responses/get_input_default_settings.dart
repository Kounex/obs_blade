import 'base.dart';

/// Gets the default settings for an input kind.
class GetInputDefaultSettingsResponse extends BaseResponse {
  GetInputDefaultSettingsResponse(super.json);

  /// Object of default settings for the input kind
  dynamic get defaultInputSettings => this.json['defaultInputSettings'];
}
