import 'package:obs_blade/types/enums/web_socket_codes/web_socket_op_code.dart';

import '../../../enums/request_type.dart';
import '../../../interfaces/message.dart';

class RequestStatusObject {
  bool result;
  int code;
  String? comment;

  RequestStatusObject(this.result, this.code, this.comment);

  static RequestStatusObject fromJSON(Map<String, dynamic> json) =>
      RequestStatusObject(
        json['result'],
        json['code'],
        json['comment'],
      );
}

/// Initial Wrapper object for responses to the requests made to the OBS
/// WebSocket
class BaseResponse implements Message {
  @override
  Map<String, dynamic> jsonRAW;

  @override
  Map<String, dynamic> json;

  BaseResponse(Map<String, dynamic> json)
      : jsonRAW = json,
        json = json['d']?['responseData'] ?? {};

  BaseResponse.d(Map<String, dynamic> json)
      : jsonRAW = {
          'op': WebSocketOpCode.RequestResponse.identifier,
          'd': json,
        },
        json = json['responseData'] ?? {};

  String get uuid => this.jsonRAW['d']['requestId'];

  RequestStatusObject get status =>
      RequestStatusObject.fromJSON(this.jsonRAW['d']['requestStatus']);

  /// An error message accompanying an [error] status
  String? get error {
    final status = this.status;

    if (!status.result) {
      return status.comment;
    }

    return null;
  }

  RequestType get requestType {
    return RequestType.values
        .firstWhere((type) => type.name == this.jsonRAW['d']['requestType']);
  }
}
