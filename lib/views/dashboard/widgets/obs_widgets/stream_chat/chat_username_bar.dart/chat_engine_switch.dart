import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../models/enums/chat_engine.dart';
import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../types/enums/settings_keys.dart';

/// Manual WebView <-> Native engine toggle for the stream chat. Renders
/// nothing for platforms without a native engine
/// ([nativeChatAvailableFor]); writes [SettingsKeys.SelectedChatEngine]
/// straight to the Settings box - the surrounding HiveBuilder in
/// `chat_username_bar.dart` rebuilds on the change.
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

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<ChatEngine>(
        groupValue: engine,

        /// Vertical segment padding brings the control near the 44pt touch
        /// target of the neighboring bar controls
        children: const {
          ChatEngine.webView: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text('WebView'),
          ),
          ChatEngine.native: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text('Native'),
          ),
        },
        onValueChanged: (selected) {
          if (selected != null) {
            this
                .settingsBox
                .put(SettingsKeys.SelectedChatEngine.name, selected);
          }
        },
      ),
    );
  }
}
