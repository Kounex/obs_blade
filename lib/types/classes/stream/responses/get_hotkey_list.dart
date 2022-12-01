import 'base.dart';

/// Gets an array of all hotkey names in OBS
class GetHotkeyListResponse extends BaseResponse {
  GetHotkeyListResponse(super.json);

  /// Array of hotkey names
  List<String> get hotkeys => List.from(this.json['hotkeys']);
}
