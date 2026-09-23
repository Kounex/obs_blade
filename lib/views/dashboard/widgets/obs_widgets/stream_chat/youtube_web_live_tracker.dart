import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../../utils/general_helper.dart';
import '../../../../../utils/youtube/youtube_live_resolver.dart';
import '../../../../../utils/youtube_target.dart';

enum YouTubeWebLiveState { resolving, live, offline, error }

/// Keeps the WebView YouTube chat pointed at a channel entry's *current*
/// stream: resolves `channel → live video id` via [YouTubeLiveResolver]
/// and re-checks on a timer, so a new stream swaps the embed's `v=` on its
/// own (the popout chat URL only takes a video id). Video entries never
/// reach this class — their id is known up front.
class YouTubeWebLiveTracker extends ChangeNotifier {
  /// Re-check cadence while offline (waiting for the stream to start).
  static const Duration kOfflineRecheck = Duration(seconds: 45);

  /// Re-check cadence while live — catches "stream ended, next one
  /// started" without the user touching anything. The check streams only
  /// the first few KB of the page.
  static const Duration kLiveRecheck = Duration(minutes: 2);

  final YouTubeLiveResolver _resolver;

  YouTubeWebLiveTracker({YouTubeLiveResolver? resolver})
    : _resolver = resolver ?? YouTubeLiveResolver();

  YouTubeChannelTarget? _target;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;

  YouTubeWebLiveState state = YouTubeWebLiveState.resolving;
  String? videoId;
  String? error;

  /// Point the tracker at [target] (null = nothing to track). Same target
  /// is a no-op; a new one resets and resolves immediately.
  void track(YouTubeChannelTarget? target) {
    if (target == this._target) return;
    this._target = target;
    this._timer?.cancel();
    this._generation++;
    this.videoId = null;
    this.error = null;
    this.state = YouTubeWebLiveState.resolving;
    if (target != null) unawaited(this._check(this._generation));
  }

  /// Skip the wait (UI "Check now").
  void recheck() {
    if (this._target == null) return;
    this._timer?.cancel();
    final generation = ++this._generation;
    if (this.state != YouTubeWebLiveState.live) {
      this.state = YouTubeWebLiveState.resolving;
      this.notifyListeners();
    }
    unawaited(this._check(generation));
  }

  Future<void> _check(int generation) async {
    final target = this._target;
    if (target == null) return;
    String? resolved;
    Object? failure;
    try {
      resolved = await this._resolver.resolveLiveVideoId(target);
    } on YouTubeLiveResolveException catch (e) {
      failure = e;
      GeneralHelper.advLog('YouTube WebView live lookup failed - $e');
    }
    if (this._disposed || generation != this._generation) return;

    if (failure is YouTubeLiveResolveException) {
      /// Keep a live embed running through a transient lookup failure —
      /// only surface the error when there's nothing to show anyway.
      if (this.state != YouTubeWebLiveState.live) {
        this.state = YouTubeWebLiveState.error;
        this.error = failure.message;
      }
    } else if (resolved != null) {
      this.state = YouTubeWebLiveState.live;
      this.videoId = resolved;
      this.error = null;
    } else {
      this.state = YouTubeWebLiveState.offline;
      this.videoId = null;
      this.error = null;
    }
    this.notifyListeners();

    /// A 404 channel won't fix itself — no timer.
    if (failure is YouTubeLiveResolveException && failure.statusCode == 404) {
      return;
    }
    this._timer = Timer(
      this.state == YouTubeWebLiveState.live ? kLiveRecheck : kOfflineRecheck,
      () => unawaited(this._check(generation)),
    );
  }

  @override
  void dispose() {
    this._disposed = true;
    this._timer?.cancel();
    super.dispose();
  }
}
