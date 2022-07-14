import 'base.dart';

/// Indicates if Studio Mode is currently enabled
class GetStudioModeStatusResponse extends BaseResponse {
  GetStudioModeStatusResponse(super.json, super.newProtocol);

  /// Indicates if Studio Mode is enabled
  bool get studioMode => this.json['studio-mode'];
}
