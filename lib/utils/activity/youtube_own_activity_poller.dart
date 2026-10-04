import 'dart:async';
import 'dart:math' as math;

import '../../stores/views/youtube_chat.dart'
    show kYouTubeQuotaResetGrace, nextYouTubeQuotaReset;
import '../../types/classes/activity/activity_event.dart';
import '../general_helper.dart';
import '../youtube/youtube_live_chat_service.dart';
import '../youtube/youtube_live_resolver.dart';
import '../youtube_target.dart';
import 'activity_mappers.dart';

/// Where the own-channel poller is.
enum YouTubeOwnActivityState {
  /// Not running: not Pro, no API key, or no own channel (sign-in)
  off,

  /// Checking (quota-free) whether the own channel is live
  waiting,

  /// Attached to the own live chat and reading it
  live,

  /// The YouTube chat itself reads the own chat right now - nothing to do
  standby,

  /// The API key's daily quota is used up - waits for the reset
  quotaExhausted,
}

/// Collects the activity feed rows (Super Chats, stickers, memberships,
/// gifts) of the user's OWN YouTube stream, whatever chat is on screen,
/// without the YouTube chat store (`docs/superpowers/specs/
/// 2026-10-04-activity-feed-status.md`).
///
/// Waiting costs no quota: the channel's `/live` page (~3 KB read with the
/// mobile user agent) every [idleCheck] in the foreground, every
/// [fastCheck] while OBS streams. Once live: one `videos.list` (1 unit),
/// then `liveChatMessages.list` (~5 units) every [pollInterval] - slower
/// than a chat on screen, a page holds up to 500 messages and the page
/// token carries on, so nothing is skipped. The first page re-sends recent
/// history; the feed dedupes by message id.
class YouTubeOwnActivityPoller {
  static const Duration idleCheck = Duration(minutes: 2);
  static const Duration fastCheck = Duration(seconds: 30);
  static const Duration pollInterval = Duration(seconds: 30);
  static const Duration _maxBackoff = Duration(minutes: 5);
  static const Duration _upcomingCheck = Duration(minutes: 5);

  /// A suspended timer never fires on iOS - the quota wait re-checks at
  /// least this often (and on [wake])
  static const Duration _maxQuotaWait = Duration(minutes: 30);

  final YouTubeLiveResolver _resolver;
  final YouTubeLiveChatService _chatService;
  final DateTime Function() _clock;

  /// Every mapped row of the own stream
  void Function(ActivityEvent event)? onEvent;

  /// State changes ([state], [liveSince])
  void Function()? onChanged;

  YouTubeOwnActivityPoller({
    YouTubeLiveResolver? resolver,
    YouTubeLiveChatService? chatService,
    DateTime Function()? clock,
  }) : _resolver = resolver ?? YouTubeLiveResolver(),
       _chatService = chatService ?? YouTubeLiveChatService(),
       _clock = clock ?? DateTime.now;

  YouTubeOwnActivityState _state = YouTubeOwnActivityState.off;
  YouTubeOwnActivityState get state => this._state;

  /// When the own broadcast started (`actualStartTime`), while [state] is
  /// live
  DateTime? _liveSince;
  DateTime? get liveSince => this._liveSince;

  /// When polling resumes after a used-up quota
  DateTime? _quotaResetAt;
  DateTime? get quotaResetAt => this._quotaResetAt;

  String? _channelId;
  String _apiKey = '';
  bool _enabled = false;
  bool _standby = false;
  bool _fast = false;
  bool _foreground = true;

  String? _videoId;
  String? _endedVideoId;
  String? _liveChatId;
  String? _pageToken;
  Duration _backoff = Duration.zero;

  bool _running = false;
  int _generation = 0;
  Completer<void>? _sleeping;

  String? get channelId => this._channelId;

  /// Inputs: the own channel id (signed in with a channel), the API key,
  /// and whether it may run at all (Pro).
  void configure({
    required String? channelId,
    required String apiKey,
    required bool enabled,
  }) {
    final run = enabled && channelId != null && apiKey.isNotEmpty;
    final switched = channelId != this._channelId;
    if (switched) this._resetChat(clearEnded: true);
    this._channelId = channelId;
    this._apiKey = apiKey;
    if (run == this._enabled) {
      if (switched && run) this.wake();
      return;
    }
    this._enabled = run;
    if (run) {
      this._start();
    } else {
      this._stop();
    }
  }

  /// The YouTube chat reads the own chat itself right now.
  set standby(bool value) {
    if (value == this._standby) return;
    this._standby = value;
    this.wake();
  }

  /// OBS is streaming - check for the own stream more often.
  set fast(bool value) {
    if (value == this._fast) return;
    this._fast = value;
    if (value) this.wake();
  }

  /// App in the foreground: only then does a waiting poller check.
  set foreground(bool value) {
    if (value == this._foreground) return;
    this._foreground = value;
    if (value) this.wake();
  }

  /// Check / poll now instead of waiting out the current pause.
  void wake() {
    final sleeping = this._sleeping;
    if (sleeping != null && !sleeping.isCompleted) sleeping.complete();
  }

  void _start() {
    if (this._running) {
      this.wake();
      return;
    }
    this._running = true;
    final generation = ++this._generation;
    unawaited(this._loop(generation));
  }

  void _stop() {
    this._running = false;
    this._generation++;
    this.wake();
    this._resetChat(clearEnded: false);
    this._quotaResetAt = null;
    this._setState(YouTubeOwnActivityState.off);
  }

  Future<void> _loop(int generation) async {
    while (this._running && generation == this._generation) {
      final delay = await this.step();
      if (!this._running || generation != this._generation) return;
      if (delay > Duration.zero) await this._sleep(delay);
    }
  }

  Future<void> _sleep(Duration delay) {
    final completer = Completer<void>();
    this._sleeping = completer;
    final timer = Timer(delay, () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future.whenComplete(timer.cancel);
  }

  void _resetChat({required bool clearEnded}) {
    this._videoId = null;
    this._liveChatId = null;
    this._pageToken = null;
    this._liveSince = null;
    this._backoff = Duration.zero;
    if (clearEnded) this._endedVideoId = null;
  }

  void _setState(YouTubeOwnActivityState state) {
    if (state == this._state) return;
    this._state = state;
    this.onChanged?.call();
  }

  Duration _waitingDelay() => this._fast ? fastCheck : idleCheck;

  Duration _backOff() {
    this._backoff = this._backoff == Duration.zero
        ? pollInterval
        : this._backoff * 2;
    if (this._backoff > _maxBackoff) this._backoff = _maxBackoff;
    return this._backoff;
  }

  /// One step of the poller; returns how long to wait before the next.
  /// Public for tests (they drive it without timers).
  Future<Duration> step() async {
    final generation = this._generation;
    final delay = await this._step();

    /// Turned off (sign-out, key removed, Pro lapsed) while a request was
    /// out: what it found must not bring the state back
    if (generation != this._generation && !this._enabled) {
      this._resetChat(clearEnded: false);
      this._setState(YouTubeOwnActivityState.off);
    }
    return delay;
  }

  Future<Duration> _step() async {
    final channelId = this._channelId;
    if (!this._enabled || channelId == null) {
      return idleCheck;
    }
    final now = this._clock();
    final resetAt = this._quotaResetAt;
    if (resetAt != null) {
      if (now.isBefore(resetAt)) {
        this._setState(YouTubeOwnActivityState.quotaExhausted);
        final wait = resetAt.difference(now);
        return wait < _maxQuotaWait ? wait : _maxQuotaWait;
      }
      this._quotaResetAt = null;
    }
    if (this._standby) {
      /// Pick up from scratch afterwards - the chat may have moved on
      this._resetChat(clearEnded: false);
      this._setState(YouTubeOwnActivityState.standby);
      return idleCheck;
    }
    if (this._liveChatId == null) return this._attach(channelId);
    return this._poll(channelId);
  }

  Future<Duration> _attach(String channelId) async {
    final generation = this._generation;
    bool stale() => generation != this._generation || !this._enabled;
    this._setState(YouTubeOwnActivityState.waiting);

    /// The `/live` check runs only while someone may look (or OBS streams)
    if (!this._foreground && !this._fast) return idleCheck;
    final String? videoId;
    try {
      videoId = await this._resolver.resolveLiveVideoId(
        YouTubeChannelTarget('channel/$channelId'),
      );
    } catch (e) {
      GeneralHelper.logFailure('Activity: YouTube live check failed', e);
      return this._waitingDelay();
    }
    if (stale()) return idleCheck;
    if (videoId == null || videoId == this._endedVideoId) {
      return this._waitingDelay();
    }
    final YouTubeLiveStreamingDetails details;
    try {
      details = await this._chatService.resolveLiveStreamingDetails(
        videoId,
        apiKey: this._apiKey,
      );
    } on YouTubeQuotaExceededException catch (e) {
      return this._quotaUsedUp(e);
    } catch (e) {
      GeneralHelper.logFailure('Activity: YouTube live chat lookup failed', e);
      return this._backOff();
    }
    if (stale()) return idleCheck;
    final liveChatId = details.liveChatId;

    /// Chat turned off, or a scheduled stream that hasn't started (its
    /// `/live` page can point at the upcoming video, whose waiting-room
    /// chat may already have an id): nothing to collect yet. Each look
    /// costs 1 unit - an upcoming stream is checked every 5 min at most.
    if (liveChatId == null || details.actualStartTime == null) {
      final wait = this._waitingDelay();
      return wait < _upcomingCheck ? _upcomingCheck : wait;
    }
    this._videoId = videoId;
    this._liveChatId = liveChatId;
    this._pageToken = null;
    this._backoff = Duration.zero;
    this._liveSince = details.actualStartTime;
    this._setState(YouTubeOwnActivityState.live);
    this.onChanged?.call();
    return Duration.zero;
  }

  Future<Duration> _poll(String channelId) async {
    final generation = this._generation;
    final YouTubeLiveChatPage page;
    try {
      page = await this._chatService.listMessages(
        this._liveChatId!,
        this._pageToken,
        apiKey: this._apiKey,
      );
    } on YouTubeChatEndedException {
      return this._ended();
    } on YouTubeQuotaExceededException catch (e) {
      return this._quotaUsedUp(e);
    } on YouTubeRateLimitedException catch (e) {
      GeneralHelper.logFailure('Activity: YouTube chat poll throttled', e);
      return this._backOff();
    } catch (e) {
      GeneralHelper.logFailure('Activity: YouTube chat poll failed', e);
      final status = e is YouTubeApiException ? e.statusCode : null;

      /// 403 / 404: the chat is gone for us (ended, turned off)
      if (status == 403 || status == 404) return this._ended();
      return this._backOff();
    }
    if (generation != this._generation || !this._enabled) return idleCheck;
    this._backoff = Duration.zero;
    this._pageToken = page.nextPageToken;
    final emit = this.onEvent;
    if (emit != null) {
      for (final message in page.messages) {
        final event = youTubeActivityFromMessage(message, channelId);
        if (event != null) emit(event);
      }
    }
    if (page.offlineAt != null) return this._ended();

    /// A full page: more is waiting, fetch it right after the minimum
    final minimum = Duration(milliseconds: page.pollingIntervalMillis);
    if (page.messages.length >= 500) return minimum;
    return Duration(
      milliseconds: math.max(
        pollInterval.inMilliseconds,
        minimum.inMilliseconds,
      ),
    );
  }

  Duration _ended() {
    this._endedVideoId = this._videoId;
    this._resetChat(clearEnded: false);
    this._setState(YouTubeOwnActivityState.waiting);
    this.onChanged?.call();
    return this._waitingDelay();
  }

  Duration _quotaUsedUp(Object error) {
    GeneralHelper.logFailure('Activity: YouTube API quota used up', error);
    final resetAt = nextYouTubeQuotaReset(
      this._clock(),
    ).add(kYouTubeQuotaResetGrace);
    this._quotaResetAt = resetAt;
    this._resetChat(clearEnded: false);
    this._setState(YouTubeOwnActivityState.quotaExhausted);
    this.onChanged?.call();
    final wait = resetAt.difference(this._clock());
    return wait < _maxQuotaWait ? wait : _maxQuotaWait;
  }

  /// Tests: enabled without the timer loop (they drive [step]).
  void enabledForTest({required String channelId, required String apiKey}) {
    this._channelId = channelId;
    this._apiKey = apiKey;
    this._enabled = true;
  }

  Future<void> dispose() async {
    this._stop();
  }
}
