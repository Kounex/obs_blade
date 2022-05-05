import 'base.dart';

/// Get the mute status of a specified source
class GetMuteResponse extends BaseResponse {
  GetMuteResponse(Map<String, dynamic> json) : super(json);

  /// Source name
  String get name => json['name'];

  /// Mute status of the source
  bool get muted => json['muted'];
}
