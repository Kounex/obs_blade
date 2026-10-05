import 'package:flutter/cupertino.dart' show kMinInteractiveDimensionCupertino;
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_chrome.dart';

/// Rows of a user card's message history visible before the "Show X
/// older messages" button. Closing and reopening the card resets to
/// this count (the expansion lives in this widget's state).
const int kUserCardHistoryInitialCount = 50;

/// The scrolling body of every platform's user card: the chatter's
/// retained messages (live buffer + session history), newest first,
/// lazily built past [kUserCardHistoryInitialCount] — a chatty user can
/// have thousands of retained rows. One-way expansion: the button shows
/// the remaining count and reveals everything on tap.
///
/// This is a ScrollView on purpose: pass it as
/// [NativeChatSheetScaffold]'s `body` together with
/// `bodyIsScrollable: true` so the scaffold doesn't wrap it in another
/// scroll view. Small histories (≤ initial count) shrink-wrap so the
/// sheet still hugs its content.
class UserCardHistoryList extends StatefulWidget {
  /// Total retained rows (live + history), newest first.
  final int messageCount;

  /// Builds the row for [index] (0 = newest) - carries the `card-msg-`
  /// key, timestamp and tombstone state of that message.
  final Widget Function(BuildContext context, int index) rowBuilder;

  /// Hairlines between rows (the timeline's separator setting).
  final bool separators;

  /// Whose card this is — the button's screen-reader label ("Show X
  /// older messages from" + this name).
  final String userName;

  /// Matches the scaffold's body padding (bottom inset only when the
  /// sheet has no footer under the list).
  final EdgeInsets padding;

  const UserCardHistoryList({
    super.key,
    required this.messageCount,
    required this.rowBuilder,
    required this.separators,
    required this.userName,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0.0,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
  });

  @override
  State<UserCardHistoryList> createState() => _UserCardHistoryListState();
}

class _UserCardHistoryListState extends State<UserCardHistoryList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final count = this.widget.messageCount;
    final shown = this._expanded
        ? count
        : count > kUserCardHistoryInitialCount
        ? kUserCardHistoryInitialCount
        : count;
    final hasMore = shown < count;

    return LayoutBuilder(
      builder: (context, constraints) {
        /// Unbounded height = the sheet's short-form fallback put this
        /// list inside its shared scroll: size to the content and let
        /// the ancestor do the scrolling (nested scrollables would fight
        /// over the drag). Only reachable for small histories — the
        /// scaffold keeps a long lazy body in its pinned layout.
        final sharedScroll = constraints.maxHeight == double.infinity;
        return ListView.separated(
          primary: false,
          padding: this.widget.padding,
          physics: sharedScroll
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),

          /// A list that can't overflow the sheet sizes to its content
          /// (the modal hugs it); everything past the initial count stays
          /// lazy instead.
          shrinkWrap: sharedScroll || count <= kUserCardHistoryInitialCount,
          itemCount: shown + (hasMore ? 1 : 0),
          separatorBuilder: (context, _) => this.widget.separators
              ? nativeChatHairline(context)
              : const SizedBox.shrink(),
          itemBuilder: (context, index) {
            if (index < shown) return this.widget.rowBuilder(context, index);
            final remaining = count - shown;
            final label =
                'Show $remaining older message${remaining == 1 ? '' : 's'}';
            return Semantics(
              button: true,
              excludeSemantics: true,
              label: '$label from ${this.widget.userName}',
              child: Pressable(
                haptic: true,
                onTap: () => this.setState(() => this._expanded = true),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: kMinInteractiveDimensionCupertino,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(
                            context,
                          ).buttonTheme.colorScheme?.secondary ??
                          StylingHelper.accent_color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
