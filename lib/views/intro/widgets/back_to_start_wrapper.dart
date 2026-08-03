import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/intro.dart';

import '../../../shared/general/themed/cupertino_button.dart';

/// Back affordance from the intro slides to the Getting Started stage
class BackToStartWrapper extends StatelessWidget {
  final Widget? child;

  const BackToStartWrapper({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.paddingOf(context).top),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: StaggeredEntrance(
              index: 0,
              child: ThemedCupertinoButton(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.chevron_left,
                      color: Theme.of(context)
                          .cupertinoOverrideTheme!
                          .primaryColor,
                    ),
                    const Text('Getting Started'),
                  ],
                ),
                onPressed: () => GetIt.instance<IntroStore>()
                    .setStage(IntroStage.GettingStarted),
              ),
            ),
          ),
        ),
        Expanded(
          child: this.child ?? const SizedBox(),
        ),
      ],
    );
  }
}
