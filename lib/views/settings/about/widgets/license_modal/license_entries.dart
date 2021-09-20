import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:obs_blade/views/settings/about/widgets/license_modal/license_detail.dart';

import '../../../../../shared/overlay/base_progress_indicator.dart';

/// This is a collection of licenses and the packages to which they apply.
/// [packageLicenseBindings] records the m+:n+ relationship between the license
/// and packages as a map of package names to license indexes.
///
/// Took from: about.dart (26.07.2020)
class LicenseData {
  final List<LicenseEntry> licenses = <LicenseEntry>[];
  final Map<String, List<int>> packageLicenseBindings = <String, List<int>>{};
  final List<String> packages = <String>[];

  void addLicense(LicenseEntry entry) {
    // Before the license can be added, we must first record the packages to
    // which it belongs.
    for (final String package in entry.packages) {
      _addPackage(package);
      // Bind this license to the package using the next index value. This
      // creates a contract that this license must be inserted at this same
      // index value.
      packageLicenseBindings[package]!.add(licenses.length);
    }
    licenses.add(entry); // Completion of the contract above.
  }

  /// Add a package and initialise package license binding. This is a no-op if
  /// the package has been seen before.
  void _addPackage(String package) {
    if (!packageLicenseBindings.containsKey(package)) {
      packageLicenseBindings[package] = <int>[];
      packages.add(package);
    }
  }

  /// Sort the packages using some comparison method, or by the default manner,
  /// which is to put the application package first, followed by every other
  /// package in case-insensitive alphabetical order.
  void sortPackages([int Function(String a, String b)? compare]) {
    packages.sort(compare ??
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }
}

class LicenseEntries extends StatefulWidget {
  final ScrollController? scrollController;

  const LicenseEntries({Key? key, this.scrollController}) : super(key: key);

  @override
  _LicenseEntriesState createState() => _LicenseEntriesState();
}

class _LicenseEntriesState extends State<LicenseEntries> {
  late Future<LicenseData> _licenses;

  @override
  void initState() {
    _licenses = LicenseRegistry.licenses
        .fold<LicenseData>(
          LicenseData(),
          (LicenseData prev, LicenseEntry license) => prev..addLicense(license),
        )
        .then((LicenseData licenseData) => licenseData..sortPackages());
    super.initState();
  }

  List<LicenseEntry> _getLicensesForPackage(
      LicenseData licenseData, String packageName) {
    List<LicenseEntry> entries = [];
    for (var licenseIndex in licenseData.packageLicenseBindings[packageName]!) {
      entries.add(
        licenseData.licenses.elementAt(licenseIndex),
      );
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LicenseData>(
      future: _licenses,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scrollbar(
            child: ListView.builder(
              shrinkWrap: true,
              controller: this.widget.scrollController,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom),
              itemCount: snapshot.data!.packages.length,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  CupertinoModalBottomSheetRoute(
                    expanded: true,
                    builder: (context) => LicenseDetail(
                        package: snapshot.data!.packages[index],
                        licenseEntries: _getLicensesForPackage(
                            snapshot.data!, snapshot.data!.packages[index])),
                  ),
                ),
                title: Text(snapshot.data!.packages[index]),
                subtitle: Text(
                  '${snapshot.data!.packageLicenseBindings[snapshot.data!.packages[index]]!.length} licenses',
                ),
              ),
            ),
          );
        }
        return Container(
          alignment: Alignment.center,
          child: BaseProgressIndicator(text: 'Fetching...'),
        );
      },
    );
  }
}
