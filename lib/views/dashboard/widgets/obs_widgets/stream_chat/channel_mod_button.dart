import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../utils/styling_helper.dart';
import 'dialogs/channel_mod_sheet.dart';

/// Native-mode bar entry for channel Mod actions. Styled like
/// [NativeChatOptionsButton] (44pt tile). Visibility is gated by the
/// username bar's fit check + [TwitchChatStore.canModerateSelectedChannel].
///
/// [onTap] defaults to the Twitch sheet; Kick / YouTube / Combined pass
/// their own.
class ChannelModButton extends StatelessWidget {
  final void Function(BuildContext context)? onTap;

  const ChannelModButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Channel moderation',
      child: Pressable(
        haptic: true,
        onTap: () => (this.onTap ?? showChannelModSheet)(context),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: kMinInteractiveDimensionCupertino,
            minHeight: kMinInteractiveDimensionCupertino,
          ),
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
          child: const Icon(CupertinoIcons.shield, size: 18.0),
        ),
      ),
    );
  }
}

/// Whether the shield + options fit in [maxWidth] without overflow (the
/// signed-in bar has no account chip next to them).
bool nativeModClusterFitsWithShield({required double maxWidth}) {
  const tile = kMinInteractiveDimensionCupertino;
  const gap = AppSpacing.sm;
  return tile + gap + tile <= maxWidth;
}
