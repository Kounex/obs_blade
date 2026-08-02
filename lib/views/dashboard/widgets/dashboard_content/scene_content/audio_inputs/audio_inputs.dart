import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/divider.dart';
import '../../../../../../shared/general/nested_list_manager.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../placeholder_scene_item.dart';
import '../visibility_slide_wrapper.dart';
import 'audio_slider.dart';

class AudioInputs extends StatefulWidget {
  const AudioInputs({
    super.key,
  });

  @override
  _AudioInputsState createState() => _AudioInputsState();
}

class _AudioInputsState extends State<AudioInputs>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _controller = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Observer(
      builder: (context) => NestedScrollManager(
        parentScrollController:
            ModalRoute.of(context)!.settings.arguments as ScrollController,
        child: Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          child: ListView(
            controller: _controller,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            children: [
              const _AudioSectionHeader(label: 'Global'),
              Column(
                children: dashboardStore.globalInputs.isNotEmpty
                    ? dashboardStore.globalInputs
                        .map(
                          (globalInput) => VisibilitySlideWrapper(
                            input: globalInput,
                            child: AudioSlider(input: globalInput),
                          ),
                        )
                        .toList()
                    : [
                        const PlaceholderSceneItem(
                            text: 'No Global Audio source available...'),
                        const SizedBox(height: AppSpacing.md),
                      ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: BaseDivider(),
              ),
              const _AudioSectionHeader(label: 'Scene'),
              Column(
                children: dashboardStore.currentInputs.isNotEmpty
                    ? dashboardStore.currentInputs
                        .map(
                          (input) => VisibilitySlideWrapper(
                            input: input,
                            child: AudioSlider(input: input),
                          ),
                        )
                        .toList()
                    : [
                        const PlaceholderSceneItem(
                            text: 'No Audio source in this scene...')
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Caption-style section header (uppercase, letterspaced, theme-aware grey)
/// replacing the old bold + underlined centered labels
class _AudioSectionHeader extends StatelessWidget {
  final String label;

  const _AudioSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          this.label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).textTheme.bodySmall!.color,
              ),
        ),
      ),
    );
  }
}
