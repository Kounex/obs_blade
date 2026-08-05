import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_badge_service.dart';

part 'twitch_badges.g.dart';

class TwitchBadgeStore = _TwitchBadgeStore with _$TwitchBadgeStore;

/// Session-scoped cache of the Twitch chat badge catalogs (global +
/// per-channel). Refetched on every chat connect, in-memory only — badge
/// failures degrade to "no badges", never to a chat error.
abstract class _TwitchBadgeStore with Store {
  final TwitchBadgeService _service;

  /// Identifies the active fetch — a superseded fetch's late results must
  /// not overwrite the newer catalog (rapid reconnect / account switch).
  int _fetchGeneration = 0;

  _TwitchBadgeStore({TwitchBadgeService? service})
      : _service = service ?? TwitchBadgeService();

  /// Global catalog: setId -> (versionId -> version)
  final ObservableMap<String, Map<String, TwitchBadgeVersion>> globalBadges =
      ObservableMap();

  /// Per-channel catalog: setId -> (versionId -> version)
  final ObservableMap<String, Map<String, TwitchBadgeVersion>> channelBadges =
      ObservableMap();

  @observable
  bool isLoading = false;

  /// Exact (setId, id) lookup — the channel catalog wins over the global
  /// one; null when unknown (the message row skips those silently).
  TwitchBadgeVersion? badgeVersion(String setId, String id) =>
      this.channelBadges[setId]?[id] ?? this.globalBadges[setId]?[id];

  @action
  Future<void> fetch({
    required String accessToken,
    required String broadcasterId,
  }) async {
    final generation = ++this._fetchGeneration;
    this.isLoading = true;

    final results = await Future.wait([
      this._tryFetch(this._service.fetchGlobalBadges(accessToken), 'global'),
      this._tryFetch(
        this._service.fetchChannelBadges(accessToken, broadcasterId),
        'channel',
      ),
    ]);

    /// A newer fetch superseded this one — it owns the catalog (and
    /// [isLoading]) now.
    if (generation != this._fetchGeneration) return;

    this.isLoading = false;
    final globalSets = results[0];
    final channelSets = results[1];
    if (globalSets != null) this._applySets(this.globalBadges, globalSets);
    if (channelSets != null) this._applySets(this.channelBadges, channelSets);
  }

  @action
  void clear() {
    this._fetchGeneration++;
    this.isLoading = false;
    this.globalBadges.clear();
    this.channelBadges.clear();
  }

  /// Badges are nice-to-have: a failed endpoint degrades to no badges for
  /// its scope instead of failing the whole fetch.
  Future<List<TwitchBadgeSet>?> _tryFetch(
    Future<List<TwitchBadgeSet>> future,
    String label,
  ) async {
    try {
      return await future;
    } catch (e) {
      GeneralHelper.advLog('Twitch badge fetch ($label) failed — $e');
      return null;
    }
  }

  void _applySets(
    ObservableMap<String, Map<String, TwitchBadgeVersion>> target,
    List<TwitchBadgeSet> sets,
  ) {
    target
      ..clear()
      ..addEntries(
        sets.map(
          (set) => MapEntry(
            set.setId,
            {for (final version in set.versions) version.id: version},
          ),
        ),
      );
  }
}
