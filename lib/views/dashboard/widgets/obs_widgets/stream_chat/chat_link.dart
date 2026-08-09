import 'package:flutter/material.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:url_launcher/url_launcher.dart';

final RegExp kChatUrlPattern = RegExp(
  r'https?://[^\s<>\[\]{}]+',
  caseSensitive: false,
);

/// Confirm, then open [rawUrl] in an external browser. Trailing sentence
/// punctuation is stripped for the launch URI but shown in the prompt.
Future<void> confirmAndOpenChatLink(
  BuildContext context,
  String rawUrl,
) async {
  final cleaned = rawUrl.replaceFirst(RegExp(r'[.,!?;:]+$'), '');
  final uri = Uri.tryParse(cleaned);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return;
  }
  await ModalHandler.showBaseDialog(
    context: context,
    barrierDismissible: true,
    dialogWidget: ConfirmationDialog(
      title: 'Open link?',
      body: cleaned,
      okText: 'Open',
      noText: 'Cancel',
      onOk: (_) async {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    ),
  );
}
