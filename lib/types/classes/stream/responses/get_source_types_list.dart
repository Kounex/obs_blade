import '../../api/source_type.dart';

import 'base.dart';

/// Get a list of all available sources types
class GetSourceTypesList extends BaseResponse {
  GetSourceTypesList(Map<String, dynamic> json) : super(json);

  List<SourceType> get types => (this.json['types'] as List<dynamic>)
      .map((type) => SourceType.fromJSON(type))
      .toList();
}
