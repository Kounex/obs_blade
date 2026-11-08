import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/card.dart';
import '../../../../../shared/general/base/sheet.dart';

/// One package's licenses - a sheet over the Credits sheet; the back
/// chevron (or a drag) returns to the package list
class LicenseDetail extends StatefulWidget {
  final String package;
  final List<LicenseEntry> licenseEntries;

  const LicenseDetail({
    super.key,
    required this.package,
    required this.licenseEntries,
  });

  @override
  State<LicenseDetail> createState() => _LicenseDetailState();
}

class _LicenseDetailState extends State<LicenseDetail> {
  /// Shared by the list and its Scrollbar - the sheet route's primary
  /// controller has no scroll view attached (the list isn't primary), so
  /// a Scrollbar without one couldn't be dragged
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseSheetScaffold(
      header: BaseSheetBackTitle(
        title: this.widget.package,
        onBack: () => Navigator.of(context).pop(),
      ),
      bodyIsScrollable: true,
      body: Scrollbar(
        controller: _scrollController,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: this.widget.licenseEntries
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
