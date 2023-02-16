import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    Key? key,
    this.title,
    this.content,
    this.dialogWidth = 420.0,
    this.contentPadding,
    this.paddingTop,
    this.paddingRight,
    this.paddingBottom,
    this.paddingLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32.0),
          width: this.dialogWidth,
          child: CupertinoPopupSurface(
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
                                  left:
                                      this.paddingRight ?? _kDialogEdgePadding,
                                  right:
                                      this.paddingLeft ?? _kDialogEdgePadding,
                                  bottom:
                                      this.paddingBottom ?? _kDialogEdgePadding,
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
    );
  }
}
