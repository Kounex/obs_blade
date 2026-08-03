import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../intro.dart';

class IntroSlide extends StatelessWidget {
  /// Optional framed screenshot. When null the slide is copy-led (app tour).
  final String? imagePath;
  final Widget? leading;
  final Widget child;

  const IntroSlide({
    super.key,
    this.imagePath,
    this.leading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = this.imagePath != null;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: kIntroControlsBottomPadding,
      ),
      child: Column(
        mainAxisAlignment:
            hasImage ? MainAxisAlignment.end : MainAxisAlignment.center,
        children: [
          if (hasImage)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: StaggeredEntrance(
                  index: 0,

                  /// Framed screenshot - rounded corners + hairline border,
                  /// hugging the image (width-driven, so no dead bands
                  /// above / below the screenshot)
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.asset(
                      this.imagePath!,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
            )
          else if (this.leading != null) ...[
            StaggeredEntrance(
              index: 0,
              child: this.leading!,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          StaggeredEntrance(
            index: hasImage || this.leading != null ? 1 : 0,
            child: this.child,
          ),
        ],
      ),
    );
  }
}
