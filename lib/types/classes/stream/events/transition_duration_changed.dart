import 'base.dart';

/// The active transition duration has been changed.
class TransitionDurationChangedEvent extends BaseEvent {
  TransitionDurationChangedEvent(json) : super(json);

  /// New transition duration
  int get newDuration => this.json['new-duration'];
}
