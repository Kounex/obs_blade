/// OBS media states the hub reasons about (`OBS_MEDIA_STATE_*`)
const String kMediaStatePlaying = 'OBS_MEDIA_STATE_PLAYING';
const String kMediaStatePaused = 'OBS_MEDIA_STATE_PAUSED';

/// `OBS_WEBSOCKET_MEDIA_INPUT_ACTION_*`
const String kMediaActionPlay = 'OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PLAY';
const String kMediaActionPause = 'OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PAUSE';
const String kMediaActionRestart = 'OBS_WEBSOCKET_MEDIA_INPUT_ACTION_RESTART';
const String kMediaActionStop = 'OBS_WEBSOCKET_MEDIA_INPUT_ACTION_STOP';
const String kMediaActionNext = 'OBS_WEBSOCKET_MEDIA_INPUT_ACTION_NEXT';
const String kMediaActionPrevious = 'OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PREVIOUS';

/// Media input kinds that answer the OBS media-input requests
bool isMediaInputKind(String? inputKind) =>
    inputKind != null &&
    (inputKind.startsWith('ffmpeg_source') ||
        inputKind.startsWith('vlc_source'));

bool isVlcInputKind(String? inputKind) =>
    inputKind != null && inputKind.startsWith('vlc_source');

/// Snapshot of one GetMediaInputStatus answer. OBS sends no cursor events
/// while a clip plays, so [cursorAt] extrapolates from the moment the
/// snapshot arrived ([receivedAt]) - re-synced on every media event.
class MediaStatus {
  final String state;

  /// Milliseconds, null while nothing is loaded
  final int? duration;
  final int? cursor;

  final DateTime receivedAt;

  const MediaStatus({
    required this.state,
    this.duration,
    this.cursor,
    required this.receivedAt,
  });

  bool get playing => this.state == kMediaStatePlaying;
  bool get paused => this.state == kMediaStatePaused;

  /// Playing or paused - something a "stop" would end
  bool get active => this.playing || this.paused;

  /// Estimated position in ms at [now]. While playing the cursor advances
  /// with wall time, clamped to [duration] (a looping clip wraps, a
  /// non-looping one ends with a MediaInputPlaybackEnded re-read anyway)
  int? cursorAt(DateTime now) {
    final int? cursor = this.cursor;
    if (cursor == null) return null;
    if (!this.playing) return cursor;
    final int estimate =
        cursor + now.difference(this.receivedAt).inMilliseconds;
    final int? duration = this.duration;
    if (duration == null || duration <= 0) return estimate;
    return estimate % duration;
  }

  /// 0..1 progress at [now], null without a known duration
  double? progressAt(DateTime now) {
    final int? duration = this.duration;
    final int? cursor = cursorAt(now);
    if (duration == null || duration <= 0 || cursor == null) return null;
    return (cursor / duration).clamp(0.0, 1.0);
  }
}

/// `m:ss` (or `h:mm:ss`) for a millisecond duration
String formatMediaTime(int ms) {
  final Duration duration = Duration(milliseconds: ms < 0 ? 0 : ms);
  final int hours = duration.inHours;
  final String minutes = (duration.inMinutes % 60).toString();
  final String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${minutes.padLeft(2, '0')}:$seconds'
      : '$minutes:$seconds';
}
