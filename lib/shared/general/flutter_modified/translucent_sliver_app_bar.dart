import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../utils/styling_helper.dart';

typedef _FlexibleConfigBuilder = _ScrollUnderFlexibleConfig Function(
    BuildContext);

const double _kLeadingWidth =
    kToolbarHeight; // So the leading button is square.
const double _kMaxTitleTextScaleFactor =
    1.34; // TODO(perc): Add link to Material spec when available, https://github.com/flutter/flutter/issues/58769.

enum _SliverAppVariant { small, medium, large }

class TransculentSliverAppBar extends StatefulWidget {
  /// Creates a Material Design app bar that can be placed in a [CustomScrollView].
  const TransculentSliverAppBar({
    super.key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.forceElevated = false,
    this.backgroundColor,
    this.foregroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.centerTitle,
    this.excludeHeaderSemantics = false,
    this.titleSpacing,
    this.collapsedHeight,
    this.expandedHeight,
    this.floating = false,
    this.pinned = false,
    this.snap = false,
    this.stretch = false,
    this.stretchTriggerOffset = 100.0,
    this.onStretchTrigger,
    this.shape,
    this.toolbarHeight = kToolbarHeight,
    this.leadingWidth,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.forceMaterialTransparency = false,
    this.clipBehavior,
  })  : assert(floating || !snap,
            'The "snap" argument only makes sense for floating app bars.'),
        assert(stretchTriggerOffset > 0.0),
        assert(
          collapsedHeight == null || collapsedHeight >= toolbarHeight,
          'The "collapsedHeight" argument has to be larger than or equal to [toolbarHeight].',
        ),
        _variant = _SliverAppVariant.small;

  /// Creates a Material Design medium top app bar that can be placed
  /// in a [CustomScrollView].
  ///
  /// Returns a [TransculentSliverAppBar] configured with appropriate defaults
  /// for a medium top app bar as defined in Material 3. It starts fully
  /// expanded with the title in an area underneath the main row of icons.
  /// When the [CustomScrollView] is scrolled, the title will be scrolled
  /// under the main row. When it is fully collapsed, a smaller version of the
  /// title will fade in on the main row. The reverse will happen if it is
  /// expanded again.
  ///
  /// {@tool dartpad}
  /// This sample shows how to use [SliverAppBar.medium] in a [CustomScrollView].
  ///
  /// ** See code in examples/api/lib/material/app_bar/sliver_app_bar.2.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///   * [AppBar], for a small or center-aligned top app bar.
  ///   * [SliverAppBar.large], for a large top app bar.
  ///   * https://m3.material.io/components/top-app-bar/overview, the Material 3
  ///     app bar specification.
  const TransculentSliverAppBar.medium({
    super.key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.forceElevated = false,
    this.backgroundColor,
    this.foregroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.centerTitle,
    this.excludeHeaderSemantics = false,
    this.titleSpacing,
    this.collapsedHeight,
    this.expandedHeight,
    this.floating = false,
    this.pinned = true,
    this.snap = false,
    this.stretch = false,
    this.stretchTriggerOffset = 100.0,
    this.onStretchTrigger,
    this.shape,
    this.toolbarHeight = _MediumScrollUnderFlexibleConfig.collapsedHeight,
    this.leadingWidth,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.forceMaterialTransparency = false,
    this.clipBehavior,
  })  : assert(floating || !snap,
            'The "snap" argument only makes sense for floating app bars.'),
        assert(stretchTriggerOffset > 0.0),
        assert(
          collapsedHeight == null || collapsedHeight >= toolbarHeight,
          'The "collapsedHeight" argument has to be larger than or equal to [toolbarHeight].',
        ),
        _variant = _SliverAppVariant.medium;

  /// Creates a Material Design large top app bar that can be placed
  /// in a [CustomScrollView].
  ///
  /// Returns a [TransculentSliverAppBar] configured with appropriate defaults
  /// for a large top app bar as defined in Material 3. It starts fully
  /// expanded with the title in an area underneath the main row of icons.
  /// When the [CustomScrollView] is scrolled, the title will be scrolled
  /// under the main row. When it is fully collapsed, a smaller version of the
  /// title will fade in on the main row. The reverse will happen if it is
  /// expanded again.
  ///
  /// {@tool dartpad}
  /// This sample shows how to use [SliverAppBar.large] in a [CustomScrollView].
  ///
  /// ** See code in examples/api/lib/material/app_bar/sliver_app_bar.3.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///   * [AppBar], for a small or center-aligned top app bar.
  ///   * [SliverAppBar.medium], for a medium top app bar.
  ///   * https://m3.material.io/components/top-app-bar/overview, the Material 3
  ///     app bar specification.
  const TransculentSliverAppBar.large({
    super.key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.forceElevated = false,
    this.backgroundColor,
    this.foregroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.centerTitle,
    this.excludeHeaderSemantics = false,
    this.titleSpacing,
    this.collapsedHeight,
    this.expandedHeight,
    this.floating = false,
    this.pinned = true,
    this.snap = false,
    this.stretch = false,
    this.stretchTriggerOffset = 100.0,
    this.onStretchTrigger,
    this.shape,
    this.toolbarHeight = _LargeScrollUnderFlexibleConfig.collapsedHeight,
    this.leadingWidth,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.forceMaterialTransparency = false,
    this.clipBehavior,
  })  : assert(floating || !snap,
            'The "snap" argument only makes sense for floating app bars.'),
        assert(stretchTriggerOffset > 0.0),
        assert(
          collapsedHeight == null || collapsedHeight >= toolbarHeight,
          'The "collapsedHeight" argument has to be larger than or equal to [toolbarHeight].',
        ),
        _variant = _SliverAppVariant.large;

  /// {@macro flutter.material.appbar.leading}
  ///
  /// This property is used to configure an [AppBar].
  final Widget? leading;

  /// {@macro flutter.material.appbar.automaticallyImplyLeading}
  ///
  /// This property is used to configure an [AppBar].
  final bool automaticallyImplyLeading;

  /// {@macro flutter.material.appbar.title}
  ///
  /// This property is used to configure an [AppBar].
  final Widget? title;

  /// {@macro flutter.material.appbar.actions}
  ///
  /// This property is used to configure an [AppBar].
  final List<Widget>? actions;

  /// {@macro flutter.material.appbar.flexibleSpace}
  ///
  /// This property is used to configure an [AppBar].
  final Widget? flexibleSpace;

  /// {@macro flutter.material.appbar.bottom}
  ///
  /// This property is used to configure an [AppBar].
  final PreferredSizeWidget? bottom;

  /// {@macro flutter.material.appbar.elevation}
  ///
  /// This property is used to configure an [AppBar].
  final double? elevation;

  /// {@macro flutter.material.appbar.scrolledUnderElevation}
  ///
  /// This property is used to configure an [AppBar].
  final double? scrolledUnderElevation;

  /// {@macro flutter.material.appbar.shadowColor}
  ///
  /// This property is used to configure an [AppBar].
  final Color? shadowColor;

  /// {@macro flutter.material.appbar.surfaceTintColor}
  ///
  /// This property is used to configure an [AppBar].
  final Color? surfaceTintColor;

  /// Whether to show the shadow appropriate for the [elevation] even if the
  /// content is not scrolled under the [AppBar].
  ///
  /// Defaults to false, meaning that the [elevation] is only applied when the
  /// [AppBar] is being displayed over content that is scrolled under it.
  ///
  /// When set to true, the [elevation] is applied regardless.
  ///
  /// Ignored when [elevation] is zero.
  final bool forceElevated;

  /// {@macro flutter.material.appbar.backgroundColor}
  ///
  /// This property is used to configure an [AppBar].
  final Color? backgroundColor;

  /// {@macro flutter.material.appbar.foregroundColor}
  ///
  /// This property is used to configure an [AppBar].
  final Color? foregroundColor;

  /// {@macro flutter.material.appbar.iconTheme}
  ///
  /// This property is used to configure an [AppBar].
  final IconThemeData? iconTheme;

  /// {@macro flutter.material.appbar.actionsIconTheme}
  ///
  /// This property is used to configure an [AppBar].
  final IconThemeData? actionsIconTheme;

  /// {@macro flutter.material.appbar.primary}
  ///
  /// This property is used to configure an [AppBar].
  final bool primary;

  /// {@macro flutter.material.appbar.centerTitle}
  ///
  /// This property is used to configure an [AppBar].
  final bool? centerTitle;

  /// {@macro flutter.material.appbar.excludeHeaderSemantics}
  ///
  /// This property is used to configure an [AppBar].
  final bool excludeHeaderSemantics;

  /// {@macro flutter.material.appbar.titleSpacing}
  ///
  /// This property is used to configure an [AppBar].
  final double? titleSpacing;

  /// Defines the height of the app bar when it is collapsed.
  ///
  /// By default, the collapsed height is [toolbarHeight]. If [bottom] widget is
  /// specified, then its height from [PreferredSizeWidget.preferredSize] is
  /// added to the height. If [primary] is true, then the [MediaQuery] top
  /// padding, [EdgeInsets.top] of [MediaQueryData.padding], is added as well.
  ///
  /// If [pinned] and [floating] are true, with [bottom] set, the default
  /// collapsed height is only the height of [PreferredSizeWidget.preferredSize]
  /// with the [MediaQuery] top padding.
  final double? collapsedHeight;

  /// The size of the app bar when it is fully expanded.
  ///
  /// By default, the total height of the toolbar and the bottom widget (if
  /// any). If a [flexibleSpace] widget is specified this height should be big
  /// enough to accommodate whatever that widget contains.
  ///
  /// This does not include the status bar height (which will be automatically
  /// included if [primary] is true).
  final double? expandedHeight;

  /// Whether the app bar should become visible as soon as the user scrolls
  /// towards the app bar.
  ///
  /// Otherwise, the user will need to scroll near the top of the scroll view to
  /// reveal the app bar.
  ///
  /// If [snap] is true then a scroll that exposes the app bar will trigger an
  /// animation that slides the entire app bar into view. Similarly if a scroll
  /// dismisses the app bar, the animation will slide it completely out of view.
  ///
  /// ## Animated Examples
  ///
  /// The following animations show how the app bar changes its scrolling
  /// behavior based on the value of this property.
  ///
  /// * App bar with [floating] set to false:
  ///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar.mp4}
  /// * App bar with [floating] set to true:
  ///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_floating.mp4}
  ///
  /// See also:
  ///
  ///  * [TransculentSliverAppBar] for more animated examples of how this property changes the
  ///    behavior of the app bar in combination with [pinned] and [snap].
  final bool floating;

  /// Whether the app bar should remain visible at the start of the scroll view.
  ///
  /// The app bar can still expand and contract as the user scrolls, but it will
  /// remain visible rather than being scrolled out of view.
  ///
  /// ## Animated Examples
  ///
  /// The following animations show how the app bar changes its scrolling
  /// behavior based on the value of this property.
  ///
  /// * App bar with [pinned] set to false:
  ///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar.mp4}
  /// * App bar with [pinned] set to true:
  ///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_pinned.mp4}
  ///
  /// See also:
  ///
  ///  * [TransculentSliverAppBar] for more animated examples of how this property changes the
  ///    behavior of the app bar in combination with [floating].
  final bool pinned;

  /// {@macro flutter.material.appbar.shape}
  ///
  /// This property is used to configure an [AppBar].
  final ShapeBorder? shape;

  /// If [snap] and [floating] are true then the floating app bar will "snap"
  /// into view.
  ///
  /// If [snap] is true then a scroll that exposes the floating app bar will
  /// trigger an animation that slides the entire app bar into view. Similarly
  /// if a scroll dismisses the app bar, the animation will slide the app bar
  /// completely out of view. Additionally, setting [snap] to true will fully
  /// expand the floating app bar when the framework tries to reveal the
  /// contents of the app bar by calling [RenderObject.showOnScreen]. For
  /// example, when a [TextField] in the floating app bar gains focus, if [snap]
  /// is true, the framework will always fully expand the floating app bar, in
  /// order to reveal the focused [TextField].
  ///
  /// Snapping only applies when the app bar is floating, not when the app bar
  /// appears at the top of its scroll view.
  ///
  /// ## Animated Examples
  ///
  /// The following animations show how the app bar changes its scrolling
  /// behavior based on the value of this property.
  ///
  /// * App bar with [snap] set to false:
  ///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_floating.mp4}
  /// * App bar with [snap] set to true:
  ///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_floating_snap.mp4}
  ///
  /// See also:
  ///
  ///  * [TransculentSliverAppBar] for more animated examples of how this property changes the
  ///    behavior of the app bar in combination with [pinned] and [floating].
  final bool snap;

  /// Whether the app bar should stretch to fill the over-scroll area.
  ///
  /// The app bar can still expand and contract as the user scrolls, but it will
  /// also stretch when the user over-scrolls.
  final bool stretch;

  /// The offset of overscroll required to activate [onStretchTrigger].
  ///
  /// This defaults to 100.0.
  final double stretchTriggerOffset;

  /// The callback function to be executed when a user over-scrolls to the
  /// offset specified by [stretchTriggerOffset].
  final AsyncCallback? onStretchTrigger;

  /// {@macro flutter.material.appbar.toolbarHeight}
  ///
  /// This property is used to configure an [AppBar].
  final double toolbarHeight;

  /// {@macro flutter.material.appbar.leadingWidth}
  ///
  /// This property is used to configure an [AppBar].
  final double? leadingWidth;

  /// {@macro flutter.material.appbar.toolbarTextStyle}
  ///
  /// This property is used to configure an [AppBar].
  final TextStyle? toolbarTextStyle;

  /// {@macro flutter.material.appbar.titleTextStyle}
  ///
  /// This property is used to configure an [AppBar].
  final TextStyle? titleTextStyle;

  /// {@macro flutter.material.appbar.systemOverlayStyle}
  ///
  /// This property is used to configure an [AppBar].
  final SystemUiOverlayStyle? systemOverlayStyle;

  /// {@macro flutter.material.appbar.forceMaterialTransparency}
  ///
  /// This property is used to configure an [AppBar].
  final bool forceMaterialTransparency;

  /// {@macro flutter.material.Material.clipBehavior}
  final Clip? clipBehavior;

  final _SliverAppVariant _variant;

  @override
  State<TransculentSliverAppBar> createState() =>
      _TransculentSliverAppBarState();
}

// This class is only Stateful because it owns the TickerProvider used
// by the floating appbar snap animation (via FloatingHeaderSnapConfiguration).
class _TransculentSliverAppBarState extends State<TransculentSliverAppBar>
    with TickerProviderStateMixin {
  FloatingHeaderSnapConfiguration? _snapConfiguration;
  OverScrollHeaderStretchConfiguration? _stretchConfiguration;
  PersistentHeaderShowOnScreenConfiguration? _showOnScreenConfiguration;

  void _updateSnapConfiguration() {
    if (widget.snap && widget.floating) {
      _snapConfiguration = FloatingHeaderSnapConfiguration(
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 200),
      );
    } else {
      _snapConfiguration = null;
    }

    _showOnScreenConfiguration = widget.floating & widget.snap
        ? const PersistentHeaderShowOnScreenConfiguration(
            minShowOnScreenExtent: double.infinity)
        : null;
  }

  void _updateStretchConfiguration() {
    if (widget.stretch) {
      _stretchConfiguration = OverScrollHeaderStretchConfiguration(
        stretchTriggerOffset: widget.stretchTriggerOffset,
        onStretchTrigger: widget.onStretchTrigger,
      );
    } else {
      _stretchConfiguration = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _updateSnapConfiguration();
    _updateStretchConfiguration();
  }

  @override
  void didUpdateWidget(TransculentSliverAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snap != oldWidget.snap ||
        widget.floating != oldWidget.floating) {
      _updateSnapConfiguration();
    }
    if (widget.stretch != oldWidget.stretch) {
      _updateStretchConfiguration();
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(!widget.primary || debugCheckHasMediaQuery(context));
    final double bottomHeight = widget.bottom?.preferredSize.height ?? 0.0;
    final double topPadding =
        widget.primary ? MediaQuery.paddingOf(context).top : 0.0;
    final double collapsedHeight =
        (widget.pinned && widget.floating && widget.bottom != null)
            ? (widget.collapsedHeight ?? 0.0) + bottomHeight + topPadding
            : (widget.collapsedHeight ?? widget.toolbarHeight) +
                bottomHeight +
                topPadding;
    final double? effectiveExpandedHeight;
    final double effectiveCollapsedHeight;
    final Widget? effectiveFlexibleSpace;
    switch (widget._variant) {
      case _SliverAppVariant.small:
        effectiveExpandedHeight = widget.expandedHeight;
        effectiveCollapsedHeight = collapsedHeight;
        effectiveFlexibleSpace = widget.flexibleSpace;
      case _SliverAppVariant.medium:
        effectiveExpandedHeight = widget.expandedHeight ??
            _MediumScrollUnderFlexibleConfig.expandedHeight + bottomHeight;
        effectiveCollapsedHeight = widget.collapsedHeight ??
            topPadding +
                _MediumScrollUnderFlexibleConfig.collapsedHeight +
                bottomHeight;
        effectiveFlexibleSpace = widget.flexibleSpace ??
            _ScrollUnderFlexibleSpace(
              title: widget.title,
              foregroundColor: widget.foregroundColor,
              configBuilder: _MediumScrollUnderFlexibleConfig.new,
              titleTextStyle: widget.titleTextStyle,
              bottomHeight: bottomHeight,
            );
      case _SliverAppVariant.large:
        effectiveExpandedHeight = widget.expandedHeight ??
            _LargeScrollUnderFlexibleConfig.expandedHeight + bottomHeight;
        effectiveCollapsedHeight = widget.collapsedHeight ??
            topPadding +
                _LargeScrollUnderFlexibleConfig.collapsedHeight +
                bottomHeight;
        effectiveFlexibleSpace = widget.flexibleSpace ??
            _ScrollUnderFlexibleSpace(
              title: widget.title,
              foregroundColor: widget.foregroundColor,
              configBuilder: _LargeScrollUnderFlexibleConfig.new,
              titleTextStyle: widget.titleTextStyle,
              bottomHeight: bottomHeight,
            );
    }

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: SliverPersistentHeader(
        floating: widget.floating,
        pinned: widget.pinned,
        delegate: _SliverAppBarDelegate(
          vsync: this,
          leading: widget.leading,
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
          title: widget.title,
          actions: widget.actions,
          flexibleSpace: effectiveFlexibleSpace,
          bottom: widget.bottom,
          elevation: widget.elevation,
          scrolledUnderElevation: widget.scrolledUnderElevation,
          shadowColor: widget.shadowColor,
          surfaceTintColor: widget.surfaceTintColor,
          forceElevated: widget.forceElevated,
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          iconTheme: widget.iconTheme,
          actionsIconTheme: widget.actionsIconTheme,
          primary: widget.primary,
          centerTitle: widget.centerTitle,
          excludeHeaderSemantics: widget.excludeHeaderSemantics,
          titleSpacing: widget.titleSpacing,
          expandedHeight: effectiveExpandedHeight,
          collapsedHeight: effectiveCollapsedHeight,
          topPadding: topPadding,
          floating: widget.floating,
          pinned: widget.pinned,
          shape: widget.shape,
          snapConfiguration: _snapConfiguration,
          stretchConfiguration: _stretchConfiguration,
          showOnScreenConfiguration: _showOnScreenConfiguration,
          toolbarHeight: widget.toolbarHeight,
          leadingWidth: widget.leadingWidth,
          toolbarTextStyle: widget.toolbarTextStyle,
          titleTextStyle: widget.titleTextStyle,
          systemOverlayStyle: widget.systemOverlayStyle,
          forceMaterialTransparency: widget.forceMaterialTransparency,
          clipBehavior: widget.clipBehavior,
          variant: widget._variant,
        ),
      ),
    );
  }
}

// Layout the AppBar's title with unconstrained height, vertically
// center it within its (NavigationToolbar) parent, and allow the
// parent to constrain the title's actual height.
class _AppBarTitleBox extends SingleChildRenderObjectWidget {
  const _AppBarTitleBox({required Widget super.child});

  @override
  _RenderAppBarTitleBox createRenderObject(BuildContext context) {
    return _RenderAppBarTitleBox(
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderAppBarTitleBox renderObject) {
    renderObject.textDirection = Directionality.of(context);
  }
}

class _RenderAppBarTitleBox extends RenderAligningShiftedBox {
  _RenderAppBarTitleBox({
    super.textDirection,
  }) : super(alignment: Alignment.center);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final BoxConstraints innerConstraints =
        constraints.copyWith(maxHeight: double.infinity);
    final Size childSize = child!.getDryLayout(innerConstraints);
    return constraints.constrain(childSize);
  }

  @override
  void performLayout() {
    final BoxConstraints innerConstraints =
        constraints.copyWith(maxHeight: double.infinity);
    child!.layout(innerConstraints, parentUsesSize: true);
    size = constraints.constrain(child!.size);
    alignChild();
  }
}

class _ScrollUnderFlexibleSpace extends StatelessWidget {
  const _ScrollUnderFlexibleSpace({
    this.title,
    this.foregroundColor,
    required this.configBuilder,
    this.titleTextStyle,
    required this.bottomHeight,
  });

  final Widget? title;
  final Color? foregroundColor;
  final _FlexibleConfigBuilder configBuilder;
  final TextStyle? titleTextStyle;
  final double bottomHeight;

  @override
  Widget build(BuildContext context) {
    late final AppBarTheme appBarTheme = AppBarTheme.of(context);
    late final AppBarTheme defaults = Theme.of(context).useMaterial3
        ? _AppBarDefaultsM3(context)
        : _AppBarDefaultsM2(context);
    final FlexibleSpaceBarSettings settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>()!;
    final _ScrollUnderFlexibleConfig config = configBuilder(context);
    assert(
      config.expandedTitlePadding.isNonNegative,
      'The _ExpandedTitleWithPadding widget assumes that the expanded title padding is non-negative. '
      'Update its implementation to handle negative padding.',
    );

    final TextStyle? expandedTextStyle = titleTextStyle ??
        appBarTheme.titleTextStyle ??
        config.expandedTextStyle?.copyWith(
            color: foregroundColor ??
                appBarTheme.foregroundColor ??
                defaults.foregroundColor);

    final Widget? expandedTitle = switch ((title, expandedTextStyle)) {
      (null, _) => null,
      (final Widget title, null) => title,
      (final Widget title, final TextStyle textStyle) =>
        DefaultTextStyle(style: textStyle, child: title),
    };

    final EdgeInsets resolvedTitlePadding =
        config.expandedTitlePadding.resolve(Directionality.of(context));
    final EdgeInsetsGeometry expandedTitlePadding = bottomHeight > 0
        ? resolvedTitlePadding.copyWith(bottom: 0)
        : resolvedTitlePadding;

    // Set maximum text scale factor to [_kMaxTitleTextScaleFactor] for the
    // title to keep the visual hierarchy the same even with larger font
    // sizes. To opt out, wrap the [title] widget in a [MediaQuery] widget
    // with a different TextScaler.
    // TODO(tahatesser): Add link to Material spec when available, https://github.com/flutter/flutter/issues/58769.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _kMaxTitleTextScaleFactor,
      // This column will assume the full height of the parent Stack.
      child: Column(
        children: <Widget>[
          Padding(
              padding: EdgeInsets.only(top: settings.minExtent - bottomHeight)),
          Flexible(
            child: ClipRect(
              child: _ExpandedTitleWithPadding(
                padding: expandedTitlePadding,
                maxExtent: settings.maxExtent - settings.minExtent,
                child: expandedTitle,
              ),
            ),
          ),
          // Reserve space for AppBar.bottom, which is a sibling of this widget,
          // on the parent Stack.
          if (bottomHeight > 0)
            Padding(padding: EdgeInsets.only(bottom: bottomHeight)),
        ],
      ),
    );
  }
}

// A widget that bottom-start aligns its child (the expanded title widget), and
// insets the child according to the specified padding.
//
// This widget gives the child an infinite max height constraint, and will also
// attempt to vertically limit the child's bounding box (not including the
// padding) to within the y range [0, maxExtent], to make sure the child is
// visible when the AppBar is fully expanded.
class _ExpandedTitleWithPadding extends SingleChildRenderObjectWidget {
  const _ExpandedTitleWithPadding({
    required this.padding,
    required this.maxExtent,
    super.child,
  });

  final EdgeInsetsGeometry padding;
  final double maxExtent;

  @override
  _RenderExpandedTitleBox createRenderObject(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);
    return _RenderExpandedTitleBox(
      padding.resolve(textDirection),
      AlignmentDirectional.bottomStart.resolve(textDirection),
      maxExtent,
      null,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderExpandedTitleBox renderObject) {
    final TextDirection textDirection = Directionality.of(context);
    renderObject
      ..padding = padding.resolve(textDirection)
      ..titleAlignment = AlignmentDirectional.bottomStart.resolve(textDirection)
      ..maxExtent = maxExtent;
  }
}

class _RenderExpandedTitleBox extends RenderShiftedBox {
  _RenderExpandedTitleBox(
      this._padding, this._titleAlignment, this._maxExtent, super.child);

  EdgeInsets get padding => _padding;
  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    if (_padding == value) {
      return;
    }
    assert(value.isNonNegative);
    _padding = value;
    markNeedsLayout();
  }

  Alignment get titleAlignment => _titleAlignment;
  Alignment _titleAlignment;
  set titleAlignment(Alignment value) {
    if (_titleAlignment == value) {
      return;
    }
    _titleAlignment = value;
    markNeedsLayout();
  }

  double get maxExtent => _maxExtent;
  double _maxExtent;
  set maxExtent(double value) {
    if (_maxExtent == value) {
      return;
    }
    _maxExtent = value;
    markNeedsLayout();
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final RenderBox? child = this.child;
    return child == null
        ? 0.0
        : child.getMaxIntrinsicHeight(math.max(0, width - padding.horizontal)) +
            padding.vertical;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final RenderBox? child = this.child;
    return child == null
        ? 0.0
        : child.getMaxIntrinsicWidth(double.infinity) + padding.horizontal;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final RenderBox? child = this.child;
    return child == null
        ? 0.0
        : child.getMinIntrinsicHeight(math.max(0, width - padding.horizontal)) +
            padding.vertical;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final RenderBox? child = this.child;
    return child == null
        ? 0.0
        : child.getMinIntrinsicWidth(double.infinity) + padding.horizontal;
  }

  Size _computeSize(BoxConstraints constraints, ChildLayouter layoutChild) {
    final RenderBox? child = this.child;
    if (child == null) {
      return Size.zero;
    }
    layoutChild(child, constraints.widthConstraints().deflate(padding));
    return constraints.biggest;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _computeSize(constraints, ChildLayoutHelper.dryLayoutChild);

  @override
  void performLayout() {
    final RenderBox? child = this.child;
    if (child == null) {
      this.size = constraints.smallest;
      return;
    }
    final Size size =
        this.size = _computeSize(constraints, ChildLayoutHelper.layoutChild);
    final Size childSize = child.size;

    assert(padding.isNonNegative);
    assert(titleAlignment.y == 1.0);
    // yAdjustement is the minimum additional y offset to shift the child in
    // the visible vertical space when AppBar is fully expanded. The goal is to
    // prevent the expanded title from being clipped when the expanded title
    // widget + the bottom padding is too tall to fit in the flexible space (the
    // top padding is basically ignored since the expanded title is
    // bottom-aligned).
    final double yAdjustement = clampDouble(
        childSize.height + padding.bottom - maxExtent, 0, padding.bottom);
    final double offsetY =
        size.height - childSize.height - padding.bottom + yAdjustement;
    final double offsetX = (titleAlignment.x + 1) /
            2 *
            (size.width - padding.horizontal - childSize.width) +
        padding.left;

    final BoxParentData childParentData = child.parentData! as BoxParentData;
    childParentData.offset = Offset(offsetX, offsetY);
  }
}

mixin _ScrollUnderFlexibleConfig {
  TextStyle? get collapsedTextStyle;
  TextStyle? get expandedTextStyle;
  EdgeInsetsGeometry get expandedTitlePadding;
}

// Hand coded defaults based on Material Design 2.
class _AppBarDefaultsM2 extends AppBarTheme {
  _AppBarDefaultsM2(this.context)
      : super(
          elevation: 4.0,
          shadowColor: const Color(0xFF000000),
          titleSpacing: NavigationToolbar.kMiddleSpacing,
          toolbarHeight: kToolbarHeight,
        );

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;

  @override
  Color? get backgroundColor =>
      _colors.brightness == Brightness.dark ? _colors.surface : _colors.primary;

  @override
  Color? get foregroundColor => _colors.brightness == Brightness.dark
      ? _colors.onSurface
      : _colors.onPrimary;

  @override
  IconThemeData? get iconTheme => _theme.iconTheme;

  @override
  TextStyle? get toolbarTextStyle => _theme.textTheme.bodyMedium;

  @override
  TextStyle? get titleTextStyle => _theme.textTheme.titleLarge;
}

// BEGIN GENERATED TOKEN PROPERTIES - AppBar

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _AppBarDefaultsM3 extends AppBarTheme {
  _AppBarDefaultsM3(this.context)
      : super(
          elevation: 0.0,
          scrolledUnderElevation: 3.0,
          titleSpacing: NavigationToolbar.kMiddleSpacing,
          toolbarHeight: 64.0,
        );

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;
  late final TextTheme _textTheme = _theme.textTheme;

  @override
  Color? get backgroundColor => _colors.surface;

  @override
  Color? get foregroundColor => _colors.onSurface;

  @override
  Color? get shadowColor => Colors.transparent;

  @override
  Color? get surfaceTintColor => _colors.surfaceTint;

  @override
  IconThemeData? get iconTheme => IconThemeData(
        color: _colors.onSurface,
        size: 24.0,
      );

  @override
  IconThemeData? get actionsIconTheme => IconThemeData(
        color: _colors.onSurfaceVariant,
        size: 24.0,
      );

  @override
  TextStyle? get toolbarTextStyle => _textTheme.bodyMedium;

  @override
  TextStyle? get titleTextStyle => _textTheme.titleLarge;
}

// Variant configuration
class _MediumScrollUnderFlexibleConfig with _ScrollUnderFlexibleConfig {
  _MediumScrollUnderFlexibleConfig(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;
  late final TextTheme _textTheme = _theme.textTheme;

  static const double collapsedHeight = 64.0;
  static const double expandedHeight = 112.0;

  @override
  TextStyle? get collapsedTextStyle =>
      _textTheme.titleLarge?.apply(color: _colors.onSurface);

  @override
  TextStyle? get expandedTextStyle =>
      _textTheme.headlineSmall?.apply(color: _colors.onSurface);

  @override
  EdgeInsetsGeometry get expandedTitlePadding =>
      const EdgeInsets.fromLTRB(16, 0, 16, 20);
}

class _LargeScrollUnderFlexibleConfig with _ScrollUnderFlexibleConfig {
  _LargeScrollUnderFlexibleConfig(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;
  late final TextTheme _textTheme = _theme.textTheme;

  static const double collapsedHeight = 64.0;
  static const double expandedHeight = 152.0;

  @override
  TextStyle? get collapsedTextStyle =>
      _textTheme.titleLarge?.apply(color: _colors.onSurface);

  @override
  TextStyle? get expandedTextStyle =>
      _textTheme.headlineMedium?.apply(color: _colors.onSurface);

  @override
  EdgeInsetsGeometry get expandedTitlePadding =>
      const EdgeInsets.fromLTRB(16, 0, 16, 28);
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.leading,
    required this.automaticallyImplyLeading,
    required this.title,
    required this.actions,
    required this.flexibleSpace,
    required this.bottom,
    required this.elevation,
    required this.scrolledUnderElevation,
    required this.shadowColor,
    required this.surfaceTintColor,
    required this.forceElevated,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconTheme,
    required this.actionsIconTheme,
    required this.primary,
    required this.centerTitle,
    required this.excludeHeaderSemantics,
    required this.titleSpacing,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.topPadding,
    required this.floating,
    required this.pinned,
    required this.vsync,
    required this.snapConfiguration,
    required this.stretchConfiguration,
    required this.showOnScreenConfiguration,
    required this.shape,
    required this.toolbarHeight,
    required this.leadingWidth,
    required this.toolbarTextStyle,
    required this.titleTextStyle,
    required this.systemOverlayStyle,
    required this.forceMaterialTransparency,
    required this.clipBehavior,
    required this.variant,
  })  : assert(primary || topPadding == 0.0),
        _bottomHeight = bottom?.preferredSize.height ?? 0.0;

  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final double? scrolledUnderElevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final bool forceElevated;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final bool primary;
  final bool? centerTitle;
  final bool excludeHeaderSemantics;
  final double? titleSpacing;
  final double? expandedHeight;
  final double collapsedHeight;
  final double topPadding;
  final bool floating;
  final bool pinned;
  final ShapeBorder? shape;
  final double? toolbarHeight;
  final double? leadingWidth;
  final TextStyle? toolbarTextStyle;
  final TextStyle? titleTextStyle;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final double _bottomHeight;
  final bool forceMaterialTransparency;
  final Clip? clipBehavior;
  final _SliverAppVariant variant;

  @override
  double get minExtent => collapsedHeight;

  @override
  double get maxExtent => math.max(
      topPadding +
          (expandedHeight ?? (toolbarHeight ?? kToolbarHeight) + _bottomHeight),
      minExtent);

  @override
  final TickerProvider vsync;

  @override
  final FloatingHeaderSnapConfiguration? snapConfiguration;

  @override
  final OverScrollHeaderStretchConfiguration? stretchConfiguration;

  @override
  final PersistentHeaderShowOnScreenConfiguration? showOnScreenConfiguration;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double visibleMainHeight = maxExtent - shrinkOffset - topPadding;
    final double extraToolbarHeight = math.max(
        minExtent -
            _bottomHeight -
            topPadding -
            (toolbarHeight ?? kToolbarHeight),
        0.0);
    final double visibleToolbarHeight =
        visibleMainHeight - _bottomHeight - extraToolbarHeight;

    final bool isScrolledUnder = overlapsContent ||
        forceElevated ||
        (pinned && shrinkOffset > maxExtent - minExtent);
    final bool isPinnedWithOpacityFade =
        pinned && floating && bottom != null && extraToolbarHeight == 0.0;
    final double toolbarOpacity = !pinned || isPinnedWithOpacityFade
        ? clampDouble(
            visibleToolbarHeight / (toolbarHeight ?? kToolbarHeight), 0.0, 1.0)
        : 1.0;
    final Widget? effectiveTitle = switch (variant) {
      _SliverAppVariant.small => title,
      _SliverAppVariant.medium || _SliverAppVariant.large => AnimatedOpacity(
          opacity: isScrolledUnder ? 1 : 0,
          duration: const Duration(milliseconds: 500),
          curve: const Cubic(0.2, 0.0, 0.0, 1.0),
          child: title,
        ),
    };

    final Widget appBar = FlexibleSpaceBar.createSettings(
      minExtent: minExtent,
      maxExtent: maxExtent,
      currentExtent: math.max(minExtent, maxExtent - shrinkOffset),
      toolbarOpacity: toolbarOpacity,
      isScrolledUnder: isScrolledUnder,
      hasLeading: leading != null || automaticallyImplyLeading,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: StylingHelper.sigma_blurry,
            sigmaY: StylingHelper.sigma_blurry,
          ),
          child: AppBar(
            clipBehavior: clipBehavior,
            leading: leading,
            automaticallyImplyLeading: automaticallyImplyLeading,
            title: effectiveTitle,
            actions: actions,
            flexibleSpace: (title == null &&
                    flexibleSpace != null &&
                    !excludeHeaderSemantics)
                ? Semantics(
                    header: true,
                    child: flexibleSpace,
                  )
                : flexibleSpace,
            bottom: bottom,
            elevation: isScrolledUnder ? elevation : 0.0,
            scrolledUnderElevation: scrolledUnderElevation,
            shadowColor: shadowColor,
            surfaceTintColor: surfaceTintColor,
            backgroundColor: StylingHelper.isApple(context)
                ? backgroundColor
                : (backgroundColor ??
                        Theme.of(context).appBarTheme.backgroundColor)
                    ?.withOpacity(1.0),
            foregroundColor: foregroundColor,
            iconTheme: iconTheme,
            actionsIconTheme: actionsIconTheme,
            primary: primary,
            centerTitle: centerTitle,
            excludeHeaderSemantics: excludeHeaderSemantics,
            titleSpacing: titleSpacing,
            shape: shape,
            toolbarOpacity: toolbarOpacity,
            bottomOpacity: pinned
                ? 1.0
                : clampDouble(visibleMainHeight / _bottomHeight, 0.0, 1.0),
            toolbarHeight: toolbarHeight,
            leadingWidth: leadingWidth,
            toolbarTextStyle: toolbarTextStyle,
            titleTextStyle: titleTextStyle,
            systemOverlayStyle: systemOverlayStyle,
            forceMaterialTransparency: forceMaterialTransparency,
          ),
        ),
      ),
    );
    return appBar;
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return leading != oldDelegate.leading ||
        automaticallyImplyLeading != oldDelegate.automaticallyImplyLeading ||
        title != oldDelegate.title ||
        actions != oldDelegate.actions ||
        flexibleSpace != oldDelegate.flexibleSpace ||
        bottom != oldDelegate.bottom ||
        _bottomHeight != oldDelegate._bottomHeight ||
        elevation != oldDelegate.elevation ||
        shadowColor != oldDelegate.shadowColor ||
        backgroundColor != oldDelegate.backgroundColor ||
        foregroundColor != oldDelegate.foregroundColor ||
        iconTheme != oldDelegate.iconTheme ||
        actionsIconTheme != oldDelegate.actionsIconTheme ||
        primary != oldDelegate.primary ||
        centerTitle != oldDelegate.centerTitle ||
        titleSpacing != oldDelegate.titleSpacing ||
        expandedHeight != oldDelegate.expandedHeight ||
        topPadding != oldDelegate.topPadding ||
        pinned != oldDelegate.pinned ||
        floating != oldDelegate.floating ||
        vsync != oldDelegate.vsync ||
        snapConfiguration != oldDelegate.snapConfiguration ||
        stretchConfiguration != oldDelegate.stretchConfiguration ||
        showOnScreenConfiguration != oldDelegate.showOnScreenConfiguration ||
        forceElevated != oldDelegate.forceElevated ||
        toolbarHeight != oldDelegate.toolbarHeight ||
        leadingWidth != oldDelegate.leadingWidth ||
        toolbarTextStyle != oldDelegate.toolbarTextStyle ||
        titleTextStyle != oldDelegate.titleTextStyle ||
        systemOverlayStyle != oldDelegate.systemOverlayStyle ||
        forceMaterialTransparency != oldDelegate.forceMaterialTransparency;
  }

  @override
  String toString() {
    return '${describeIdentity(this)}(topPadding: ${topPadding.toStringAsFixed(1)}, bottomHeight: ${_bottomHeight.toStringAsFixed(1)}, ...)';
  }
}
