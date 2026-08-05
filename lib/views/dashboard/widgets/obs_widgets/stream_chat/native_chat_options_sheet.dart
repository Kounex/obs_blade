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

/// Options for the native chat engines, one section per platform — today
/// only Twitch (badge visibility). Future native platforms add their
/// section to the body switch; the bar entry point stays this one.
class NativeChatOptionsSheet extends StatelessWidget {
  final ChatType chatType;

  const NativeChatOptionsSheet({super.key, required this.chatType});

  /// (label, settings key) pairs in display order
  static const List<(String, SettingsKeys)> _twitchBadgeRows = [
    ('Broadcaster', SettingsKeys.TwitchChatBadgeBroadcaster),
    ('Moderator', SettingsKeys.TwitchChatBadgeModerator),
    ('VIP', SettingsKeys.TwitchChatBadgeVip),
    ('Subscriber', SettingsKeys.TwitchChatBadgeSubscriber),
    ('Founder', SettingsKeys.TwitchChatBadgeFounder),
    ('Bits', SettingsKeys.TwitchChatBadgeBits),
    ('Other badges', SettingsKeys.TwitchChatBadgeOther),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Native chat options',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          switch (this.chatType) {
            ChatType.Twitch => const _TwitchBadgeOptions(),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

/// Twitch section of [NativeChatOptionsSheet]: the badge visibility
/// toggles, default-on, persisted straight to the Settings box (the
/// message list re-filters live via its own HiveBuilder).
class _TwitchBadgeOptions extends StatelessWidget {
  const _TwitchBadgeOptions();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Twitch — badge visibility',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: NativeChatOptionsSheet._twitchBadgeRows
              .map((row) => row.$2)
              .toList(),
          builder: (context, settingsBox, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...ListTile.divideTiles(
                context: context,
                tiles: NativeChatOptionsSheet._twitchBadgeRows.map(
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
