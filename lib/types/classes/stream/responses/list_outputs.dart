import '../../api/output.dart';
import 'base.dart';

/// List existing outputs
class ListOutputsResponse extends BaseResponse {
  ListOutputsResponse(super.json, super.newProtocol);

  /// Outputs list
  List<Output> get outputs => (this.json['outputs'] as List<dynamic>)
      .map((output) => Output.fromJSON(output))
      .toList();
}
