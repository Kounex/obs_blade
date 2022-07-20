import 'package:obs_blade/types/enums/request_type.dart';

enum RequestBatchType {
  /// RequestType.GetInputVolume,
  /// RequestType.GetInputMute
  Input;

  List<RequestType> get requestTypes => {
        RequestBatchType.Input: [
          RequestType.GetInputVolume,
          RequestType.GetInputMute,
        ],
      }[this]!;
}
