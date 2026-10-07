import 'base.dart';

/// Gets the private settings of a scene item (per placement) - the source
/// color assigned in OBS 32+ lives here ('color-preset' / 'color').
class GetSceneItemPrivateSettingsResponse extends BaseResponse {
  GetSceneItemPrivateSettingsResponse(super.json);

  /// Arbitrary private settings object of the scene item - unknown /
  /// missing keys simply mean "not set" (e.g. no color)
  Map<String, dynamic> get sceneItemSettings => Map<String, dynamic>.from(
    this.json['sceneItemSettings'] as Map? ?? const {},
  );
}
