import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../native_chat_options_sheet.dart';

/// Entry point in the native-mode chat bar for Kick: opens the shared
/// [NativeChatOptionsSheet] (Appearance only — Kick reads are anonymous,
/// so there are no account/setup/mod rows this wave). Styled like
/// [YouTubeChatOptionsButton] — same container idiom, 44pt touch target.
class KickChatOptionsButton extends StatelessWidget {
  const KickChatOptionsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Native chat options',
      child: Pressable(
        haptic: true,
        onTap: () => ModalHandler.showBaseBottomSheet(
          context: context,
          barrierDismissible: true,
          enableDrag: true,
          maxHeightFraction: 0.72,
          builder: (sheetContext) =>
              const NativeChatOptionsSheet(chatType: ChatType.Kick),
        ),
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
          child: const Icon(CupertinoIcons.slider_horizontal_3, size: 18.0),
        ),
      ),
    );
  }
}
