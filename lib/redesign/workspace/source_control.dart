/// Item IDs are unique only inside their owning scene or group.
typedef ObsSourceTarget = ({String owner, int id});

class SourceControl {
  const SourceControl({
    required this.target,
    required this.name,
    required this.depth,
    required this.isGroup,
    required this.enabled,
    required this.hiddenByGroup,
    required this.canChange,
    required this.busy,
    this.error,
  });

  final ObsSourceTarget target;
  final String name;
  final int depth;
  final bool isGroup;
  final bool? enabled;
  final bool hiddenByGroup;
  final bool canChange;
  final bool busy;
  final String? error;
}
