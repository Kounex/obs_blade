import 'base.dart';

/// Get the mute status of a specified source
class GetMuteResponse extends BaseResponse {
  GetMuteResponse(super.json, super.newProtocol);

  /// Source name
  String get name => json['name'];

  /// Mute status of the source
  bool get muted => json['muted'];
}
