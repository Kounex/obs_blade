import 'base.dart';

/// The list of available transitions has been modified. Transitions have been added, removed, or renamed
class TransitionListChangedEvent extends BaseEvent {
  TransitionListChangedEvent(Map<String, dynamic> json) : super(json);

  /// Transitions list
  List<String> get transitions => List.from(
      this.json['transitions'].map((transition) => transition['name']));
}
