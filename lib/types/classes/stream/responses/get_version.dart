import 'package:obs_blade/types/classes/stream/responses/base.dart';

/// Get the volume of the specified source
class GetVersionResponse extends BaseResponse {
  GetVersionResponse(Map<String, dynamic> json) : super(json);

  /// OBSRemote compatible API version. Fixed to 1.1 for retrocompatibility
  num get version => this.json['version'];

  /// obs-websocket plugin version
  String get obsWebsocketVersion => this.json['obs-websocket-version'];

  /// OBS Studio program version
  String get obsStudioVersion => this.json['obs-studio-version'];

  /// List of available request types, formatted as a comma-separated list string (e.g. : "Method1,Method2,Method3")
  String get availableRequests => this.json['available-requests'];

  /// List of supported formats for features that use image export (like the TakeSourceScreenshot request type) formatted as a comma-separated list string
  String get supportedImageExportFormats =>
      this.json['supported-image-export-formats'];
}
