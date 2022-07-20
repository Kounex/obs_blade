import 'base.dart';

/// The state of the record output has changed.
class RecordStateChangedEvent extends BaseEvent {
  RecordStateChangedEvent(super.json);

  /// Whether the output is active
  bool get outputActive => this.json['outputActive'];

  /// The specific state of the output
  String get outputState => this.json['outputState'];

  /// File name for the saved recording, if record stopped. null otherwise
  String? get outputPath => this.json['outputPath'];
}
