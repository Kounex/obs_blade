import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../stores/views/combined_chat.dart';
import '../../../../../../utils/styling_helper.dart';
import '../chat_type_brand.dart';
import '../combined_sources_sheet.dart';

/// Channel slot of the chat bar for [ChatType.Combined]: the active combo
/// ("My chats" — the only one in wave 1) with a status-tinted icon per
/// source. Tapping opens the sources sheet (toggles, sign-in, retry).
/// Same bar-control idiom as the platform channel dropdowns.
class CombinedChatPicker extends StatelessWidget {
  const CombinedChatPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final statusColors =
        Theme.of(context).extension<AppStatusColors>() ??
        AppStatusColors.standard;
    return Flexible(
      child: Pressable(
        haptic: true,
        onTap: () => showCombinedSourcesSheet(context),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 100.0,
            minHeight: kMinInteractiveDimensionCupertino,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
          child: Observer(
            builder: (_) {
              final store = GetIt.instance<CombinedChatStore>();
              final statuses = store.sourceStatus;
              return Row(
                children: [
                  const Flexible(
                    child: Text(
                      'My chats',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  for (final source in store.activeSources) ...[
                    _SourceIcon(
                      platform: source.platform,
                      dimmed:
                          statuses[source.platform] !=
                          CombinedSourceStatus.live,
                      alert:
                          statuses[source.platform] ==
                              CombinedSourceStatus.error ||
                          statuses[source.platform] ==
                              CombinedSourceStatus.needsSetup,
                      alertColor: statusColors.unreachable,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  const Spacer(),
                  const Icon(CupertinoIcons.chevron_down, size: 14.0),
                ],
              );
            },
          ),
        ),
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
