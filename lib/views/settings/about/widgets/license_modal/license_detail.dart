import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/general/transculent_cupertino_navbar_wrapper.dart';

class LicenseDetail extends StatelessWidget {
  final LicenseEntry licenseEntry;

  LicenseDetail({@required this.licenseEntry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Packages',
        title: this.licenseEntry.toString(),
      ),
    );
  }
}
