import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/adaptive_switch.dart';
import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import 'native_chat_appearance.dart';

export 'native_chat_appearance.dart' show NativeChatAppearance;

/// Entry point in the native-mode chat bar: opens [NativeChatOptionsSheet].
/// Styled like the bar's other control containers, 44pt touch target.
class NativeChatOptionsButton extends StatelessWidget {
  final ChatType chatType;

  const NativeChatOptionsButton({super.key, required this.chatType});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Native chat options',
      child: Pressable(
        haptic: true,
        onTap: () => ModalHandler.showBaseBottomSheet(
          context: context,
          barrierDismissible: true,
          builder: (context) =>
              NativeChatOptionsSheet(chatType: this.chatType),
        ),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: kMinInteractiveDimensionCupertino,
            minHeight: kMinInteractiveDimensionCupertino,
          ),
          decoration: BoxDecoration(
            color:
                StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              width: 0.0,
            ),
          ),
          child: const Icon(
            CupertinoIcons.slider_horizontal_3,
            size: 18.0,
          ),
        ),
      ),
    );
  }
}

enum _OptionsPage { root, appearance, emotes, badges }

/// Options for the native chat engines. Root lists short groups; each
/// drills into a sub-page (page-swap, no nested Navigator). Twitch gets
/// Appearance + Emotes + Badges; other chat types only Appearance.
class NativeChatOptionsSheet extends StatefulWidget {
  final ChatType chatType;

  const NativeChatOptionsSheet({super.key, required this.chatType});

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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: switch (this._page) {
        _OptionsPage.root => this._buildRoot(context),
        _OptionsPage.appearance => _AppearancePage(onBack: this._back),
        _OptionsPage.emotes => _EmotesPage(onBack: this._back),
        _OptionsPage.badges => _BadgesPage(onBack: this._back),
      },
    );
  }

  Widget _buildRoot(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Native chat options',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        this._navRow(
          context,
          label: 'Appearance',
          onTap: () => this._open(_OptionsPage.appearance),
        ),
        if (this._isTwitch) ...[
          this._navRow(
            context,
            label: 'Emotes',
            onTap: () => this._open(_OptionsPage.emotes),
          ),
          this._navRow(
            context,
            label: 'Badges',
            onTap: () => this._open(_OptionsPage.badges),
          ),
        ],
      ],
    );
  }

  Widget _navRow(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return Pressable(
      haptic: true,
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        trailing: const Icon(CupertinoIcons.chevron_forward, size: 16.0),
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final List<Widget> children;

  const _PageScaffold({
    required this.title,
    required this.onBack,
    required this.children,
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
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
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
          onBack: this.onBack,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(this.label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              this.value.round().toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Slider(
          value: this.value.clamp(this.min, this.max),
          min: this.min,
          max: this.max,
          divisions: (this.max - this.min).round(),
          label: this.value.round().toString(),
          onChanged: (v) => this.onChanged(v.roundToDouble()),
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
    return _PageScaffold(
      title: 'Emotes',
      onBack: this.onBack,
      children: [
        HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: const [SettingsKeys.TwitchChatThirdPartyEmotes],
          builder: (context, settingsBox, child) => ListTile(
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
        ),
      ],
    );
  }
}

class _BadgesPage extends StatelessWidget {
  final VoidCallback onBack;

  const _BadgesPage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Badges',
      onBack: this.onBack,
      children: [
        HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: NativeChatOptionsSheet.twitchBadgeRows
              .map((row) => row.$2)
              .toList(),
          builder: (context, settingsBox, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...ListTile.divideTiles(
                context: context,
                tiles: NativeChatOptionsSheet.twitchBadgeRows.map(
                  (row) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row.$1),
                    trailing: BaseAdaptiveSwitch(
                      value:
                          settingsBox.get(row.$2.name, defaultValue: true),
                      onChanged: (value) =>
                          settingsBox.put(row.$2.name, value),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
