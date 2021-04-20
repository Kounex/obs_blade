import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/settings/data_management/widgets/data_entry.dart';

import '../../../../shared/general/base_card.dart';

class DataBlock extends StatelessWidget {
  final List<DataEntry> dataEntries;

  DataBlock({
    required this.dataEntries,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> entries = List.from(
      this.dataEntries.expand(
            (entry) => [
              entry,
              Divider(height: 32.0),
            ],
          ),
    );

    if (entries.isNotEmpty) entries.removeLast();

    return BaseCard(
      bottomPadding: 12.0,
      child: Column(
        children: entries,
      ),
    );
  }
}
