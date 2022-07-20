import 'base.dart';

/// The current preview scene has changed.
class CurrentPreviewSceneChangedEvent extends BaseEvent {
  CurrentPreviewSceneChangedEvent(super.json);

  /// Name of the scene that was switched to
  String get sceneName => this.json['sceneName'];
}
