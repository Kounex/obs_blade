import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user_emote.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_emote_service.dart';

part 'twitch_emotes.g.dart';

class TwitchEmoteStore = _TwitchEmoteStore with _$TwitchEmoteStore;

/// Session-scoped catalog of the first-party emotes the logged-in user can
/// use in their own channel's chat (Helix `chat/emotes/user`), split for
/// the picker into channel vs global sections. Refetched on every chat
/// connect, in-memory only — failures degrade to "no first-party emotes",
/// never to a chat error.
abstract class _TwitchEmoteStore with Store {
  final TwitchEmoteService _service;

  /// Identifies the active fetch — a superseded fetch's late results must
  /// not overwrite the newer catalog (rapid reconnect / account switch).
  int _fetchGeneration = 0;

  _TwitchEmoteStore({TwitchEmoteService? service})
      : _service = service ?? TwitchEmoteService();

  /// Emotes owned by the logged-in channel, alpha-sorted by name.
  final ObservableList<TwitchUserEmote> channelEmotes = ObservableList();

  /// Everything else (Twitch globals), alpha-sorted by name.
  final ObservableList<TwitchUserEmote> globalEmotes = ObservableList();

  /// Bumped once per applied fetch (and on [clear]) — the picker sheet's
  /// Observer reads this so the grid rebuilds once when the catalog lands.
  @observable
  int catalogVersion = 0;

  /// True while a fetch is in flight — the sheet shows a spinner when the
  /// catalog is still empty.
  @observable
  bool isLoading = false;

  @action
  Future<void> fetch({
    required String accessToken,
    required String userId,
  }) async {
    final generation = ++this._fetchGeneration;
    this.isLoading = true;

    /// The chat engine only ever connects to the user's own channel, so
    /// userId doubles as broadcasterId.
    final emotes = await this._tryFetch(
      this._service.fetchUserEmotes(
        accessToken,
        userId: userId,
        broadcasterId: userId,
      ),
    );

    /// A newer fetch superseded this one — it owns the catalog (and
    /// [catalogVersion]/[isLoading]) now.
    if (generation != this._fetchGeneration) return;

    final channel = <TwitchUserEmote>[];
    final global = <TwitchUserEmote>[];
    for (final emote in emotes ?? const <TwitchUserEmote>[]) {
      (emote.ownerId == userId ? channel : global).add(emote);
    }
    int byName(TwitchUserEmote a, TwitchUserEmote b) =>
        a.name.compareTo(b.name);
    channel.sort(byName);
    global.sort(byName);

    this.channelEmotes
      ..clear()
      ..addAll(channel);
    this.globalEmotes
      ..clear()
      ..addAll(global);
    this.isLoading = false;
    this.catalogVersion++;
  }

  @action
  void clear() {
    this._fetchGeneration++;
    this.channelEmotes.clear();
    this.globalEmotes.clear();
    this.isLoading = false;
    this.catalogVersion++;
  }

  /// First-party emotes are nice-to-have: a failed fetch degrades to no
  /// emotes instead of failing chat connect.
  Future<List<TwitchUserEmote>?> _tryFetch(
      Future<List<TwitchUserEmote>> future) async {
    try {
      return await future;
    } catch (e) {
      GeneralHelper.advLog('Twitch user emote fetch failed — $e');
      return null;
    }
  }
}
