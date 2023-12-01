import 'package:obs_blade/types/classes/stream/batch_responses/base.dart';
import 'package:obs_blade/types/classes/stream/responses/get_source_filter_default_settings.dart';

class FilterDefaultSettingsResponse extends BaseBatchResponse {
  FilterDefaultSettingsResponse(super.json);

  Iterable<GetSourceFilterDefaultSettingsResponse> get defaultSettings =>
      this.responses.map((response) =>
          GetSourceFilterDefaultSettingsResponse(response.jsonRAW));
}
