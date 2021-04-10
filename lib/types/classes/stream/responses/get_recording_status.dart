import 'base.dart';

/// Get current recording status
class GetRecordingStatusResponse extends BaseResponse {
  GetRecordingStatusResponse(json) : super(json);

  /// Current recording status
  bool get isRecording => this.json['isRecording'];

  /// Whether the recording is paused or not
  bool get isRecordingPaused => this.json['isRecordingPaused'];

  /// Time elapsed since recording started (only present if currently recording)
  String? get recordTimecode => this.json['recordTimecode'];

  /// Absolute path to the recording file (only present if currently recording)
  String? get recordingFilename => this.json['recordingFilename'];
}
