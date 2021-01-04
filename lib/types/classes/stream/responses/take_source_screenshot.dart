import 'package:obs_blade/types/classes/stream/responses/base.dart';

/// Get the volume of the specified source
class TakeSourceScreenshotResponse extends BaseResponse {
  TakeSourceScreenshotResponse(json) : super(json);

  /// Source name
  String get sourceName => this.json['sourceName'];

  /// Image Data URI (if embedPictureFormat was specified in the request)
  String get img => this.json['img'];

  /// Absolute path to the saved image file (if saveToFilePath was specified in the request)
  String get imageFile => this.json['imageFile'];
}
