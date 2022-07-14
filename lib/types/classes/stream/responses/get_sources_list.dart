import '../../api/source.dart';
import 'base.dart';

/// List all sources available in the running OBS instance
class GetSourcesListResponse extends BaseResponse {
  GetSourcesListResponse(super.json, super.newProtocol);

  /// Array of sources
  List<Source> get sources => (this.json['sources'] as List<dynamic>)
      .map((source) => Source.fromJSON(source))
      .toList();
}
