import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../stores/views/combined_chat.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../utils/modal_handler.dart';
import '../chat_type_brand.dart';
import '../native_chat_chrome.dart';
import '../native_combined_chat_view.dart';
import 'channel_mod_chrome.dart';
import 'channel_mod_sheet.dart';
import 'kick_channel_mod_sheet.dart';
import 'youtube_channel_mod_sheet.dart';

/// Opens the combined chat's channel mod sheet on [context].
void showCombinedChannelModSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.85,
      builder: (_) => CombinedChannelModSheet(
        onToast: (message) => showChannelModToast(context, message),
      ),
    );

/// Platforms the combined sheet offers a tab for: the active sources the
/// account may moderate — Twitch when it moderates the combo's channel
/// (known), Kick / YouTube whenever signed in with write access (the
/// platform answers a non-mod with 403, which toasts).
List<ChatType> combinedModPlatforms(CombinedChatStore combined) {
  final writable = combined.writableTargets;
  final twitch = GetIt.instance<TwitchChatStore>();
  return [
    for (final platform in writable)
      if (platform != ChatType.Twitch || twitch.canModerateSelectedChannel)
        platform,
  ];
}

/// One sheet, one tab per moderatable source — each tab is that
/// platform's own channel mod panel (the store already points at the
/// combo's channel, so its actions hit the right one). A single platform
/// hides the tab strip.
class CombinedChannelModSheet extends StatefulWidget {
  final void Function(String message) onToast;

  const CombinedChannelModSheet({super.key, required this.onToast});

  @override
  State<CombinedChannelModSheet> createState() =>
      _CombinedChannelModSheetState();
}

class _CombinedChannelModSheetState extends State<CombinedChannelModSheet> {
  ChatType? _selected;

  Widget _panel(ChatType platform) => switch (platform) {
    ChatType.Twitch => ChannelModSheet(
      key: const ValueKey('combined-mod-Twitch'),
      embedded: true,
      onFailure: this.widget.onToast,
    ),
    ChatType.YouTube => YouTubeChannelModPanel(
      key: const ValueKey('combined-mod-YouTube'),
      showTitle: false,
      onToast: this.widget.onToast,
    ),
    ChatType.Kick => KickChannelModPanel(
      key: const ValueKey('combined-mod-Kick'),
      showTitle: false,
      onToast: this.widget.onToast,
    ),
    _ => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final combined = GetIt.instance<CombinedChatStore>();
        final platforms = combinedModPlatforms(combined);
        final labels = {
          for (final source in combined.activeSources)
            source.platform: source.label,
        };
        final selected = platforms.contains(this._selected)
            ? this._selected!
            : (platforms.isEmpty ? null : platforms.first);

        return NativeChatSheetScaffold(
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Moderate', style: nativeChatSheetTitleStyle(context)),
              if (platforms.length > 1) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (final platform in platforms)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs / 2,
                          ),
                          child: _PlatformTab(
                            platform: platform,
                            label: labels[platform] ?? platform.text,
                            selected: platform == selected,
                            onTap: () =>
                                this.setState(() => this._selected = platform),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          body: selected == null
              ? const ChannelModNote(
                  'Sign in on a platform of this combined chat to moderate '
                  'it here.',
                )
              : AnimatedSwitcher(
                  duration: AppMotion.medium,
                  child: KeyedSubtree(
                    key: ValueKey(selected),
                    child: this._panel(selected),
                  ),
                ),
        );
      },
    );
  }
}

class _PlatformTab extends StatelessWidget {
  final ChatType platform;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PlatformTab({
    required this.platform,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand =
        this.platform.brandColor ?? Theme.of(context).colorScheme.secondary;
    return Pressable(
      key: Key('combined-mod-tab-${this.platform.name}'),
      haptic: true,
      onTap: this.onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        constraints: const BoxConstraints(
          minHeight: kMinInteractiveDimensionCupertino,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: brand.withValues(alpha: this.selected ? 0.18 : 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: brand.withValues(alpha: this.selected ? 0.9 : 0.25),
            width: this.selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CombinedPlatformBadge(platform: this.platform),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                this.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: this.selected ? FontWeight.w700 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
