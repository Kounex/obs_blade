import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../models/twitch_auth.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../types/classes/twitch/twitch_channel_ref.dart';
import '../../../../../../types/classes/twitch/twitch_channel_search_result.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/twitch/twitch_channel_service.dart';
import 'add_chat_sheet_chrome.dart';
import '../twitch_device_code_dialog.dart';

/// Opens the "Add chat" picker sheet (multi-chat) — the entry behind
/// `NativeChannelDropdown`'s "Add chat…" item. [pickOnly]: the combined
/// chat builder's "Other Twitch channel…" - the tapped channel is the
/// sheet's result (any of them, listed or not) instead of being added.
Future<TwitchChannelRef?> showAddChatSheet(
  BuildContext context, {
  TwitchChannelService? channelService,
  bool pickOnly = false,
}) => ModalHandler.showBaseBottomSheet<TwitchChannelRef>(
  context: context,
  barrierDismissible: true,
  enableDrag: true,
  maxHeightFraction: 0.72,
  builder: (context) =>
      AddChatSheet(channelService: channelService, pickOnly: pickOnly),
);

/// "Add chat" picker (multi-chat): find another streamer's channel and add
/// it to the native chat. A debounced search field queries Helix Search
/// Channels; with an empty query the "Channels you moderate" / "Channels
/// you follow" quick-pick sections show instead (each fails independently
/// with an inline retry). Already-added channels (and the user's own)
/// render checked and disabled. Sections whose scope the token lacks are
/// hidden, with a re-login CTA at the bottom.
class AddChatSheet extends StatefulWidget {
  /// Injectable for tests — no real HTTP in unit tests.
  final TwitchChannelService? channelService;

  /// Picker for the combined chat builder: tapping a channel pops it as
  /// the result; nothing is added and nothing is greyed out.
  final bool pickOnly;

  const AddChatSheet({super.key, this.channelService, this.pickOnly = false});

  @override
  State<AddChatSheet> createState() => _AddChatSheetState();
}

class _AddChatSheetState extends State<AddChatSheet> {
  static const Duration _kDebounce = Duration(milliseconds: 300);

  late final TwitchChannelService _channelService =
      this.widget.channelService ?? TwitchChannelService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  /// Guards against a stale search overwriting a newer one's results.
  int _searchSeq = 0;
  String _lastQuery = '';
  bool _searching = false;
  Object? _searchError;
  List<TwitchChannelSearchResult> _results = const [];

  bool _loadingModerated = false;
  bool _loadingFollowed = false;
  Object? _moderatedError;
  Object? _followedError;
  List<TwitchChannelRef> _moderated = const [];
  List<TwitchChannelRef> _followed = const [];

  /// Live viewer counts for each quick-pick section (from best-effort
  /// `/streams`). Key present ⇒ live.
  Map<String, int> _moderatedLiveViewers = const {};
  Map<String, int> _followedLiveViewers = const {};
  Map<String, int> _searchLiveViewers = const {};

  TwitchChatStore get _store => GetIt.instance<TwitchChatStore>();

  String? get _accessToken => Hive.box<TwitchAuth>(
    HiveKeys.TwitchAuth.name,
  ).get(TwitchAuth.kBoxKey)?.accessToken;

  @override
  void initState() {
    super.initState();
    if (this._store.canReadModeratedChannels) this._loadModerated();
    if (this._store.canReadFollows) this._loadFollowed();
  }

  @override
  void dispose() {
    this._debounce?.cancel();
    this._searchController.dispose();
    super.dispose();
  }

  /// Best-effort live enrich — a streams failure must not fail the
  /// section (list still renders, just without LIVE chips / live-first).
  Future<Map<String, int>> _liveViewerCountsFor(
    String accessToken,
    Iterable<String> ids,
  ) async {
    try {
      return await this._channelService.getLiveBroadcasterIds(
        accessToken: accessToken,
        broadcasterIds: ids,
      );
    } catch (_) {
      return const {};
    }
  }

  Future<void> _loadModerated() async {
    final token = this._accessToken;
    final userId = this._store.user?.id;
    this.setState(() {
      this._loadingModerated = true;
      this._moderatedError = null;
    });
    try {
      if (token == null || userId == null) {
        throw StateError('Not logged in');
      }
      final refs = await this._channelService.getModeratedChannels(
        accessToken: token,
        userId: userId,
      );
      final liveCounts = await this._liveViewerCountsFor(
        token,
        refs.map((ref) => ref.id),
      );
      final sorted = sortChannelPickerRefs(
        refs,
        liveIds: liveCounts.keys.toSet(),
        modIds: const {},
      );
      if (this.mounted) {
        this.setState(() {
          this._moderated = sorted;
          this._moderatedLiveViewers = liveCounts;
          this._loadingModerated = false;
        });
      }
    } catch (e) {
      if (this.mounted) {
        this.setState(() {
          this._moderatedError = e;
          this._loadingModerated = false;
        });
      }
    }
  }

  Future<void> _loadFollowed() async {
    final token = this._accessToken;
    final userId = this._store.user?.id;
    this.setState(() {
      this._loadingFollowed = true;
      this._followedError = null;
    });
    try {
      if (token == null || userId == null) {
        throw StateError('Not logged in');
      }
      final refs = await this._channelService.getFollowedChannels(
        accessToken: token,
        userId: userId,
      );
      final liveCounts = await this._liveViewerCountsFor(
        token,
        refs.map((ref) => ref.id),
      );
      final modIds = this._store.moderatedChannelIds.toSet();
      final sorted = sortChannelPickerRefs(
        refs,
        liveIds: liveCounts.keys.toSet(),
        modIds: modIds,
      );
      if (this.mounted) {
        this.setState(() {
          this._followed = sorted;
          this._followedLiveViewers = liveCounts;
          this._loadingFollowed = false;
        });
      }
    } catch (e) {
      if (this.mounted) {
        this.setState(() {
          this._followedError = e;
          this._loadingFollowed = false;
        });
      }
    }
  }

  void _onQueryChanged(String query) {
    this._debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      this.setState(() {
        this._lastQuery = '';
        this._results = const [];
        this._searchLiveViewers = const {};
        this._searchError = null;
        this._searching = false;
      });
      return;
    }
    this._debounce = Timer(_kDebounce, () => this._search(trimmed));
  }

  Future<void> _search(String query) async {
    final token = this._accessToken;
    final seq = ++this._searchSeq;
    this.setState(() {
      this._lastQuery = query;
      this._searching = true;
      this._searchError = null;
    });
    try {
      if (token == null) throw StateError('Not logged in');
      final results = await this._channelService.searchChannels(
        accessToken: token,
        query: query,
      );
      final sorted = sortChannelSearchResults(
        results,
        modIds: this._store.moderatedChannelIds.toSet(),
      );
      final liveCounts = await this._liveViewerCountsFor(
        token,
        sorted.map((result) => result.id),
      );
      if (this.mounted && seq == this._searchSeq) {
        this.setState(() {
          this._results = sorted;
          this._searchLiveViewers = liveCounts;
          this._searching = false;
        });
      }
    } catch (e) {
      if (this.mounted && seq == this._searchSeq) {
        this.setState(() {
          this._searchError = e;
          this._searching = false;
        });
      }
    }
  }

  /// Adding expresses intent to view — the store switches straight away.
  /// Fire-and-forget: the sheet closes immediately, the switch lands on
  /// the chat view behind it.
  void _addChannel(TwitchChannelRef ref) {
    if (this.widget.pickOnly) {
      Navigator.of(context).pop(ref);
      return;
    }
    unawaited(this._store.addChannel(ref));
    Navigator.of(context).pop();
  }

  static String _searchSubtitle(TwitchChannelSearchResult result) {
    final login = '@${result.login}';
    if (result.gameName.isEmpty) return login;
    return '$login · ${result.gameName}';
  }

  @override
  Widget build(BuildContext context) {
    final store = this._store;
    final locked = !store.canReadModeratedChannels || !store.canReadFollows;

    return AddChatSheetFrame(
      title: this.widget.pickOnly ? 'Twitch channel' : 'Add chat',
      controller: this._searchController,
      onChanged: this._onQueryChanged,
      hintText: 'Search channels',
      body: Observer(
        builder: (_) {
          /// Read an observable up front — the loading/error
          /// branches build no rows, which would otherwise leave
          /// the Observer with nothing tracked.
          final ownId = store.user?.id;
          return this._searchController.text.trim().isNotEmpty
              ? this._buildSearchResults(context, store, ownId)
              : this._buildSections(context, store, ownId);
        },
      ),
      footer: locked
          ? Row(
              children: [
                Icon(
                  CupertinoIcons.lock_fill,
                  size: 14.0,
                  color:
                      (Theme.of(context).extension<AppTextColors>() ??
                              AppTextColors.standard)
                          .highlightText,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Some lists need new permissions',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                AddChatTextAction(
                  label: 'Re-login',
                  onTap: () => startTwitchLogin(context),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildSections(
    BuildContext context,
    TwitchChatStore store,
    String? ownId,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (store.canReadModeratedChannels) ...[
          const AddChatSectionHeader('Channels you moderate'),
          this._sectionBody(
            context,
            chipScope: 'mod',
            loading: this._loadingModerated,
            error: this._moderatedError,
            onRetry: this._loadModerated,
            refs: this._moderated,
            liveViewers: this._moderatedLiveViewers,

            /// Section header already means mod — no Mod chip here.
            showModChip: false,
            store: store,
            ownId: ownId,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (store.canReadFollows) ...[
          const AddChatSectionHeader('Channels you follow'),
          this._sectionBody(
            context,
            chipScope: 'fol',
            loading: this._loadingFollowed,
            error: this._followedError,
            onRetry: this._loadFollowed,
            refs: this._followed,
            liveViewers: this._followedLiveViewers,
            showModChip: true,
            store: store,
            ownId: ownId,
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    TwitchChatStore store,
    String? ownId,
  ) {
    if (this._searching) return const AddChatLoading(large: true);
    if (this._searchError != null) {
      return AddChatErrorRow(onRetry: () => this._search(this._lastQuery));
    }
    if (this._results.isEmpty) {
      return const AddChatHint(text: 'No channels found');
    }
    final modIds = store.moderatedChannelIds;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final result in this._results)
          AddChatChannelRow(
            chipScope: 'search',
            id: result.id,
            displayName: result.displayName,
            subtitle: _searchSubtitle(result),
            live:
                result.isLive || this._searchLiveViewers.containsKey(result.id),
            viewerCount: this._searchLiveViewers[result.id],
            mod: modIds.contains(result.id),
            added: this._isAdded(store, ownId, result.id),
            onAdd: () => this._addChannel(
              TwitchChannelRef(
                id: result.id,
                login: result.login,
                displayName: result.displayName,
                addedAt: DateTime.now(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionBody(
    BuildContext context, {
    required String chipScope,
    required bool loading,
    required Object? error,
    required VoidCallback onRetry,
    required List<TwitchChannelRef> refs,
    required Map<String, int> liveViewers,
    required bool showModChip,
    required TwitchChatStore store,
    required String? ownId,
  }) {
    if (loading) return const AddChatLoading();
    if (error != null) return AddChatErrorRow(onRetry: onRetry);
    if (refs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text('None', style: Theme.of(context).textTheme.bodySmall),
      );
    }
    final modIds = store.moderatedChannelIds;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ref in refs)
          AddChatChannelRow(
            chipScope: chipScope,
            id: ref.id,
            displayName: ref.displayName,
            subtitle: '@${ref.login}',
            live: liveViewers.containsKey(ref.id),
            viewerCount: liveViewers[ref.id],
            mod: showModChip && modIds.contains(ref.id),
            added: this._isAdded(store, ownId, ref.id),
            onAdd: () => this._addChannel(ref),
          ),
      ],
    );
  }

  /// Already-added channels — and the user's own — are checked off (the
  /// store dedupes by id, but adding yourself would duplicate the own
  /// channel in the dropdown).
  bool _isAdded(TwitchChatStore store, String? ownId, String id) =>
      !this.widget.pickOnly &&
      (id == ownId || store.channels.any((channel) => channel.id == id));
}
