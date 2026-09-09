import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../models/enums/chat_engine.dart';
import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../stores/pro_store.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/icons/jam_icons.dart';

/// Manual WebView <-> Native engine toggle for the stream chat. Renders
/// nothing for platforms without a native engine
/// ([nativeChatAvailableFor]); writes [SettingsKeys.SelectedChatEngine]
/// straight to the Settings box - the surrounding HiveBuilder in
/// `chat_username_bar.dart` rebuilds on the change.
///
/// Native engines are a Pro entitlement: the switch itself is always
/// usable (the Native segment carries a lock badge while
/// [ProStore.isPro] is false) - the enforcement lives behind it: the
/// pane renders the locked Pro upsell instead of chat (stream_chat.dart)
/// and the stores refuse to connect without the entitlement
/// (`connectChat` gates on [ProStore.isPro]).
class ChatEngineSwitch extends StatelessWidget {
  final Box settingsBox;
  final ChatType chatType;

  const ChatEngineSwitch({
    super.key,
    required this.settingsBox,
    required this.chatType,
  });

  @override
  Widget build(BuildContext context) {
    if (!nativeChatAvailableFor(this.chatType)) {
      return const SizedBox.shrink();
    }

    final ChatEngine engine = this.settingsBox.get(
          SettingsKeys.SelectedChatEngine.name,
          defaultValue: ChatEngine.webView,
        );

    return Observer(
      builder: (context) {
        final bool isPro = GetIt.instance<ProStore>().isPro;

        return SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<ChatEngine>(
            groupValue: engine,

            /// Vertical segment padding brings the control near the 44pt
            /// touch target of the neighboring bar controls
            children: {
              ChatEngine.webView: const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('WebView'),
              ),
              ChatEngine.native: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Native'),
                    if (!isPro) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(JamIcons.padlock, size: 13.0),
                    ],
                  ],
                ),
              ),
            },
            onValueChanged: (selected) {
              if (selected == null) return;

              /// The switch always applies - without the entitlement the
              /// pane renders the locked Pro upsell (and the stores
              /// refuse to connect), so the paywall is one tap away from
              /// there instead of intercepting here
              this
                  .settingsBox
                  .put(SettingsKeys.SelectedChatEngine.name, selected);
            },
          ),
        );
      },
    );
  }
}
