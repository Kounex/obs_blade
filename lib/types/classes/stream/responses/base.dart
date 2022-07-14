import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';

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
  /// Trivial, but just to persist the correct string used for
  /// ok status so we don't have to guess every time we add
  /// new calls
  static String ok = 'ok';

  /// Next all currently used and supported error messages
  /// so we check them correctly
  static String failedAuthentication =
      GetIt.instance<NetworkStore>().newProtocol
          ? WebSocketCloseCode.AuthenticationFailed.message
          : 'Authentication Failed.';

  @override
  bool newProtocol;

  @override
  Map<String, dynamic> jsonRAW;

  @override
  Map<String, dynamic> json;

  BaseResponse(Map<String, dynamic> json, this.newProtocol)
      : jsonRAW = json,
        json = newProtocol ? (json['d']['responseData'] ?? {}) : json;

  /// The client defined identifier specified in the request
  int get messageIDOld => int.parse(this.json['message-id']);

  /// Response status, will be one of the following: [ok], [error]
  ///
  /// OLD, < 4.X
  String get statusOld => this.json['status'];

  /// NEW > 5.X
  RequestStatusObject get statusNew => this.jsonRAW['d']['requestStatus'];

  /// An error message accompanying an [error] status
  String? get error {
    if (this.newProtocol) {
      final status = this.statusNew;

      if (!status.result) {
        return status.comment;
      }

      return null;
    }
    return this.statusOld != BaseResponse.ok ? this.json['error'] : null;
  }

  RequestType get requestType {
    if (this.newProtocol) {
      return RequestType.values
          .firstWhere((type) => type.name == this.jsonRAW['d']['requestType']);
    }
    return RequestType.values[this.messageIDOld];
  }
}
