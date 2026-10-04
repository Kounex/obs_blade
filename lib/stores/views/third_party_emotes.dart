import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/twitch/third_party_emote.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/third_party_emote_service.dart';

part 'third_party_emotes.g.dart';

class ThirdPartyEmoteStore = _ThirdPartyEmoteStore with _$ThirdPartyEmoteStore;

/// Session-scoped cache of the third-party emote catalogs (7TV + BTTV +
/// FFZ):
/// the shared global catalogs plus per-broadcaster channel catalogs
/// (keyed by broadcaster for multi-chat). Refetched on every chat
/// connect / channel switch, in-memory only — catalog failures degrade to
/// "no third-party emotes", never to a chat error.
abstract class _ThirdPartyEmoteStore with Store {
  final ThirdPartyEmoteService _service;

  /// Fetches are numbered; each source (FFZ, BTTV, 7TV) of each scope
  /// (global, a broadcaster) keeps the number of the fetch it came from.
  /// A result applies only over an older one - a superseded fetch's late
  /// answer never overwrites a newer catalog (rapid reconnect), and a
  /// source that failed keeps its last good catalog. Per scope: one
  /// "newest fetch wins" for the whole store let Twitch's and Kick's
  /// connects in a combined chat throw each other's channel catalogs away
  /// (ohnePixel's 7TV / BTTV emotes as text, 2026-10-04).
  int _fetchSeq = 0;

  /// Fetches started up to here were cleared away ([clear])
  int _clearedSeq = 0;
  final List<_Applied> _globalSources = [_Applied(), _Applied(), _Applied()];
  final Map<String, List<_Applied>> _channelSources = {};

  _ThirdPartyEmoteStore({ThirdPartyEmoteService? service})
    : _service = service ?? ThirdPartyEmoteService();

  /// Merged global catalogs (emote name -> emote): FFZ applied first,
  /// then BTTV, 7TV wins same-name ties.
  final ObservableMap<String, ThirdPartyEmote> globalEmotes = ObservableMap();

  /// Per-broadcaster merged channel catalogs:
  /// broadcasterId -> (emote name -> emote)
  final ObservableMap<String, Map<String, ThirdPartyEmote>> channelEmotes =
      ObservableMap();

  /// Bumped once per applied fetch (and on [clear]) — the chat view's
  /// outer Observer reads this so the visible rows rebuild once when
  /// catalogs land (pop-in) instead of every row observing the map.
  @observable
  int catalogVersion = 0;

  /// Exact, case-sensitive lookup by chat token — [broadcasterId]'s
  /// channel catalog wins over the global one and an unfetched broadcaster
  /// falls back to global cleanly; null when unknown (the message row
  /// renders the token as text then).
  String? emoteImageUrl(String token, {required String broadcasterId}) =>
      this.emote(token, broadcasterId: broadcasterId)?.imageUrl;

  /// Same lookup as [emoteImageUrl], returning the whole emote (the
  /// message rows need [ThirdPartyEmote.zeroWidth]).
  ThirdPartyEmote? emote(String token, {required String broadcasterId}) =>
      this.channelEmotes[broadcasterId]?[token] ?? this.globalEmotes[token];

  /// Merged picker view for [broadcasterId] — its channel emotes win over
  /// the shared globals on name ties.
  List<ThirdPartyEmote> emotesFor(String broadcasterId) => {
    ...this.globalEmotes,
    ...?this.channelEmotes[broadcasterId],
  }.values.toList();

  /// [isKick]: [broadcasterId] is the Kick USER id — only 7TV's `kick`
  /// platform is queried for the channel scope (BTTV has no Kick
  /// platform at all; see [ThirdPartyEmoteService.fetchSevenTvKickChannel]).
  /// The global scope (both catalogs) is unaffected — 7TV/BTTV global
  /// sets aren't platform-gated, so they're shared across engines.
  @action
  Future<void> fetch({
    required String broadcasterId,
    bool isKick = false,
  }) async {
    final seq = ++this._fetchSeq;

    final results = await Future.wait([
      this._tryFetch(this._service.fetchBttvGlobal(), 'bttv-global'),
      this._tryFetch(this._service.fetchSevenTvGlobal(), '7tv-global'),
      isKick
          ? Future.value(const <String, ThirdPartyEmote>{})
          : this._tryFetch(
              this._service.fetchBttvChannel(broadcasterId),
              'bttv-channel',
            ),
      this._tryFetch(
        isKick
            ? this._service.fetchSevenTvKickChannel(broadcasterId)
            : this._service.fetchSevenTvChannel(broadcasterId),
        isKick ? '7tv-kick-channel' : '7tv-channel',
      ),

      /// FFZ is Twitch-only for channels; its global set is shared.
      this._tryFetch(this._service.fetchFfzGlobal(), 'ffz-global'),
      isKick
          ? Future.value(const <String, ThirdPartyEmote>{})
          : this._tryFetch(
              this._service.fetchFfzChannel(broadcasterId),
              'ffz-channel',
            ),
    ]);

    /// Merge order decides precedence on name ties — later wins:
    /// FFZ -> BTTV -> 7TV within each scope; the channel scope wins at
    /// lookup.
    final (bttvGlobal, sevenTvGlobal, bttvChannel, sevenTvChannel) = (
      results[0],
      results[1],
      results[2],
      results[3],
    );
    final (ffzGlobal, ffzChannel) = (results[4], results[5]);

    if (seq <= this._clearedSeq) return;
    final globalChanged = _apply(this._globalSources, seq, [
      ffzGlobal,
      bttvGlobal,
      sevenTvGlobal,
    ]);
    if (globalChanged) {
      this.globalEmotes
        ..clear()
        ..addEntries(_merged(this._globalSources));
    }
    final channel = this._channelSources[broadcasterId] ??= [
      _Applied(),
      _Applied(),
      _Applied(),
    ];

    /// Only the fetched broadcaster's slot is replaced — other channels'
    /// catalogs (multi-chat, the other platform) survive the refetch.
    final channelChanged = _apply(channel, seq, [
      ffzChannel,
      bttvChannel,
      sevenTvChannel,
    ]);
    if (channelChanged) {
      this.channelEmotes[broadcasterId] = Map.fromEntries(_merged(channel));
    }
    if (globalChanged || channelChanged) this.catalogVersion++;
  }

  /// Applies each [fresh] source that answered and is newer than what the
  /// slot holds; true when anything changed
  static bool _apply(
    List<_Applied> slots,
    int seq,
    List<Map<String, ThirdPartyEmote>?> fresh,
  ) {
    var changed = false;
    for (var i = 0; i < slots.length; i++) {
      final emotes = fresh[i];
      if (emotes == null || seq <= slots[i].seq) continue;
      slots[i]
        ..seq = seq
        ..emotes = emotes;
      changed = true;
    }
    return changed;
  }

  static Iterable<MapEntry<String, ThirdPartyEmote>> _merged(
    List<_Applied> sources,
  ) => [
    for (final source in sources)
      if (source.emotes case final emotes?) ...emotes.entries,
  ];

  @action
  void clear() {
    this._clearedSeq = this._fetchSeq;
    for (final slot in this._globalSources) {
      slot
        ..seq = 0
        ..emotes = null;
    }
    this._channelSources.clear();
    this.globalEmotes.clear();
    this.channelEmotes.clear();
    this.catalogVersion++;
  }

  /// Third-party emotes are nice-to-have: a failed endpoint degrades to
  /// no emotes for its scope instead of failing the whole fetch.
  Future<Map<String, ThirdPartyEmote>?> _tryFetch(
    Future<Map<String, ThirdPartyEmote>> future,
    String label,
  ) async {
    try {
      return await future;
    } catch (e) {
      GeneralHelper.advLog('Third-party emote fetch ($label) failed - $e');
      return null;
    }
  }
}

/// One source's catalog in a scope, and the fetch it came from
class _Applied {
  int seq = 0;
  Map<String, ThirdPartyEmote>? emotes;
}
