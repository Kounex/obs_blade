import 'youtube_live_chat_service.dart';
import 'youtube_live_chat_stream.dart';

/// A call that closes sooner than this (from its start) costs more than
/// polling at Google's 2-5 s interval would have (5 units either way).
/// Google closes every call ~10.3 s after its start (measured 2026-10-19).
const Duration kYouTubeStreamMinLifetime = Duration(seconds: 5);

/// Short calls in a row (or calls that never opened) before polling
/// takes over / checks.
const int kYouTubeShortStreamLimit = 3;

/// How long a chat polls after the stream gave way, before it tries the
/// stream again (one call - 5 units).
const Duration kYouTubeStreamRetryAfter = Duration(minutes: 10);

/// First wait before reconnecting a call that dropped or closed early;
/// doubles per try up to [kYouTubeStreamMaxReconnectDelay].
const Duration kYouTubeStreamReconnectDelay = Duration(seconds: 1);
const Duration kYouTubeStreamMaxReconnectDelay = Duration(seconds: 60);

/// What a read loop does after a `streamList` call ended.
enum YouTubeStreamNext {
  /// Open the next call - after [YouTubeStreamDecision.delay]
  reconnect,

  /// Poll until [YouTubeStreamPolicy.shouldStream] again
  poll,
}

class YouTubeStreamDecision {
  final YouTubeStreamNext next;
  final Duration delay;

  /// The call dropped soon after opening, or never opened: worth a
  /// "reconnecting" in the UI (a long call's drop reconnects at once and
  /// shows nothing - Google may rotate calls)
  final bool dropped;

  const YouTubeStreamDecision.reconnect(this.delay, {this.dropped = false})
    : next = YouTubeStreamNext.reconnect;

  const YouTubeStreamDecision.poll()
    : next = YouTubeStreamNext.poll,
      delay = Duration.zero,
      dropped = false;
}

/// The rules for reading one live chat over `streamList` with
/// `liveChatMessages.list` as the fallback - the YouTube chat's read loop
/// (`docs/superpowers/specs/2026-10-19-youtube-chat-quota-design.md`):
///
/// - a long call the server closed or that dropped: reconnect at once
///   from the last page token;
/// - [kYouTubeShortStreamLimit] opened calls in a row under
///   [kYouTubeStreamMinLifetime]: they cost what polling does - poll for
///   [kYouTubeStreamRetryAfter];
/// - calls that never opened (not billed): back off; after
///   [kYouTubeShortStreamLimit] of them one poll checks - a dead network
///   fails it too and its first answer hands back to the stream, while
///   the stream still not opening after a poll worked means gRPC can't
///   get through: poll for [kYouTubeStreamRetryAfter];
/// - `FAILED_PRECONDITION` (ended **or** disabled): one poll tells; when
///   the poll answered (the chat runs) and the stream says it again, poll
///   for [kYouTubeStreamRetryAfter];
/// - any other refusal ([YouTubeStreamFallbackException]): the poll's
///   answers say what's wrong - poll for [kYouTubeStreamRetryAfter].
///
/// A chat-ended row / `offlineAt` on a streamed page is the caller's to
/// handle (definitive).
class YouTubeStreamPolicy {
  final DateTime Function() _now;

  YouTubeStreamPolicy({DateTime Function()? now}) : _now = now ?? DateTime.now;

  DateTime? _pollUntil;
  int _shortCalls = 0;
  int _unopenedCalls = 0;
  bool _probing = false;
  bool _pollWorkedWithoutStream = false;
  Duration _reconnectDelay = Duration.zero;

  /// The poll is checking a `FAILED_PRECONDITION` / answered it normally
  bool _checkingEnded = false;
  bool _endedCheckAnswered = false;

  /// Stream now (no poll window running)?
  bool get shouldStream {
    final until = this._pollUntil;
    return until == null || !this._now().isBefore(until);
  }

  /// When the poll window ends (null: none)
  DateTime? get pollUntil => this._pollUntil;

  /// A poll got an answer.
  void pollAnswered() {
    if (this._checkingEnded) {
      this._checkingEnded = false;
      this._endedCheckAnswered = true;
    }
    if (!this._probing) return;
    this._probing = false;
    this._pollWorkedWithoutStream = true;
  }

  /// A read loop (re)starts streaming this chat: short calls and the
  /// reconnect wait count from here - a resume or a switch back isn't
  /// held to the calls before it.
  void newRead() {
    this._shortCalls = 0;
    this._reconnectDelay = Duration.zero;
  }

  /// A new chat (or the chat ended): start over.
  void reset() {
    this._pollUntil = null;
    this._shortCalls = 0;
    this._unopenedCalls = 0;
    this._probing = false;
    this._pollWorkedWithoutStream = false;
    this._reconnectDelay = Duration.zero;
    this._checkingEnded = false;
    this._endedCheckAnswered = false;
  }

  /// A call that started at [startedAt] ended: [opened] whether Google
  /// accepted it (billed), [error] what it ended with (null: the server
  /// closed it / it was closed on purpose). Its length counts from
  /// [startedAt]: what bills is calls per hour, and an accepted call's
  /// headers can come seconds late.
  YouTubeStreamDecision callEnded({
    required DateTime startedAt,
    required bool opened,
    required Object? error,
  }) {
    final now = this._now();
    if (error is YouTubeChatEndedException) {
      if (this._endedCheckAnswered) {
        this._endedCheckAnswered = false;
        return this._pollFor(kYouTubeStreamRetryAfter);
      }
      final decision = this._pollFor(Duration.zero);
      this._checkingEnded = true;
      return decision;
    }
    if (error != null && error is! YouTubeStreamDroppedException) {
      return this._pollFor(kYouTubeStreamRetryAfter);
    }
    if (opened) {
      this._unopenedCalls = 0;
      this._pollWorkedWithoutStream = false;
      final short = now.difference(startedAt) < kYouTubeStreamMinLifetime;
      if (!short) {
        this._shortCalls = 0;
        this._reconnectDelay = Duration.zero;
        this._endedCheckAnswered = false;
        return const YouTubeStreamDecision.reconnect(Duration.zero);
      }
      if (++this._shortCalls >= kYouTubeShortStreamLimit) {
        return this._pollFor(kYouTubeStreamRetryAfter);
      }
      return YouTubeStreamDecision.reconnect(
        this._nextDelay(),
        dropped: error != null,
      );
    }
    if (++this._unopenedCalls >= kYouTubeShortStreamLimit) {
      if (this._pollWorkedWithoutStream) {
        return this._pollFor(kYouTubeStreamRetryAfter);
      }
      final decision = this._pollFor(Duration.zero);
      this._probing = true;
      return decision;
    }
    return YouTubeStreamDecision.reconnect(this._nextDelay(), dropped: true);
  }

  YouTubeStreamDecision _pollFor(Duration window) {
    this._pollUntil = this._now().add(window);
    this._shortCalls = 0;
    this._unopenedCalls = 0;
    this._probing = false;
    if (window > Duration.zero) this._pollWorkedWithoutStream = false;
    this._reconnectDelay = Duration.zero;
    return const YouTubeStreamDecision.poll();
  }

  Duration _nextDelay() {
    final next = this._reconnectDelay == Duration.zero
        ? kYouTubeStreamReconnectDelay
        : this._reconnectDelay * 2;
    this._reconnectDelay = next > kYouTubeStreamMaxReconnectDelay
        ? kYouTubeStreamMaxReconnectDelay
        : next;
    return this._reconnectDelay;
  }
}
