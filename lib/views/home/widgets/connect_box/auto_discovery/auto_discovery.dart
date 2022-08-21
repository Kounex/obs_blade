import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../models/connection.dart';
import '../../../../../shared/animator/fader.dart';
import '../../../../../shared/general/base/divider.dart';
import '../../../../../shared/general/keyboard_number_header.dart';
import '../../../../../shared/general/question_mark_tooltip.dart';
import '../../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../../stores/views/home.dart';
import '../../../../../utils/validation_helper.dart';
import 'result_entry.dart';
import 'session_tile.dart';

class AutoDiscovery extends StatefulWidget {
  const AutoDiscovery({Key? key}) : super(key: key);

  @override
  _AutoDiscoveryState createState() => _AutoDiscoveryState();
}

class _AutoDiscoveryState extends State<AutoDiscovery> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _portFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = GetIt.instance<HomeStore>();

    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 18.0, right: 18.0, left: 18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Flexible(
                child: Text('Port for autodiscovery: '),
              ),
              Container(width: 10.0),
              const QuestionMarkTooltip(
                  message:
                      'Usually 4455. Can be seen and changed in the WebSocket Plugin settings in OBS:\n\nTools -> obs-websocket Settings'),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 24.0),
          width: 65.0,
          child: Form(
            key: _formKey,
            child: KeyboardNumberHeader(
              focusNode: _portFocusNode,
              child: TextFormField(
                focusNode: _portFocusNode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFeatures: [
                    FontFeature.tabularFigures(),
                  ],
                ),
                controller:
                    TextEditingController(text: landingStore.autodiscoverPort),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (text) {
                  landingStore.setAutodiscoverPort(text);
                  _formKey.currentState!.validate();
                },
                validator: (text) => ValidationHelper.portValidator(text),
              ),
            ),
          ),
        ),
        const BaseDivider(),
        Observer(
          builder: (context) => FutureBuilder<List<Connection>>(
            future: landingStore.autodiscoverConnections,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Fader(
                    child: Column(
                      children: snapshot.data!
                          .expand(
                            (availableObsConnection) => [
                              SessionTile(
                                connection: availableObsConnection,
                              ),
                              const BaseDivider(),
                            ],
                          )
                          .toList()
                        ..removeLast(),
                    ),
                  );
                }
                return ResultEntry(
                  result: snapshot.hasData && snapshot.data!.isEmpty
                      ? 'Could not find an open OBS session via autodiscovery! Make sure you have an open OBS session in your local network with the OBS WebSocket plugin installed!\n\nCheck the FAQ section in the settings tab.'
                      : snapshot.error.toString().contains('NotInWLANException')
                          ? 'Your Device is not connected via WLAN! Autodiscovery only works if you are connected to your local network via WLAN.'
                          : 'Error occured! Either something is wrong with your WLAN connection or the app could not make use of autodiscovery.\n\nCheck the FAQ section in the settings tab.',
                );
              }
              return Fader(
                child: SizedBox(
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
