import 'obs_canvas.dart';

/// Aitum Vertical (github.com/Aitum/obs-vertical-canvas) registers this
/// obs-websocket vendor - its requests go through `CallVendorRequest`, its
/// events arrive as `VendorEvent`
const String kAitumVendorName = 'aitum-vertical-canvas';

/// Name of the OBS canvas Aitum Vertical creates and finds again by name
/// (`CANVAS_NAME` in the plugin) - the only canvas its vendor controls
const String kAitumCanvasName = 'Aitum Vertical';

/// Whether Aitum Vertical's vendor answers on the current connection
enum AitumSupport {
  /// Not asked yet (no extra canvas, or the check is in flight)
  unknown,

  /// The vendor answered `version`
  available,

  /// No vendor - the plugin isn't installed, or (known plugin bug) it was
  /// installed without a stored canvas and OBS wasn't restarted since
  missing,
}

/// Whether [canvas] is the one Aitum Vertical drives
bool isAitumCanvas(ObsCanvas? canvas) =>
    canvas != null && !canvas.isMain && canvas.name == kAitumCanvasName;

/// Aitum's vendor requests pick their canvas by resolution - an unknown
/// one (0) matches any
Map<String, dynamic> aitumCanvasTarget(ObsCanvas? canvas) => {
  'width': canvas?.baseWidth ?? 0,
  'height': canvas?.baseHeight ?? 0,
};

/// Outputs of the Aitum Vertical canvas (vendor `status` / output events)
class AitumOutputStatus {
  final bool streaming;
  final bool recording;

  /// Aitum's replay buffer
  final bool backtrack;

  const AitumOutputStatus({
    this.streaming = false,
    this.recording = false,
    this.backtrack = false,
  });

  factory AitumOutputStatus.fromJson(Map<String, dynamic> json) =>
      AitumOutputStatus(
        streaming: json['streaming'] == true,
        recording: json['recording'] == true,
        backtrack: json['backtrack'] == true,
      );

  AitumOutputStatus copyWith({
    bool? streaming,
    bool? recording,
    bool? backtrack,
  }) => AitumOutputStatus(
    streaming: streaming ?? this.streaming,
    recording: recording ?? this.recording,
    backtrack: backtrack ?? this.backtrack,
  );
}

/// Why scene switching / outputs don't work for [canvas] - shown when the
/// user tries one of them
String aitumBlockedReason(AitumSupport support, ObsCanvas? canvas) {
  if (support == AitumSupport.available) {
    return 'Switching scenes and going live only work on the '
        '$kAitumCanvasName canvas';
  }
  if (support == AitumSupport.missing && isAitumCanvas(canvas)) {
    return '$kAitumCanvasName didn\'t answer - restart OBS once after '
        'installing it';
  }
  if (support == AitumSupport.unknown) {
    return 'Still checking for $kAitumCanvasName in OBS - try again in a '
        'moment';
  }
  return 'Switching this canvas\' live scene and going live need the '
      '$kAitumCanvasName plugin in OBS';
}
