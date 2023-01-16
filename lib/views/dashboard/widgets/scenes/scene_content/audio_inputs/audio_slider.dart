import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../stores/shared/network.dart';
import '../../../../../../types/classes/api/input.dart';
import '../../../../../../types/enums/request_type.dart';
import '../../../../../../utils/network_helper.dart';

class AudioSlider extends StatelessWidget {
  final Input input;

  const AudioSlider({
    Key? key,
    required this.input,
  }) : super(key: key);

  double _transformMulToLevel(double mul) {
    double level = 0.3 * (log(0.9 * mul) / log(10)) + 1;
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
          Text(
            this.input.inputName != null ? this.input.inputName! : '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12.0),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: LayoutBuilder(
              builder: (_, constraints) => Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    color: Theme.of(context).disabledColor,
                  ),
                  if (this.input.inputLevelsMul != null &&
                      this.input.inputLevelsMul!.isNotEmpty &&
                      this.input.inputLevelsMul!.first.current! > 0)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      height: 4,
                      width: constraints.maxWidth *
                          _transformMulToLevel(
                              this.input.inputLevelsMul!.first.current!),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  if (this.input.inputLevelsMul != null &&
                      this.input.inputLevelsMul!.isNotEmpty &&
                      this.input.inputLevelsMul!.first.average! > 0)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      left: constraints.maxWidth *
                          _transformMulToLevel(
                              this.input.inputLevelsMul!.first.average!),
                      child: Container(
                        height: 4,
                        width: 2,
                        color: Colors.black,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  (this.input.inputMuted ?? true)
                      ? Icons.volume_off
                      : Icons.volume_up,
                  color: (this.input.inputMuted ?? true)
                      ? CupertinoColors.destructiveRed
                      : Theme.of(context).buttonTheme.colorScheme!.primary,
                ),
                padding: const EdgeInsets.all(0.0),
                onPressed: () => NetworkHelper.makeRequest(
                    networkStore.activeSession!.socket,
                    RequestType.SetInputMute, {
                  'inputName': this.input.inputName,
                  'inputMuted': !(this.input.inputMuted ?? true)
                }),
              ),
              Expanded(
                child: Slider(
                  min: 0.0,
                  max: 1.0,
                  value: (this.input.inputVolumeMul ?? 0.0),
                  activeColor:
                      Theme.of(context).buttonTheme.colorScheme!.secondary,
                  onChanged: (volume) => NetworkHelper.makeRequest(
                      networkStore.activeSession!.socket,
                      RequestType.SetInputVolume, {
                    'inputName': this.input.inputName,
                    'inputVolumeMul': volume,
                  }),
                ),
              ),
              Container(
                width: 48.0,
                padding: const EdgeInsets.only(right: 12.0),
                alignment: Alignment.center,
                child: Text(
                    ((((this.input.inputVolumeMul ?? 0.0) * 100).toInt()) / 100)
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
