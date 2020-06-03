import 'package:obs_station/types/classes/stream/responses/base.dart';

class GetVolumeResponse extends BaseResponse {
  GetVolumeResponse(json) : super(json);

  /// Source name
  String get name => this.json['name'];

  /// Volume of the source. Between 0.0 and 1.0
  num get volume => this.json['name'];

  /// Indicates whether the source is muted
  bool get muted => this.json['name'];
}
