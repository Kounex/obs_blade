import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/adaptive_text_field.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'question_mark_tooltip.dart';

class ConnectHostInput extends StatefulWidget {
  final CustomValidationTextEditingController hostIP;
  final CustomValidationTextEditingController hostDomain;
  final bool manual;
  final bool domainMode;
  final String protocolScheme;
  final TargetPlatform? platform;

  final bool showHelp;

  final void Function(bool? domainMode)? onChangeMode;
  final void Function(String? protocolScheme)? onChangeProtocolScheme;

  const ConnectHostInput({
    Key? key,
    required this.hostIP,
    required this.hostDomain,
    required this.manual,
    required this.domainMode,
    this.protocolScheme = 'wss://',
    this.showHelp = true,
    this.onChangeMode,
    this.onChangeProtocolScheme,
    this.platform,
  });

  @override
  State<ConnectHostInput> createState() => _ConnectHostInputState();
}

class _ConnectHostInputState extends State<ConnectHostInput> {
  final GlobalKey<FormFieldState> _hostFormFieldKey =
      GlobalKey<FormFieldState>();

  final FocusNode _inputFocusNode = FocusNode();

  bool _dropdownTapped = false;

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus) {
        setState(() {});
      } else {
        if (!_dropdownTapped) {
          setState(() {});
        }
        _dropdownTapped = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BaseAdaptiveTextField(
          key: _hostFormFieldKey,
          controller: this.widget.domainMode
              ? this.widget.hostDomain
              : this.widget.hostIP,
          focusNode: _inputFocusNode,
          autocorrect: false,
          readOnly: !this.widget.manual,
          enabled: this.widget.manual,
          platform: this.widget.platform,
          errorPaddingAlways: true,
          style: const TextStyle(
            fontFeatures: [
              FontFeature.tabularFigures(),
            ],
          ),
          prefix: this.widget.manual &&
                  this.widget.domainMode &&
                  (_inputFocusNode.hasFocus ||
                      this.widget.hostDomain.text.isNotEmpty)
              ? Padding(
                  padding: EdgeInsets.only(
                      left: StylingHelper.isApple(context,
                              platform: this.widget.platform)
                          ? 8.0
                          : 0),
                  child: SizedBox(
                    height: StylingHelper.isApple(context,
                            platform: this.widget.platform)
                        ? null
                        : 20.0,
                    child: Material(
                      type: MaterialType.transparency,
                      child: DropdownButton<String>(
                        value: this.widget.protocolScheme,
                        isDense: true,
                        underline: const SizedBox(),
                        alignment: Alignment.center,
                        items: const [
                          DropdownMenuItem(
                            value: 'wss://',
                            child: Text('wss://'),
                          ),
                          DropdownMenuItem(
                            value: 'ws://',
                            child: Text('ws://'),
                          ),
                          DropdownMenuItem(
                            value: '',
                            child: Text('-'),
                          ),
                        ],
                        onTap: () => _dropdownTapped = true,
                        onChanged: (scheme) {
                          this
                              .widget
                              .onChangeProtocolScheme
                              ?.call(scheme ?? 'wss://');
                          _inputFocusNode.requestFocus();
                        },
                      ),
                    ),
                  ),
                )
              : null,
          labelText:
              !this.widget.domainMode ? 'IP Address (internal)' : 'Hostname',
          placeholder:
              !this.widget.domainMode ? '192.168.178.10' : 'obs-stream.com',
          bottom: this.widget.manual
              ? Row(
                  children: [
                    Expanded(
                      child: CupertinoSlidingSegmentedControl<bool>(
                        groupValue: this.widget.domainMode,
                        children: const {
                          false: Text('IP'),
                          true: Text('Domain'),
                        },
                        onValueChanged: (domainMode) {
                          FocusManager.instance.primaryFocus?.unfocus();
                          this.widget.onChangeMode?.call(domainMode ?? true);
                          // homeStore.typedInConnection.host = '';
                          // _hostFormFieldKey.currentState?.reset();
                          // this.widget.host.clear();
                        },
                      ),
                    ),
                    if (this.widget.showHelp) ...[
                      const SizedBox(width: 12.0),
                      const QuestionMarkTooltip(
                        message:
                            'IP mode expects an IP address and is using "ws://" as the protocol scheme (standard way to connect to a local OBS instance), while Domain mode does not have any input validation and you can select the protocol scheme yourself.\n\n"-" means I provide no protocol scheme and you have to add it yourself. I highly recommend making use of "ws://" or "wss://" though since it\'s usually what WebSockets use.',
                      ),
                    ],
                    // const SizedBox(width: 12.0),
                  ],
                )
              : const SizedBox(),
          // onChanged: (host) => homeStore.typedInConnection.host = host,
        ),
      ],
    );
  }
}
