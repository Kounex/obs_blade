import 'package:obs_station/types/enums/response_status.dart';

class BaseResponse {
  dynamic json;

  BaseResponse(this.json);

  int get messageID => int.parse(this.json['message-id']);

  String get status => this.json['status'];

  String get error =>
      this.status != ResponseStatus.OK.text ? this.json['error'] : null;
}
