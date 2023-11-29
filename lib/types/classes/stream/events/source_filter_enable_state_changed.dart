import 'base.dart';

/// A source filter's enable state has changed.
class SourceFilterEnableStateChangedEvent extends BaseEvent {
  SourceFilterEnableStateChangedEvent(super.json);

  /// Name of the source the filter is on
  String get sourceName => this.json['sourceName'];

  /// Name of the filter
  String get filterName => this.json['filterName'];

  /// Whether the filter is enabled
  bool get filterEnabled => this.json['filterEnabled'];
}
