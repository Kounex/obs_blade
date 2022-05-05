import 'base.dart';

/// Indicates if Studio Mode is currently enabled
class GetStudioModeStatusResponse extends BaseResponse {
  GetStudioModeStatusResponse(Map<String, dynamic> json) : super(json);

  /// Indicates if Studio Mode is enabled
  bool get studioMode => this.json['studio-mode'];
}
