import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/animator/selectable_box.dart';
import 'package:obs_blade/shared/general/base/card.dart';
import 'package:obs_blade/shared/general/base/constrained_box.dart';
import 'package:obs_blade/shared/general/question_mark_tooltip.dart';
import 'package:obs_blade/shared/general/themed/cupertino_button.dart';
import 'package:obs_blade/stores/views/intro.dart';

class VersionSelection extends StatefulWidget {
  const VersionSelection({
    super.key,
  });

  @override
  State<VersionSelection> createState() => _VersionSelectionState();
}

class _VersionSelectionState extends State<VersionSelection> {
  IntroStage? _nextStage;

  @override
  Widget build(BuildContext context) {
    return BaseConstrainedBox(
      hasBasePadding: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'First of all, please select the version of OBS you are using. This will determine what you need to do in order to use this app with your OBS instance!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontSize: 18,
                ),
          ),
          BaseCard(
            paintBorder: true,
            topPadding: 32.0,
            bottomPadding: 18.0,
            borderColor: Theme.of(context).dividerColor.withOpacity(0.2),
            title: 'Version',
            trailingTitleWidget: const QuestionMarkTooltip(
                message:
                    'Where to find the version of your OBS instance depends on your operating system:\n\nWindows / Linux:\nHelp -> About\n\nmacOS:\nOBS -> About OBS'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SelectableBox(
                    colorUnselected: Theme.of(context).scaffoldBackgroundColor,
                    selected: _nextStage == IntroStage.TwentyEightParty,
                    text: '28.X and above',
                    onTap: () => setState(
                        () => _nextStage = IntroStage.TwentyEightParty),
                  ),
                  SelectableBox(
                    colorUnselected: Theme.of(context).scaffoldBackgroundColor,
                    selected: _nextStage == IntroStage.InstallationSlides,
                    text: '27.X and below',
                    onTap: () => setState(
                        () => _nextStage = IntroStage.InstallationSlides),
                  ),
                ],
              ),
            ),
          ),
          // GestureDetector(
          //   onTap: () =>
          //       setState(() => _nextStage = IntroStage.TwentyEightParty),
          //   child: BaseCard(
          //     backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          //     constrainedAlignment: CrossAxisAlignment.center,
          //     leftPadding: 0,
          //     rightPadding: 0,
          //     paintBorder: _nextStage == IntroStage.TwentyEightParty,
          //     borderColor: _nextStage == IntroStage.TwentyEightParty
          //         ? Theme.of(context)
          //             .switchTheme
          //             .trackColor!
          //             .resolve({MaterialState.selected})
          //         : null,
          //     title: 'OBS Version 28.X and above',
          //     titlePadding: const EdgeInsets.all(12),
          //     child: const Text('OBS Version >= 28.X'),
          //   ),
          // ),
          // GestureDetector(
          //   onTap: () =>
          //       setState(() => _nextStage = IntroStage.InstallationSlides),
          //   child: BaseCard(
          //     backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          //     constrainedAlignment: CrossAxisAlignment.center,
          //     leftPadding: 0,
          //     rightPadding: 0,
          //     paintBorder: _nextStage == IntroStage.InstallationSlides,
          //     borderColor: _nextStage == IntroStage.InstallationSlides
          //         ? Theme.of(context)
          //             .switchTheme
          //             .trackColor!
          //             .resolve({MaterialState.selected})
          //         : null,
          //     title: 'OBS version 27.X and below',
          //     titlePadding: const EdgeInsets.all(12),
          //     child: const Text('OBS Version < 28.X'),
          //   ),
          // ),
          ThemedCupertinoButton(
            onPressed: _nextStage != null
                ? () => GetIt.instance<IntroStore>().setStage(_nextStage!)
                : null,
            text: 'Next',
          ),
        ],
      ),
    );
  }
}
