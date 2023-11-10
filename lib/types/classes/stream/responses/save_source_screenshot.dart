import 'base.dart';

/// Saves a screenshot of a source to the filesystem.
/// The imageWidth and imageHeight parameters are treated as "scale to inner",
/// meaning the smallest ratio will be used and the aspect ratio of the
/// original resolution is kept. If imageWidth and imageHeight are not
/// specified, the compressed image will use the full resolution of the source.
class SaveSourceScreenshotResponse extends BaseResponse {
  SaveSourceScreenshotResponse(super.json);

  /// Base64-encoded screenshot
  String get imageData => this.json['imageData'];
}
