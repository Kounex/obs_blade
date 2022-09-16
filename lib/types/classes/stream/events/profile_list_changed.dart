import 'base.dart';

/// The profile list has changed.
class ProfileListChangedEvent extends BaseEvent {
  ProfileListChangedEvent(super.json);

  /// Updated list of profiles
  List<String> get profiles => List.from(this.json['profiles']);
}
