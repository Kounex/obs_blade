import 'package:obs_blade/types/classes/stream/batch_responses/base.dart';
import 'package:obs_blade/types/classes/stream/responses/get_input_mute.dart';
import 'package:obs_blade/types/classes/stream/responses/get_input_volume.dart';
import 'package:obs_blade/types/enums/request_type.dart';

class InputsBatchResponse extends BaseBatchResponse {
  InputsBatchResponse(super.json);

  Iterable<GetInputVolumeResponse> get inputsVolume => this
      .responses
      .where((response) => response.requestType == RequestType.GetInputVolume)
      .map((response) => GetInputVolumeResponse(response.jsonRAW));

  Iterable<GetInputMuteResponse> get inputsMute => this
      .responses
      .where((response) => response.requestType == RequestType.GetInputMute)
      .map((response) => GetInputMuteResponse(response.jsonRAW));
}
