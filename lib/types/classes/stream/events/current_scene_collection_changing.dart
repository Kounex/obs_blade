import 'package:obs_blade/types/classes/stream/events/base.dart';

/// The current scene collection has begun changing.
///
/// Note: We recommend using this event to trigger a pause of all polling requests,
/// as performing any requests during a scene collection change is considered undefined
/// behavior and can cause crashes!
class CurrentSceneCollectionChangingEvent extends BaseEvent {
  CurrentSceneCollectionChangingEvent(super.json);

  /// Name of the current scene collection
  String get sceneCollectionName => this.json['sceneCollectionName'];
}
