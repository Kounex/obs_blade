import 'base.dart';

/// Gets data about the current plugin and RPC version.
class GetVersionResponse extends BaseResponse {
  GetVersionResponse(super.json);

  /// Current OBS Studio version
  String get obsVersion => this.json['obsVersion'];

  /// Current obs-websocket version
  String get obsWebSocketVersion => this.json['obsWebSocketVersion'];

  /// Current latest obs-websocket RPC version
  int get rpcVersion => this.json['rpcVersion'];

  /// Array of available RPC requests for the currently negotiated RPC version
  List<dynamic> get availableRequests =>
      List.from(this.json['availableRequests']);

  /// Image formats available in GetSourceScreenshot and SaveSourceScreenshot requests.
  List<String> get supportedImageFormats =>
      List.from(this.json['supportedImageFormats']);

  /// Name of the platform. Usually windows, macos, or ubuntu (linux flavor).
  /// Not guaranteed to be any of those
  String get platform => this.json['platform'];

  /// Description of the platform, like Windows 10 (10.0)
  String get platformDescription => this.json['platformDescription'];
}
