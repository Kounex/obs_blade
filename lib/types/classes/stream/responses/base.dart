import '../../../enums/request_type.dart';

import '../../../interfaces/message.dart';

/// Initial Wrapper object for responses to the requests made to the OBS
/// WebSocket
class BaseResponse implements Message {
  /// Trivial, but just to persist the correct string used for
  /// ok status so we don't have to guess every time we add
  /// new calls
  static String ok = 'ok';

  /// Next all currently used and supported error messages
  /// so we check them correctly
  static String failedAuthentication = 'Authentication Failed.';

  @override
  Map<String, dynamic> json;

  BaseResponse(this.json);

  /// The client defined identifier specified in the request
  int get messageID => int.parse(this.json['message-id']);

  /// Response status, will be one of the following: [ok], [error]
  String get status => this.json['status'];

  /// An error message accompanying an [error] status
  String? get error =>
      this.status != BaseResponse.ok ? this.json['error'] : null;

  RequestType get requestType => RequestType.values[this.messageID];
}
