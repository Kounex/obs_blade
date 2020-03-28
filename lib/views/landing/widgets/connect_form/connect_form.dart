import 'package:flutter/material.dart';
import 'package:obs_station/shared/question_mark_tooltip.dart';

class ConnectForm extends StatefulWidget {
  @override
  _ConnectFormState createState() => _ConnectFormState();
}

class _ConnectFormState extends State<ConnectForm> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            decoration: InputDecoration(hintText: 'IP Address'),
            validator: (text) {
              List<String> ip = text.split('.');
              if (ip.length == 4 &&
                  ip.every((part) =>
                      part.length > 0 &&
                      part.length < 4 &&
                      int.tryParse(part) != null &&
                      int.parse(part) <= 255)) {
                return null;
              }
              return 'Not an IP address';
            },
          ),
          TextFormField(
            decoration: InputDecoration(hintText: 'Password'),
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
                      print('YEEES');
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 192.0),
                  child: QuestionMarkTooltip(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
