import 'base.dart';

class GetCurrentSceneCollectionResponse extends BaseResponse {
  GetCurrentSceneCollectionResponse(super.json, super.newProtocol);

  /// Name of the currently active scene collection
  String get scName => this.json['sc-name'];
}
