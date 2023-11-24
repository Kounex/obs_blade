import 'package:freezed_annotation/freezed_annotation.dart';

part 'transition.freezed.dart';
part 'transition.g.dart';

@freezed
class Transition with _$Transition {
  const factory Transition({
    /// Name of the transition
    required String transitionName,

    /// Kind of the transition
    required String transitionKind,

    /// Whether the transition uses a fixed (unconfigurable) duration
    required bool transitionFixed,

    /// Configured transition duration in milliseconds. null if transition is fixed
    required int? transitionDuration,

    /// Whether the transition supports being configured
    required bool transitionConfigurable,

    /// Object of settings for the transition. null if transition is not configurable
    required dynamic transitionSettings,
  }) = _Transition;

  factory Transition.fromJson(Map<String, Object?> json) =>
      _$TransitionFromJson(json);
}
