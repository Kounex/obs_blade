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

  final bool virtualCamera;

  /// The vendor neither reports nor announces a pause - tracked from the
  /// app's own pause / resume answers (see
  /// [CanvasViewStore.setAitumRecordingPaused])
  final bool recordingPaused;

  const AitumOutputStatus({
    this.streaming = false,
    this.recording = false,
    this.backtrack = false,
    this.virtualCamera = false,
    this.recordingPaused = false,
  });

  /// A `status` answer - [recordingPaused] isn't part of it, so the known
  /// pause carries over while the recording keeps running
  factory AitumOutputStatus.fromJson(
    Map<String, dynamic> json, {
    bool recordingPaused = false,
  }) {
    final bool recording = json['recording'] == true;
    return AitumOutputStatus(
      streaming: json['streaming'] == true,
      recording: recording,
      backtrack: json['backtrack'] == true,
      virtualCamera: json['virtual_camera'] == true,
      recordingPaused: recording && recordingPaused,
    );
  }

  AitumOutputStatus copyWith({
    bool? streaming,
    bool? recording,
    bool? backtrack,
    bool? virtualCamera,
    bool? recordingPaused,
  }) => AitumOutputStatus(
    streaming: streaming ?? this.streaming,
    recording: recording ?? this.recording,
    backtrack: backtrack ?? this.backtrack,
    virtualCamera: virtualCamera ?? this.virtualCamera,
    recordingPaused: recordingPaused ?? this.recordingPaused,
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

/// What the app bar's extra-canvas pill shows - see
/// [CanvasViewStore.extraCanvasOnAir]
class ExtraCanvasOnAir {
  final ObsCanvas canvas;

  /// Sent along with the main stream (Enhanced Broadcasting / Twitch Dual
  /// Format) - live exactly while the main stream is
  final bool viaMainStream;

  final bool streaming;
  final bool recording;
  final bool recordingPaused;

  const ExtraCanvasOnAir({
    required this.canvas,
    required this.viaMainStream,
    required this.streaming,
    required this.recording,
    required this.recordingPaused,
  });
}
