class AudioInputControl {
  const AudioInputControl({
    required this.name,
    required this.volume,
    required this.muted,
    required this.fresh,
    required this.busy,
    this.pendingVolume,
    this.error,
  });

  final String name;
  final double? volume;
  final bool muted;
  final bool fresh;
  final bool busy;
  final double? pendingVolume;
  final String? error;
  bool get canChange => fresh && !busy;
}
