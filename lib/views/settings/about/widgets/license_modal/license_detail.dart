import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/general/base_card.dart';
import '../../../../../shared/general/transculent_cupertino_navbar_wrapper.dart';

class LicenseDetail extends StatelessWidget {
  final String package;
  final List<LicenseEntry> licenseEntries;

  LicenseDetail({@required this.package, @required this.licenseEntries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Packages',
        title: this.package,
        showScrollBar: true,
        listViewChildren: this
            .licenseEntries
            .map(
              (licenseEntry) => BaseCard(
                child: Column(
                  children: [
                    ...licenseEntry.paragraphs
                        .map(
                          (paragraph) => Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: 24.0 * paragraph.indent),
                              child: Text(paragraph.text),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
