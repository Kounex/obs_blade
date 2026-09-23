import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/adaptive_switch.dart';
import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import 'chat_search_sheet.dart';
import 'debug_chat_samples.dart';
import 'dialogs/channel_mod_sheet.dart';
import 'native_chat_appearance.dart';
import 'native_chat_chrome.dart';
import 'native_chat_text_field.dart';

export 'native_chat_appearance.dart' show NativeChatAppearance;

/// Entry point in the native-mode chat bar: opens [NativeChatOptionsSheet].
/// Styled like the bar's other control containers, 44pt touch target.
///
/// When [modFoldedIntoOptions] is true (shield did not fit on the bar),
/// renders a wider gear + shield chip and the sheet shows the featured
/// Mod card.
class NativeChatOptionsButton extends StatelessWidget {
  final ChatType chatType;

  /// Mod shield is hidden for space — this control carries options + mod.
  final bool modFoldedIntoOptions;

  const NativeChatOptionsButton({
    super.key,
    required this.chatType,
    this.modFoldedIntoOptions = false,
  });

  @override
  Widget build(BuildContext context) {
    final folded = this.modFoldedIntoOptions;
    return Tooltip(
      message: folded ? 'Chat options & moderation' : 'Native chat options',
      child: Pressable(
        haptic: true,
        onTap: () => ModalHandler.showBaseBottomSheet(
          context: context,
          barrierDismissible: true,
          enableDrag: true,
          maxHeightFraction: 0.72,
          builder: (context) => NativeChatOptionsSheet(
            chatType: this.chatType,
            modFoldedIntoOptions: folded,
          ),
        ),
        child: Container(
          constraints: BoxConstraints(
            minWidth: folded
                ? kMinInteractiveDimensionCupertino + 28.0
                : kMinInteractiveDimensionCupertino,
            minHeight: kMinInteractiveDimensionCupertino,
          ),
          padding: folded
              ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: StylingHelper.lightenDarkenColor(
              Theme.of(context).cardColor,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              width: 0.0,
            ),
          ),
          child: folded
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.slider_horizontal_3, size: 18.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Container(
                        width: 1.0,
                        height: 16.0,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.55),
                      ),
                    ),
                    const Icon(CupertinoIcons.shield, size: 18.0),
                  ],
                )
              : const Icon(CupertinoIcons.slider_horizontal_3, size: 18.0),
        ),
      ),
    );
  }
}

enum _OptionsPage {
  root,
  appearance,
  emotes,
  badges,
  history,
  eventMessages,
  highlights,
  muteWords,
  debugSamples,
}

/// Options for the native chat engines. Root lists short groups; each
/// drills into a sub-page (page-swap, no nested Navigator) — except
/// "Search chat", which closes this sheet and opens the dedicated
/// [ChatSearchSheet] instead (an action, not a settings page). Appearance
/// + Highlights (self-mention/keyword row wash) + Mute words (drops
/// matching rows entirely) + Search chat are common to every engine;
/// Twitch additionally gets Emotes + per-category Badges + Event
/// messages; Kick additionally gets Emotes + a single-toggle Badges page
/// (`badge_type` values are unverified free-strings, so there is no
/// stable catalog to build per-category rows from) + Event messages.
class NativeChatOptionsSheet extends StatefulWidget {
  final ChatType chatType;

  /// When true, show the featured Mod card (shield folded into Options).
  /// When false, Moderation is not listed — the bar shield is the entry.
  final bool modFoldedIntoOptions;

  const NativeChatOptionsSheet({
    super.key,
    required this.chatType,
    this.modFoldedIntoOptions = false,
  });

  /// (label, settings key) pairs in display order
  static const List<(String, SettingsKeys)> twitchBadgeRows = [
    ('Broadcaster', SettingsKeys.TwitchChatBadgeBroadcaster),
    ('Moderator', SettingsKeys.TwitchChatBadgeModerator),
    ('VIP', SettingsKeys.TwitchChatBadgeVip),
    ('Subscriber', SettingsKeys.TwitchChatBadgeSubscriber),
    ('Founder', SettingsKeys.TwitchChatBadgeFounder),
    ('Bits', SettingsKeys.TwitchChatBadgeBits),
    ('Other badges', SettingsKeys.TwitchChatBadgeOther),
  ];

  /// In-chat system-line category toggles (+ first-message chrome).
  static const List<(String, SettingsKeys)> twitchNoticeRows = [
    ('Subs & gifts', SettingsKeys.TwitchChatNoticeSubs),
    ('Watch streaks', SettingsKeys.TwitchChatNoticeStreaks),
    ('Raids', SettingsKeys.TwitchChatNoticeRaids),
    ('Announcements', SettingsKeys.TwitchChatNoticeAnnouncements),
    ('Bits badge', SettingsKeys.TwitchChatNoticeBitsBadge),
    ('Charity', SettingsKeys.TwitchChatNoticeCharity),
    ('Modiversary', SettingsKeys.TwitchChatNoticeModiversary),
    ('Other events', SettingsKeys.TwitchChatNoticeOther),
    ('First message', SettingsKeys.TwitchChatNoticeFirstMessage),
  ];

  /// In-chat system-line category toggles for the smaller Kick notice
  /// surface (no streaks/raids/announcements/bits/charity — Kick's
  /// Pusher catalog has no such events; `/clear` is not listed here,
  /// same as Twitch).
  static const List<(String, SettingsKeys)> kickNoticeRows = [
    ('Subs & gifts', SettingsKeys.KickChatNoticeSubs),
    ('Hosts', SettingsKeys.KickChatNoticeHosts),
  ];

  @override
  State<NativeChatOptionsSheet> createState() => _NativeChatOptionsSheetState();
}

class _NativeChatOptionsSheetState extends State<NativeChatOptionsSheet> {
  _OptionsPage _page = _OptionsPage.root;

  bool get _isTwitch => this.widget.chatType == ChatType.Twitch;

  bool get _isKick => this.widget.chatType == ChatType.Kick;

  void _open(_OptionsPage page) => this.setState(() => this._page = page);

  void _back() => this.setState(() => this._page = _OptionsPage.root);

  /// Every page renders through [NativeChatSheetScaffold]: handle +
  /// title / back chevron stay pinned, only the page body scrolls.
  @override
  Widget build(BuildContext context) {
    return switch (this._page) {
      _OptionsPage.root => this._buildRoot(context),
      _OptionsPage.appearance => _AppearancePage(onBack: this._back),
      _OptionsPage.emotes => _SingleTogglePage(
        onBack: this._back,
        title: 'Emotes',
        settingsKey: this._isKick
            ? SettingsKeys.KickChatThirdPartyEmotes
            : SettingsKeys.TwitchChatThirdPartyEmotes,
        rowLabel: this._isKick
            ? 'Third-party emotes (7TV)'
            : 'Third-party emotes (7TV/BTTV/FFZ)',
        description: this._isKick
            ? 'Choose whether 7TV emotes render inline in chat.'
            : 'Choose whether 7TV, BTTV and FFZ emotes render inline in '
                  'chat.',
      ),
      _OptionsPage.badges =>
        this._isKick
            ? _SingleTogglePage(
                onBack: this._back,
                title: 'Badges',
                settingsKey: SettingsKeys.KickChatBadges,
                rowLabel: 'Role badge artwork',
                description:
                    'Choose whether role badges (moderator, '
                    'subscriber, and similar) appear next to names.',
              )
            : _BadgesPage(onBack: this._back),
      _OptionsPage.history => _SingleTogglePage(
        onBack: this._back,
        title: 'Chat history',
        settingsKey: SettingsKeys.TwitchChatLoadHistory,
        rowLabel: 'Load recent messages on join',
        description:
            'Show the last messages sent before you joined a '
            'channel (dimmed), from the community '
            'recent-messages service Chatterino uses.',
      ),
      _OptionsPage.eventMessages => _EventMessagesPage(
        onBack: this._back,
        rows: this._isKick
            ? NativeChatOptionsSheet.kickNoticeRows
            : NativeChatOptionsSheet.twitchNoticeRows,
      ),
      _OptionsPage.highlights => _HighlightsPage(onBack: this._back),
      _OptionsPage.muteWords => _MuteWordsPage(onBack: this._back),
      _OptionsPage.debugSamples => _DebugSamplesPage(onBack: this._back),
    };
  }

  Widget _buildRoot(BuildContext context) {
    return NativeChatSheetScaffold(
      header: Text(
        'Native chat options',
        style: nativeChatSheetTitleStyle(context),
      ),
      body: this._buildRootBody(context),
    );
  }

  Widget _buildRootBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (this._isTwitch && this.widget.modFoldedIntoOptions)
          this._foldedModCard(context),
        this._navRow(
          context,
          label: 'Appearance',
          subtitle: 'Text size, emote size, spacing, and separators',
          onTap: () => this._open(_OptionsPage.appearance),
        ),
        this._navRow(
          context,
          label: 'Highlights',
          subtitle: 'Highlight your name, keywords and users',
          onTap: () => this._open(_OptionsPage.highlights),
        ),
        this._navRow(
          context,
          label: 'Mute words',
          subtitle: 'Hide or censor words, ignore users',
          onTap: () => this._open(_OptionsPage.muteWords),
        ),
        this._navRow(
          context,
          label: 'Search chat',
          subtitle: 'Find messages or names in the buffered history',
          onTap: () {
            Navigator.of(context).pop();
            showChatSearchSheet(context, chatType: this.widget.chatType);
          },
        ),
        if (this._isTwitch) ...[
          this._navRow(
            context,
            label: 'Emotes',
            subtitle: 'Third-party emotes in chat',
            onTap: () => this._open(_OptionsPage.emotes),
          ),
          this._navRow(
            context,
            label: 'Badges',
            subtitle: 'Which role badges appear next to names',
            onTap: () => this._open(_OptionsPage.badges),
          ),
          this._navRow(
            context,
            label: 'Event messages',
            subtitle: 'Subs, raids, streaks, and similar system lines',
            onTap: () => this._open(_OptionsPage.eventMessages),
          ),
          this._navRow(
            context,
            label: 'Chat history',
            subtitle: 'Recent messages from before you joined',
            onTap: () => this._open(_OptionsPage.history),
          ),
          if (kDebugMode && GetIt.instance.isRegistered<TwitchChatStore>())
            this._navRow(
              context,
              label: 'Debug samples',
              subtitle: 'Inject crafted messages (GIF, power-up, shared chat)',
              onTap: () => this._open(_OptionsPage.debugSamples),
            ),
        ],
        if (this._isKick) ...[
          this._navRow(
            context,
            label: 'Emotes',
            subtitle: 'Third-party (7TV) emotes in chat',
            onTap: () => this._open(_OptionsPage.emotes),
          ),
          this._navRow(
            context,
            label: 'Badges',
            subtitle: 'Role badge artwork next to names',
            onTap: () => this._open(_OptionsPage.badges),
          ),
          this._navRow(
            context,
            label: 'Event messages',
            subtitle: 'Subs, gifts, and host notices',
            onTap: () => this._open(_OptionsPage.eventMessages),
          ),
        ],
      ],
    );
  }

  /// Featured Mod entry when the bar shield is folded into Options.
  Widget _foldedModCard(BuildContext context) {
    if (!GetIt.instance.isRegistered<TwitchChatStore>()) {
      return const SizedBox.shrink();
    }
    return Observer(
      builder: (_) {
        final store = GetIt.instance<TwitchChatStore>();
        store.authState;
        store.selectedChannelId;
        store.moderatedChannelIds.length;
        if (!store.canModerateSelectedChannel) {
          return const SizedBox.shrink();
        }
        final textColors =
            Theme.of(context).extension<AppTextColors>() ??
            AppTextColors.standard;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Pressable(
            haptic: true,
            onTap: () => showChannelModSheet(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: StylingHelper.lightenDarkenColor(
                  Theme.of(context).cardColor,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  width: 0.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      CupertinoIcons.shield,
                      size: 18.0,
                      color: textColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Channel moderation',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Clear · modes · Shield · announce',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16.0,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _navRow(
    BuildContext context, {
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return PressFlash(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(CupertinoIcons.chevron_forward, size: 16.0),
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onBack;
  final List<Widget> children;
  final VoidCallback? onReset;

  const _PageScaffold({
    required this.title,
    required this.description,
    required this.onBack,
    required this.children,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final textColors =
        Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard;
    return NativeChatSheetScaffold(
      headerGap: 0.0,
      header: Row(
        children: [
          Pressable(
            haptic: true,
            onTap: this.onBack,
            child: Padding(
              padding: const EdgeInsets.only(
                right: AppSpacing.sm,
                top: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: Icon(
                CupertinoIcons.chevron_back,
                size: 20.0,
                color: textColors.highlightText,
              ),
            ),
          ),
          Expanded(
            child: Text(this.title, style: nativeChatSheetTitleStyle(context)),
          ),
          if (this.onReset != null)
            Tooltip(
              message: 'Reset to defaults',
              child: Pressable(
                haptic: true,
                onTap: this.onReset,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.md,
                  ),
                  child: Text(
                    'Reset',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: textColors.highlightText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xs),
          Text(this.description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          ...this.children,
        ],
      ),
    );
  }
}

class _AppearancePage extends StatelessWidget {
  final VoidCallback onBack;

  const _AppearancePage({required this.onBack});

  void _reset(Box settingsBox) {
    settingsBox.put(
      SettingsKeys.TwitchChatTextSize.name,
      NativeChatAppearance.textSizeDefault,
    );
    settingsBox.put(
      SettingsKeys.TwitchChatEmoteSize.name,
      NativeChatAppearance.emoteSizeDefault,
    );
    settingsBox.put(
      SettingsKeys.TwitchChatMessageSpacing.name,
      NativeChatAppearance.messageSpacingDefault,
    );
    settingsBox.put(
      SettingsKeys.TwitchChatMessageSeparators.name,
      NativeChatAppearance.separatorsDefault,
    );
    settingsBox.put(
      SettingsKeys.ChatShowTimestamps.name,
      NativeChatAppearance.timestampsDefault,
    );
    settingsBox.put(
      SettingsKeys.ChatAlternateRows.name,
      NativeChatAppearance.alternateRowsDefault,
    );
    settingsBox.put(
      SettingsKeys.ChatReadableNameColors.name,
      NativeChatAppearance.readableNamesDefault,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.TwitchChatTextSize,
        SettingsKeys.TwitchChatEmoteSize,
        SettingsKeys.TwitchChatMessageSpacing,
        SettingsKeys.TwitchChatMessageSeparators,
        SettingsKeys.ChatShowTimestamps,
        SettingsKeys.ChatAlternateRows,
        SettingsKeys.ChatReadableNameColors,
      ],
      builder: (context, settingsBox, child) {
        final textSize = NativeChatAppearance.textSize(settingsBox);
        final emoteSize = NativeChatAppearance.emoteSize(settingsBox);
        final spacing = NativeChatAppearance.messageSpacing(settingsBox);
        final separators = NativeChatAppearance.separators(settingsBox);
        return _PageScaffold(
          title: 'Appearance',
          description:
              'Adjust how chat lines look - size, spacing, dividers, '
              'timestamps, and name colors.',
          onBack: this.onBack,
          onReset: () => this._reset(settingsBox),
          children: [
            _AppearancePreview(
              textSize: textSize,
              emoteSize: emoteSize,
              spacing: spacing,
            ),
            const SizedBox(height: AppSpacing.md),
            _AppearanceSlider(
              label: 'Text size',
              value: textSize,
              min: NativeChatAppearance.textSizeMin,
              max: NativeChatAppearance.textSizeMax,
              onChanged: (v) =>
                  settingsBox.put(SettingsKeys.TwitchChatTextSize.name, v),
            ),
            _AppearanceSlider(
              label: 'Emote size',
              value: emoteSize,
              min: NativeChatAppearance.emoteSizeMin,
              max: NativeChatAppearance.emoteSizeMax,
              onChanged: (v) =>
                  settingsBox.put(SettingsKeys.TwitchChatEmoteSize.name, v),
            ),
            _AppearanceSlider(
              label: 'Message spacing',
              value: spacing,
              min: NativeChatAppearance.messageSpacingMin,
              max: NativeChatAppearance.messageSpacingMax,
              onChanged: (v) => settingsBox.put(
                SettingsKeys.TwitchChatMessageSpacing.name,
                v,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Separators'),
              subtitle: const Text('Thin line between messages'),
              trailing: BaseAdaptiveSwitch(
                value: separators,
                onChanged: (value) => settingsBox.put(
                  SettingsKeys.TwitchChatMessageSeparators.name,
                  value,
                ),
              ),
            ),
            for (final (key, title, subtitle, fallback) in [
              (
                SettingsKeys.ChatAlternateRows,
                'Alternating rows',
                'Tint every other message',
                NativeChatAppearance.alternateRowsDefault,
              ),
              (
                SettingsKeys.ChatShowTimestamps,
                'Timestamps',
                'Show the time before each message',
                NativeChatAppearance.timestampsDefault,
              ),
              (
                SettingsKeys.ChatReadableNameColors,
                'Readable name colors',
                'Lighten or darken names that blend into the background',
                NativeChatAppearance.readableNamesDefault,
              ),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: BaseAdaptiveSwitch(
                  value:
                      settingsBox.get(key.name, defaultValue: fallback) == true,
                  onChanged: (value) => settingsBox.put(key.name, value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AppearancePreview extends StatelessWidget {
  final double textSize;
  final double emoteSize;
  final double spacing;

  const _AppearancePreview({
    required this.textSize,
    required this.emoteSize,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final textColors =
        Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard;
    return Container(
      key: const Key('appearance-preview'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: this.spacing),
      decoration: BoxDecoration(
        color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 0.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text.rich(
          TextSpan(
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: this.textSize),
            children: [
              TextSpan(
                text: 'Streamer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textColors.highlightText,
                ),
              ),
              const TextSpan(text: ': Nice stream '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  key: const Key('appearance-preview-emote'),
                  width: this.emoteSize,
                  height: this.emoteSize,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppearanceSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _AppearanceSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColors =
        Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                this.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              this.value.round().toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColors.highlightText,
              ),
            ),
          ],
        ),

        /// The global slider grammar (neutral knob, 55% highlight track)
        /// comes from the theme — only the slimmer track and the
        /// suppressed value bubble are local.
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.0,
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: this.value.clamp(this.min, this.max),
            min: this.min,
            max: this.max,
            divisions: (this.max - this.min).round(),
            onChanged: (v) => this.onChanged(v.roundToDouble()),
          ),
        ),
      ],
    );
  }
}

/// A single boolean-toggle settings page — used for both engines' Emotes
/// page and Kick's Badges page (a single master toggle, unlike Twitch's
/// per-category `_BadgesPage`).
class _SingleTogglePage extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final SettingsKeys settingsKey;
  final String rowLabel;
  final String description;

  const _SingleTogglePage({
    required this.onBack,
    required this.title,
    required this.settingsKey,
    required this.rowLabel,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: [this.settingsKey],
      builder: (context, settingsBox, child) => _PageScaffold(
        title: this.title,
        description: this.description,
        onBack: this.onBack,
        onReset: () => settingsBox.put(this.settingsKey.name, true),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(this.rowLabel),
            trailing: BaseAdaptiveSwitch(
              value: settingsBox.get(this.settingsKey.name, defaultValue: true),
              onChanged: (value) =>
                  settingsBox.put(this.settingsKey.name, value),
            ),
          ),
        ],
      ),
    );
  }
}

/// Self-mention / keyword row highlighting — a self-mention toggle plus a
/// free-text keyword list, shared by every native engine (not per-engine:
/// the settings keys and the matching rule are the same everywhere). The
/// keyword field's [TextEditingController] is a stable instance field
/// (not rebuilt from the settings box on every keystroke) so typing
/// doesn't fight the [HiveBuilder] rebuild its own writes trigger.
class _HighlightsPage extends StatefulWidget {
  final VoidCallback onBack;

  const _HighlightsPage({required this.onBack});

  @override
  State<_HighlightsPage> createState() => _HighlightsPageState();
}

class _HighlightsPageState extends State<_HighlightsPage> {
  late final TextEditingController _keywordsController = TextEditingController(
    text: _settingText(SettingsKeys.ChatHighlightKeywords),
  );
  late final TextEditingController _usersController = TextEditingController(
    text: _settingText(SettingsKeys.ChatHighlightUsers),
  );

  @override
  void dispose() {
    this._keywordsController.dispose();
    this._usersController.dispose();
    super.dispose();
  }

  void _reset(Box settingsBox) {
    settingsBox.put(SettingsKeys.ChatHighlightSelfMention.name, true);
    settingsBox.put(SettingsKeys.ChatHighlightKeywords.name, '');
    settingsBox.put(SettingsKeys.ChatHighlightUsers.name, '');
    this._keywordsController.text = '';
    this._usersController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.ChatHighlightSelfMention,
        SettingsKeys.ChatHighlightKeywords,
        SettingsKeys.ChatHighlightUsers,
      ],
      builder: (context, settingsBox, child) {
        final selfMention = settingsBox.get(
          SettingsKeys.ChatHighlightSelfMention.name,
          defaultValue: true,
        );
        return _PageScaffold(
          title: 'Highlights',
          description:
              'Wash a message row when it mentions your name, a keyword '
              'you\'re watching for, or comes from a highlighted user.',
          onBack: this.widget.onBack,
          onReset: () => this._reset(settingsBox),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Highlight my name'),
              subtitle: const Text(
                'Matches your username anywhere in a message',
              ),
              trailing: BaseAdaptiveSwitch(
                value: selfMention,
                onChanged: (value) => settingsBox.put(
                  SettingsKeys.ChatHighlightSelfMention.name,
                  value,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Keywords', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            NativeChatTextField(
              key: const Key('chat-highlight-keywords-field'),
              controller: this._keywordsController,
              hintText: 'One per line, or comma-separated',
              minLines: 2,
              maxLines: 4,
              onChanged: (value) => settingsBox.put(
                SettingsKeys.ChatHighlightKeywords.name,
                value,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Wrap an entry in slashes for a regex, e.g. /^!drop/',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Users', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            NativeChatTextField(
              key: const Key('chat-highlight-users-field'),
              controller: this._usersController,
              hintText: 'Usernames, one per line (or long-press a message)',
              minLines: 2,
              maxLines: 4,
              onChanged: (value) =>
                  settingsBox.put(SettingsKeys.ChatHighlightUsers.name, value),
            ),
          ],
        );
      },
    );
  }
}

/// Mute-word filtering — a free-text word list, shared by every native
/// engine. Unlike [_HighlightsPage] (which washes a matching row), a
/// match here drops the row from the timeline entirely — filtered at the
/// message-list level in each `native_*_chat_view.dart`, not per-row.
class _MuteWordsPage extends StatefulWidget {
  final VoidCallback onBack;

  const _MuteWordsPage({required this.onBack});

  @override
  State<_MuteWordsPage> createState() => _MuteWordsPageState();
}

class _MuteWordsPageState extends State<_MuteWordsPage> {
  late final TextEditingController _wordsController;
  late final TextEditingController _usersController = TextEditingController(
    text: _settingText(SettingsKeys.ChatIgnoredUsers),
  );

  @override
  void initState() {
    super.initState();
    var initial = '';
    if (Hive.isBoxOpen(HiveKeys.Settings.name)) {
      final value = Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.ChatMuteWords.name);
      if (value is String) initial = value;
    }
    this._wordsController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    this._wordsController.dispose();
    this._usersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.ChatMuteWords,
        SettingsKeys.ChatMuteReplace,
        SettingsKeys.ChatIgnoredUsers,
      ],
      builder: (context, settingsBox, child) {
        final replace =
            settingsBox.get(
              SettingsKeys.ChatMuteReplace.name,
              defaultValue: false,
            ) ==
            true;
        return _PageScaffold(
          title: 'Mute words',
          description: replace
              ? 'Matching words are replaced with *** - the rest of the '
                    'message stays visible.'
              : 'Messages containing any of these words are hidden from '
                    'the timeline entirely.',
          onBack: this.widget.onBack,
          onReset: () {
            settingsBox.put(SettingsKeys.ChatMuteWords.name, '');
            settingsBox.put(SettingsKeys.ChatMuteReplace.name, false);
            settingsBox.put(SettingsKeys.ChatIgnoredUsers.name, '');
            this._wordsController.text = '';
            this._usersController.text = '';
          },
          children: [
            NativeChatTextField(
              key: const Key('chat-mute-words-field'),
              controller: this._wordsController,
              hintText: 'One per line, or comma-separated',
              minLines: 2,
              maxLines: 4,
              onChanged: (value) =>
                  settingsBox.put(SettingsKeys.ChatMuteWords.name, value),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Wrap an entry in slashes for a regex, e.g. /spoil(er|s)/',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Replace instead of hide'),
              subtitle: const Text('Show the message with the words as ***'),
              trailing: BaseAdaptiveSwitch(
                value: replace,
                onChanged: (value) =>
                    settingsBox.put(SettingsKeys.ChatMuteReplace.name, value),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ignored users',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            NativeChatTextField(
              key: const Key('chat-ignored-users-field'),
              controller: this._usersController,
              hintText: 'Usernames, one per line (or long-press a message)',
              minLines: 2,
              maxLines: 4,
              onChanged: (value) =>
                  settingsBox.put(SettingsKeys.ChatIgnoredUsers.name, value),
            ),
          ],
        );
      },
    );
  }
}

class _BadgesPage extends StatelessWidget {
  final VoidCallback onBack;

  const _BadgesPage({required this.onBack});

  void _reset(Box settingsBox) {
    for (final row in NativeChatOptionsSheet.twitchBadgeRows) {
      settingsBox.put(row.$2.name, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: NativeChatOptionsSheet.twitchBadgeRows
          .map((row) => row.$2)
          .toList(),
      builder: (context, settingsBox, child) {
        final rows = NativeChatOptionsSheet.twitchBadgeRows;
        return _PageScaffold(
          title: 'Badges',
          description: 'Show or hide badge categories next to chatter names.',
          onBack: this.onBack,
          onReset: () => this._reset(settingsBox),
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) nativeChatHairline(context),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(rows[i].$1),
                trailing: BaseAdaptiveSwitch(
                  value: settingsBox.get(rows[i].$2.name, defaultValue: true),
                  onChanged: (value) => settingsBox.put(rows[i].$2.name, value),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EventMessagesPage extends StatelessWidget {
  final VoidCallback onBack;
  final List<(String, SettingsKeys)> rows;

  const _EventMessagesPage({required this.onBack, required this.rows});

  void _reset(Box settingsBox) {
    for (final row in this.rows) {
      settingsBox.put(row.$2.name, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: this.rows.map((row) => row.$2).toList(),
      builder: (context, settingsBox, child) {
        final rows = this.rows;
        return _PageScaffold(
          title: 'Event messages',
          description:
              'Choose which system chat lines appear in the feed. '
              'These are in-chat only - not device notifications.',
          onBack: this.onBack,
          onReset: () => this._reset(settingsBox),
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) nativeChatHairline(context),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(rows[i].$1),
                trailing: BaseAdaptiveSwitch(
                  value: settingsBox.get(rows[i].$2.name, defaultValue: true),
                  onChanged: (value) => settingsBox.put(rows[i].$2.name, value),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Debug/dogfood only (`kDebugMode`): inject crafted sample events into
/// the live chat buffer — see `debug_chat_samples.dart`. Closes the sheet
/// after an injection so the result is immediately visible in chat.
class _DebugSamplesPage extends StatelessWidget {
  final VoidCallback onBack;

  const _DebugSamplesPage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final samples = debugChatSamples();
    return _PageScaffold(
      title: 'Debug samples',
      description:
          'Append a crafted message to the current chat to check rendering '
          'paths that are hard to trigger on demand.',
      onBack: this.onBack,
      children: [
        for (var i = 0; i < samples.length; i++) ...[
          if (i > 0) nativeChatHairline(context),
          PressFlash(
            onTap: () {
              GetIt.instance<TwitchChatStore>().debugInjectMessage(
                samples[i].event,
              );
              Navigator.of(context).pop();
            },
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(samples[i].label),
              subtitle: Text(
                samples[i].description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Current raw text of a free-text settings list (empty when unset or the
/// box isn't open, e.g. isolated widget tests).
String _settingText(SettingsKeys key) {
  if (!Hive.isBoxOpen(HiveKeys.Settings.name)) return '';
  final value = Hive.box(HiveKeys.Settings.name).get(key.name);
  return value is String ? value : '';
}
