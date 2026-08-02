import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/animator/selectable_box.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/card.dart';
import 'package:obs_blade/shared/general/base/constrained_box.dart';
import 'package:obs_blade/shared/general/question_mark_tooltip.dart';
import 'package:obs_blade/stores/views/intro.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'intro_primary_button.dart';

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
          StaggeredEntrance(
            index: 0,
            child: Text(
              'First of all, please select the version of OBS you are using. This will determine what you need to do in order to use this app with your OBS instance!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          StaggeredEntrance(
            index: 1,
            child: BaseCard(
              paintBorder: true,
              topPadding: AppSpacing.xl,
              borderColor: Theme.of(context).dividerColor.withOpacity(0.2),
              title: 'Version',
              trailingTitleWidget: const QuestionMarkTooltip(
                  message:
                      'Where to find the version of your OBS instance depends on your operating system:\n\nWindows / Linux:\nHelp -> About\n\nmacOS:\nOBS -> About OBS'),
              paddingChild: const EdgeInsets.symmetric(
                vertical: AppSpacing.xl,
                horizontal: AppSpacing.lg,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  children: [
                    _VersionCard(
                      width: constraints.maxWidth,
                      selected: _nextStage == IntroStage.TwentyEightParty,
                      version: '28.X',
                      description: 'and above',
                      onTap: () => setState(
                          () => _nextStage = IntroStage.TwentyEightParty),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _VersionCard(
                      width: constraints.maxWidth,
                      selected: _nextStage == IntroStage.InstallationSlides,
                      version: '27.X',
                      description: 'and below',
                      onTap: () => setState(
                          () => _nextStage = IntroStage.InstallationSlides),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            index: 2,
            child: IntroPrimaryButton(
              onPressed: _nextStage != null
                  ? () => GetIt.instance<IntroStore>().setStage(_nextStage!)
                  : null,
              text: 'Next',
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero selection card for the OBS version choice - physical press feedback
/// ([Pressable]) while the fill / border / check animations stay on the
/// existing [SelectableBox] API
class _VersionCard extends StatelessWidget {
  final double width;

  final bool selected;
  final String version;
  final String description;

  final void Function() onTap;

  const _VersionCard({
    required this.width,
    required this.selected,
    required this.version,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: true,
      onTap: this.onTap,
      child: SelectableBox(
        boxAnimation: AppMotion.medium,
        height: 88.0,
        width: this.width,
        selected: this.selected,

        /// Unselected fill sits one luminance step above the surrounding
        /// card instead of dropping back to the scaffold color (which read
        /// as a hole punched into the card)
        colorUnselected: StylingHelper.lightenDarkenColor(
          Theme.of(context).cardColor,
          8,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      this.version,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      this.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(
                            color: this.selected ? Colors.white70 : null,
                          ),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: this.selected ? 1.0 : 0.0,
                duration: AppMotion.fast,
                curve: AppMotion.spring,
                child: const Icon(Icons.check_circle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
