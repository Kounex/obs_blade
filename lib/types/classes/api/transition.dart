class Transition {
  /// Name of the transition
  String transitionName;

  /// Kind of the transition
  String transitionKind;

  /// Whether the transition uses a fixed (unconfigurable) duration
  bool transitionFixed;

  /// Configured transition duration in milliseconds. null if transition is fixed
  int? transitionDuration;

  /// Whether the transition supports being configured
  bool transitionConfigurable;

  /// Object of settings for the transition. null if transition is not configurable
  dynamic transitionSettings;

  Transition({
    required this.transitionName,
    required this.transitionKind,
    required this.transitionFixed,
    this.transitionDuration,
    required this.transitionConfigurable,
    this.transitionSettings,
  });

  static Transition fromJSON(Map<String, dynamic> json) => Transition(
        transitionName: json['transitionName'],
        transitionKind: json['transitionKind'],
        transitionFixed: json['transitionFixed'],
        transitionDuration: json['transitionDuration'],
        transitionConfigurable: json['transitionConfigurable'],
        transitionSettings: json['transitionSettings'],
      );
}
