import 'package:obs_blade/types/classes/stream/batch_responses/base.dart';
import 'package:obs_blade/types/classes/stream/responses/get_stats.dart';
import 'package:obs_blade/types/classes/stream/responses/get_stream_status.dart';
import 'package:obs_blade/types/enums/request_type.dart';

import '../responses/get_record_status.dart';

class StatsBatchResponse extends BaseBatchResponse {
  StatsBatchResponse(super.json);

  GetStreamStatusResponse get streamStatus => this.response(
        RequestType.GetStreamStatus,
        (jsonRAW) => GetStreamStatusResponse(jsonRAW),
      );

  GetRecordStatusResponse get recordStatus => this.response(
        RequestType.GetRecordStatus,
        (jsonRAW) => GetRecordStatusResponse(jsonRAW),
      );

  GetStatsResponse get stats => this.response(
        RequestType.GetStats,
        (jsonRAW) => GetStatsResponse(jsonRAW),
      );
}
