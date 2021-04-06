import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obs_blade/shared/general/keyboard_number_header.dart';
import 'package:provider/provider.dart';

import '../../../../models/connection.dart';
import '../../../../shared/general/question_mark_tooltip.dart';
import '../../../../stores/shared/network.dart';
import '../../../../stores/views/home.dart';
import '../../../../types/classes/stream/responses/base.dart';
import '../../../../utils/validation_helper.dart';

class ConnectForm extends StatefulWidget {
  final Connection? connection;
  final bool saveCredentials;

  ConnectForm({this.connection, this.saveCredentials = false});

  @override
  _ConnectFormState createState() => _ConnectFormState();
}

class _ConnectFormState extends State<ConnectForm> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _ip;
  late TextEditingController _port;
  late TextEditingController _pw;

  FocusNode _portFocusNode = FocusNode();

  bool _obscurePWText = true;

  StreamController<BaseResponse> _connectResponse = StreamController();

  @override
  void initState() {
    super.initState();
    _ip = TextEditingController(text: this.widget.connection?.ip);
    _port = TextEditingController(
        text: this.widget.connection?.port.toString() ?? '4444');
    _pw = TextEditingController(text: this.widget.connection?.pw);
  }

  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = context.watch<HomeStore>();
    NetworkStore networkStore = context.watch<NetworkStore>();

    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Flexible(
                flex: 7,
                child: TextFormField(
                  controller: _ip,
                  readOnly: !widget.saveCredentials,
                  enabled: this.widget.saveCredentials,
                  onChanged: (ip) => this.widget.saveCredentials
                      ? landingStore.typedInConnection.ip = ip
                      : null,
                  decoration: InputDecoration(
                    labelText: 'IP Address (internal)',
                    hintText: 'e.g. 192.168.178.10',
                  ),
                  validator: (text) => ValidationHelper.ipValidation(text),
                ),
              ),
              Spacer(),
              Flexible(
                flex: 2,
                child: KeyboardNumberHeader(
                  focusNode: _portFocusNode,
                  child: TextFormField(
                    controller: _port,
                    focusNode: _portFocusNode,
                    readOnly: !widget.saveCredentials,
                    enabled: this.widget.saveCredentials,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (port) => this.widget.saveCredentials
                        ? landingStore.typedInConnection.port = int.parse(port)
                        : null,
                    decoration:
                        InputDecoration(labelText: 'Port', errorMaxLines: 2),
                    validator: (text) => ValidationHelper.portValidation(text),
                  ),
                ),
              ),
            ],
          ),
          StreamBuilder<BaseResponse>(
            stream: _connectResponse.stream,
            builder: (context, snapshot) => StatefulBuilder(
              builder: (context, innerState) => TextFormField(
                controller: _pw,
                onChanged: (pw) => this.widget.saveCredentials
                    ? landingStore.typedInConnection.pw = pw
                    : null,
                obscureText: _obscurePWText,
                decoration: InputDecoration(
                  errorText: snapshot.hasData &&
                          snapshot.data!.error ==
                              BaseResponse.failedAuthentication
                      ? 'Wrong password'
                      : null,
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePWText
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        innerState(() => _obscurePWText = !_obscurePWText),
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
                RaisedButton(
                  child: Text('Connect'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      FocusScope.of(context).unfocus();
                      networkStore
                          .setOBSWebSocket(
                            Connection(
                                _ip.text, int.parse(_port.text), _pw.text),
                          )
                          .then((response) => _connectResponse.add(response));
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 192.0),
                  child: QuestionMarkTooltip(
                      message:
                          'Password is optional. You have to set it manually in the OBS WebSocket Plugin.\n\nIt is highly recommended though!'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
