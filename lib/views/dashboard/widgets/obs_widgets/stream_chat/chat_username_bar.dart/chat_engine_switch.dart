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
import '../../../../../../utils/routing_helper.dart';

/// Manual WebView <-> Native engine toggle for the stream chat. Renders
/// nothing for platforms without a native engine
/// ([nativeChatAvailableFor]); writes [SettingsKeys.SelectedChatEngine]
/// straight to the Settings box - the surrounding HiveBuilder in
/// `chat_username_bar.dart` rebuilds on the change.
///
/// Native engines are a Pro entitlement: when [ProStore.isPro] is false the
/// Native segment carries a lock badge and tapping it pushes the Pro
/// paywall route instead of switching the engine (the box put is skipped).
/// Pro users get the byte-identical pre-gate behavior.
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

              /// Not Pro: the paywall is the destination, the engine stays
              if (selected == ChatEngine.native && !isPro) {
                Navigator.of(context)
                    .pushNamed(HomeTabRoutingKeys.Pro.route);
                return;
              }

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
