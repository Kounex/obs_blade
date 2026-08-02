import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../intro.dart';

class IntroSlide extends StatelessWidget {
  final String imagePath;
  final Widget child;

  const IntroSlide({
    super.key,
    required this.imagePath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: kIntroControlsBottomPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
                          .withOpacity(0.4),
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Image.asset(
                    this.imagePath,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
          ),
          StaggeredEntrance(
            index: 1,
            child: this.child,
          ),
        ],
      ),
    );
  }
}
