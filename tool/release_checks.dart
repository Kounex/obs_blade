// OBS Blade's own release checks, run by store-release's preflight
// (`release.yaml` -> preflight.checks). Exits non-zero when a check fails.
//
//   dart run tool/release_checks.dart
//
// - the app-owned Kick OAuth client (docs/private/kick_oauth.json) is present:
//   store builds compile it in with --dart-define-from-file;
// - it carries no secret: a client secret would be readable in the binary,
//   and the app would then skip the exchange host;
// - it doesn't turn on the dogfood-only Pro unlock.

import 'dart:convert';
import 'dart:io';

const String kickOauthDefines = 'docs/private/kick_oauth.json';
const String proUnlockDefine = 'PRO_RELEASE_TEST_UNLOCK';

/// Defines in [json] that must never be compiled into a store build: any
/// non-empty value whose key contains SECRET, and the Pro test unlock.
List<String> forbiddenDefines(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map) return const [];
  return [
    for (final MapEntry(:key, :value) in decoded.entries)
      if ((key.toString().contains('SECRET') && '$value'.trim().isNotEmpty) ||
          key.toString() == proUnlockDefine)
        key.toString(),
  ];
}

void main() {
  final file = File(kickOauthDefines);
  if (!file.existsSync()) {
    stderr.writeln('✗ app-owned Kick OAuth client missing: $kickOauthDefines');
    exit(1);
  }
  final List<String> forbidden;
  try {
    forbidden = forbiddenDefines(file.readAsStringSync());
  } on FormatException {
    stderr.writeln('✗ $kickOauthDefines is not valid JSON');
    exit(1);
  }
  if (forbidden.isNotEmpty) {
    stderr.writeln('✗ remove ${forbidden.join(', ')} from $kickOauthDefines');
    exit(1);
  }
  stdout.writeln('✓ Kick OAuth client present, no secrets or test unlocks');
}
