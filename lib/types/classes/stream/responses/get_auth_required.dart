import 'base.dart';

/// Tells the client if authentication is required. If so, returns
/// authentication parameters challenge and salt
/// (see "Authentication" for more information)
class GetAuthRequiredResponse extends BaseResponse {
  GetAuthRequiredResponse(super.json, super.newProtocol);

  /// Indicates whether authentication is required
  bool get authRequired => this.json['authRequired'];

  /// Used for authentication if required to
  String? get challenge => this.json['challenge'];

  /// Used to authentication if required to
  String? get salt => this.json['salt'];
}
