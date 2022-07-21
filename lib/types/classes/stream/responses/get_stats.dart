import 'base.dart';

/// Gets statistics about OBS, obs-websocket, and the current session.
class GetStatsResponse extends BaseResponse {
  GetStatsResponse(super.json);

  /// Current CPU usage in percent
  double get cpuUsage => this.json['cpuUsage'];

  /// Amount of memory in MB currently being used by OBS
  double get memoryUsage => this.json['memoryUsage'];

  /// Available disk space on the device being used for recording storage
  double get availableDiskSpace => this.json['availableDiskSpace'];

  /// Current FPS being rendered
  double get activeFps => this.json['activeFps'];

  /// Average time in milliseconds that OBS is taking to render a frame
  double get averageFrameRenderTime => this.json['averageFrameRenderTime'];

  /// Number of frames skipped by OBS in the render thread
  int get renderSkippedFrames => this.json['renderSkippedFrames'];

  /// Total number of frames outputted by the render thread
  int get renderTotalFrames => this.json['renderTotalFrames'];

  /// Number of frames skipped by OBS in the output thrcead
  int get outputSkippedFrames => this.json['outputSkippedFrames'];

  /// Total number of frames outputted by the output thread
  int get outputTotalFrames => this.json['outputTotalFrames'];

  /// Total number of messages received by obs-websocket from the client
  int get webSocketSessionIncomingMessages =>
      this.json['webSocketSessionIncomingMessages'];

  /// Total number of messages sent by obs-websocket to the client
  int get webSocketSessionOutgoingMessages =>
      this.json['webSocketSessionOutgoingMessages'];
}
