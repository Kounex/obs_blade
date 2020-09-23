import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/utils/icons/cupertino_icons_extended.dart';

import '../../../../../models/connection.dart';
import '../connect_form/connect_form.dart';

class SessionTile extends StatelessWidget {
  final Connection connection;

  SessionTile({@required this.connection});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(CupertinoIconsExtended.pie_chart_solid),
      title: Text(this.connection.ip),
      children: <Widget>[
        Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24, bottom: 12),
          child: ConnectForm(connection: this.connection),
        )
      ],
    );
  }
}
