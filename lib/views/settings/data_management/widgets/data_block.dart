import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../shared/general/base/card.dart';
import '../../../../shared/general/column_separated.dart';
import 'data_entry.dart';

class DataBlock extends StatelessWidget {
  final List<DataEntry> dataEntries;

  const DataBlock({
    Key? key,
    required this.dataEntries,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      bottomPadding: 12.0,
      child: ColumnSeparated(
        paddingSeparator: const EdgeInsets.symmetric(vertical: 16.0),
        children: this.dataEntries,
      ),
    );
  }
}
