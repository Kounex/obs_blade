import 'package:obs_station/types/classes/responses/base.dart';

class GetAuthRequiredResponse extends BaseResponse {
  GetAuthRequiredResponse(json) : super(json);

  bool get authRequired => this.json['authRequired'];
  String get challenge => this.json['challenge'];
  String get salt => this.json['salt'];
}
