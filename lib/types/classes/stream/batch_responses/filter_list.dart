import 'package:obs_blade/types/classes/stream/batch_responses/base.dart';
import 'package:obs_blade/types/classes/stream/responses/get_source_filter_list.dart';

class FilterListBatchResponse extends BaseBatchResponse {
  FilterListBatchResponse(super.json);

  Iterable<GetSourceFilterListResponse> get filterLists => this
      .responses
      .map((response) => GetSourceFilterListResponse(response.jsonRAW));
}
