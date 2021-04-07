import 'package:obs_blade/types/classes/stream/responses/base.dart';

/// Get the name of the currently selected transition in the frontend's dropdown menu
class GetCurrentTransitionResponse extends BaseResponse {
  GetCurrentTransitionResponse(json) : super(json);

  /// Name of the selected transition.
  String get name => this.json['name'];

  /// Transition duration (in milliseconds) if supported by the transition
  int? get duration => this.json['duration'];
}
