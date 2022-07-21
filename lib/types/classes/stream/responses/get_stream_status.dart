import 'base.dart';

/// Gets the status of the stream output.
class GetStreamStatusResponse extends BaseResponse {
  GetStreamStatusResponse(super.json);

  /// Whether the output is active
  bool get outputActive => this.json['outputActive'];

  /// Whether the output is currently reconnecting
  bool get outputReconnecting => this.json['outputReconnecting'];

  /// Current formatted timecode string for the output
  String get outputTimecode => this.json['outputTimecode'];

  /// Current duration in milliseconds for the output
  int get outputDuration => this.json['outputDuration'];

  /// Congestion of the output
  double get outputCongestion => this.json['outputCongestion'];

  /// Number of bytes sent by the output
  int get outputBytes => this.json['outputBytes'];

  /// Number of frames skipped by the output's process
  int get outputSkippedFrames => this.json['outputSkippedFrames'];

  /// Total number of frames delivered by the output's process
  int get outputTotalFrames => this.json['outputTotalFrames'];
}
