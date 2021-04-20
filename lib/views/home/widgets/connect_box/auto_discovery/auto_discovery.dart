import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/external/platform_check/platform_check.dart';
import 'package:obs_blade/shared/general/keyboard_number_header.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/light_divider.dart';
import 'package:provider/provider.dart';

import '../../../../../models/connection.dart';
import '../../../../../shared/animator/fader.dart';
import '../../../../../shared/general/question_mark_tooltip.dart';
import '../../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../../stores/views/home.dart';
import '../../../../../utils/validation_helper.dart';
import 'result_entry.dart';
import 'session_tile.dart';

class AutoDiscovery extends StatefulWidget {
  @override
  _AutoDiscoveryState createState() => _AutoDiscoveryState();
}

class _AutoDiscoveryState extends State<AutoDiscovery> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  FocusNode _portFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = context.watch<HomeStore>();

    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 24.0, right: 24.0, left: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text('Port for autodiscovery: '),
              ),
              Container(width: 10.0),
              QuestionMarkTooltip(
                  message:
                      'Usually 4444. Can be seen and changed in the WebSocket Plugin settings in OBS\n\n(Tools -> WebSocket Plugin)'),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.only(bottom: 24.0),
          width: 65.0,
          child: Form(
            key: _formKey,
            child: KeyboardNumberHeader(
              focusNode: _portFocusNode,
              child: TextFormField(
                focusNode: _portFocusNode,
                textAlign: TextAlign.center,
                controller:
                    TextEditingController(text: landingStore.autodiscoverPort),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (text) {
                  landingStore.setAutodiscoverPort(text);
                  _formKey.currentState!.validate();
                },
                validator: (text) => ValidationHelper.portValidation(text),
              ),
            ),
          ),
        ),
        Divider(height: 1.0),
        Observer(
          builder: (context) => FutureBuilder<List<Connection>>(
            future: landingStore.autodiscoverConnections,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData && snapshot.data!.length > 0) {
                  return Fader(
                    child: Column(
                      children: snapshot.data!
                          .expand(
                            (availableObsConnection) => [
                              SessionTile(
                                connection: availableObsConnection,
                              ),
                              LightDivider(),
                            ],
                          )
                          .toList()
                            ..removeLast(),
                    ),
                  );
                }
                return ResultEntry(
                  result: snapshot.hasData && snapshot.data!.length == 0
                      ? 'Could not find an open OBS session via autodiscovery! Make sure you have an open OBS session in your local network with the OBS WebSocket plugin installed!\n\nCheck the FAQ section in the settings tab!'
                      : snapshot.error.toString().contains('NotInWLANException')
                          ? 'Your Device is not connected via WLAN! Autodiscovery only works if you are connected to your local network via WLAN!'
                          : 'Error occured! Either something is wrong with your WLAN connection or the app could not make use of autodiscovery.\n\nCheck the FAQ section in the settings tab!',
                );
              }
              return Fader(
                child: Container(
                  height: 150.0,
                  child: BaseProgressIndicator(text: 'Searching...'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
