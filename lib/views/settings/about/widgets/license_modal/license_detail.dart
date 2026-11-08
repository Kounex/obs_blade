import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/card.dart';
import '../../../../../shared/general/base/sheet.dart';

/// One package's licenses - a sheet over the Credits sheet; the back
/// chevron (or a drag) returns to the package list
class LicenseDetail extends StatelessWidget {
  final String package;
  final List<LicenseEntry> licenseEntries;

  const LicenseDetail({
    super.key,
    required this.package,
    required this.licenseEntries,
  });

  @override
  Widget build(BuildContext context) {
    return BaseSheetScaffold(
      header: BaseSheetBackTitle(
        title: this.package,
        onBack: () => Navigator.of(context).pop(),
      ),
      bodyIsScrollable: true,
      body: Scrollbar(
        child: ListView(
          primary: false,
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: this.licenseEntries
              .map(
                (licenseEntry) => BaseCard(
                  topPadding: 0.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: licenseEntry.paragraphs
                        .map(
                          (paragraph) => Padding(
                            padding: EdgeInsets.only(
                              bottom: AppSpacing.xl,
                              left: AppSpacing.xl * paragraph.indent,
                            ),
                            child: Text(paragraph.text),
                          ),
                        )
                        .toList(),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
