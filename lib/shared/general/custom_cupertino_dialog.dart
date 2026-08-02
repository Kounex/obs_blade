import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

const double _kDialogEdgePadding = 20.0;

class CustomCupertinoDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;

  final double dialogWidth;

  final EdgeInsetsGeometry? contentPadding;

  final double? paddingTop;
  final double? paddingRight;
  final double? paddingBottom;
  final double? paddingLeft;

  const CustomCupertinoDialog({
    super.key,
    this.title,
    this.content,
    this.dialogWidth = 420.0,
    this.contentPadding,
    this.paddingTop,
    this.paddingRight,
    this.paddingBottom,
    this.paddingLeft,
  });

  @override
  Widget build(BuildContext context) {
    /// Opaque themed surface at the design-system dialog radius
    /// ([AppRadius.lg]) - CupertinoPopupSurface hardcodes 13pt and
    /// exposes no override, and this matches [ThemeData.dialogTheme]
    final BorderRadius dialogRadius = BorderRadius.circular(AppRadius.lg);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32.0),
          width: this.dialogWidth,
          child: ClipRRect(
            borderRadius: dialogRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).dialogTheme.backgroundColor ??
                    Theme.of(context).cardColor,
                borderRadius: dialogRadius,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  this.title ?? const SizedBox(),
                  this.content != null
                      ? Flexible(
                          child: DefaultTextStyle(
                            style: Theme.of(context).textTheme.bodyLarge!,
                            textAlign: TextAlign.center,
                            child: Padding(
                              padding: this.contentPadding ??
                                  EdgeInsets.only(
                                    top: this.paddingTop ?? _kDialogEdgePadding,
                                    left: this.paddingRight ??
                                        _kDialogEdgePadding,
                                    right:
                                        this.paddingLeft ?? _kDialogEdgePadding,
                                    bottom: this.paddingBottom ??
                                        _kDialogEdgePadding,
                                  ),
                              child: this.content,
                            ),
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
