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

/// What OBS does with a media source outside the live scene - per source,
/// from its settings (checked against OBS 32 for the ffmpeg source)
enum MediaLiveBehavior {
  /// Keeps playing unheard and carries on from there once live (ffmpeg
  /// "Restart playback when source becomes active" off, VLC "Always play")
  keepsPlaying,

  /// Stops on leaving and plays from the start whenever its scene goes
  /// live - even after a manual stop (the ffmpeg default, VLC "Stop when
  /// not visible, restart when visible")
  restarts,

  /// Pauses on leaving and resumes once live (VLC "Pause when not visible,
  /// unpause when visible")
  holds,
}

/// [MediaLiveBehavior] from a GetInputSettings answer. OBS only returns the
/// settings that differ from the defaults, so a missing key is the default
MediaLiveBehavior? mediaLiveBehaviorOf(
  String? inputKind,
  Map<String, dynamic>? settings,
) {
  if (isVlcInputKind(inputKind)) {
    return switch (settings?['playback_behavior']) {
      'always_play' => MediaLiveBehavior.keepsPlaying,
      'pause_unpause' => MediaLiveBehavior.holds,
      _ => MediaLiveBehavior.restarts,
    };
  }
  if (isMediaInputKind(inputKind)) {
    return (settings?['restart_on_activate'] ?? true) == true
        ? MediaLiveBehavior.restarts
        : MediaLiveBehavior.keepsPlaying;
  }
  return null;
}

/// One media input as the hub shows it: its status read together with
/// whether it is live and what OBS does with it while it isn't. The one
/// place that decides what runs and what can be pressed.
///
/// Outside the live scene OBS starts nothing: play from the top, restart,
/// seek and previous / next are accepted but end the clip or leave it
/// waiting. What already plays either keeps playing unheard, stops, or
/// pauses - see [MediaLiveBehavior].
class MediaPlayback {
  final MediaStatus? status;

  /// In program; unknown (not read yet) counts as live - no false alarm
  final bool live;

  /// Null until the settings are read
  final MediaLiveBehavior? behavior;

  const MediaPlayback({this.status, this.live = true, this.behavior});

  bool get playing => this.status?.playing ?? false;
  bool get paused => this.status?.paused ?? false;
  bool get active => this.status?.active ?? false;

  /// Not live and OBS plays it from the start once it is
  bool get restartsWhenLive =>
      !this.live && this.behavior == MediaLiveBehavior.restarts;

  /// Held by OBS (VLC pause_unpause) until its scene is live again
  bool get onHold =>
      !this.live && this.paused && this.behavior == MediaLiveBehavior.holds;

  /// The cursor really moves: playing live, or unheard in the background
  bool get running =>
      this.playing &&
      (this.live || this.behavior == MediaLiveBehavior.keepsPlaying);

  /// A position worth showing - not the parked cursor of a play request
  /// that waits for the scene to go live
  bool get showsPosition => this.active && !this.restartsWhenLive;

  /// Play from the top, restart, previous / next
  bool get canStart => this.live;

  bool get canSeek =>
      this.live && this.active && (this.status?.duration ?? 0) > 0;

  /// The play / pause button: pause whatever plays; play only where OBS
  /// really starts it - live, or resuming a clip that plays on unheard
  bool get canPlayPause =>
      this.playing ||
      this.live ||
      (this.paused && this.behavior == MediaLiveBehavior.keepsPlaying);

  bool get canStop => this.active;

  /// Cursor in ms at [now] - only extrapolated while [running]
  int? cursorAt(DateTime now) =>
      this.running ? this.status?.cursorAt(now) : this.status?.cursor;

  double? progressAt(DateTime now) {
    final int? duration = this.status?.duration;
    final int? cursor = cursorAt(now);
    if (duration == null || duration <= 0 || cursor == null) return null;
    return (cursor / duration).clamp(0.0, 1.0);
  }

  /// `0:12 / 0:45`, or the state when there is no position to show
  String line(DateTime now) {
    final MediaStatus? status = this.status;
    if (status == null) return '—';
    if (this.restartsWhenLive) return 'Restarts when live';
    final int? cursor = cursorAt(now);
    final int? duration = status.duration;
    if (this.onHold) {
      return cursor == null
          ? 'On hold · resumes when live'
          : 'On hold at ${formatMediaTime(cursor)} · resumes when live';
    }
    if (status.active && cursor != null && duration != null) {
      return '${formatMediaTime(cursor)} / ${formatMediaTime(duration)}';
    }
    return switch (status.state) {
      'OBS_MEDIA_STATE_ENDED' => 'Ended',
      'OBS_MEDIA_STATE_STOPPED' => 'Stopped',
      'OBS_MEDIA_STATE_OPENING' => 'Opening…',
      'OBS_MEDIA_STATE_BUFFERING' => 'Buffering…',
      'OBS_MEDIA_STATE_ERROR' => 'Error',
      _ => 'Ready',
    };
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
