import 'base.dart';

/// Gets the names of all special inputs.
class GetSpecialInputsResponse extends BaseResponse {
  GetSpecialInputsResponse(super.json);

  /// Name of the Desktop Audio input
  String? get desktop1 => this.json['desktop1'];

  /// Name of the Desktop Audio 2 input
  String? get desktop2 => this.json['desktop2'];

  /// Name of the Mic/Auxiliary Audio input
  String? get mic1 => this.json['mic1'];

  /// Name of the Mic/Auxiliary Audio 2 input
  String? get mic2 => this.json['mic2'];

  /// Name of the Mic/Auxiliary Audio 3 input
  String? get mic3 => this.json['mic3'];

  /// Name of the Mic/Auxiliary Audio 3 input
  String? get mic4 => this.json['mic4'];
}
