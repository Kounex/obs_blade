import 'base.dart';

class GetAuthRequiredResponse extends BaseResponse {
  GetAuthRequiredResponse(json) : super(json);

  /// indicates whether authentication is required
  bool get authRequired => this.json['authRequired'];

  /// used for authentication if required to
  String get challenge => this.json['challenge'];

  /// used to authentication if required to
  String get salt => this.json['salt'];
}
