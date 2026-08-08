import 'package:flutter/material.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../utils/modal_handler.dart';

/// Opens the "Add chat" picker sheet (multi-chat) — the entry behind
/// `NativeChannelDropdown`'s "Add chat…" item.
void showAddChatSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AddChatSheet(),
    );

/// "Add chat" picker (multi-chat): find another streamer's channel and add
/// it to the native chat. The search field and the moderated/followed
/// quick-pick sections are filled in by the picker task.
class AddChatSheet extends StatelessWidget {
  const AddChatSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add chat',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
