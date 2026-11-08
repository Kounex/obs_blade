import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../design/design.dart';

/// Widest a sheet gets. Tablets show every sheet as a centered card this
/// wide - Material 3's own bottom sheet cap, which the chat sheets had
/// before the dashboard / settings sheets moved onto the same helper
const double kBaseSheetMaxWidth = 640.0;

/// The most of the screen height a sheet may take. A sheet with less
/// content stays as short as its content; these only cap it, and the top
/// gap they leave keeps a barrier to tap.
enum BaseSheetHeight {
  /// A handful of rows (pick a target, a short choice)
  compact(0.5),

  /// Most sheets: settings, actions, mod tools, user cards
  standard(0.72),

  /// Lists, forms and pages (search, setup, pickers, filters, credits)
  tall(0.88);

  final double fraction;

  const BaseSheetHeight(this.fraction);
}

/// Sheet / page titles — title2 scale so they read clearly above body
/// (`titleMedium` is 15px in the On Air theme, same as body).
TextStyle? baseSheetTitleStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .titleLarge
    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3);

/// Section headings inside a sheet ("All chats", TTS's Who /
/// What, emote groups, mod sections ...): title3 size (17) in bold on the
/// secondary text level - bigger than the 15 pt rows they head (the
/// app's 11 pt caption read smaller), gray so it reads as a label, not
/// one more entry. Sentence case, as written; give it room above.
TextStyle? baseSheetSectionStyle(BuildContext context) =>
    Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color:
          (Theme.of(context).extension<AppTextColors>() ??
                  AppTextColors.standard)
              .textSecondary,
    );

/// Drag handle - the one close control every sheet shows.
Widget baseSheetDragHandle(BuildContext context) => Center(
  child: Container(
    width: 36.0,
    height: 4.0,
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    decoration: BoxDecoration(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
      borderRadius: AppRadius.pill,
    ),
  ),
);

/// Back chevron + [title] - the header of a sheet another one hopped to
/// (e.g. the chat's `showChatSheetRun`); [onBack] pops it with the page it came from.
class BaseSheetBackTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  /// After the title (e.g. a Reset action)
  final Widget? trailing;

  const BaseSheetBackTitle({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Pressable(
          key: const Key('chat-sheet-back'),
          haptic: true,
          onTap: this.onBack,
          child: Padding(
            padding: const EdgeInsets.only(
              right: AppSpacing.sm,
              top: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            child: Icon(
              CupertinoIcons.chevron_back,
              size: 20.0,
              color:
                  (Theme.of(context).extension<AppTextColors>() ??
                          AppTextColors.standard)
                      .highlightText,
            ),
          ),
        ),
        Expanded(child: Text(this.title, style: baseSheetTitleStyle(context))),
        ?this.trailing,
      ],
    );
  }
}

/// Standard sheet layout (every sheet in the app, see
/// [ModalHandler.showBaseBottomSheet]): drag handle + [header] (title, back
/// chevron, actions) pinned at the top, only [body] scrolls. The shared
/// modal body caps the sheet height and still turns a pull past the top
/// of [body] into a sheet drag (same setup as the YouTube setup sheet).
/// Rule: sheets with a handle / title / back chevron never put those
/// inside the scroll view.
///
/// [pinned] sits between the header and [body] and [footer] under it,
/// neither scrolling (user cards: facts + LIVE above the messages, the
/// self card's account footer below) - unless the sheet is too short for
/// that to leave room (a phone in landscape), then all of it scrolls
/// together. When the three don't fit, [body] keeps at least a third of
/// the room and [pinned] / [footer] share the rest ([_PinnedSheetLayout]);
/// whatever doesn't fit its share scrolls on its own (large text sizes).
class BaseSheetScaffold extends StatelessWidget {
  final Widget header;
  final Widget body;
  final Widget? pinned;
  final Widget? footer;

  /// [body] is its own scroll view (a lazy [ListView], e.g. a user
  /// card's long message history): the scaffold passes it to the layout
  /// unwrapped instead of putting a [SingleChildScrollView] around it
  /// (which would force it to size/build unbounded). The pinned slot
  /// keeps scrolling on its own, so the short-sheet fallback (everything
  /// in one scroll) is skipped — a lazy body can't join a shared scroll,
  /// and the slotted layout guarantees it a third of the room anyway.
  final bool bodyIsScrollable;

  /// Only with [bodyIsScrollable]: the body is small enough to join the
  /// short-sheet fallback's shared scroll after all (a shrink-wrapping
  /// list that then stops scrolling itself). False for a long lazy body.
  final bool bodySharesScrollWhenShort;

  /// Gap between the pinned header and the scrolling body.
  final double headerGap;

  /// Below this much room under the header, [pinned] / [footer] scroll
  /// with [body] - a pinned block would leave the messages a sliver.
  static const double minHeightToPin = 320.0;

  const BaseSheetScaffold({
    super.key,
    required this.header,
    required this.body,
    this.pinned,
    this.footer,
    this.bodyIsScrollable = false,
    this.bodySharesScrollWhenShort = false,
    this.headerGap = AppSpacing.sm,
  });

  static const EdgeInsets _sidePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
  );

  Widget _scroll(Widget child, {EdgeInsets? padding}) => SingleChildScrollView(
    primary: false,
    physics: const ClampingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    padding:
        padding ??
        const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0.0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
    child: child,
  );

  Widget _allScrolling() => this._scroll(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [?this.pinned, this.body, ?this.footer],
    ),
  );

  Widget _pinnedLayout() => _PinnedSheetLayout(
    pinned: this.pinned == null
        ? null
        : this._scroll(this.pinned!, padding: _sidePadding),
    body: this.bodyIsScrollable
        ? this.body
        : this._scroll(
            this.body,
            padding: this.footer == null ? null : _sidePadding,
          ),
    footer: this.footer == null ? null : this._scroll(this.footer!),
  );

  @override
  Widget build(BuildContext context) {
    final hasPinned = this.pinned != null || this.footer != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            this.headerGap,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [baseSheetDragHandle(context), this.header],
          ),
        ),
        Flexible(
          child: !hasPinned
              ? (this.bodyIsScrollable ? this.body : this._scroll(this.body))
              : LayoutBuilder(
                  builder: (context, constraints) =>
                      constraints.maxHeight < minHeightToPin &&
                          (!this.bodyIsScrollable ||
                              this.bodySharesScrollWhenShort)
                      ? this._allScrolling()
                      : this._pinnedLayout(),
                ),
        ),
      ],
    );
  }
}

enum _SheetSlot { pinned, body, footer }

/// [BaseSheetScaffold]'s pinned / body / footer column (each child
/// a scroll view). Everything that fits sits at its natural height; when
/// it doesn't, [body] keeps at least a third of the room (less only if it
/// needs less) and [pinned] / [footer] share the rest - each up to half,
/// one that needs less leaves the other more. A Column can't do this: it
/// would give [body] nothing once the other two are tall (a self card's
/// footer at large text sizes).
class _PinnedSheetLayout
    extends SlottedMultiChildRenderObjectWidget<_SheetSlot, RenderBox> {
  final Widget? pinned;
  final Widget body;
  final Widget? footer;

  const _PinnedSheetLayout({
    required this.pinned,
    required this.body,
    required this.footer,
  });

  @override
  Iterable<_SheetSlot> get slots => _SheetSlot.values;

  @override
  Widget? childForSlot(_SheetSlot slot) => switch (slot) {
    _SheetSlot.pinned => this.pinned,
    _SheetSlot.body => this.body,
    _SheetSlot.footer => this.footer,
  };

  @override
  _RenderPinnedSheetLayout createRenderObject(BuildContext context) =>
      _RenderPinnedSheetLayout();
}

class _RenderPinnedSheetLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_SheetSlot, RenderBox> {
  /// Top to bottom
  Iterable<RenderBox> get _ordered => [
    for (final slot in _SheetSlot.values) ?childForSlot(slot),
  ];

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    final width = this.constraints.maxWidth;
    final maxHeight = this.constraints.maxHeight;
    double lay(RenderBox? child, double max) {
      if (child == null) return 0.0;
      child.layout(
        BoxConstraints.tightFor(width: width).copyWith(maxHeight: max),
        parentUsesSize: true,
      );
      return child.size.height;
    }

    final pinned = childForSlot(_SheetSlot.pinned);
    final body = childForSlot(_SheetSlot.body)!;
    final footer = childForSlot(_SheetSlot.footer);
    var top = lay(pinned, maxHeight);
    var bottom = lay(footer, maxHeight);
    var middle = lay(body, maxHeight);
    if (top + middle + bottom > maxHeight) {
      final room = maxHeight - math.min(middle, maxHeight / 3);
      if (top + bottom > room) {
        final half = room / 2;
        final (topCap, bottomCap) = top <= half
            ? (top, room - top)
            : bottom <= half
            ? (room - bottom, bottom)
            : (half, half);
        top = lay(pinned, topCap);
        bottom = lay(footer, bottomCap);
      }
      middle = lay(body, maxHeight - top - bottom);
    }
    var y = 0.0;
    for (final child in this._ordered) {
      (child.parentData! as BoxParentData).offset = Offset(0.0, y);
      y += child.size.height;
    }
    this.size = this.constraints.constrain(Size(width, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in this._ordered) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in this._ordered.toList().reversed) {
      final offset = (child.parentData! as BoxParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

/// A sheet's title row for [BaseSheetScaffold.header]: [title] in the
/// sheet title style, an optional [subtitle] under it (the source a sheet
/// edits) and [trailing] actions (Save, a Pro badge, a help tooltip) at
/// the end of the title line.
class BaseSheetTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Right after the title text instead of at the far end (a badge that
  /// belongs to the title)
  final Widget? titleSuffix;
  final Widget? trailing;

  const BaseSheetTitle(
    this.title, {
    super.key,
    this.subtitle,
    this.titleSuffix,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      this.title,
                      style: baseSheetTitleStyle(context),
                    ),
                  ),
                  if (this.titleSuffix != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    this.titleSuffix!,
                  ],
                ],
              ),
            ),
            ?this.trailing,
          ],
        ),
        if (this.subtitle != null)
          Text(
            this.subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  (theme.extension<AppTextColors>() ?? AppTextColors.standard)
                      .textSecondary,
            ),
          ),
      ],
    );
  }
}
