import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/shared/basic/question_mark_tooltip.dart';
import 'package:obs_station/stores/shared/network.dart';
import 'package:obs_station/stores/views/landing.dart';
import 'package:obs_station/utils/validation_helper.dart';
import 'package:provider/provider.dart';

class ConnectForm extends StatefulWidget {
  final Connection connection;
  final bool saveCredentials;

  ConnectForm({this.connection, this.saveCredentials = false});

  @override
  _ConnectFormState createState() => _ConnectFormState();
}

class _ConnectFormState extends State<ConnectForm> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _ip;
  TextEditingController _port;
  TextEditingController _pw;

  bool obscurePWText = true;

  @override
  void initState() {
    super.initState();
    _ip = TextEditingController(text: widget.connection?.ip);
    _port = TextEditingController(
        text: widget.connection?.port?.toString() ?? '4444');
    _pw = TextEditingController(text: widget.connection?.pw);
  }

  @override
  Widget build(BuildContext context) {
    LandingStore landingStore = Provider.of<LandingStore>(context);

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
                  enabled: widget.saveCredentials,
                  onChanged: (ip) => widget.saveCredentials
                      ? landingStore.typedInConnection.ip = ip
                      : null,
                  decoration: InputDecoration(
                    labelText: 'IP Address',
                  ),
                  validator: (text) => ValidationHelper.ipValidation(text),
                ),
              ),
              Spacer(),
              Flexible(
                flex: 2,
                child: TextFormField(
                  controller: _port,
                  readOnly: !widget.saveCredentials,
                  enabled: widget.saveCredentials,
                  inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                  onChanged: (port) => widget.saveCredentials
                      ? landingStore.typedInConnection.port = int.parse(port)
                      : null,
                  decoration:
                      InputDecoration(labelText: 'Port', errorMaxLines: 2),
                  validator: (text) => ValidationHelper.portValidation(text),
                ),
              ),
            ],
          ),
          StatefulBuilder(builder: (context, innerState) {
            return TextFormField(
              controller: _pw,
              onChanged: (pw) => widget.saveCredentials
                  ? landingStore.typedInConnection.pw = pw
                  : null,
              obscureText: obscurePWText,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                      obscurePWText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () =>
                      innerState(() => obscurePWText = !obscurePWText),
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                RaisedButton(
                  child: Text('Connect'),
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      Provider.of<NetworkStore>(context, listen: false)
                          .setOBSWebSocket(
                        Connection(_ip.text, int.parse(_port.text), _pw.text),
                      );
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 192.0),
                  child: QuestionMarkTooltip(
                      message:
                          'Password is optional. You have to set it manually in the OBS WebSocket Plugin. It is highly recommended though!'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
