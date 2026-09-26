import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/icon_button.dart';
import 'package:obs_blade/shared/general/cupertino_number_text_field.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import '../../../../../../stores/shared/network.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../types/classes/api/input.dart';
import '../../../../../../types/enums/request_type.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/network_helper.dart';
import '../animated_toggle_icon.dart';
import 'audio_settings_sheet.dart';

class AudioSlider extends StatefulWidget {
  final Input input;

  const AudioSlider({super.key, required this.input});

  @override
  State<AudioSlider> createState() => _AudioSliderState();
}

class _AudioSliderState extends State<AudioSlider> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  /// Peak-hold tick (meter): pins to the latest level rise, holds for
  /// [_peakHoldFor], then steps back down to the live level - the tick's
  /// AnimatedPositioned smooths each step
  double _peakLevel = 0.0;
  double _lastLevel = 0.0;
  Timer? _peakHoldTimer;
  Timer? _peakDecayTimer;

  static const Duration _peakHoldFor = Duration(milliseconds: 500);
  static const double _peakDecayStep = 0.12;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: this.widget.input.syncOffset.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant AudioSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        this.widget.input.syncOffset.toString() != _controller.text) {
      _controller.text = this.widget.input.syncOffset.toString();
    }
    _trackPeak(_currentLevel());
  }

  @override
  void dispose() {
    _peakHoldTimer?.cancel();
    _peakDecayTimer?.cancel();
    super.dispose();
  }

  void _trackPeak(double level) {
    if (level >= _peakLevel) {
      _peakLevel = level;
      _peakHoldTimer?.cancel();
      _peakDecayTimer?.cancel();
      _peakHoldTimer = Timer(_peakHoldFor, () {
        _peakDecayTimer = Timer.periodic(AppMotion.instant, (timer) {
          if (!this.mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            _peakLevel = max(_lastLevel, _peakLevel - _peakDecayStep);
          });
          if (_peakLevel <= _lastLevel) {
            timer.cancel();
          }
        });
      });
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

  double _currentLevel() =>
      (this.widget.input.inputLevelsMul != null &&
          this.widget.input.inputLevelsMul!.isNotEmpty &&
          this.widget.input.inputLevelsMul!.first.current! > 0)
      ? _transformMulToLevel(this.widget.input.inputLevelsMul!.first.current!)
      : 0.0;

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = GetIt.instance<NetworkStore>();
    ThemeData theme = Theme.of(context);
    final AppStatusColors statusColors = theme.extension<AppStatusColors>()!;

    /// Highlight (control slot) for the mute affordance
    Color highlight = theme.colorScheme.secondary;

    final double currentLevel = _currentLevel();
    _lastLevel = currentLevel;

    /// Near-clip (~-6dBFS and up) tips the meter into the warning-red `.hot`
    /// zone - the meter is the ratified rule-7 exception: semantic live
    /// green as a GRADIENT, never a flat fill
    final bool meterHot = currentLevel >= 0.9;

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md),
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
                rebuildKeys: const [SettingsKeys.ExposeInputAudioSyncOffset],
                builder: (context, settingsBox, child) => AnimatedSwitcher(
                  duration: AppMotion.medium,
                  child:
                      settingsBox.get(
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
                          onDone: () =>
                              GetIt.instance<DashboardStore>().sendMutation(
                                RequestType.SetInputAudioSyncOffset,
                                fields: {
                                  'inputName': this.widget.input.inputName,
                                  'inputAudioSyncOffset':
                                      int.tryParse(_controller.text) ?? 0,
                                },
                                label: 'Audio sync offset',
                              ),
                        )
                      : const SizedBox(),
                ),
              ),
              Semantics(
                button: true,
                label: 'Audio settings for ${this.widget.input.inputName}',
                excludeSemantics: true,
                child: Pressable(
                  onTap: this.widget.input.inputName == null
                      ? null
                      : () => ModalHandler.showBaseCupertinoBottomSheet(
                          context: context,
                          modalWidgetBuilder: (context, controller) =>
                              AudioSettingsSheet(
                                inputName: this.widget.input.inputName!,
                              ),
                        ),
                  child: SizedBox(
                    width: kBaseIconButtonMinHitArea,
                    height: kBaseIconButtonMinHitArea,
                    child: Center(
                      child: Icon(
                        CupertinoIcons.slider_horizontal_3,
                        size: 20.0,
                        color: theme.extension<AppTextColors>()!.textSecondary,
                      ),
                    ),
                  ),
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
                    if (currentLevel > 0)
                      AnimatedContainer(
                        duration: AppMotion.instant,
                        height: 6.0,
                        width: constraints.maxWidth * currentLevel,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.pill,
                          gradient: LinearGradient(
                            colors: meterHot
                                ? [
                                    statusColors.live.withValues(alpha: 0.75),
                                    statusColors.live.withValues(alpha: 0.75),
                                    statusColors.recording.withValues(
                                      alpha: 0.85,
                                    ),
                                  ]
                                : [
                                    statusColors.live.withValues(alpha: 0.55),
                                    statusColors.live.withValues(alpha: 0.90),
                                  ],
                            stops: meterHot ? const [0.0, 0.7, 1.0] : null,
                          ),
                        ),
                      ),
                    if (_peakLevel > 0)
                      AnimatedPositioned(
                        duration: AppMotion.fast,
                        left: constraints.maxWidth * _peakLevel,
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
              Semantics(
                button: true,
                toggled: !this.widget.input.inputMuted,
                label: this.widget.input.inputMuted
                    ? 'Unmute ${this.widget.input.inputName}'
                    : 'Mute ${this.widget.input.inputName}',
                excludeSemantics: true,
                child: Pressable(
                  haptic: true,
                  onTap: () => GetIt.instance<DashboardStore>().sendMutation(
                    RequestType.SetInputMute,
                    fields: {
                      'inputName': this.widget.input.inputName,
                      'inputMuted': !this.widget.input.inputMuted,
                    },
                    label: 'Audio mute',
                  ),
                  child: SizedBox(
                    width: kBaseIconButtonMinHitArea,
                    height: kBaseIconButtonMinHitArea,
                    child: Center(
                      child: AnimatedToggleIcon(
                        icon: this.widget.input.inputMuted
                            ? Icons.volume_off
                            : Icons.volume_up,

                        /// Control on-state = highlight; the muted off-state
                        /// drops to faint text (mock .mute.muted) - red is
                        /// reserved for recording/program status
                        color: this.widget.input.inputMuted
                            ? theme.extension<AppTextColors>()!.textTertiary
                            : highlight,
                      ),
                    ),
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

                    /// Screen readers announce a percentage, not the raw
                    /// 0..1 multiplier
                    semanticFormatterCallback: (value) =>
                        '${this.widget.input.inputName} volume ${(value * 100).round()} percent',

                    /// Track/fill/knob come from the sliderTheme (token-
                    /// delta §2 variant A: hairline track, highlight 55%
                    /// fill, neutral knob) - no per-widget color override
                    ///
                    /// Ticks stay fire-and-forget: the thumb is bound to
                    /// OBS-fed state and dragging must not block. The final
                    /// value is committed through the command-ack layer on
                    /// [Slider.onChangeEnd] - a failed commit re-reads the
                    /// confirmed volume (socket order guarantees the commit
                    /// wins over in-flight ticks)
                    onChanged: (volume) => NetworkHelper.sendRequest(
                      networkStore.activeSession!.socket,
                      RequestType.SetInputVolume,
                      {
                        'inputName': this.widget.input.inputName,
                        'inputVolumeMul': volume,
                      },
                    ),
                    onChangeEnd: (volume) =>
                        GetIt.instance<DashboardStore>().sendMutation(
                          RequestType.SetInputVolume,
                          fields: {
                            'inputName': this.widget.input.inputName,
                            'inputVolumeMul': volume,
                          },
                          label: 'Volume',
                        ),
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
