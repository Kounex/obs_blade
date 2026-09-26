import 'base.dart';

/// Gets the active and show state of a source.
class GetSourceActiveResponse extends BaseResponse {
  GetSourceActiveResponse(super.json);

  /// Whether the source is showing in Program
  bool get videoActive => this.json['videoActive'] ?? false;

  /// Whether the source is showing in the UI (Preview, Projector, Properties)
  bool get videoShowing => this.json['videoShowing'] ?? false;
}
