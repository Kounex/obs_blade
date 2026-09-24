import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../models/enums/chat_type.dart';
import '../../../../../models/twitch_auth.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../shared/general/themed/cupertino_button.dart';
import '../../../../../stores/views/combined_chat.dart';
import '../../../../../stores/views/kick_chat.dart';
import '../../../../../stores/views/twitch_chat.dart';
import '../../../../../stores/views/youtube_chat.dart';
import '../../../../../types/classes/combined/combined_combo.dart';
import '../../../../../types/classes/twitch/twitch_channel_ref.dart';
import '../../../../../types/classes/twitch/twitch_channel_search_result.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/combined/combined_match_finder.dart';
import '../../../../../utils/kick_channel_slug.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/twitch/twitch_channel_service.dart';
import '../../../../../utils/youtube_target.dart';
import 'chat_type_brand.dart';
import 'native_chat_chrome.dart';
import 'native_chat_text_field.dart';

/// Opens the combined chat builder — new combo, or editing [combo].
Future<void> showCombinedChatBuilderSheet(
  BuildContext context, {
  CombinedCombo? combo,
  CombinedMatchFinder? matchFinder,
}) => ModalHandler.showBaseBottomSheet(
  context: context,
  barrierDismissible: true,
  enableDrag: true,
  maxHeightFraction: 0.9,
  builder: (_) =>
      CombinedChatBuilderSheet(combo: combo, matchFinder: matchFinder),
);

/// One platform's pick in the builder.
class _Pick {
  /// Twitch: channel ref; YouTube: label + value; Kick: slug.
  final TwitchChannelRef? twitch;
  final CombinedYouTubeSource? youTube;
  final String? kickSlug;

  /// What the row shows.
  final String label;

  /// The signed-in account's own channel.
  final bool own;

  const _Pick({
    required this.label,
    this.twitch,
    this.youTube,
    this.kickSlug,
    this.own = false,
  });
}

/// Builds or edits a combined chat: one row per platform (the account's
/// own channel, channels already on that platform's list, or another one
/// by name), same-name suggestions for the empty platforms after the
/// first pick (tap to use — never added on their own), an optional name.
/// At least two sources to save.
class CombinedChatBuilderSheet extends StatefulWidget {
  final CombinedCombo? combo;
  final CombinedMatchFinder? matchFinder;

  const CombinedChatBuilderSheet({super.key, this.combo, this.matchFinder});

  @override
  State<CombinedChatBuilderSheet> createState() =>
      _CombinedChatBuilderSheetState();
}

class _CombinedChatBuilderSheetState extends State<CombinedChatBuilderSheet> {
  static const List<ChatType> _kPlatforms = [
    ChatType.Twitch,
    ChatType.YouTube,
    ChatType.Kick,
  ];

  final Map<ChatType, _Pick> _picks = <ChatType, _Pick>{};

  /// The platform picked first — names the combo when no name is typed.
  ChatType? _primary;
  final TextEditingController _name = TextEditingController();

  /// Suggestions for the platforms without a pick.
  List<CombinedMatch> _matches = const [];
  bool _findingMatches = false;
  int _matchSeq = 0;

  late final CombinedMatchFinder _finder =
      this.widget.matchFinder ??
      CombinedMatchFinder(twitchSearch: _twitchSearch());

  TwitchChatStore get _twitch => GetIt.instance<TwitchChatStore>();
  YouTubeChatStore get _youTube => GetIt.instance<YouTubeChatStore>();
  KickChatStore get _kick => GetIt.instance<KickChatStore>();

  bool get _editing => this.widget.combo != null;

  @override
  void initState() {
    super.initState();
    final combo = this.widget.combo;
    if (combo != null) {
      this._name.text = combo.name ?? '';
      this._primary = combo.primary;
      if (combo.twitch case final ref?) {
        this._picks[ChatType.Twitch] = _Pick(
          label: ref.displayName,
          twitch: ref,
          own: ref.id == this._twitch.user?.id,
        );
      }
      if (combo.youTube case final source?) {
        this._picks[ChatType.YouTube] = _Pick(
          label: source.label,
          youTube: source,
        );
      }
      if (combo.kickSlug case final slug?) {
        this._picks[ChatType.Kick] = _Pick(
          label: slug,
          kickSlug: slug,
          own: this._kick.isOwnChannel(slug),
        );
      }
    }
  }

  @override
  void dispose() {
    this._name.dispose();
    super.dispose();
  }

  /// Twitch search with the signed-in token — null when signed out (no
  /// Twitch suggestions, no "Other…" lookup).
  static Future<List<TwitchChannelSearchResult>> Function(String)?
  _twitchSearch() {
    final token = Hive.box<TwitchAuth>(
      HiveKeys.TwitchAuth.name,
    ).get(TwitchAuth.kBoxKey)?.accessToken;
    if (token == null) return null;
    final service = TwitchChannelService();
    return (String query) =>
        service.searchChannels(accessToken: token, query: query);
  }

  void _setPick(ChatType platform, _Pick? pick) {
    setState(() {
      if (pick == null) {
        this._picks.remove(platform);
        if (this._primary == platform) {
          this._primary = this._picks.keys.firstOrNull;
        }
      } else {
        this._picks[platform] = pick;
        this._primary ??= platform;
      }
      this._matches = [
        for (final match in this._matches)
          if (!this._picks.containsKey(match.platform)) match,
      ];
    });
    if (pick != null) unawaited(this._findMatches(pick));
  }

  /// Look the picked name up on the platforms still empty.
  Future<void> _findMatches(_Pick pick) async {
    final empty = {
      for (final platform in _kPlatforms)
        if (!this._picks.containsKey(platform)) platform,
    };
    if (empty.isEmpty) return;
    final name =
        pick.twitch?.login ??
        pick.kickSlug ??
        switch (parseYouTubeTarget(pick.youTube?.value)) {
          YouTubeChannelTarget(:final displayName) => displayName,
          _ => pick.label,
        };
    final seq = ++this._matchSeq;
    setState(() => this._findingMatches = true);
    final matches = await this._finder.find(name, platforms: empty);
    if (!this.mounted || seq != this._matchSeq) return;
    setState(() {
      this._findingMatches = false;
      this._matches = [
        for (final match in matches)
          if (!this._picks.containsKey(match.platform)) match,
      ];
    });
  }

  _Pick _pickFromMatch(CombinedMatch match) => switch (match.platform) {
    ChatType.Twitch => _Pick(
      label: match.label,
      twitch: TwitchChannelRef(
        id: match.value,
        login: match.twitchLogin ?? match.label.toLowerCase(),
        displayName: match.label,
        addedAt: DateTime.now(),
      ),
    ),
    ChatType.YouTube => _Pick(
      label: match.label,
      youTube: CombinedYouTubeSource(label: match.label, value: match.value),
    ),
    _ => _Pick(label: match.value, kickSlug: match.value),
  };

  /// Choices for a platform: own channel first, then the platform's list.
  List<_Pick> _optionsFor(ChatType platform) {
    switch (platform) {
      case ChatType.Twitch:
        final user = this._twitch.user;
        return [
          if (this._twitch.isLoggedIn && user != null)
            _Pick(
              label: user.displayName ?? user.login,
              own: true,
              twitch: TwitchChannelRef(
                id: user.id,
                login: user.login,
                displayName: user.displayName ?? user.login,
                addedAt: DateTime.now(),
              ),
            ),
          for (final ref in this._twitch.channels)
            _Pick(label: ref.displayName, twitch: ref),
        ];
      case ChatType.YouTube:
        final own = this._youTube.ownChannel;
        final entries = Hive.box(
          HiveKeys.Settings.name,
        ).get(SettingsKeys.YouTubeUsernames.name);
        return [
          if (own != null)
            _Pick(
              label: own.displayName,
              own: true,
              youTube: CombinedYouTubeSource(
                label: own.displayName,
                value: own.target.storageValue,
              ),
            ),
          if (entries is Map)
            for (final entry in entries.entries)
              if (entry.key is String && entry.value is String)
                _Pick(
                  label: entry.key as String,
                  youTube: CombinedYouTubeSource(
                    label: entry.key as String,
                    value: entry.value as String,
                  ),
                ),
        ];
      case ChatType.Kick:
        return [
          for (final slug in this._kick.nativeChannels)
            _Pick(
              label: slug,
              kickSlug: slug,
              own: this._kick.isOwnChannel(slug),
            ),
        ];
      case ChatType.Owncast:
      case ChatType.Combined:
        return const [];
    }
  }

  Future<void> _pickOther(ChatType platform) async {
    final controller = TextEditingController();
    final value = await showCupertinoDialog<String>(
      context: this.context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Text('${platform.text} channel'),
        content: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Material(
            type: MaterialType.transparency,
            child: NativeChatTextField(
              controller: controller,
              hintText: switch (platform) {
                ChatType.YouTube => '@handle or channel URL',
                ChatType.Twitch => 'Twitch login',
                _ => 'Channel name or kick.com link',
              },
              onSubmitted: (text) => Navigator.of(context).pop(text),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Use'),
          ),
        ],
      ),
    );
    controller.dispose();
    final input = value?.trim();
    if (input == null || input.isEmpty || !this.mounted) return;
    switch (platform) {
      case ChatType.Kick:
        final slug = extractKickChannelSlug(input);
        if (slug == null) return this._toast('Not a Kick channel name');
        this._setPick(platform, _Pick(label: slug, kickSlug: slug));
      case ChatType.YouTube:
        final target = parseYouTubeTarget(input);
        if (target is! YouTubeChannelTarget) {
          return this._toast('Use an @handle or channel link');
        }
        this._setPick(
          platform,
          _Pick(
            label: target.displayName,
            youTube: CombinedYouTubeSource(
              label: target.displayName,
              value: target.storageValue,
            ),
          ),
        );
      case ChatType.Twitch:
        final matches = await this._finder.find(
          input,
          platforms: {ChatType.Twitch},
        );
        if (!this.mounted) return;
        if (matches.isEmpty) {
          return this._toast('No Twitch channel "$input" found');
        }
        this._setPick(platform, this._pickFromMatch(matches.first));
      case ChatType.Owncast:
      case ChatType.Combined:
        break;
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.maybeOf(this.context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final name = this._name.text.trim();
    final combo = CombinedCombo(
      id:
          this.widget.combo?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.isEmpty ? null : name,
      twitch: this._picks[ChatType.Twitch]?.twitch,
      youTube: this._picks[ChatType.YouTube]?.youTube,
      kickSlug: this._picks[ChatType.Kick]?.kickSlug,
      primary: this._primary,
    );
    await GetIt.instance<CombinedChatStore>().saveCombo(combo);
    if (this.mounted) Navigator.of(this.context).pop();
  }

  void _confirmDelete() {
    final combo = this.widget.combo;
    if (combo == null) return;
    ModalHandler.showBaseDialog(
      context: this.context,
      dialogWidget: ConfirmationDialog(
        title: 'Delete combined chat?',
        body:
            '"${combo.displayName}" is removed. Its channels stay in each '
            'platform\'s own list.',
        okText: 'Delete',
        isYesDestructive: true,
        onOk: (_) async {
          await GetIt.instance<CombinedChatStore>().deleteCombo(combo.id);
          if (this.mounted) Navigator.of(this.context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSave = this._picks.length >= 2;
    return NativeChatSheetScaffold(
      headerGap: AppSpacing.sm,
      header: Row(
        children: [
          Expanded(
            child: Text(
              this._editing ? 'Edit combined chat' : 'New combined chat',
              style: nativeChatSheetTitleStyle(context),
            ),
          ),
          ThemedCupertinoButton(
            key: const Key('combined-builder-save'),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            text: 'Save',
            onPressed: canSave ? this._save : null,
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pick one channel per platform - yours, a streamer you mod, or '
            'anyone you watch. The app can\'t tell whether channels belong '
            'to the same person, so check the suggestions before using them.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final platform in _kPlatforms)
            _PlatformRow(
              platform: platform,
              pick: this._picks[platform],
              options: this._optionsFor(platform),
              onPick: (pick) => this._setPick(platform, pick),
              onOther: () => this._pickOther(platform),
              onClear: () => this._setPick(platform, null),
            ),
          if (this._findingMatches || this._matches.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Same name on other platforms',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (this._findingMatches && this._matches.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: CupertinoActivityIndicator(),
              ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final match in this._matches)
                  _SuggestionChip(
                    match: match,
                    onTap: () => this._setPick(
                      match.platform,
                      this._pickFromMatch(match),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          NativeChatTextField(
            controller: this._name,
            hintText: switch (this._primary) {
              final primary? when this._picks[primary] != null =>
                'Name (optional) - "${this._picks[primary]!.label}"',
              _ => 'Name (optional)',
            },
          ),
          if (!canSave) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pick at least two channels to save.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (this._editing) ...[
            const SizedBox(height: AppSpacing.lg),
            ThemedCupertinoButton(
              isDestructive: true,
              text: 'Delete combined chat',
              onPressed: this._confirmDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  final ChatType platform;
  final _Pick? pick;
  final List<_Pick> options;
  final ValueChanged<_Pick> onPick;
  final VoidCallback onOther;
  final VoidCallback onClear;

  const _PlatformRow({
    required this.platform,
    required this.pick,
    required this.options,
    required this.onPick,
    required this.onOther,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final pick = this.pick;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(this.platform.icon, color: this.platform.brandColor, size: 20.0),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PopupMenuButton<Object>(
              key: Key('combined-builder-${this.platform.name}'),
              tooltip: 'Pick a ${this.platform.text} channel',
              onSelected: (value) =>
                  value is _Pick ? this.onPick(value) : this.onOther(),
              itemBuilder: (_) => [
                for (final option in this.options)
                  PopupMenuItem<Object>(
                    value: option,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            option.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (option.own) ...[
                          const SizedBox(width: AppSpacing.xs),
                          NativeChatYouChip(
                            color:
                                this.platform.brandColor ??
                                Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                PopupMenuItem<Object>(
                  value: 'other',
                  child: Text('Other ${this.platform.text} channel…'),
                ),
              ],
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: kMinInteractiveDimensionCupertino,
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        pick?.label ?? 'No ${this.platform.text} channel',
                        overflow: TextOverflow.ellipsis,
                        style: pick == null
                            ? Theme.of(context).textTheme.bodySmall
                            : null,
                      ),
                    ),
                    if (pick?.own ?? false) ...[
                      const SizedBox(width: AppSpacing.xs),
                      NativeChatYouChip(
                        color:
                            this.platform.brandColor ??
                            Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(CupertinoIcons.chevron_down, size: 14.0),
                  ],
                ),
              ),
            ),
          ),
          if (pick != null)
            ThemedCupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              onPressed: this.onClear,
              child: const Icon(CupertinoIcons.xmark_circle_fill, size: 18.0),
            ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final CombinedMatch match;
  final VoidCallback onTap;

  const _SuggestionChip({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brand =
        this.match.platform.brandColor ??
        Theme.of(context).colorScheme.secondary;
    return Pressable(
      haptic: true,
      onTap: this.onTap,
      child: Container(
        key: Key('combined-suggestion-${this.match.platform.name}'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: brand.withValues(alpha: 0.12),
          borderRadius: AppRadius.pill,
          border: Border.all(color: brand.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(this.match.platform.icon, size: 14.0, color: brand),
            const SizedBox(width: AppSpacing.xs),
            Text('Use ${this.match.label}'),
            const SizedBox(width: AppSpacing.xs),
            const Icon(CupertinoIcons.add, size: 14.0),
          ],
        ),
      ),
    );
  }
}
