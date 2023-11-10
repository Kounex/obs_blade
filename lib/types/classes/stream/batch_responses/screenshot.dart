import 'package:obs_blade/types/classes/stream/batch_responses/base.dart';
import 'package:obs_blade/types/classes/stream/responses/get_source_screenshot.dart';
import 'package:obs_blade/types/enums/request_type.dart';

class ScreenshotBatchResponse extends BaseBatchResponse {
  ScreenshotBatchResponse(super.json);

  GetSourceScreenshotResponse get getSourceScreenshotResponse => this.response(
        RequestType.GetSourceScreenshot,
        (jsonRAW) => GetSourceScreenshotResponse(jsonRAW),
      );
}
