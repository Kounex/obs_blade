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
import 'debug_chat_samples.dart';
import 'dialogs/channel_mod_sheet.dart';
import 'native_chat_appearance.dart';
import 'native_chat_chrome.dart';

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
            color:
                StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
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
                    const Icon(
                      CupertinoIcons.slider_horizontal_3,
                      size: 18.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Container(
                        width: 1.0,
                        height: 16.0,
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.shield,
                      size: 18.0,
                    ),
                  ],
                )
              : const Icon(
                  CupertinoIcons.slider_horizontal_3,
                  size: 18.0,
                ),
        ),
      ),
    );
  }
}

enum _OptionsPage { root, appearance, emotes, badges, eventMessages, debugSamples }

/// Options for the native chat engines. Root lists short groups; each
/// drills into a sub-page (page-swap, no nested Navigator). Twitch gets
/// Appearance + Emotes + Badges + Event messages; other chat types only
/// Appearance.
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

  @override
  State<NativeChatOptionsSheet> createState() => _NativeChatOptionsSheetState();
}

class _NativeChatOptionsSheetState extends State<NativeChatOptionsSheet> {
  _OptionsPage _page = _OptionsPage.root;

  bool get _isTwitch => this.widget.chatType == ChatType.Twitch;

  void _open(_OptionsPage page) => this.setState(() => this._page = page);

  void _back() => this.setState(() => this._page = _OptionsPage.root);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            nativeChatSheetDragHandle(context),
            switch (this._page) {
              _OptionsPage.root => this._buildRoot(context),
              _OptionsPage.appearance => _AppearancePage(onBack: this._back),
              _OptionsPage.emotes => _EmotesPage(onBack: this._back),
              _OptionsPage.badges => _BadgesPage(onBack: this._back),
              _OptionsPage.eventMessages =>
                _EventMessagesPage(onBack: this._back),
              _OptionsPage.debugSamples =>
                _DebugSamplesPage(onBack: this._back),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildRoot(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Native chat options',
          style: nativeChatSheetTitleStyle(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (this._isTwitch && this.widget.modFoldedIntoOptions)
          this._foldedModCard(context),
        this._navRow(
          context,
          label: 'Appearance',
          subtitle: 'Text size, emote size, spacing, and separators',
          onTap: () => this._open(_OptionsPage.appearance),
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
          if (kDebugMode &&
              GetIt.instance.isRegistered<TwitchChatStore>())
            this._navRow(
              context,
              label: 'Debug samples',
              subtitle:
                  'Inject crafted messages (GIF, power-up, shared chat)',
              onTap: () => this._open(_OptionsPage.debugSamples),
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
        final scheme = Theme.of(context).colorScheme;
        final tint = scheme.secondary.withValues(alpha: 0.14);
        final border = scheme.secondary.withValues(alpha: 0.45);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Pressable(
            haptic: true,
            onTap: () => showChannelModSheet(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.secondary.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      CupertinoIcons.shield,
                      size: 18.0,
                      color: scheme.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Channel moderation',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2.0),
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
    return Pressable(
      haptic: true,
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Pressable(
              haptic: true,
              onTap: this.onBack,
              child: const Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: Icon(CupertinoIcons.chevron_back, size: 20.0),
              ),
            ),
            Expanded(
              child: Text(
                this.title,
                style: nativeChatSheetTitleStyle(context),
              ),
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
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      'Reset',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          this.description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...this.children,
      ],
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
      ],
      builder: (context, settingsBox, child) {
        final textSize = NativeChatAppearance.textSize(settingsBox);
        final emoteSize = NativeChatAppearance.emoteSize(settingsBox);
        final spacing = NativeChatAppearance.messageSpacing(settingsBox);
        final separators = NativeChatAppearance.separators(settingsBox);
        return _PageScaffold(
          title: 'Appearance',
          description:
              'Adjust how chat lines look — size, spacing, and dividers.',
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
              onChanged: (v) => settingsBox.put(
                SettingsKeys.TwitchChatTextSize.name,
                v,
              ),
            ),
            _AppearanceSlider(
              label: 'Emote size',
              value: emoteSize,
              min: NativeChatAppearance.emoteSizeMin,
              max: NativeChatAppearance.emoteSizeMax,
              onChanged: (v) => settingsBox.put(
                SettingsKeys.TwitchChatEmoteSize.name,
                v,
              ),
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
    final statusColors = Theme.of(context).extension<AppStatusColors>() ??
        AppStatusColors.standard;
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: this.textSize,
                ),
            children: [
              TextSpan(
                text: 'Streamer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
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
                    color: statusColors.live.withValues(alpha: 0.35),
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
    final scheme = Theme.of(context).colorScheme;
    final track = scheme.onSurface.withValues(alpha: 0.22);
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
                    color: scheme.primary,
                  ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.0,
            activeTrackColor: scheme.primary,
            inactiveTrackColor: track,
            thumbColor: scheme.primary,
            overlayColor: scheme.primary.withValues(alpha: 0.12),
            valueIndicatorColor: scheme.primary,
            showValueIndicator: ShowValueIndicator.never,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8.0,
              elevation: 1.0,
            ),
            trackShape: const RoundedRectSliderTrackShape(),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
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

class _EmotesPage extends StatelessWidget {
  final VoidCallback onBack;

  const _EmotesPage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.TwitchChatThirdPartyEmotes],
      builder: (context, settingsBox, child) => _PageScaffold(
        title: 'Emotes',
        description:
            'Choose whether 7TV and BTTV emotes render inline in chat.',
        onBack: this.onBack,
        onReset: () => settingsBox.put(
          SettingsKeys.TwitchChatThirdPartyEmotes.name,
          true,
        ),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Third-party emotes (7TV/BTTV)'),
            trailing: BaseAdaptiveSwitch(
              value: settingsBox.get(
                SettingsKeys.TwitchChatThirdPartyEmotes.name,
                defaultValue: true,
              ),
              onChanged: (value) => settingsBox.put(
                SettingsKeys.TwitchChatThirdPartyEmotes.name,
                value,
              ),
            ),
          ),
        ],
      ),
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
          description:
              'Show or hide badge categories next to chatter names.',
          onBack: this.onBack,
          onReset: () => this._reset(settingsBox),
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) nativeChatHairline(context),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(rows[i].$1),
                trailing: BaseAdaptiveSwitch(
                  value: settingsBox.get(
                    rows[i].$2.name,
                    defaultValue: true,
                  ),
                  onChanged: (value) =>
                      settingsBox.put(rows[i].$2.name, value),
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

  const _EventMessagesPage({required this.onBack});

  void _reset(Box settingsBox) {
    for (final row in NativeChatOptionsSheet.twitchNoticeRows) {
      settingsBox.put(row.$2.name, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: NativeChatOptionsSheet.twitchNoticeRows
          .map((row) => row.$2)
          .toList(),
      builder: (context, settingsBox, child) {
        final rows = NativeChatOptionsSheet.twitchNoticeRows;
        return _PageScaffold(
          title: 'Event messages',
          description:
              'Choose which system chat lines appear in the feed. '
              'These are in-chat only — not device notifications.',
          onBack: this.onBack,
          onReset: () => this._reset(settingsBox),
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) nativeChatHairline(context),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(rows[i].$1),
                trailing: BaseAdaptiveSwitch(
                  value: settingsBox.get(
                    rows[i].$2.name,
                    defaultValue: true,
                  ),
                  onChanged: (value) =>
                      settingsBox.put(rows[i].$2.name, value),
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(samples[i].label),
            subtitle: Text(
              samples[i].description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () {
              GetIt.instance<TwitchChatStore>()
                  .debugInjectMessage(samples[i].event);
              Navigator.of(context).pop();
            },
          ),
        ],
      ],
    );
  }
}
