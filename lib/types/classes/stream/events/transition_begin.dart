import 'base.dart';

/// A transition (other than "cut") has begun
class TransitionBeginEvent extends BaseEvent {
  TransitionBeginEvent(super.json);

  /// Transition name
  String get name => this.json['name'];

  /// Transition type
  String get type => this.json['type'];

  /// transition duration (in milliseconds). Will be -1 for any transition
  /// with a fixed duration, such as a Stinger, due to limitations
  /// of the OBS API
  int get duration => this.json['duration'];

  /// Source scene of the transition
  String get fromScene => this.json['from-scene'];

  /// Destination scene of the transition
  String get toScene => this.json['to-scene'];
}
