import 'base.dart';

/// The list of available transitions has been modified. Transitions have been added, removed, or renamed
class TransitionListChangedEvent extends BaseEvent {
  TransitionListChangedEvent(json) : super(json);

  /// Transitions list
  List<String> get transitions =>
      this.json['transitions'].map((transition) => transition.name).toList();
}
