import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/twitch/third_party_emote.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/third_party_emote_service.dart';

part 'third_party_emotes.g.dart';

class ThirdPartyEmoteStore = _ThirdPartyEmoteStore with _$ThirdPartyEmoteStore;

/// Session-scoped cache of the third-party emote catalogs (7TV + BTTV):
/// the shared global catalogs plus per-broadcaster channel catalogs
/// (keyed by broadcaster for multi-chat). Refetched on every chat
/// connect / channel switch, in-memory only — catalog failures degrade to
/// "no third-party emotes", never to a chat error.
abstract class _ThirdPartyEmoteStore with Store {
  final ThirdPartyEmoteService _service;

  /// Identifies the active fetch — a superseded fetch's late results must
  /// not overwrite the newer catalog (rapid reconnect / account switch).
  int _fetchGeneration = 0;

  _ThirdPartyEmoteStore({ThirdPartyEmoteService? service})
      : _service = service ?? ThirdPartyEmoteService();

  /// Merged global catalogs (emote name -> emote): BTTV applied first,
  /// 7TV wins same-name ties.
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
      this.channelEmotes[broadcasterId]?[token]?.imageUrl ??
      this.globalEmotes[token]?.imageUrl;

  /// Merged picker view for [broadcasterId] — its channel emotes win over
  /// the shared globals on name ties.
  List<ThirdPartyEmote> emotesFor(String broadcasterId) => {
        ...this.globalEmotes,
        ...?this.channelEmotes[broadcasterId],
      }.values.toList();

  @action
  Future<void> fetch({required String broadcasterId}) async {
    final generation = ++this._fetchGeneration;

    final results = await Future.wait([
      this._tryFetch(this._service.fetchBttvGlobal(), 'bttv-global'),
      this._tryFetch(this._service.fetchSevenTvGlobal(), '7tv-global'),
      this._tryFetch(
          this._service.fetchBttvChannel(broadcasterId), 'bttv-channel'),
      this._tryFetch(
          this._service.fetchSevenTvChannel(broadcasterId), '7tv-channel'),
    ]);

    /// A newer fetch superseded this one — it owns the catalog (and
    /// [catalogVersion]) now.
    if (generation != this._fetchGeneration) return;

    /// Merge order decides precedence on name ties — later wins:
    /// BTTV -> 7TV within each scope; the channel scope wins at lookup.
    this.globalEmotes
      ..clear()
      ..addEntries([
        for (final result in results.sublist(0, 2))
          if (result != null) ...result.entries,
      ]);

    /// Only the fetched broadcaster's slot is replaced — other channels'
    /// catalogs (multi-chat) survive the refetch.
    this.channelEmotes[broadcasterId] = Map.fromEntries([
      for (final result in results.sublist(2))
        if (result != null) ...result.entries,
    ]);
    this.catalogVersion++;
  }

  @action
  void clear() {
    this._fetchGeneration++;
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
      GeneralHelper.advLog('Third-party emote fetch ($label) failed — $e');
      return null;
    }
  }
}
