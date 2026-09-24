import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../stores/views/combined_chat.dart';
import '../../../../../../types/classes/combined/combined_combo.dart';
import '../../../../../../utils/styling_helper.dart';
import '../chat_type_brand.dart';
import '../combined_chat_builder_sheet.dart';
import '../combined_sources_sheet.dart';

/// Channel slot of the chat bar for [ChatType.Combined]: a dropdown of
/// "My chats" (the signed-in "You" entries), the saved combos and a
/// "New combined chat…" action. Long-press a saved combo to edit or
/// delete it. The closed control shows the combo name plus a
/// status-tinted icon per source; a trailing button opens the sources
/// sheet (status, sign-in, retry, My-chats toggles). Same bar-control
/// idiom as the platform channel dropdowns.
class CombinedChatPicker extends StatelessWidget {
  /// "New combined chat…" is an action sentinel (never a selection).
  static const String _kNewComboValue = '__new_combo__';

  const CombinedChatPicker({super.key});

  void _editCombo(BuildContext context, CombinedCombo combo) {
    /// Close the open menu first — [context] is the Observer-captured one
    /// under the dropdown, so it survives the pop.
    Navigator.of(context).pop();
    showCombinedChatBuilderSheet(context, combo: combo);
  }

  Widget _label(BuildContext context, String name, {bool mine = false}) {
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
        ),
        if (mine) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(
            CupertinoIcons.person_crop_circle_fill,
            size: 14.0,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColors =
        Theme.of(context).extension<AppStatusColors>() ??
        AppStatusColors.standard;
    return Flexible(
      child: Observer(
        builder: (_) {
          final store = GetIt.instance<CombinedChatStore>();
          final statuses = store.sourceStatus;
          final combos = store.combos.toList();

          final items = <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: kMyChatsComboId,
              child: this._label(context, 'My chats', mine: true),
            ),
            for (final combo in combos)
              DropdownMenuItem<String>(
                value: combo.id,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () => this._editCombo(context, combo),
                  child: Row(
                    children: [
                      Flexible(child: this._label(context, combo.displayName)),
                      const SizedBox(width: AppSpacing.xs),
                      for (final platform in combo.platforms)
                        Padding(
                          padding: const EdgeInsets.only(left: 2.0),
                          child: Icon(
                            platform.icon,
                            size: 12.0,
                            color: platform.brandColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const DropdownMenuItem<String>(
              value: _kNewComboValue,
              child: Row(
                children: [
                  Icon(CupertinoIcons.plus, size: 16.0),
                  SizedBox(width: AppSpacing.xs),
                  Text('New combined chat…'),
                ],
              ),
            ),
          ];

          /// Closed control: name + one status icon per source.
          Widget closed(String name, {bool mine = false}) => Row(
            children: [
              Flexible(child: this._label(context, name, mine: mine)),
              const SizedBox(width: AppSpacing.sm),
              for (final source in store.activeSources) ...[
                _SourceIcon(
                  platform: source.platform,
                  dimmed:
                      statuses[source.platform] != CombinedSourceStatus.live,
                  alert:
                      statuses[source.platform] == CombinedSourceStatus.error ||
                      statuses[source.platform] ==
                          CombinedSourceStatus.needsSetup,
                  alertColor: statusColors.unreachable,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          );

          return Container(
            constraints: const BoxConstraints(
              minWidth: 100.0,
              minHeight: kMinInteractiveDimensionCupertino,
            ),
            alignment: Alignment.centerLeft,
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
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      child: DropdownButton<String>(
                        value: store.selectedComboId,
                        isExpanded: true,
                        isDense: true,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: items,
                        selectedItemBuilder: (_) => [
                          closed('My chats', mine: true),
                          for (final combo in combos) closed(combo.displayName),
                          closed('New combined chat…'),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          if (value == _kNewComboValue) {
                            showCombinedChatBuilderSheet(context);
                            return;
                          }
                          store.selectCombo(value);
                        },
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Chat sources',
                  child: Pressable(
                    haptic: true,
                    onTap: () => showCombinedSourcesSheet(context),
                    child: const SizedBox(
                      width: kMinInteractiveDimensionCupertino,
                      height: kMinInteractiveDimensionCupertino,
                      child: Icon(
                        CupertinoIcons.dot_radiowaves_left_right,
                        size: 18.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A source's platform icon: full brand color while live, dimmed
/// otherwise, with a small alert dot when it needs the user.
class _SourceIcon extends StatelessWidget {
  final ChatType platform;
  final bool dimmed;
  final bool alert;
  final Color alertColor;

  const _SourceIcon({
    required this.platform,
    required this.dimmed,
    required this.alert,
    required this.alertColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${this.platform.text}${this.dimmed ? ', not live' : ''}',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: this.dimmed ? 0.4 : 1.0,
            child: Icon(
              this.platform.icon,
              key: Key('combined-picker-${this.platform.name}'),
              size: 16.0,
              color: this.platform.brandColor,
            ),
          ),
          if (this.alert)
            Positioned(
              right: -2.0,
              top: -2.0,
              child: Container(
                width: 7.0,
                height: 7.0,
                decoration: BoxDecoration(
                  color: this.alertColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
