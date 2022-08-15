import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/base/card.dart';
import 'package:obs_blade/stores/views/intro.dart';

class VersionSelection extends StatefulWidget {
  const VersionSelection({super.key});

  @override
  State<VersionSelection> createState() => _VersionSelectionState();
}

class _VersionSelectionState extends State<VersionSelection> {
  IntroStage? _nextStage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => setState(() => _nextStage = IntroStage.TwentyEightParty),
          child: BaseCard(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            constrainedAlignment: CrossAxisAlignment.center,
            paintBorder: _nextStage == IntroStage.TwentyEightParty,
            borderColor: _nextStage == IntroStage.TwentyEightParty
                ? Theme.of(context)
                    .switchTheme
                    .trackColor!
                    .resolve({MaterialState.selected})
                : null,
            child: const Text('OBS Version >= 28.X'),
          ),
        ),
        GestureDetector(
          onTap: () =>
              setState(() => _nextStage = IntroStage.InstallationSlides),
          child: BaseCard(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            constrainedAlignment: CrossAxisAlignment.center,
            paintBorder: _nextStage == IntroStage.InstallationSlides,
            borderColor: _nextStage == IntroStage.InstallationSlides
                ? Theme.of(context)
                    .switchTheme
                    .trackColor!
                    .resolve({MaterialState.selected})
                : null,
            child: const Text('OBS Version < 28.X'),
          ),
        ),
        ElevatedButton(
          onPressed: _nextStage != null
              ? () => GetIt.instance<IntroStore>().setStage(_nextStage!)
              : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}
