import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'app_glass.dart';

/// Which edge of a floating bar faces the scrollable content - the 1px
/// specular gradient line sits on that edge (token-delta §3)
enum GlassBarEdge { top, bottom }

/// Resolves the [AppGlass] tokens, deriving them from the theme's bar slot
/// when the extension isn't registered (bare test themes)
AppGlass appGlassOf(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  return theme.extension<AppGlass>() ??
      AppGlass.forBar(
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
      );
}

/// The single surface every floating bar (nav bars, tab bar) goes through,
/// driven by the [AppGlass] theme extension: backdrop blur (sigma) + bar
/// slot color at glass alpha + the specular edge line.
///
/// Same glass on every platform - Android blurs too (the chat WebView
/// renders through texture-layer composition by default, which a
/// [BackdropFilter] samples like any other layer).
///
/// Fallbacks (token-delta §3), one code path:
/// - True Dark scaffold (#000): blur contributes nothing - specular +
///   alpha only
/// - reduced transparency: Flutter exposes no reduce-transparency
///   accessibility flag (checked Flutter 3.44 `MediaQuery` /
///   `AccessibilityFeatures`) - when the SDK surfaces one it folds into
///   the same `_blur` condition here
///
/// The `AppGlass.saturate` garnish is plumbed through the token but not
/// applied: `dart:ui` `ImageFilter` has no color-filter pass (blur /
/// geometric matrix / compose only), so a backdrop saturation pass cannot
/// be expressed without a custom fragment shader.
class GlassBar extends StatelessWidget {
  final Widget child;

  /// Edge facing the content - the specular line renders there
  final GlassBarEdge contentEdge;

  /// Overrides the bar color (already alpha'd) - defaults to
  /// [AppGlass.barColor] (the appBar slot); the tab bar passes its tabBar
  /// slot instead
  final Color? color;

  const GlassBar({
    super.key,
    required this.child,
    this.contentEdge = GlassBarEdge.bottom,
    this.color,
  });

  /// Shared navbar min content height (token-delta §3) - holds even when
  /// no action slots are populated
  static const double minContentHeight = 55.0;

  @override
  Widget build(BuildContext context) {
    final AppGlass glass = appGlassOf(context);
    final bool blur =
        Theme.of(context).scaffoldBackgroundColor != Colors.black;
    final Color barColor = this.color ?? glass.barColor;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: blur
              ? ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: glass.sigma,
                      sigmaY: glass.sigma,
                    ),
                    child: ColoredBox(color: barColor),
                  ),
                )
              : ColoredBox(color: barColor),
        ),
        this.child,
        Positioned(
          top: this.contentEdge == GlassBarEdge.top ? 0.0 : null,
          bottom: this.contentEdge == GlassBarEdge.bottom ? 0.0 : null,
          left: 0.0,
          right: 0.0,
          height: 1.0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: this.contentEdge == GlassBarEdge.bottom
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                end: this.contentEdge == GlassBarEdge.bottom
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: glass.specularOpacity),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
