import 'package:obs_blade/types/classes/stream/responses/base.dart';

/// Get the volume of the specified source
class GetVolumeResponse extends BaseResponse {
  GetVolumeResponse(json) : super(json);

  /// Source name
  String get name => this.json['name'];

  /// Volume of the source. Between 0.0 and 1.0
  double get volume => this.json['volume'];

  /// Indicates whether the source is muted
  bool get muted => this.json['muted'];
}
