import 'base.dart';

/// Gets an array of all scene collections
class GetSceneCollectionListResponse extends BaseResponse {
  GetSceneCollectionListResponse(super.json);

  /// The name of the current scene collection
  String get currentSceneCollectionName =>
      this.json['currentSceneCollectionName'];

  /// Array of all available scene collections
  List<String> get sceneCollections => List.from(this.json['sceneCollections']);
}
