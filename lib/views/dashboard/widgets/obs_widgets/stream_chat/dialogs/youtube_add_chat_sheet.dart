import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../stores/views/youtube_chat.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/general_helper.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/youtube/youtube_channel_search_service.dart';
import '../../../../../../utils/youtube/youtube_entry_name.dart';
import '../../../../../../utils/youtube/youtube_live_chat_service.dart';
import '../../../../../../utils/youtube/youtube_live_status_service.dart';
import '../../../../../../utils/youtube_target.dart';
import 'add_chat_sheet_chrome.dart';

/// What the combined chat builder gets back from a pick-only sheet: the
/// label the entry has (or will get) in [SettingsKeys.YouTubeUsernames]
/// and its stored value. Nothing is saved by the sheet in that mode.
class YouTubeAddChatPick {
  final String label;
  final String value;

  /// The signed-in account's own channel.
  final bool own;

  const YouTubeAddChatPick({
    required this.label,
    required this.value,
    this.own = false,
  });
}

/// Opens the YouTube "Add chat" picker — the native channel menu's "Add
/// chat…" and the combined chat builder's "Other YouTube channel…"
/// ([pickOnly]). Needs an API key (the native YouTube chat does anyway);
/// callers without one keep the add dialog.
Future<YouTubeAddChatPick?> showYouTubeAddChatSheet(
  BuildContext context, {
  YouTubeChannelSearchService? searchService,
  YouTubeEntryNamer? namer,
  YouTubeLiveStatusService? liveStatusService,
  bool pickOnly = false,
}) => ModalHandler.showBaseBottomSheet<YouTubeAddChatPick>(
  context: context,
  barrierDismissible: true,
  enableDrag: true,
  maxHeightFraction: 0.72,
  builder: (context) => YouTubeAddChatSheet(
    searchService: searchService,
    namer: namer,
    liveStatusService: liveStatusService,
    pickOnly: pickOnly,
  ),
);

/// YouTube "Add chat" picker, modelled on Twitch's [AddChatSheet]:
///
/// - empty query: "Channels you subscribe to" when signed in with a
///   channel, else a hint;
/// - a link / `@handle` / `UC…` id: one row that adds exactly that (a
///   video link pins that stream, as in the add dialog);
/// - a name (3+ chars): channel search with LIVE chips. Search spends one
///   of the API key's 100 searches a day, so it waits 700 ms and answers
///   are cached; when the day's searches are used up the sheet says so and
///   offers `@<query>` as a handle.
///
/// Picks are stored by `UC…` id under the channel's title.
class YouTubeAddChatSheet extends StatefulWidget {
  /// Injectable for tests — no real HTTP in unit tests.
  final YouTubeChannelSearchService? searchService;

  /// Names a pasted link / handle (test seam).
  final YouTubeEntryNamer? namer;

  /// LIVE + viewers lookup (test seam; the shared one remembers answers)
  final YouTubeLiveStatusService? liveStatusService;

  /// Combined chat builder: the pick is the result, nothing is saved and
  /// nothing is greyed out.
  final bool pickOnly;

  const YouTubeAddChatSheet({
    super.key,
    this.searchService,
    this.namer,
    this.liveStatusService,
    this.pickOnly = false,
  });

  YouTubeLiveStatusService get liveStatus =>
      this.liveStatusService ?? YouTubeLiveStatusService.shared;

  @override
  State<YouTubeAddChatSheet> createState() => _YouTubeAddChatSheetState();
}

class _YouTubeAddChatSheetState extends State<YouTubeAddChatSheet> {
  static const Duration _kDebounce = Duration(milliseconds: 700);

  late final YouTubeChannelSearchService _searchService =
      this.widget.searchService ?? YouTubeChannelSearchService.shared;
  late final YouTubeEntryNamer _namer =
      this.widget.namer ?? YouTubeEntryNamer();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  int _searchSeq = 0;
  String _lastQuery = '';
  bool _searching = false;
  Object? _searchError;
  List<YouTubeChannelSuggestion> _results = const [];

  bool _loadingSubscriptions = false;
  Object? _subscriptionsError;
  List<YouTubeChannelSuggestion> _subscriptions = const [];

  /// Key of the row whose pick is resolving (naming a pasted link).
  String? _busyKey;

  /// LIVE + viewers per channel id, filled in as checks answer
  final Map<String, YouTubeLiveStatus> _live = {};

  /// The subscriptions' live check: (done, total) while it runs, null
  /// once done (or not started)
  (int, int)? _liveProgress;

  /// "Live now" picked: only live subscriptions, most viewers first. The
  /// list itself never reorders - a channel can't move while scrolled to.
  bool _liveOnly = false;

  /// Ask for LIVE + viewers of [channels] (quota-free page reads + one
  /// 1-unit videos.list per chunk); chips fill in as answers come in.
  Future<void> _checkLive(
    List<YouTubeChannelSuggestion> channels, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (channels.isEmpty) return;
    await this.widget.liveStatus.check(
      [for (final channel in channels) channel.channelId],
      apiKey: YouTubeLiveChatService.resolveApiKey(),
      accessToken: this._store.accessTokenForRead,
      onUpdate: (update) {
        if (this.mounted) this.setState(() => this._live.addAll(update));
      },
      onProgress: onProgress,
      cancelled: () => !this.mounted,
    );
  }

  /// Live subscriptions, most viewers on top
  List<YouTubeChannelSuggestion> get _liveSubscriptions =>
      [
        for (final channel in this._subscriptions)
          if (this._live[channel.channelId]?.live ?? false) channel,
      ]..sort(
        (a, b) => (this._live[b.channelId]?.viewers ?? -1).compareTo(
          this._live[a.channelId]?.viewers ?? -1,
        ),
      );

  YouTubeChatStore get _store => GetIt.instance<YouTubeChatStore>();

  bool get _showsSubscriptions =>
      this._store.isSignedIn && !this._store.signedInWithoutChannel;

  @override
  void initState() {
    super.initState();
    if (this._showsSubscriptions) this._loadSubscriptions();
  }

  @override
  void dispose() {
    this._debounce?.cancel();
    this._searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptions() async {
    this.setState(() {
      this._loadingSubscriptions = true;
      this._subscriptionsError = null;
    });
    try {
      final subscriptions = await this._store.loadSubscriptions(
        this._searchService,
      );
      if (this.mounted) {
        this.setState(() {
          this._subscriptions = subscriptions;
          this._liveOnly = false;
          this._liveProgress = subscriptions.isEmpty
              ? null
              : (0, subscriptions.length);
          this._loadingSubscriptions = false;
        });
        await this._checkLive(
          subscriptions,
          onProgress: (done, total) {
            if (this.mounted && identical(this._subscriptions, subscriptions)) {
              this.setState(() => this._liveProgress = (done, total));
            }
          },
        );
        if (this.mounted && identical(this._subscriptions, subscriptions)) {
          this.setState(() => this._liveProgress = null);
        }
      }
    } catch (e) {
      if (this.mounted) {
        this.setState(() {
          this._subscriptionsError = e;
          this._loadingSubscriptions = false;
        });
      }
    }
  }

  /// Links, `@handles` and `UC…` ids are taken as they are — no search.
  /// A name may contain `.` or `/` ("Mr. Beast", "AC/DC") and is searched.
  static bool _isLinkLike(String query) {
    final lower = query.toLowerCase();
    return lower.contains('://') ||
        lower.contains('youtube.com') ||
        lower.contains('youtu.be') ||
        parseYouTubeTarget(query) is YouTubeChannelTarget;
  }

  void _onQueryChanged(String query) {
    this._debounce?.cancel();
    final trimmed = query.trim();
    final searchable =
        !_isLinkLike(trimmed) &&
        trimmed.length >= YouTubeChannelSearchService.kSearchMinLength;
    this._searchSeq++;
    this.setState(() {
      this._lastQuery = trimmed;
      this._searchError = null;
      this._results = const [];
      this._searching = searchable;
    });
    if (!searchable) return;
    final cached = this._searchService.cached(trimmed);
    if (cached != null) {
      this.setState(() {
        this._results = cached;
        this._searching = false;
      });
      unawaited(this._checkLive(cached));
      return;
    }
    this._debounce = Timer(_kDebounce, () => this._search(trimmed));
  }

  Future<void> _search(String query) async {
    final seq = ++this._searchSeq;
    this.setState(() {
      this._searching = true;
      this._searchError = null;
    });
    try {
      final results = await this._searchService.searchChannels(
        query,
        apiKey: YouTubeLiveChatService.resolveApiKey(),
      );
      if (this.mounted && seq == this._searchSeq) {
        this.setState(() {
          this._results = results;
          this._searching = false;
        });
        unawaited(this._checkLive(results));
      }
    } catch (e) {
      GeneralHelper.logFailure('YouTube channel search failed', e);
      if (this.mounted && seq == this._searchSeq) {
        this.setState(() {
          this._searchError = e;
          this._searching = false;
        });
      }
    }
  }

  /// Every target key the native list already shows (own channel too).
  /// Pick mode greys nothing out, but [channels] is read either way so
  /// the Observer always tracks the list.
  Set<String> _addedKeys(List<YouTubeChatChannel> channels) {
    final keys = {for (final channel in channels) channel.target.key};
    return this.widget.pickOnly ? const {} : keys;
  }

  static YouTubeChannelTarget _targetOf(YouTubeChannelSuggestion channel) =>
      YouTubeChannelTarget('channel/${channel.channelId}');

  bool _suggestionAdded(Set<String> added, YouTubeChannelSuggestion channel) =>
      added.contains(_targetOf(channel).key) ||
      (channel.handle != null &&
          added.contains(YouTubeChannelTarget(channel.handle!).key));

  /// [aliasKeys]: the channel's other stored form when known (a search
  /// hit's handle). A pasted channel looks its other form up while it is
  /// named, so an `@handle` finds a `UC…` entry (and the own channel).
  Future<void> _pick(
    YouTubeTarget target, {
    String? name,
    String? busyKey,
    Set<String> aliasKeys = const {},
  }) async {
    if (this._busyKey != null) return;
    var label = name;
    var aliases = aliasKeys;
    if (label == null) {
      this.setState(() => this._busyKey = busyKey);
      final lookups = await Future.wait([
        this._namer.nameFor(target),
        if (target is YouTubeChannelTarget)
          this._searchService.aliasKeysFor(
            target,
            apiKey: YouTubeLiveChatService.resolveApiKey(),
          ),
      ]);
      if (!this.mounted) return;
      label = lookups.first as String;
      if (lookups.length > 1) aliases = lookups[1] as Set<String>;
    }
    final navigator = Navigator.of(this.context);
    final store = this._store;
    if (!this.widget.pickOnly) {
      unawaited(store.addChannelEntry(target, label, aliasKeys: aliases));
      navigator.pop();
      return;
    }
    final own = store.ownChannel;
    if (own != null && {target.key, ...aliases}.contains(own.target.key)) {
      navigator.pop(
        YouTubeAddChatPick(
          label: own.displayName,
          value: own.target.storageValue,
          own: true,
        ),
      );
      return;
    }
    final entries = Hive.box(
      HiveKeys.Settings.name,
    ).get(SettingsKeys.YouTubeUsernames.name, defaultValue: <String, String>{});

    /// An already listed channel comes back as that entry (its label and
    /// value), so saving the combo doesn't add a second copy.
    final pick = youTubeEntryLabelFor(
      target,
      label,
      entries is Map ? Map<String, String>.from(entries) : const {},
      aliasKeys: aliases,
    );
    navigator.pop(YouTubeAddChatPick(label: pick.label, value: pick.value));
  }

  static String _subtitle(YouTubeChannelSuggestion channel) => [
    ?channel.handle,
    if (channel.subscriberCount case final count?)
      '${formatAddChatCount(count)} subscribers',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    return AddChatSheetFrame(
      title: this.widget.pickOnly ? 'YouTube channel' : 'Add chat',
      controller: this._searchController,
      onChanged: this._onQueryChanged,
      hintText: 'Search or paste a channel / stream link',
      body: Observer(
        builder: (_) {
          final store = this._store;

          /// Read up front so the Observer always tracks something.
          final added = this._addedKeys(store.nativeChannels);
          final query = this._lastQuery;
          if (query.isEmpty) return this._buildEmpty(context, added);
          if (_isLinkLike(query)) return this._buildDirect(context, added);
          if (query.length < YouTubeChannelSearchService.kSearchMinLength) {
            return const AddChatHint(text: 'Type at least 3 characters');
          }
          return this._buildSearch(context, added);
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, Set<String> added) {
    if (!this._showsSubscriptions) {
      return const AddChatHint(
        text:
            'Search a channel by name, or paste an @handle, channel link '
            'or stream link.',
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AddChatSectionHeader('Channels you subscribe to'),
        if (!this._loadingSubscriptions)
          if (this._liveControl(context) case final control?)
            /// Progress and pills take the same height - rows don't
            /// shift when one becomes the other
            Container(
              height: _FilterPill.height,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              alignment: Alignment.centerLeft,
              child: control,
            ),
        if (this._loadingSubscriptions)
          const AddChatLoading()
        else if (this._subscriptionsError != null)
          AddChatErrorRow(onRetry: this._loadSubscriptions)
        else if (this._subscriptions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text('None', style: Theme.of(context).textTheme.bodySmall),
          )
        else
          for (final channel
              in this._liveOnly ? this._liveSubscriptions : this._subscriptions)
            this._suggestionRow(channel, added, chipScope: 'sub'),
      ],
    );
  }

  /// Under the subscriptions heading: the live check's progress while it
  /// runs, then All / Live now (n) - only when someone is live
  Widget? _liveControl(BuildContext context) {
    if (this._liveProgress case (final done, final total)) {
      return Row(
        key: const Key('add-chat-live-progress'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 7.0),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Checking who\'s live $done/$total',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }
    final live = this._liveSubscriptions.length;
    if (live == 0) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FilterPill(
          key: const Key('add-chat-filter-all'),
          label: 'All',
          selected: !this._liveOnly,
          onTap: () => this.setState(() => this._liveOnly = false),
        ),
        const SizedBox(width: AppSpacing.xs),
        _FilterPill(
          key: const Key('add-chat-filter-live'),
          label: 'Live now $live',
          selected: this._liveOnly,
          onTap: () => this.setState(() => this._liveOnly = true),
        ),
      ],
    );
  }

  Widget _buildDirect(BuildContext context, Set<String> added) {
    final target = parseYouTubeTarget(this._lastQuery);
    if (target == null) {
      return const AddChatHint(
        icon: CupertinoIcons.link,
        text: 'Not a YouTube channel or stream link',
      );
    }
    return this._targetRow(target, added);
  }

  Widget _buildSearch(BuildContext context, Set<String> added) {
    final query = this._lastQuery;
    final videoTarget = parseYouTubeTarget(query);

    /// A plain word that could be a handle — offered when search can't
    /// help (no hits, or the day's searches are used up).
    final handleTarget = parseYouTubeTarget('@$query');
    final fallback = [
      if (handleTarget is YouTubeChannelTarget)
        this._targetRow(handleTarget, added),
    ];

    final List<Widget> children;
    if (this._searching) {
      children = [const AddChatLoading(large: true)];
    } else if (this._searchError case final error?) {
      children = [
        AddChatErrorRow(
          message: _searchErrorText(error),
          onRetry: error is YouTubeQuotaExceededException
              ? null
              : () => this._search(query),
        ),
        ...fallback,
      ];
    } else if (this._results.isEmpty) {
      children = [const AddChatHint(text: 'No channels found'), ...fallback];
    } else {
      children = [
        for (final channel in this._results)
          this._suggestionRow(channel, added, chipScope: 'search'),
      ];
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...children,

        /// An 11-character word is also a valid video id.
        if (videoTarget is YouTubeVideoTarget && !this._searching) ...[
          const SizedBox(height: AppSpacing.sm),
          this._targetRow(videoTarget, added),
        ],
      ],
    );
  }

  static String _searchErrorText(Object error) => switch (error) {
    YouTubeQuotaExceededException() =>
      'The 100 searches a day of your API key are used up (back after '
          'midnight Pacific). Paste an @handle or channel link instead.',
    YouTubeForbiddenException() =>
      'YouTube refused the search - check the API key in the YouTube setup.',
    _ => 'Could not search channels',
  };

  Widget _suggestionRow(
    YouTubeChannelSuggestion channel,
    Set<String> added, {
    required String chipScope,
  }) => AddChatChannelRow(
    /// Keyed: a press stays with its channel when rows move
    key: ValueKey('add-chat-row-$chipScope-${channel.channelId}'),
    chipScope: chipScope,
    id: channel.channelId,
    displayName: channel.title,
    subtitle: _subtitle(channel),

    /// The check's answer wins; until then a search hit's own flag
    live: this._live[channel.channelId]?.live ?? channel.isLive,
    viewerCount: this._live[channel.channelId]?.viewers,
    added: this._suggestionAdded(added, channel),
    onAdd: () => this._pick(
      _targetOf(channel),
      name: channel.title,
      aliasKeys: {
        if (channel.handle case final handle?) YouTubeChannelTarget(handle).key,
      },
    ),
  );

  /// One row that adds exactly what was typed / pasted.
  Widget _targetRow(YouTubeTarget target, Set<String> added) {
    final (title, subtitle, icon) = switch (target) {
      /// A pasted `UC…` id is no name - the entry gets the channel's title
      /// when added.
      YouTubeChannelTarget(:final path) when path.startsWith('channel/') => (
        'Channel from this link',
        'Follows its current livestream',
        CupertinoIcons.person_crop_circle,
      ),
      YouTubeChannelTarget() => (
        target.displayName,
        'Follows its current livestream',
        CupertinoIcons.person_crop_circle,
      ),
      YouTubeVideoTarget(:final videoId) => (
        'Stream $videoId',
        'Pins this one stream',
        CupertinoIcons.play_rectangle,
      ),
    };
    return AddChatChannelRow(
      key: Key('youtube-add-chat-direct-${target.key}'),
      chipScope: 'direct',
      id: target.key,
      displayName: title,
      subtitle: subtitle,
      leadingIcon: icon,
      added: added.contains(target.key),
      busy: this._busyKey == target.key,
      onAdd: () => this._pick(target, busyKey: target.key),
    );
  }
}

/// All / Live now - the activity feed's filter pill
class _FilterPill extends StatelessWidget {
  static const double height = 28.0;

  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Semantics(
      button: true,
      selected: this.selected,
      label: '${this.label} filter',
      excludeSemantics: true,
      child: Pressable(
        springy: false,
        onTap: this.onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: this.selected
                ? accent
                : Theme.of(context).dividerColor.withValues(alpha: 0.12),
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            this.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: this.selected
                  ? Theme.of(context).colorScheme.onSecondary
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
