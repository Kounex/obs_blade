import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/views/home.dart';

import '../../../../../shared/general/question_mark_tooltip.dart';
import '../../../../../utils/validation_helper.dart';

class ConnectHostInput extends StatefulWidget {
  final TextEditingController host;
  final bool manual;

  const ConnectHostInput({
    Key? key,
    required this.host,
    required this.manual,
  }) : super(key: key);

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
    HomeStore landingStore = GetIt.instance<HomeStore>();

    return Observer(builder: (_) {
      return Column(
        children: [
          TextFormField(
            key: _hostFormFieldKey,
            controller: this.widget.host,
            focusNode: _inputFocusNode,
            autocorrect: false,
            readOnly: !this.widget.manual,
            enabled: this.widget.manual,
            decoration: InputDecoration(
              prefix: this.widget.manual &&
                      landingStore.domainMode &&
                      (_inputFocusNode.hasFocus ||
                          this.widget.host.text.isNotEmpty)
                  ? SizedBox(
                      height: 18.0,
                      child: DropdownButton<String>(
                        value: landingStore.protocolScheme,
                        isDense: true,
                        underline: Container(),
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
                          landingStore.setProtocolScheme(scheme ?? 'wss://');
                          _inputFocusNode.requestFocus();
                        },
                      ),
                    )
                  : null,
              // prefixText: landingStore.domainMode ? 'wss://' : null,
              labelText: !landingStore.domainMode
                  ? 'IP Address (internal)'
                  : 'Hostname',
              hintText: !landingStore.domainMode
                  ? '192.168.178.10'
                  : 'obs-stream.com',
            ),
            validator: (text) =>
                ValidationHelper.minLengthValidator(text) ??
                (!landingStore.domainMode
                    ? ValidationHelper.ipValidator(text)
                    : null),
            onChanged: (host) => landingStore.typedInConnection.host = host,
          ),

          // const SizedBox(height: 6.0),
          this.widget.manual
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoSlidingSegmentedControl<bool>(
                          groupValue: landingStore.domainMode,
                          children: const {
                            false: Text('IP'),
                            true: Text('Domain'),
                          },
                          onValueChanged: (domainMode) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            landingStore.setDomainMode(domainMode ?? true);
                            _hostFormFieldKey.currentState?.reset();
                            this.widget.host.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      const QuestionMarkTooltip(
                        message:
                            'IP mode expects an IP address and is using "ws://" as the protocol scheme (standard way to connect to a local OBS instance), while Domain mode does not have any input validation and you can select the protocol scheme yourself.\n\n"-" means I provide no protocol scheme and you have to add it yourself. I highly suggest making use of "ws://" or "wss://" though since it\'s usually what WebSockets use.',
                      ),
                      // const SizedBox(width: 12.0),
                    ],
                  ),
                )
              : Container(),
        ],
      );
    });
  }
}
