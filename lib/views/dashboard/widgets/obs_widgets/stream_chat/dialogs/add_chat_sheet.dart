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
import '../twitch_device_code_dialog.dart';

/// Opens the "Add chat" picker sheet (multi-chat) — the entry behind
/// `NativeChannelDropdown`'s "Add chat…" item.
void showAddChatSheet(
  BuildContext context, {
  TwitchChannelService? channelService,
}) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddChatSheet(channelService: channelService),
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

  const AddChatSheet({super.key, this.channelService});

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

  TwitchChatStore get _store => GetIt.instance<TwitchChatStore>();

  String? get _accessToken => Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name)
      .get(TwitchAuth.kBoxKey)
      ?.accessToken;

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
      final refs = await this
          ._channelService
          .getModeratedChannels(accessToken: token, userId: userId);
      if (this.mounted) {
        this.setState(() {
          this._moderated = refs;
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
      final refs = await this
          ._channelService
          .getFollowedChannels(accessToken: token, userId: userId);
      if (this.mounted) {
        this.setState(() {
          this._followed = refs;
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
      final results = await this
          ._channelService
          .searchChannels(accessToken: token, query: query);
      if (this.mounted && seq == this._searchSeq) {
        this.setState(() {
          this._results = results;
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
    unawaited(this._store.addChannel(ref));
    Navigator.of(context).pop();
  }

  static String _formatFollowers(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final store = this._store;
    final locked =
        !store.canReadModeratedChannels || !store.canReadFollows;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add chat',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: this._searchController,
            onChanged: this._onQueryChanged,
            decoration: const InputDecoration(
              hintText: 'Search channels',
              prefixIcon: Icon(CupertinoIcons.search),
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: SingleChildScrollView(
              child: Observer(
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
            ),
          ),
          if (locked) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  CupertinoIcons.lock_fill,
                  size: 14.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Some lists need new permissions',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Pressable(
                  haptic: true,
                  onTap: () => startTwitchLogin(context),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: kMinInteractiveDimensionCupertino,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Re-login',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
          this._sectionHeader(context, 'Channels you moderate'),
          this._sectionBody(
            context,
            loading: this._loadingModerated,
            error: this._moderatedError,
            onRetry: this._loadModerated,
            refs: this._moderated,
            store: store,
            ownId: ownId,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (store.canReadFollows) ...[
          this._sectionHeader(context, 'Channels you follow'),
          this._sectionBody(
            context,
            loading: this._loadingFollowed,
            error: this._followedError,
            onRetry: this._loadFollowed,
            refs: this._followed,
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
    if (this._searching) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (this._searchError != null) {
      return this._errorRow(
        context,
        onRetry: () => this._search(this._lastQuery),
      );
    }
    if (this._results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'No channels found',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final result in this._results)
          this._channelRow(
            context,
            id: result.id,
            displayName: result.displayName,
            subtitle:
                '@${result.login} · ${_formatFollowers(result.followerCount)} followers',
            live: result.isLive,
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

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      );

  Widget _sectionBody(
    BuildContext context, {
    required bool loading,
    required Object? error,
    required VoidCallback onRetry,
    required List<TwitchChannelRef> refs,
    required TwitchChatStore store,
    required String? ownId,
  }) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (error != null) return this._errorRow(context, onRetry: onRetry);
    if (refs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(
          'None',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ref in refs)
          this._channelRow(
            context,
            id: ref.id,
            displayName: ref.displayName,
            subtitle: '@${ref.login}',
            added: this._isAdded(store, ownId, ref.id),
            onAdd: () => this._addChannel(ref),
          ),
      ],
    );
  }

  Widget _errorRow(BuildContext context, {required VoidCallback onRetry}) =>
      Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 14.0,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Could not load this list',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Pressable(
            haptic: true,
            onTap: onRetry,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimensionCupertino,
              ),
              alignment: Alignment.center,
              child: Text(
                'Retry',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      );

  /// Already-added channels — and the user's own — are checked off (the
  /// store dedupes by id, but adding yourself would duplicate the own
  /// channel in the dropdown).
  bool _isAdded(TwitchChatStore store, String? ownId, String id) =>
      id == ownId ||
      store.channels.any((channel) => channel.id == id);

  Widget _channelRow(
    BuildContext context, {
    required String id,
    required String displayName,
    required String subtitle,
    required bool added,
    bool live = false,
    required VoidCallback onAdd,
  }) {
    return Pressable(
      haptic: true,
      onTap: added ? null : onAdd,
      child: Container(
        constraints:
            const BoxConstraints(minHeight: kMinInteractiveDimensionCupertino),
        alignment: Alignment.centerLeft,
        child: Opacity(
          opacity: added ? 0.5 : 1.0,
          child: Row(
            children: [
              if (live) ...[
                Container(
                  key: Key('add-chat-live-$id'),
                  width: 8.0,
                  height: 8.0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (added)
                Icon(
                  Icons.check,
                  size: 18.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
