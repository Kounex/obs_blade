import 'base.dart';

/// Triggered when switching to another scene collection or when renaming the current scene collection
class SceneCollectionChangedEvent extends BaseEvent {
  SceneCollectionChangedEvent(Map<String, dynamic> json) : super(json);

  /// Name of the new current scene collection
  String get sceneCollection => this.json['sceneCollection'];
}
