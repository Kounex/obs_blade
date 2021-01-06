import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/custom_expansion_tile.dart';

import '../../../../../models/connection.dart';
import '../connect_form.dart';

class SessionTile extends StatelessWidget {
  final Connection connection;

  SessionTile({@required this.connection});

  @override
  Widget build(BuildContext context) {
    return CustomExpansionTile(
      leadingIcon: CupertinoIcons.desktopcomputer,
      headerText: this.connection.ip,
      headerPadding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 18.0,
      ),
      expandedBody: Column(
        children: [
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(
              top: 12.0,
              left: 24.0,
              right: 24,
              bottom: 12.0,
            ),
            child: ConnectForm(connection: this.connection),
          ),
        ],
      ),
    );
  }
}
