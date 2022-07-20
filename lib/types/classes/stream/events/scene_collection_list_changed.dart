import 'base.dart';

/// The scene collection list has changed.
class SceneCollectionListChangedEvent extends BaseEvent {
  SceneCollectionListChangedEvent(super.json);

  /// Updated list of scene collections
  List<String> get sceneCollections => List.from(this.json['sceneCollections']);
}
