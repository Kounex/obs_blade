import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/views/home/widgets/connect_box/quick_connect/quick_connect.dart';

import '../../../../stores/views/home.dart';
import 'auto_discovery/auto_discovery.dart';
import 'connect_form/connect_form.dart';
import 'switcher_card.dart';

class ConnectBox extends StatelessWidget {
  const ConnectBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    HomeStore homeStore = GetIt.instance<HomeStore>();

    return Observer(
      builder: (_) => SwitcherCard(
        title: homeStore.connectMode.text,
        child: () {
          switch (homeStore.connectMode) {
            case ConnectMode.Autodiscover:
              return const AutoDiscovery();
            case ConnectMode.QR:
              return const Padding(
                padding: EdgeInsets.only(
                  top: 20.0,
                  left: 24.0,
                  right: 24.0,
                  bottom: 18.0,
                ),
                child: QuickConnect(),
              );
            case ConnectMode.Manual:
              return Padding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  bottom: 18.0,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: ConnectForm(
                    connection: homeStore.typedInConnection,
                    manual: true,
                  ),
                ),
              );
          }
        }(),
      ),
    );
  }
}
