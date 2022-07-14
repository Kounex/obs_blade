import 'base.dart';

/// Triggered when switching to another scene collection or when renaming the current scene collection
class SceneCollectionChangedEvent extends BaseEvent {
  SceneCollectionChangedEvent(super.json, super.newProtocol);

  /// Name of the new current scene collection
  String get sceneCollection => this.json['sceneCollection'];
}
