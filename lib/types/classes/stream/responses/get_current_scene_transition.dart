import 'base.dart';

/// Gets information about the current scene transition.
class GetCurrentSceneTransitionResponse extends BaseResponse {
  GetCurrentSceneTransitionResponse(super.json);

  /// Name of the transition
  String get transitionName => this.json['transitionName'];

  /// Kind of the transition
  String get transitionKind => this.json['transitionKind'];

  /// Whether the transition uses a fixed (unconfigurable) duration
  bool get transitionFixed => this.json['transitionFixed'];

  /// Configured transition duration in milliseconds. null if transition is fixed
  int? get transitionDuration => this.json['transitionDuration'];

  /// Whether the transition supports being configured
  bool get transitionConfigurable => this.json['transitionConfigurable'];

  /// Object of settings for the transition. null if transition is not configurable
  dynamic get transitionSettings => this.json['transitionSettings'];
}
