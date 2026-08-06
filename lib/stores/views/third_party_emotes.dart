import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/twitch/third_party_emote.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/third_party_emote_service.dart';

part 'third_party_emotes.g.dart';

class ThirdPartyEmoteStore = _ThirdPartyEmoteStore with _$ThirdPartyEmoteStore;

/// Session-scoped cache of the third-party emote catalogs (7TV + BTTV,
/// global + channel, merged into one map). Refetched on every chat
/// connect, in-memory only — catalog failures degrade to "no third-party
/// emotes", never to a chat error.
abstract class _ThirdPartyEmoteStore with Store {
  final ThirdPartyEmoteService _service;

  /// Identifies the active fetch — a superseded fetch's late results must
  /// not overwrite the newer catalog (rapid reconnect / account switch).
  int _fetchGeneration = 0;

  _ThirdPartyEmoteStore({ThirdPartyEmoteService? service})
      : _service = service ?? ThirdPartyEmoteService();

  /// Merged catalog (emote name -> emote).
  final ObservableMap<String, ThirdPartyEmote> emotes = ObservableMap();

  /// Bumped once per applied fetch (and on [clear]) — the chat view's
  /// outer Observer reads this so the visible rows rebuild once when
  /// catalogs land (pop-in) instead of every row observing the map.
  @observable
  int catalogVersion = 0;

  /// Exact, case-sensitive lookup by chat token; null when unknown (the
  /// message row renders the token as text then).
  String? emoteImageUrl(String token) => this.emotes[token]?.imageUrl;

  @action
  Future<void> fetch({required String broadcasterId}) async {
    final generation = ++this._fetchGeneration;

    /// Merge order decides precedence on name ties — later wins:
    /// global-BTTV -> global-7TV -> channel-BTTV -> channel-7TV
    /// (net: channel > global, 7TV > BTTV).
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

    this.emotes
      ..clear()
      ..addEntries([
        for (final result in results)
          if (result != null) ...result.entries,
      ]);
    this.catalogVersion++;
  }

  @action
  void clear() {
    this._fetchGeneration++;
    this.emotes.clear();
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
