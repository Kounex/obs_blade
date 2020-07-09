import 'package:obs_blade/types/classes/stream/responses/base.dart';

/// Get the mute status of a specified source
class GetMuteResponse extends BaseResponse {
  GetMuteResponse(json) : super(json);

  /// Source name
  String get name => json['name'];

  /// Mute status of the source
  bool get muted => json['muted'];
}
