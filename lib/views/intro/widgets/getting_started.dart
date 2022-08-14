import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/animator/fader.dart';
import 'package:obs_blade/shared/general/base/constrained_box.dart';
import 'package:obs_blade/stores/views/intro.dart';

import '../../../utils/styling_helper.dart';

class GettingStarted extends StatelessWidget {
  const GettingStarted({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseConstrainedBox(
      child: Column(
        children: [
          Fader(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeIn,
            child: Image.asset(
              StylingHelper.brightnessAwareOBSLogo(context),
            ),
          ),
          const Fader(
              duration: Duration(milliseconds: 1000),
              delay: Duration(milliseconds: 500),
              curve: Curves.easeIn,
              child: Text('Intro Text')),
          Fader(
            duration: const Duration(milliseconds: 1000),
            delay: const Duration(milliseconds: 1000),
            curve: Curves.easeIn,
            child: ElevatedButton(
              child: const Text('Start'),
              onPressed: () => GetIt.instance<IntroStore>()
                  .setStage(IntroStage.VersionSelection),
            ),
          ),
        ],
      ),
    );
  }
}
