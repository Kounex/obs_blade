import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/views/intro.dart';

import '../../../shared/general/themed/cupertino_button.dart';

class BackToSelectionWrapper extends StatelessWidget {
  final Widget? child;

  const BackToSelectionWrapper({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.paddingOf(context).top),
        ThemedCupertinoButton(
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
        Expanded(
          child: this.child ?? const SizedBox(),
        ),
      ],
    );
  }
}
