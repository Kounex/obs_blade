import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../stores/views/kick_chat.dart';
import '../../../../../../types/classes/kick/kick_channel_suggestion.dart';
import '../../../../../../utils/kick/kick_channel_service.dart';
import '../../../../../../utils/kick_channel_slug.dart';
import '../../../../../../utils/modal_handler.dart';
import 'add_chat_sheet_chrome.dart';

/// Opens the Kick "Add chat" picker — the native channel menu's "Add
/// chat…" and the combined chat builder's "Other Kick channel…"
/// ([pickOnly], the picked slug is the result).
Future<String?> showKickAddChatSheet(
  BuildContext context, {
  bool pickOnly = false,
  String? languageCode,
}) => ModalHandler.showBaseBottomSheet<String>(
  context: context,
  barrierDismissible: true,
  enableDrag: true,
  maxHeightFraction: 0.72,
  builder: (context) =>
      KickAddChatSheet(pickOnly: pickOnly, languageCode: languageCode),
);

/// Kick "Add chat" picker, modelled on Twitch's [AddChatSheet]:
///
/// - empty query: "Popular live now" in the device language when signed
///   in (the official listing needs a token; mature streams are left
///   out), else a hint;
/// - a kick.com link: one row that adds that channel;
/// - a name (3+ chars): the website's channel search (anonymous, works
///   signed out) with LIVE chips and Kick's verified seal. When search
///   fails or finds nothing, the typed slug is offered as is.
///
/// Kick has no follow or "channels I moderate" API, so there are no such
/// lists here.
class KickAddChatSheet extends StatefulWidget {
  /// Combined chat builder: the pick is the result, nothing is saved and
  /// nothing is greyed out.
  final bool pickOnly;

  /// Language of the "Popular live now" list (test seam) — defaults to
  /// the device language.
  final String? languageCode;

  const KickAddChatSheet({super.key, this.pickOnly = false, this.languageCode});

  @override
  State<KickAddChatSheet> createState() => _KickAddChatSheetState();
}

class _KickAddChatSheetState extends State<KickAddChatSheet> {
  static const Duration _kDebounce = Duration(milliseconds: 300);

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  int _searchSeq = 0;
  String _lastQuery = '';
  bool _searching = false;
  Object? _searchError;
  List<KickChannelSuggestion> _results = const [];

  bool _loadingPopular = false;
  Object? _popularError;
  List<KickChannelSuggestion> _popular = const [];

  KickChatStore get _store => GetIt.instance<KickChatStore>();

  @override
  void initState() {
    super.initState();
    if (this._store.canWrite) this._loadPopular();
  }

  @override
  void dispose() {
    this._debounce?.cancel();
    this._searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPopular() async {
    this.setState(() {
      this._loadingPopular = true;
      this._popularError = null;
    });
    try {
      final popular = await this._store.loadPopularLive(
        languageCode:
            this.widget.languageCode ??
            PlatformDispatcher.instance.locale.languageCode,
      );
      if (this.mounted) {
        this.setState(() {
          this._popular = popular;
          this._loadingPopular = false;
        });
      }
    } catch (e) {
      if (this.mounted) {
        this.setState(() {
          this._popularError = e;
          this._loadingPopular = false;
        });
      }
    }
  }

  static bool _isLink(String query) =>
      query.contains('/') || query.contains('.');

  void _onQueryChanged(String query) {
    this._debounce?.cancel();
    final trimmed = query.trim();
    final searchable =
        !_isLink(trimmed) &&
        trimmed.length >= KickChannelService.kSearchMinLength;
    this._searchSeq++;
    this.setState(() {
      this._lastQuery = trimmed;
      this._searchError = null;
      this._results = const [];
      this._searching = searchable;
    });
    if (searchable) {
      this._debounce = Timer(_kDebounce, () => this._search(trimmed));
    }
  }

  Future<void> _search(String query) async {
    final seq = ++this._searchSeq;
    this.setState(() {
      this._searching = true;
      this._searchError = null;
    });
    try {
      final results = await this._store.searchChannels(query);
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

  void _pick(String slug) {
    if (this.widget.pickOnly) {
      Navigator.of(this.context).pop(slug);
      return;
    }
    unawaited(this._store.addChannel(slug));
    Navigator.of(this.context).pop();
  }

  bool _isAdded(KickChatStore store, String slug) =>
      !this.widget.pickOnly && store.nativeChannels.contains(slug);

  static String _searchSubtitle(KickChannelSuggestion channel) => [
    if (channel.displayName.toLowerCase() != channel.slug) channel.slug,
    if (channel.followersCount case final count?)
      '${formatAddChatCount(count)} followers',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    return AddChatSheetFrame(
      title: this.widget.pickOnly ? 'Kick channel' : 'Add chat',
      controller: this._searchController,
      onChanged: this._onQueryChanged,
      hintText: 'Search or paste a kick.com link',
      body: Observer(
        builder: (_) {
          final store = this._store;

          /// Read up front so the Observer always tracks something.
          final listed = store.nativeChannels;
          final query = this._lastQuery;
          if (query.isEmpty) return this._buildEmpty(context, store);
          if (_isLink(query)) {
            final slug = extractKickChannelSlug(query);
            return slug == null
                ? const AddChatHint(
                    icon: CupertinoIcons.link,
                    text: 'Not a Kick channel link',
                  )
                : this._slugRow(store, slug);
          }
          if (query.length < KickChannelService.kSearchMinLength) {
            return const AddChatHint(text: 'Type at least 3 characters');
          }
          return this._buildSearch(context, store, listed);
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, KickChatStore store) {
    if (!store.canWrite) {
      return const AddChatHint(
        text:
            'Search a channel by name or paste a kick.com link. Signed in, '
            'popular live channels show here.',
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AddChatSectionHeader('Popular live now'),
        if (this._loadingPopular)
          const AddChatLoading()
        else if (this._popularError != null)
          AddChatErrorRow(onRetry: this._loadPopular)
        else if (this._popular.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text('None', style: Theme.of(context).textTheme.bodySmall),
          )
        else
          for (final stream in this._popular)
            AddChatChannelRow(
              chipScope: 'popular',
              id: stream.slug,
              displayName: stream.displayName,
              subtitle: stream.categoryName ?? '',
              live: true,
              viewerCount: stream.viewerCount,
              added: this._isAdded(store, stream.slug),
              onAdd: () => this._pick(stream.slug),
            ),
      ],
    );
  }

  Widget _buildSearch(
    BuildContext context,
    KickChatStore store,
    List<String> listed,
  ) {
    final typedSlug = extractKickChannelSlug(this._lastQuery);
    final fallback = [
      ?(typedSlug == null ? null : this._slugRow(store, typedSlug)),
    ];
    if (this._searching) return const AddChatLoading(large: true);
    if (this._searchError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AddChatErrorRow(
            message: 'Could not search Kick',
            onRetry: () => this._search(this._lastQuery),
          ),
          ...fallback,
        ],
      );
    }
    if (this._results.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AddChatHint(text: 'No channels found'),
          ...fallback,
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final channel in this._results)
          AddChatChannelRow(
            chipScope: 'search',
            id: channel.slug,
            displayName: channel.displayName,
            subtitle: _searchSubtitle(channel),
            live: channel.isLive,
            verified: channel.verified,
            added: this._isAdded(store, channel.slug),
            onAdd: () => this._pick(channel.slug),
          ),
      ],
    );
  }

  /// One row that adds exactly the typed / pasted slug.
  Widget _slugRow(KickChatStore store, String slug) => AddChatChannelRow(
    key: Key('kick-add-chat-direct-$slug'),
    chipScope: 'direct',
    id: slug,
    displayName: slug,
    subtitle: 'kick.com/$slug',
    leadingIcon: CupertinoIcons.link,
    added: this._isAdded(store, slug),
    onAdd: () => this._pick(slug),
  );
}
