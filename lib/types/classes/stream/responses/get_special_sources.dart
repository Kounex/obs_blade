import 'package:obs_station/types/classes/stream/responses/base.dart';

/// Get configured special sources like Desktop Audio and Mic/Aux sources
class GetSpecialSourcesResponse extends BaseResponse {
  GetSpecialSourcesResponse(json) : super(json);

  /// Name of the first Desktop Audio capture source
  String get desktop1 => this.json['desktop-1'];

  /// Name of the second Desktop Audio capture source
  String get desktop2 => this.json['desktop-2'];

  /// Name of the first Mic/Aux input source
  String get mic1 => this.json['mic-1'];

  /// Name of the second Mic/Aux input source
  String get mic2 => this.json['mic-2'];

  /// Name of the third Mic/Aux input source
  String get mic3 => this.json['mic-3'];
}
