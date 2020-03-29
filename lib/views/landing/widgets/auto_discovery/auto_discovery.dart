import 'package:flutter/material.dart';
import 'package:mobx_provider/mobx_provider.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/shared/question_mark_tooltip.dart';
import 'package:obs_station/stores/landing.dart';
import 'package:obs_station/shared/fade_inner.dart';
import 'package:obs_station/utils/validation_helper.dart';
import 'package:obs_station/views/landing/widgets/auto_discovery/session_tile.dart';

class AutoDiscovery extends StatefulWidget {
  @override
  _AutoDiscoveryState createState() => _AutoDiscoveryState();
}

class _AutoDiscoveryState extends State<AutoDiscovery> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return MobxStatefulProvider<LandingStore>(builder: (context, landingStore) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text('Port for autodiscovery: '),
                QuestionMarkTooltip(
                    message:
                        'Usually 4444. Can be seen and changed in the WebSocket Plugin settings in OBS (Tools -> WebSocket Plugin)'),
                Container(width: 25.0),
                Container(
                  width: 65.0,
                  child: Form(
                    key: _formKey,
                    child: TextFormField(
                      textAlign: TextAlign.center,
                      controller: TextEditingController(
                          text: landingStore.autodiscoverPort),
                      onChanged: (text) {
                        landingStore.setAutodiscoverPort(text);
                        _formKey.currentState.validate();
                      },
                      validator: (text) =>
                          ValidationHelper.portValidation(text),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 0.0,
          ),
          MobxWidgetProvider<LandingStore>(builder: (context, landingStore) {
            return FutureBuilder<List<Connection>>(
              future: landingStore.obsAutodiscoverConnections,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    if (snapshot.data.length > 0) {
                      return FadeInner(
                        child: Column(
                          children: snapshot.data
                              .map(
                                (availableObsConnection) => SessionTile(
                                  connection: availableObsConnection,
                                ),
                              )
                              .toList(),
                        ),
                      );
                    }
                    return Container(
                      padding: EdgeInsets.only(left: 24.0, right: 24.0),
                      alignment: Alignment.center,
                      height: 150.0,
                      child: FadeInner(
                        child: Text(
                          'Could not find an open OBS session via autodiscovery! Make sure you have an open OBS session in your local network with the OBS WebSocket plugin installed!\n\nPull down to try again!',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      padding: EdgeInsets.only(left: 24.0, right: 24.0),
                      alignment: Alignment.center,
                      height: 150.0,
                      child: FadeInner(
                        child: Text(
                          'Network error occured! Make sure you are connected to your local network!\n\nPull down to try again!',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                }
                return Align(
                  child: Container(
                    height: 150.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 12.0),
                          child: Text('Searching...'),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ],
      );
    });
  }
}
