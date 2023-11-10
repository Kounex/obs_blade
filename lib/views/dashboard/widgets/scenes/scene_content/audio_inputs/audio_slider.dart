import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/cupertino_number_text_field.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import '../../../../../../stores/shared/network.dart';
import '../../../../../../types/classes/api/input.dart';
import '../../../../../../types/enums/request_type.dart';
import '../../../../../../utils/network_helper.dart';

class AudioSlider extends StatefulWidget {
  final Input input;

  const AudioSlider({
    Key? key,
    required this.input,
  }) : super(key: key);

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

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 12.0),
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
                ),
              ),
              HiveBuilder<dynamic>(
                hiveKey: HiveKeys.Settings,
                rebuildKeys: const [
                  SettingsKeys.ExposeInputAudioSyncOffset,
                ],
                builder: (context, settingsBox, child) => settingsBox.get(
                  SettingsKeys.ExposeInputAudioSyncOffset.name,
                  defaultValue: false,
                )
                    ? CupertinoNumberTextField(
                        width: 102.0,
                        controller: _controller,
                        focusNode: _focusNode,
                        suffix: 'ms',
                        onDone: (_) => NetworkHelper.makeRequest(
                          GetIt.instance<NetworkStore>().activeSession!.socket,
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
            ],
          ),
          const SizedBox(height: 12.0),
          LayoutBuilder(
            builder: (_, constraints) => Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  color: Theme.of(context).disabledColor,
                ),
                if (this.widget.input.inputLevelsMul != null &&
                    this.widget.input.inputLevelsMul!.isNotEmpty &&
                    this.widget.input.inputLevelsMul!.first.current! > 0)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    height: 4,
                    width: constraints.maxWidth *
                        _transformMulToLevel(
                            this.widget.input.inputLevelsMul!.first.current!),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                if (this.widget.input.inputLevelsMul != null &&
                    this.widget.input.inputLevelsMul!.isNotEmpty &&
                    this.widget.input.inputLevelsMul!.first.average! > 0)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: constraints.maxWidth *
                        _transformMulToLevel(
                            this.widget.input.inputLevelsMul!.first.average!),
                    child: Container(
                      height: 4,
                      width: 2,
                      color: Colors.black,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  this.widget.input.inputMuted
                      ? Icons.volume_off
                      : Icons.volume_up,
                  color: this.widget.input.inputMuted
                      ? CupertinoColors.destructiveRed
                      : Theme.of(context).buttonTheme.colorScheme!.primary,
                ),
                padding: const EdgeInsets.all(0.0),
                onPressed: () => NetworkHelper.makeRequest(
                  networkStore.activeSession!.socket,
                  RequestType.SetInputMute,
                  {
                    'inputName': this.widget.input.inputName,
                    'inputMuted': !this.widget.input.inputMuted
                  },
                ),
              ),
              Expanded(
                child: Slider(
                  min: 0.0,
                  max: 1.0,
                  value: (this.widget.input.inputVolumeMul ?? 0.0),
                  activeColor:
                      Theme.of(context).buttonTheme.colorScheme!.secondary,
                  onChanged: (volume) => NetworkHelper.makeRequest(
                      networkStore.activeSession!.socket,
                      RequestType.SetInputVolume, {
                    'inputName': this.widget.input.inputName,
                    'inputVolumeMul': volume,
                  }),
                ),
              ),
              Container(
                width: 64.0,
                padding: const EdgeInsets.only(right: 0.0),
                alignment: Alignment.center,
                child: Text(((((this.widget.input.inputVolumeMul ?? 0.0) * 100)
                            .toInt()) /
                        100)
                    .toString()
                    .padRight(4, '0')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
