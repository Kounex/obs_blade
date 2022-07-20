import 'package:obs_blade/types/classes/stream/events/base.dart';

/// The current scene collection has changed.
///
/// Note: If polling has been paused during CurrentSceneCollectionChanging,
/// this is the que to restart polling.
class CurrentSceneCollectionChangedEvent extends BaseEvent {
  CurrentSceneCollectionChangedEvent(super.json);

  /// Name of the current scene collection
  String get sceneCollectionName => this.json['sceneCollectionName'];
}
