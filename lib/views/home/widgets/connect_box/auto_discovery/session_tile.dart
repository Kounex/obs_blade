import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../models/connection.dart';
import '../../../../../shared/general/base/divider.dart';
import '../../../../../shared/general/custom_expansion_tile.dart';
import '../connect_form.dart';

class SessionTile extends StatelessWidget {
  final Connection connection;

  const SessionTile({Key? key, required this.connection}) : super(key: key);

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
          const BaseDivider(),
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
