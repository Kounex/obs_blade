import 'package:obs_blade/types/classes/api/transition.dart';

import 'base.dart';

/// List of all transitions available in the frontend's dropdown menu
class GetSceneTransitionListResponse extends BaseResponse {
  GetSceneTransitionListResponse(super.json);

  /// Name of the current scene transition. Can be null
  String? get currentSceneTransitionName =>
      this.json['currentSceneTransitionName'];

  /// Kind of the current scene transition. Can be null
  String? get currentSceneTransitionKind =>
      this.json['currentSceneTransitionKind'];

  /// List of transitions
  List<Transition> get transitions => List.from(
      json['transitions'].map((transition) => Transition.fromJSON(transition)));
}
