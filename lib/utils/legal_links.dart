import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The legal pages live on the website - the single source of truth for
/// every app version, so there is no bundled copy that can drift from it.
/// Both stores only require the privacy policy to be linked from the app.
final Uri kPrivacyPolicyUri = Uri.parse(
  'https://obs-blade.kounex.com/privacy-policy',
);
final Uri kImprintUri = Uri.parse('https://obs-blade.kounex.com/imprint');

/// Apple's standard EULA (the app ships no custom terms document)
final Uri kTermsUri = Uri.parse(
  'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
);

/// Opens a legal page in the in-app browser (Safari view / Custom Tabs),
/// with a snackbar when nothing can open it.
Future<void> openLegalPage(BuildContext context, Uri uri) async {
  bool opened;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (_) {
    opened = false;
  }
  if (opened || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Couldn\'t open the link.')));
}
