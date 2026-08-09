import 'package:flutter/material.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// http(s) URLs, plus bare / www hosts that look like domains (Twitch-like).
/// Prefer [chatUrlMatches] — it drops common file-extension false positives.
/// Bare TLDs are letters-only and must not be a prefix of a longer token
/// (`clip.mp4` must not match as `clip.mp`).
final RegExp kChatUrlPattern = RegExp(
  r'(?:https?://[^\s<>\[\]{}]+)'
  r'|(?<![@\w./])(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}'
  r'(?![a-z0-9])(?:/[^\s<>\[\]{}]*)?)',
  caseSensitive: false,
);

/// Last labels that are almost always filenames, not TLDs.
const Set<String> kChatUrlIgnoredTlds = {
  'png',
  'jpg',
  'jpeg',
  'gif',
  'webp',
  'bmp',
  'svg',
  'mp4',
  'mov',
  'avi',
  'mkv',
  'webm',
  'mp3',
  'wav',
  'flac',
  'aac',
  'txt',
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'csv',
  'zip',
  'rar',
  '7z',
  'tar',
  'gz',
  'exe',
  'dmg',
  'apk',
  'ipa',
};

bool isIgnoredChatUrlMatch(String raw) {
  final cleaned = raw.replaceFirst(RegExp(r'[.,!?;:]+$'), '');
  final withoutScheme = cleaned.replaceFirst(
    RegExp(r'^https?://', caseSensitive: false),
    '',
  );
  final host =
      withoutScheme.split('/').first.split('?').first.split('#').first;
  final parts = host.split('.');
  if (parts.length < 2) return true;
  return kChatUrlIgnoredTlds.contains(parts.last.toLowerCase());
}

/// Matches from [kChatUrlPattern], excluding file-extension lookalikes.
Iterable<RegExpMatch> chatUrlMatches(String text) =>
    kChatUrlPattern.allMatches(text).where(
          (match) => !isIgnoredChatUrlMatch(match.group(0)!),
        );

/// Strip trailing sentence punctuation and ensure an http(s) scheme.
/// Returns null when the result is not a usable http(s) URI.
String? normalizeChatLinkUrl(String rawUrl) {
  final cleaned = rawUrl.replaceFirst(RegExp(r'[.,!?;:]+$'), '');
  if (cleaned.isEmpty) return null;
  final withScheme =
      RegExp(r'^https?://', caseSensitive: false).hasMatch(cleaned)
          ? cleaned
          : 'https://$cleaned';
  final uri = Uri.tryParse(withScheme);
  /// Dart percent-encodes spaces into the host (`not%20a%20url`) — reject
  /// those along with hosts that have no dot (chat never needs localhost).
  if (uri == null ||
      !(uri.isScheme('http') || uri.isScheme('https')) ||
      uri.host.isEmpty ||
      uri.host.contains('%') ||
      !uri.host.contains('.') ||
      !RegExp(r'^[a-z0-9.-]+$', caseSensitive: false).hasMatch(uri.host)) {
    return null;
  }
  return withScheme;
}

/// Confirm, then open [rawUrl] in an external browser. Trailing sentence
/// punctuation is stripped for the launch URI but shown in the prompt.
Future<void> confirmAndOpenChatLink(
  BuildContext context,
  String rawUrl,
) async {
  final launchUrlString = normalizeChatLinkUrl(rawUrl);
  if (launchUrlString == null) return;
  final uri = Uri.parse(launchUrlString);
  final display = rawUrl.replaceFirst(RegExp(r'[.,!?;:]+$'), '');
  await ModalHandler.showBaseDialog(
    context: context,
    barrierDismissible: true,
    dialogWidget: ConfirmationDialog(
      title: 'Open link?',
      body: display,
      okText: 'Open',
      noText: 'Cancel',
      onOk: (_) async {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    ),
  );
}
