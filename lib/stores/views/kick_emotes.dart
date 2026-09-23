import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/kick/kick_emote.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/kick/kick_emote_service.dart';

part 'kick_emotes.g.dart';

class KickEmoteStore = _KickEmoteStore with _$KickEmoteStore;

/// Session-scoped catalog of a Kick channel's own emotes plus Kick's
/// platform-wide Global/Emoji sets (all three returned by the same
/// `GET /emotes/{slug}` call) — picker-only; inline rendering of emotes
/// already in a message uses the `[emote:id:name]` token path directly.
/// Refetched on every chat connect / channel switch, in-memory only —
/// failures degrade to "no first-party emotes", never a chat error (same
/// contract as [ThirdPartyEmoteStore]/`TwitchEmoteStore`).
abstract class _KickEmoteStore with Store {
  final KickEmoteService _service;

  /// Identifies the active fetch — a superseded fetch's late results must
  /// not overwrite the newer catalog (rapid reconnect / channel switch).
  int _fetchGeneration = 0;

  _KickEmoteStore({KickEmoteService? service})
    : _service = service ?? KickEmoteService();

  /// Channel-first order (`Channel`, `Global`, `Emojis`) as returned by
  /// the service.
  final ObservableList<KickEmoteSection> sections = ObservableList();

  /// Bumped once per applied fetch (and on [clear]) — the picker sheet's
  /// Observer reads this so the grid rebuilds once when the catalog
  /// lands (pop-in).
  @observable
  int catalogVersion = 0;

  /// True while a fetch is in flight — the picker shows a spinner when
  /// the catalog is still empty.
  @observable
  bool isLoading = false;

  @action
  Future<void> fetch(String slug) async {
    final generation = ++this._fetchGeneration;
    this.isLoading = true;

    final result = await this._tryFetch(slug);

    /// A newer fetch superseded this one — it owns the catalog (and
    /// [catalogVersion]/[isLoading]) now.
    if (generation != this._fetchGeneration) return;

    this.sections
      ..clear()
      ..addAll(result ?? const <KickEmoteSection>[]);
    this.isLoading = false;
    this.catalogVersion++;
  }

  @action
  void clear() {
    this._fetchGeneration++;
    this.sections.clear();
    this.isLoading = false;
    this.catalogVersion++;
  }

  Future<List<KickEmoteSection>?> _tryFetch(String slug) async {
    try {
      return await this._service.fetchChannelEmotes(slug);
    } catch (e) {
      GeneralHelper.advLog('Kick emote fetch failed — $e');
      return null;
    }
  }
}
