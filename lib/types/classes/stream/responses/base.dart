import '../../../enums/response_status.dart';

class BaseResponse {
  Map<String, dynamic> json;

  BaseResponse(this.json);

  /// The client defined identifier specified in the request
  int get messageID => int.parse(this.json['message-id']);

  /// Response status, will be one of the following: [ok], [error]
  String get status => this.json['status'];

  /// An error message accompanying an [error] status
  String get error =>
      this.status != ResponseStatus.OK.text ? this.json['error'] : null;
}
