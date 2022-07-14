import 'base.dart';

/// List of all transitions available in the frontend's dropdown menu
class GetTransitionListResponse extends BaseResponse {
  GetTransitionListResponse(super.json, super.newProtocol);

  /// Name of the currently active transition
  String get currentTransition => this.json['current-transition'];

  /// List of transitions
  List<String> get transitions =>
      List.from(json['transitions'].map((transition) => transition['name']));
}
