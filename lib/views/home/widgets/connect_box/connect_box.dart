import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/views/home/widgets/connect_box/switcher_card.dart';
import 'package:provider/provider.dart';

import '../../../../stores/views/home.dart';
import 'auto_discovery/auto_discovery.dart';
import 'connect_form.dart';

class ConnectBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = context.watch<HomeStore>();

    return Align(
      child: Observer(
        builder: (_) => SwitcherCard(
          title: landingStore.manualMode ? 'Connection' : 'Autodiscover',
          child: landingStore.manualMode
              ? Padding(
                  padding: const EdgeInsets.only(
                      left: 24.0, right: 24.0, bottom: 12.0),
                  child: ConnectForm(
                    connection: landingStore.typedInConnection,
                    saveCredentials: true,
                  ),
                )
              : AutoDiscovery(),
        ),
      ),
    );
  }
}
