import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/overlay/base_progress_indicator.dart';

/// This is a collection of licenses and the packages to which they apply.
/// [packageLicenseBindings] records the m+:n+ relationship between the license
/// and packages as a map of package names to license indexes.
///
/// Took from: about.dart (26.07.2020)
class _LicenseData {
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
      packageLicenseBindings[package].add(licenses.length);
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
  void sortPackages([int compare(String a, String b)]) {
    packages.sort(compare ??
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }
}

class LicenseEntries extends StatefulWidget {
  final ScrollController scrollController;

  LicenseEntries({this.scrollController});

  @override
  _LicenseEntriesState createState() => _LicenseEntriesState();
}

class _LicenseEntriesState extends State<LicenseEntries> {
  Future<_LicenseData> _licenses;

  @override
  void initState() {
    _licenses = LicenseRegistry.licenses
        .fold<_LicenseData>(
          _LicenseData(),
          (_LicenseData prev, LicenseEntry license) =>
              prev..addLicense(license),
        )
        .then((_LicenseData licenseData) => licenseData..sortPackages());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LicenseData>(
      future: _licenses,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            controller: widget.scrollController,
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            itemCount: snapshot.data.packages.length,
            itemBuilder: (context, index) => ListTile(
              dense: true,
              title: Text(snapshot.data.packages[index]),
              subtitle: Text(
                  '${snapshot.data.packageLicenseBindings[snapshot.data.packages[index]].length} licenses'),
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
