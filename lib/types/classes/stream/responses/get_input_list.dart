import '../../api/input.dart';
import 'base.dart';

/// Gets an array of all inputs in OBS.
class GetInputListResponse extends BaseResponse {
  GetInputListResponse(super.json);

  /// Array of inputs
  List<Input> get inputs => (this.json['inputs'] as List<dynamic>)
      .map((input) => Input.fromJSON(input))
      .toList();
}
