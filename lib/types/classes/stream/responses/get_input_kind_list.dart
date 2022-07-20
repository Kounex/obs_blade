import 'base.dart';

/// Gets an array of all available input kinds in OBS.
class GetInputKindListResponse extends BaseResponse {
  GetInputKindListResponse(super.json);

  List<String> get inputKinds => List.from(this.json['inputKinds']);
}
