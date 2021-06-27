import 'package:obs_blade/types/classes/stream/responses/base.dart';

/// List of all transitions available in the frontend's dropdown menu
class GetTransitionListResponse extends BaseResponse {
  GetTransitionListResponse(Map<String, dynamic> json) : super(json);

  /// Name of the currently active transition
  String get currentTransition => this.json['current-transition'];

  /// List of transitions
  List<String> get transitions =>
      List.from(json['transitions'].map((transition) => transition['name']));
}
