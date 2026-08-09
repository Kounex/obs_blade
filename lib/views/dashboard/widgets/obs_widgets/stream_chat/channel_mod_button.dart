import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../utils/styling_helper.dart';
import 'dialogs/channel_mod_sheet.dart';

/// Native-mode bar entry for channel Mod actions. Styled like
/// [NativeChatOptionsButton] (44pt tile). Visibility is gated by the
/// username bar's fit check + [TwitchChatStore.canModerateSelectedChannel].
class ChannelModButton extends StatelessWidget {
  const ChannelModButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Channel moderation',
      child: Pressable(
        haptic: true,
        onTap: () => showChannelModSheet(context),
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
            CupertinoIcons.shield,
            size: 18.0,
          ),
        ),
      ),
    );
  }
}

/// Preferred width of the connected-account chip for the right-cluster
/// fit check (padding + icon + gap + ellipsized name ≤ 96).
double accountChipPreferredWidth(
  BuildContext context,
  String? displayName,
) {
  final style = Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
      );
  final painter = TextPainter(
    text: TextSpan(text: displayName ?? 'Twitch', style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout(maxWidth: 96.0);
  return AppSpacing.md * 2 + 18.0 + AppSpacing.xs + painter.width;
}

/// Whether options + shield + account fit in [maxWidth] without overflow.
bool nativeModClusterFitsWithShield({
  required double maxWidth,
  required double accountWidth,
}) {
  const tile = kMinInteractiveDimensionCupertino;
  const gap = AppSpacing.sm;
  return tile + gap + tile + gap + accountWidth <= maxWidth;
}
