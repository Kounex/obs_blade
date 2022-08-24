import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/views/home/widgets/connect_box/connect_form/connect_host_input.dart';

import '../../../../../models/connection.dart';
import '../../../../../shared/general/base/button.dart';
import '../../../../../shared/general/keyboard_number_header.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/home.dart';
import '../../../../../utils/validation_helper.dart';

class ConnectForm extends StatefulWidget {
  final Connection? connection;
  final bool manual;

  const ConnectForm({Key? key, this.connection, this.manual = false})
      : super(key: key);

  @override
  _ConnectFormState createState() => _ConnectFormState();
}

class _ConnectFormState extends State<ConnectForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _host;
  late TextEditingController _port;
  late TextEditingController _pw;

  final FocusNode _portFocusNode = FocusNode();

  bool _obscurePW = true;

  final StreamController<WebSocketCloseCode> _clodeCode = StreamController();

  @override
  void initState() {
    super.initState();

    _host = TextEditingController(text: this.widget.connection?.host);
    _port = TextEditingController(
        text: this.widget.connection?.port?.toString() ?? '');
    _pw = TextEditingController(text: this.widget.connection?.pw);
  }

  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = GetIt.instance<HomeStore>();
    NetworkStore networkStore = GetIt.instance<NetworkStore>();

    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          // if (this.widget.manual) ...[
          //   const SizedBox(height: 12.0),
          //   BaseButton(
          //     onPressed: () => ModalHandler.showBaseDialog(
          //       context: context,
          //       dialogWidget: InfoDialog(
          //         title: 'Quick Connect',
          //         body: '',
          //         enableDontShowAgainOption: true,
          //         onPressed: (dontShow) {},
          //       ),
          //     ),
          //     icon: const Icon(CupertinoIcons.qrcode_viewfinder),
          //     text: 'Quick Connect',
          //   ),
          //   const BaseDivider(height: 24.0),
          // ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Flexible(
                flex: 7,
                child: ConnectHostInput(
                  host: _host,
                  manual: this.widget.manual,
                ),
              ),
              const Spacer(),
              Flexible(
                flex: 2,
                child: KeyboardNumberHeader(
                  focusNode: _portFocusNode,
                  child: TextFormField(
                    controller: _port,
                    focusNode: _portFocusNode,
                    readOnly: !this.widget.manual,
                    enabled: this.widget.manual,
                    style: const TextStyle(
                      fontFeatures: [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (port) {
                      landingStore.typedInConnection.port = int.tryParse(port);
                    },
                    decoration: const InputDecoration(
                        labelText: 'Port', errorMaxLines: 2),
                    validator: (text) => text != null && text.isNotEmpty
                        ? ValidationHelper.portValidator(text)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          StreamBuilder<WebSocketCloseCode>(
            stream: _clodeCode.stream,
            builder: (context, snapshot) => StatefulBuilder(
              builder: (context, innerState) => TextFormField(
                controller: _pw,
                onChanged: (pw) => this.widget.manual
                    ? landingStore.typedInConnection.pw = pw
                    : null,
                obscureText: _obscurePW,
                decoration: InputDecoration(
                  errorText: snapshot.hasData &&
                          snapshot.data! ==
                              WebSocketCloseCode.AuthenticationFailed
                      ? 'Wrong password'
                      : null,
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePW ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => innerState(() => _obscurePW = !_obscurePW),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // if (this.widget.manual) ...[
                    //   BaseButton(
                    //     onPressed: () => ModalHandler.showBaseDialog(
                    //       context: context,
                    //       dialogWidget: InfoDialog(
                    //         title: 'Quick Connect',
                    //         body: '',
                    //         enableDontShowAgainOption: true,
                    //         onPressed: (dontShow) {},
                    //       ),
                    //     ),
                    //     icon: const Icon(CupertinoIcons.qrcode_viewfinder),
                    //     text: 'Quick Connect',
                    //   ),
                    //   const SizedBox(width: 24.0),
                    // ],
                    BaseButton(
                      text: 'Connect',
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          FocusScope.of(context).unfocus();
                          networkStore
                              .setOBSWebSocket(
                                Connection(
                                  (this.widget.manual && landingStore.domainMode
                                          ? landingStore.protocolScheme
                                          : '') +
                                      _host.text,
                                  int.tryParse(_port.text),
                                  _pw.text,
                                  this.widget.manual
                                      ? landingStore.domainMode
                                      : false,
                                ),
                              )
                              .then((clodeCode) => _clodeCode.add(clodeCode));
                        }
                      },
                    ),
                  ],
                ),
                // const Positioned(
                //   bottom: 12.0,
                //   right: 32.0,
                //   child: QuestionMarkTooltip(
                //       message:
                //           'Password is optional. You have to set it manually in the OBS WebSocket Plugin.\n\nIt is highly recommended though!'),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
