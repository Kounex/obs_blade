import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../chat_type_brand.dart';
import '../twitch_device_code_dialog.dart';

/// Native-mode Twitch sign-in control for the username bar: a "Connect
/// Twitch" pill while logged out, nothing while logged in - the account
/// and its sign-out live in the chat header's sheet, so the bar's right
/// side stays free for the mod shield. Only visible while the native
/// engine is selected - the WebView engine shows the classic username
/// actions instead.
class TwitchAccountControl extends StatelessWidget {
  const TwitchAccountControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = GetIt.instance<TwitchChatStore>();
        if (store.isLoggedIn) return const SizedBox.shrink();
        return const Align(
          alignment: Alignment.centerRight,

          /// Hug the pill: a full-width Align left a gap next to the
          /// options button in the chat bar row.
          widthFactor: 1.0,
          child: _ConnectPill(),
        );
      },
    );
  }
}

/// Same visual style as the "Connect Twitch" pill in the native connect
/// empty state (`stream_chat.dart`)
class _ConnectPill extends StatelessWidget {
  const _ConnectPill();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: true,
      onTap: () => startTwitchLogin(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color:
              ChatType.Twitch.brandColor ??
              Theme.of(context).colorScheme.secondary,
          borderRadius: AppRadius.pill,
        ),
        child: AutoSizeText(
          'Connect Twitch',
          maxLines: 1,
          minFontSize: 10.0,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
