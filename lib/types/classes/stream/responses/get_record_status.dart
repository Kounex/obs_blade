import 'base.dart';

/// Gets the status of the record output.
class GetRecordStatusResponse extends BaseResponse {
  GetRecordStatusResponse(super.json);

  /// Whether the output is active
  bool get outputActive => this.json['outputActive'];

  /// Whether the output is paused
  bool? get outputPaused => this.json['outputPaused'];

  /// Current formatted timecode string for the output
  String get outputTimecode => this.json['outputTimecode'];

  /// Current duration in milliseconds for the output
  int get outputDuration => this.json['outputDuration'];

  /// Number of bytes sent by the output
  int get outputBytes => this.json['outputBytes'];
}
