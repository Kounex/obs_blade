import 'base.dart';

class TransitionBeginEvent extends BaseEvent {
  TransitionBeginEvent(json) : super(json);

  /// transition name
  String get name => this.json['name'];

  /// transition type
  String get type => this.json['type'];

  /// transition duration (in milliseconds). will be -1 for any transition
  /// with a fixed duration, such as a Stinger, due to limitations
  /// of the OBS API
  int get duration => this.json['duration'];

  /// source scene of the transition
  String get fromScene => this.json['from-scene'];

  /// destination scene of the transition
  String get toScene => this.json['to-scene'];
}
