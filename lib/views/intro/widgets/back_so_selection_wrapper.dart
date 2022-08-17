import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/views/intro.dart';

import '../../../shared/general/themed/cupertino_button.dart';

class BackToSelectionWrapper extends StatelessWidget {
  final Widget? child;

  const BackToSelectionWrapper({
    Key? key,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        this.child ?? const SizedBox(),
        Positioned(
          top: MediaQuery.of(context).viewPadding.top,
          left: 0,
          child: ThemedCupertinoButton(
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.chevron_left,
                  color: Theme.of(context).cupertinoOverrideTheme!.primaryColor,
                ),
                const Text('Version Selection')
              ],
            ),
            onPressed: () => GetIt.instance<IntroStore>()
                .setStage(IntroStage.VersionSelection),
          ),
        ),
      ],
    );
  }
}
