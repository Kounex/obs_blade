import 'package:flutter/material.dart';
import 'package:obs_station/shared/question_mark_tooltip.dart';
import 'package:obs_station/utils/validation_helper.dart';

class ConnectForm extends StatefulWidget {
  @override
  _ConnectFormState createState() => _ConnectFormState();
}

class _ConnectFormState extends State<ConnectForm> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _ip = TextEditingController();
  TextEditingController _port = TextEditingController(text: '4444');
  TextEditingController _pw = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(
                flex: 7,
                child: TextFormField(
                  controller: _ip,
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
                  decoration: InputDecoration(
                    labelText: 'Port',
                  ),
                  validator: (text) => ValidationHelper.portValidation(text),
                ),
              ),
            ],
          ),
          TextFormField(
            controller: _pw,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                RaisedButton(
                  child: Text('Connect'),
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      // TODO: connection
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
