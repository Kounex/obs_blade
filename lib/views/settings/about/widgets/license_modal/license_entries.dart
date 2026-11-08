import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../utils/modal_handler.dart';

import '../../../../../shared/overlay/base_progress_indicator.dart';
import 'license_detail.dart';

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
    packages.sort(
      compare ??
          (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
  }
}

class LicenseEntries extends StatefulWidget {
  /// First in the list, scrolling with it (the Credits logo) - pinned, it
  /// left a landscape phone no room for the packages
  final Widget? leading;

  const LicenseEntries({super.key, this.leading});

  @override
  _LicenseEntriesState createState() => _LicenseEntriesState();
}

class _LicenseEntriesState extends State<LicenseEntries> {
  /// Shared by the list and its Scrollbar - the sheet route's primary
  /// controller has no scroll view attached (the list isn't primary), so
  /// a Scrollbar without one couldn't be dragged
  final ScrollController _scrollController = ScrollController();
  late Future<LicenseData> _licenses;

  @override
  void initState() {
    _licenses = LicenseRegistry.licenses
        .fold<LicenseData>(
          LicenseData(),
          (LicenseData prev, LicenseEntry license) => prev..addLicense(license),
        )
        .then((LicenseData licenseData) => licenseData..sortPackages())
        /// Guard against a never-completing registry stream so the modal
        /// lands on the error state instead of a perpetual spinner
        .timeout(const Duration(seconds: 10));
    super.initState();
  }

  List<LicenseEntry> _getLicensesForPackage(
    LicenseData licenseData,
    String packageName,
  ) {
    List<LicenseEntry> entries = [];
    for (var licenseIndex in licenseData.packageLicenseBindings[packageName]!) {
      entries.add(licenseData.licenses.elementAt(licenseIndex));
    }
    return entries;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LicenseData>(
      future: _licenses,
      builder: (context, snapshot) {
        final int lead = this.widget.leading != null ? 1 : 0;

        /// Error / empty / loading below the leading block, scrolling with
        /// it like the list does
        Widget state(Widget child) => ListView(
          controller: _scrollController,
          children: [
            ?this.widget.leading,
            SizedBox(height: 160.0, child: child),
          ],
        );

        /// The registry future can also complete with an error / timeout or
        /// with zero packages - both used to render nothing (blank area or
        /// a spinner that never resolved), so they get explicit states now
        if (snapshot.hasError) {
          return state(
            const _LicenseStateMessage(
              text: 'The license information could not be loaded.',
            ),
          );
        }
        if (snapshot.hasData) {
          if (snapshot.data!.packages.isEmpty) {
            return state(
              const _LicenseStateMessage(
                text: 'No license information available.',
              ),
            );
          }
          return Scrollbar(
            controller: _scrollController,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              itemCount: snapshot.data!.packages.length + lead,
              itemBuilder: (context, i) {
                if (i < lead) return this.widget.leading!;
                final int index = i - lead;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  onTap: () => ModalHandler.showBaseBottomSheet(
                    context: context,
                    height: BaseSheetHeight.tall,
                    builder: (context) => LicenseDetail(
                      package: snapshot.data!.packages[index],
                      licenseEntries: _getLicensesForPackage(
                        snapshot.data!,
                        snapshot.data!.packages[index],
                      ),
                    ),
                  ),
                  title: Text(snapshot.data!.packages[index]),
                  subtitle: Text(
                    '${snapshot.data!.packageLicenseBindings[snapshot.data!.packages[index]]!.length} licenses',
                  ),
                );
              },
            ),
          );
        }
        return state(BaseProgressIndicator(text: 'Fetching...'));
      },
    );
  }
}

/// Centered terminal-state note (error / empty) for the license list so the
/// modal never renders a blank area
class _LicenseStateMessage extends StatelessWidget {
  final String text;

  const _LicenseStateMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        this.text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
