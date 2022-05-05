import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/views/home/widgets/connect_box/connect_form/connect_target_input.dart';

import '../../../../../models/connection.dart';
import '../../../../../shared/general/base/button.dart';
import '../../../../../shared/general/keyboard_number_header.dart';
import '../../../../../shared/general/question_mark_tooltip.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/home.dart';
import '../../../../../types/classes/stream/responses/base.dart';
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

  final StreamController<BaseResponse> _connectResponse = StreamController();

  @override
  void initState() {
    super.initState();
    _host = TextEditingController(text: this.widget.connection?.host);
    _port = TextEditingController(
        text: this.widget.connection?.port.toString() ?? '4444');
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Flexible(
                flex: 7,
                child: ConnectTargetInput(
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
                    readOnly: !widget.manual,
                    enabled: this.widget.manual,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (port) => this.widget.manual
                        ? landingStore.typedInConnection.port = int.parse(port)
                        : null,
                    decoration: const InputDecoration(
                        labelText: 'Port', errorMaxLines: 2),
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
                onChanged: (pw) => this.widget.manual
                    ? landingStore.typedInConnection.pw = pw
                    : null,
                obscureText: _obscurePW,
                decoration: InputDecoration(
                  errorText: snapshot.hasData &&
                          snapshot.data!.error ==
                              BaseResponse.failedAuthentication
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
                BaseButton(
                  text: 'Connect',
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      FocusScope.of(context).unfocus();
                      networkStore
                          .setOBSWebSocket(
                            Connection(
                              _host.text,
                              int.parse(_port.text),
                              _pw.text,
                              this.widget.manual
                                  ? landingStore.domainMode
                                  : false,
                            ),
                          )
                          .then((response) => _connectResponse.add(response));
                    }
                  },
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 192.0),
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
