import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../utils/styling_helper.dart';
import 'app_glass.dart';

/// Which edge of a floating bar faces the scrollable content - the 1px
/// specular gradient line sits on that edge (token-delta §3)
enum GlassBarEdge { top, bottom }

/// The single surface every floating bar (nav bars, tab bar) goes through,
/// driven by the [AppGlass] theme extension: backdrop blur (sigma) + bar
/// slot color at glass alpha + the specular edge line.
///
/// Fallbacks (token-delta §3), one code path:
/// - non-Apple platforms: no [BackdropFilter] (live blur over platform
///   views is a known jank path) - near-opaque solid at [fallbackAlpha]
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

  /// Alpha of the solid (no-blur) fallback path
  static const double fallbackAlpha = 0.9;

  @override
  Widget build(BuildContext context) {
    final AppGlass glass = Theme.of(context).extension<AppGlass>()!;
    final bool apple = StylingHelper.isApple(context);
    final bool trueDark =
        Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final bool blur = apple && !trueDark;

    Color barColor = this.color ?? glass.barColor;
    if (!apple) {
      barColor = barColor.withValues(alpha: fallbackAlpha);
    }

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
