import 'base.dart';

/// The active transition duration has been changed.
class TransitionDurationChangedEvent extends BaseEvent {
  TransitionDurationChangedEvent(Map<String, dynamic> json) : super(json);

  /// New transition duration
  int get newDuration => this.json['new-duration'];
}
