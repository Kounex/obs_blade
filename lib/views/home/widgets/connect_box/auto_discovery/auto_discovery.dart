import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/shared/network.dart';

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

  String _processResult(AsyncSnapshot<List<Connection>> snapshot) {
    if (snapshot.error.toString().contains('NotInWLANException')) {
      return 'Your Device is not connected via WLAN! Autodiscovery only works if you are connected to your local network via WLAN.';
    }
    if (snapshot.error.toString().contains('NoNetworkException')) {
      return 'OBS Blade was not able to retrieve your local IP address so it can\'t perform an autodiscovery!\n\nMake sure your device is connected via WLAN and has an IP address assigned.';
    }
    if (snapshot.hasData && snapshot.data!.isEmpty) {
      if (GetIt.instance<NetworkStore>().subnetMask != null &&
          GetIt.instance<NetworkStore>().nonDefaultSubnetMask) {
        return 'Your network is using a "non default" subnet mask to assign local client ip addresses (${GetIt.instance<NetworkStore>().subnetMask}). Therefore OBS Blade can\'t reliably perform the autodiscovery.\n\nEither adjust the network settings of your router (if you really need autodiscovery) or use the manual mode to enter the IP address directly!';
      }
      return 'Could not find an open OBS session via autodiscovery! Make sure you have an open OBS session in your local network with the OBS WebSocket plugin installed!\n\nCheck the FAQ section in the settings tab.';
    }

    return 'Error occured! Either something is wrong with your WLAN connection or the app could not make use of autodiscovery.\n\nCheck the FAQ section in the settings tab.';
  }

  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = GetIt.instance<HomeStore>();

    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 18.0, right: 18.0, left: 18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text('Port for autodiscovery: '),
              ),
              SizedBox(width: 10.0),
              QuestionMarkTooltip(
                  message:
                      'Usually 4455. Can be seen and changed in the WebSocket Plugin settings in OBS:\n\nTools -> WebSocket Server Settings'),
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
                  result: _processResult(snapshot),
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
