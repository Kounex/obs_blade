import 'base.dart';

/// Get settings of the specified source
class GetSourceSettingsResponse extends BaseResponse {
  GetSourceSettingsResponse(Map<String, dynamic> json) : super(json);

  /// Source name
  String get sourceName => this.json['sourceName'];

  /// Type of the specified source
  String get sourceType => this.json['sourceType'];

  /// Source settings (varies between source types, may require some probing around)
  dynamic get sourceSettings => this.json['sourceSettings'];
}
