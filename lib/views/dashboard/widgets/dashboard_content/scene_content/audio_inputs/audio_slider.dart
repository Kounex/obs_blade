import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/cupertino_number_text_field.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import '../../../../../../stores/shared/network.dart';
import '../../../../../../types/classes/api/input.dart';
import '../../../../../../types/enums/request_type.dart';
import '../../../../../../types/extensions/color.dart';
import '../../../../../../utils/network_helper.dart';
import '../animated_toggle_icon.dart';

class AudioSlider extends StatefulWidget {
  final Input input;

  const AudioSlider({
    super.key,
    required this.input,
  });

  @override
  State<AudioSlider> createState() => _AudioSliderState();
}

class _AudioSliderState extends State<AudioSlider> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController(text: this.widget.input.syncOffset.toString());
  }

  @override
  void didUpdateWidget(covariant AudioSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        this.widget.input.syncOffset.toString() != _controller.text) {
      _controller.text = this.widget.input.syncOffset.toString();
    }
  }

  double _transformMulToLevel(double mul) {
    double level = 0.33 * (log(mul) / log(10)) + 1;
    return level < 0
        ? 0
        : level > 1
            ? 1
            : level;
  }

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = GetIt.instance<NetworkStore>();
    ThemeData theme = Theme.of(context);

    /// Meter gradient derived from the theme highlight (dB fill)
    Color highlight = theme.colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpacing.md, right: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  this.widget.input.inputName != null
                      ? this.widget.input.inputName!
                      : '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              HiveBuilder<dynamic>(
                hiveKey: HiveKeys.Settings,
                rebuildKeys: const [
                  SettingsKeys.ExposeInputAudioSyncOffset,
                ],
                builder: (context, settingsBox, child) => AnimatedSwitcher(
                  duration: AppMotion.medium,
                  child: settingsBox.get(
                    SettingsKeys.ExposeInputAudioSyncOffset.name,
                    defaultValue: false,
                  )
                      ? CupertinoNumberTextField(
                          width: 112.0,
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLength: 6,
                          negativeAllowed: true,
                          minValue: -950,
                          maxValue: 20000,
                          suffix: 'ms',
                          onDone: () => NetworkHelper.makeRequest(
                            GetIt.instance<NetworkStore>()
                                .activeSession!
                                .socket,
                            RequestType.SetInputAudioSyncOffset,
                            {
                              'inputName': this.widget.input.inputName,
                              'inputAudioSyncOffset':
                                  int.tryParse(_controller.text) ?? 0
                            },
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedOpacity(
            duration: AppMotion.medium,
            opacity: this.widget.input.inputMuted ? 0.35 : 1.0,
            child: LayoutBuilder(
              builder: (_, constraints) => SizedBox(
                height: 12.0,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 6.0,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.disabledColor.withValues(alpha: 0.6),
                        borderRadius: AppRadius.pill,
                      ),
                    ),
                    if (this.widget.input.inputLevelsMul != null &&
                        this.widget.input.inputLevelsMul!.isNotEmpty &&
                        this.widget.input.inputLevelsMul!.first.current! > 0)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        height: 6.0,
                        width: constraints.maxWidth *
                            _transformMulToLevel(this
                                .widget
                                .input
                                .inputLevelsMul!
                                .first
                                .current!),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.pill,
                          gradient: LinearGradient(
                            colors: [
                              highlight.darken(25),
                              highlight.lighten(10),
                            ],
                          ),
                        ),
                      ),
                    if (this.widget.input.inputLevelsMul != null &&
                        this.widget.input.inputLevelsMul!.isNotEmpty &&
                        this.widget.input.inputLevelsMul!.first.average! > 0)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        left: constraints.maxWidth *
                            _transformMulToLevel(this
                                .widget
                                .input
                                .inputLevelsMul!
                                .first
                                .average!),
                        child: Container(
                          height: 12.0,
                          width: 2.0,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface,
                            borderRadius: AppRadius.pill,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Pressable(
                haptic: true,
                onTap: () => NetworkHelper.makeRequest(
                  networkStore.activeSession!.socket,
                  RequestType.SetInputMute,
                  {
                    'inputName': this.widget.input.inputName,
                    'inputMuted': !this.widget.input.inputMuted
                  },
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: AnimatedToggleIcon(
                    icon: this.widget.input.inputMuted
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: this.widget.input.inputMuted
                        ? theme.extension<AppStatusColors>()!.recording
                        : theme.buttonTheme.colorScheme!.primary,
                  ),
                ),
              ),
              Expanded(
                child: AnimatedOpacity(
                  duration: AppMotion.medium,
                  opacity: this.widget.input.inputMuted ? 0.35 : 1.0,
                  child: Slider(
                    min: 0.0,
                    max: 1.0,
                    value: (this.widget.input.inputVolumeMul ?? 0.0),

                    /// Highlight (not the red accent) for the active track -
                    /// red stays reserved for the muted-state affordance
                    activeColor: theme.colorScheme.secondary,
                    onChanged: (volume) => NetworkHelper.makeRequest(
                        networkStore.activeSession!.socket,
                        RequestType.SetInputVolume, {
                      'inputName': this.widget.input.inputName,
                      'inputVolumeMul': volume,
                    }),
                  ),
                ),
              ),
              SizedBox(
                width: 64.0,
                child: AnimatedOpacity(
                  duration: AppMotion.medium,
                  opacity: this.widget.input.inputMuted ? 0.5 : 1.0,
                  child: Text(
                    ((((this.widget.input.inputVolumeMul ?? 0.0) * 100)
                                .toInt()) /
                            100)
                        .toString()
                        .padRight(4, '0'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall!.copyWith(
                      fontFeatures: kTabularFigures,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
