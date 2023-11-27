import 'package:obs_blade/types/classes/api/filter.dart';

import 'base.dart';

/// Gets an array of all of a source's filters.
class GetSourceFilterListResponse extends BaseResponse {
  GetSourceFilterListResponse(super.json);

  /// Array of filters
  List<Filter> get filters =>
      List.from(this.json['filters'].map((filter) => Filter.fromJson(filter)));
}
