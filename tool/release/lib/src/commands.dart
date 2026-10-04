import 'dart:convert';
import 'dart:io';

import 'project.dart';
import 'stores.dart';

/// Forbidden in store builds: the Pro test unlock must never ship.
const String _forbiddenDefine = 'PRO_RELEASE_TEST_UNLOCK';

class Release {
  Release(this.project, {required this.yes});

  final Project project;

  /// Commands that write to a store only act with --yes; otherwise they
  /// print what they would do.
  final bool yes;

  // ------------------------------------------------------------- helpers

  Future<int> _run(
    String exe,
    List<String> args, {
    Map<String, String>? env,
  }) async {
    stdout.writeln('\$ $exe ${args.join(' ')}');
    final p = await Process.start(
      exe,
      args,
      workingDirectory: project.root,
      environment: env,
      mode: ProcessStartMode.inheritStdio,
    );
    return p.exitCode;
  }

  Future<String> _out(String exe, List<String> args) async {
    final r = await Process.run(exe, args, workingDirectory: project.root);
    return (r.stdout as String).trim();
  }

  Future<int> _fastlane(
    String platform,
    String lane,
    Map<String, String> options,
  ) {
    final args = [
      'exec',
      'fastlane',
      platform,
      lane,
      for (final e in options.entries) '${e.key}:${e.value}',
    ];
    if (!yes) {
      stdout.writeln('\nDRY RUN - would run: bundle ${args.join(' ')}');
      stdout.writeln('Re-run with --yes to do it.');
      return Future.value(0);
    }
    return _run(
      'bundle',
      args,
      env: {'FASTLANE_SKIP_UPDATE_CHECK': '1', 'FASTLANE_OPT_OUT_USAGE': '1'},
    );
  }

  void _heading(String text) => stdout.writeln('\n== $text');

  Map<String, Object?>? _readStamp(String platform) {
    final f = project.stamp(platform);
    return f.existsSync()
        ? jsonDecode(f.readAsStringSync()) as Map<String, Object?>
        : null;
  }

  // -------------------------------------------------------------- status

  Future<int> status() async {
    final v = project.version;
    stdout.writeln(
      'Local: ${v.name} (${v.build})  HEAD ${await _out('git', ['rev-parse', '--short', 'HEAD'])}',
    );

    final asc = AppStore.connect();
    _heading('App Store versions');
    for (final item in await asc.versions()) {
      final a = item['attributes'] as Map;
      stdout.writeln('  ${a['versionString']}  ${a['appStoreState']}');
    }
    _heading('App Store builds');
    for (final item in await asc.builds()) {
      final a = item['attributes'] as Map;
      stdout.writeln(
        '  ${a['version']}  ${a['processingState']}${a['expired'] == true ? '  (expired)' : ''}  uploaded ${a['uploadedDate']}',
      );
    }
    _heading('App Store in-app products');
    for (final item in [
      ...await asc.inAppPurchases(),
      ...await asc.subscriptions(),
    ]) {
      final a = item['attributes'] as Map;
      stdout.writeln('  ${a['productId']}  ${a['state']}');
    }

    final play = await PlayStore.connect();
    try {
      _heading('Google Play tracks');
      for (final track in await play.tracks()) {
        final releases = (track['releases'] as List?) ?? const [];
        if (releases.isEmpty) stdout.writeln('  ${track['track']}: -');
        for (final r in releases.cast<Map>()) {
          stdout.writeln(
            '  ${track['track']}: ${r['name']}  ${r['versionCodes']}  ${r['status']}'
            '${r['userFraction'] != null ? '  ${r['userFraction']}' : ''}',
          );
        }
      }
    } finally {
      play.close();
    }
    return 0;
  }

  // ----------------------------------------------------------- preflight

  /// Checks one or both platforms; prints every check and returns whether
  /// all passed. [online] also compares build numbers with the stores.
  Future<bool> preflight(Set<String> platforms, {bool online = true}) async {
    var ok = true;
    void check(bool pass, String label, [String? fix]) {
      stdout.writeln(
        '  ${pass ? 'ok  ' : 'FAIL'}  $label${!pass && fix != null ? '  -> $fix' : ''}',
      );
      if (!pass) ok = false;
    }

    _heading('Preflight (${platforms.join(' + ')})');
    final v = project.version;
    stdout.writeln('  version ${v.name}+${v.build}');

    check(
      (await _out('git', ['status', '--porcelain'])).isEmpty,
      'working tree clean',
      'commit or stash first',
    );
    await _out('git', ['fetch', '-q', 'origin']);
    final branch = await _out('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
    check(
      await _out('git', ['rev-parse', 'HEAD']) ==
          await _out('git', ['rev-parse', 'origin/$branch']),
      'HEAD is pushed (origin/$branch)',
      'git push',
    );
    final kickDefines = File(project.kickOauthDefines);
    check(
      kickDefines.existsSync(),
      'app-owned Kick OAuth client present',
      'docs/private/kick_oauth.json',
    );
    if (kickDefines.existsSync()) {
      final forbidden = Project.forbiddenDefines(
        kickDefines.readAsStringSync(),
      );
      check(
        forbidden.isEmpty,
        'no secrets in the Kick defines',
        'remove ${forbidden.join(', ')} from docs/private/kick_oauth.json',
      );
    }
    check(
      (await Process.run('bundle', [
            'exec',
            'fastlane',
            '--version',
          ], workingDirectory: project.root)).exitCode ==
          0,
      'fastlane installed',
      'bundle install',
    );

    if (platforms.contains('ios')) {
      final plist = File(
        project.path('ios/Runner/Info.plist'),
      ).readAsStringSync();
      check(
        RegExp(
          r'<key>ITSAppUsesNonExemptEncryption</key>\s*<false/>',
        ).hasMatch(plist),
        'iOS: export compliance declared (ITSAppUsesNonExemptEncryption)',
      );
      final notes = File(project.iosReleaseNotes);
      check(
        notes.existsSync() && notes.readAsStringSync().trim().isNotEmpty,
        'iOS: release notes present',
      );
      for (final name in [
        'OBS_BLADE_ASC_KEY_PATH',
        'OBS_BLADE_ASC_KEY_ID',
        'OBS_BLADE_ASC_ISSUER_ID',
        'OBS_BLADE_ASC_APP_ID',
      ]) {
        check((Platform.environment[name] ?? '').isNotEmpty, 'iOS: $name set');
      }
    }
    if (platforms.contains('android')) {
      check(
        File(project.path('android/key.properties')).existsSync(),
        'Android: upload key configured (android/key.properties)',
      );
      final notes = File(project.playReleaseNotes);
      final length = notes.existsSync()
          ? notes.readAsStringSync().trim().length
          : 0;
      check(
        length > 0 && length <= 500,
        'Android: what\'s new present, $length/500 chars',
      );
      check(
        (Platform.environment['OBS_BLADE_GOOGLE_APPLICATION_CREDENTIALS'] ?? '')
            .isNotEmpty,
        'Android: OBS_BLADE_GOOGLE_APPLICATION_CREDENTIALS set',
      );
    }

    if (online && ok) {
      if (platforms.contains('ios')) {
        final latest = (await AppStore.connect().builds())
            .map(
              (b) =>
                  int.tryParse('${(b['attributes'] as Map)['version']}') ?? 0,
            )
            .fold(0, (a, b) => a > b ? a : b);
        check(
          v.build > latest,
          'iOS: build ${v.build} is newer than App Store Connect ($latest)',
          'release bump',
        );
      }
      if (platforms.contains('android')) {
        final play = await PlayStore.connect();
        try {
          final codes = (await play.tracks())
              .expand((t) => ((t['releases'] as List?) ?? const []).cast<Map>())
              .expand((r) => ((r['versionCodes'] as List?) ?? const []))
              .map((c) => int.tryParse('$c') ?? 0);
          final latest = codes.fold(0, (a, b) => a > b ? a : b);
          check(
            v.build > latest,
            'Android: versionCode ${v.build} is newer than Play ($latest)',
            'release bump',
          );
        } finally {
          play.close();
        }
      }
    }
    stdout.writeln(ok ? '\nPreflight passed.' : '\nPreflight failed.');
    return ok;
  }

  // ---------------------------------------------------------------- bump

  int bump() {
    final current = project.version.build;
    final next = Project.nextBuild(current, DateTime.now());
    project.setBuild(next);
    stdout.writeln(
      'pubspec: ${project.version.name}+$current -> +$next (commit + push before building)',
    );
    return 0;
  }

  // --------------------------------------------------------------- build

  Future<int> build(String platform) async {
    if (!await preflight({platform})) return 1;
    final defines = ['--dart-define-from-file=${project.kickOauthDefines}'];
    if (defines.any((d) => d.contains(_forbiddenDefine)))
      throw StateError('forbidden define');

    int code;
    if (platform == 'ios') {
      final keychainPw = Platform.environment['RELEASE_KEYCHAIN_PASSWORD_FILE'];
      if (keychainPw != null) {
        // SSH sessions start with a locked login keychain (maintainer setup)
        await Process.run('security', [
          'unlock-keychain',
          '-p',
          File(keychainPw).readAsStringSync().trim(),
          '${Platform.environment['HOME']}/Library/Keychains/login.keychain-db',
        ]);
      }
      code = await _run('flutter', [
        'build',
        'ipa',
        '--release',
        '--export-options-plist=${project.path('tool/release/ExportOptions.plist')}',
        ...defines,
      ]);
    } else {
      code = await _run('flutter', [
        'build',
        'appbundle',
        '--release',
        ...defines,
      ]);
    }
    if (code != 0) return code;

    final v = project.version;
    final artifact = platform == 'ios'
        ? Directory(project.ipaDir)
              .listSync()
              .whereType<File>()
              .firstWhere((f) => f.path.endsWith('.ipa'))
              .path
        : project.aab;
    project.stamp(platform)
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'version': v.name,
          'build': v.build,
          'commit': await _out('git', ['rev-parse', 'HEAD']),
          'artifact': artifact,
          'builtAt': DateTime.now().toIso8601String(),
        }),
      );
    stdout.writeln('\nBuilt ${v.name} (${v.build}): $artifact');
    return 0;
  }

  /// Commits after a build that can't change the binary: docs, Markdown,
  /// store listing files and the release tooling itself.
  static bool _outsideBinary(String path) =>
      path.startsWith('docs/') ||
      path.endsWith('.md') ||
      path.startsWith('fastlane/') ||
      path.startsWith('tool/');

  /// Whether [built] and [head] build the same binary: the same commit, or
  /// only non-binary files changed in between.
  Future<bool> _sameBinaryInputs(String built, String head) async {
    if (built == head) return true;
    final r = await Process.run('git', [
      'diff',
      '--name-only',
      built,
      head,
    ], workingDirectory: project.root);
    if (r.exitCode != 0) return false;
    final changed = (r.stdout as String)
        .split('\n')
        .where((l) => l.trim().isNotEmpty);
    return changed.every(_outsideBinary);
  }

  /// The artifact from `build` must match the current version, and nothing
  /// that goes into the binary may have changed since.
  Future<String?> _artifact(String platform) async {
    final s = _readStamp(platform);
    final v = project.version;
    final head = await _out('git', ['rev-parse', 'HEAD']);
    if (s == null ||
        s['build'] != v.build ||
        !await _sameBinaryInputs('${s['commit']}', head) ||
        !File('${s['artifact']}').existsSync()) {
      stderr.writeln(
        'No $platform build for ${v.name}+${v.build} at HEAD - run: release build $platform',
      );
      return null;
    }
    return s['artifact'] as String;
  }

  // ---------------------------------------------------------------- beta

  Future<int> beta(String platform) async {
    final artifact = await _artifact(platform);
    if (artifact == null) return 1;
    final v = project.version;
    stdout.writeln(
      platform == 'ios'
          ? 'Upload ${v.name} (${v.build}) to TestFlight, internal testers only.'
          : 'Upload ${v.name} (${v.build}) to the Play internal track (replaces what is there).',
    );
    return _fastlane(
      platform,
      'beta',
      platform == 'ios' ? {'ipa': artifact} : {'aab': artifact},
    );
  }

  // ------------------------------------------------------------ metadata

  Future<int> metadata(String platform) async {
    final v = project.version;
    if (platform == 'ios') {
      final shots = Directory(
        project.path('fastlane/screenshots/en-US'),
      ).listSync().where((f) => f.path.endsWith('.png'));
      stdout.writeln(
        'Push to App Store version ${v.name}: listing text from fastlane/metadata/ios, '
        '${shots.length} screenshots (replacing the current ones).',
      );
      return _fastlane('ios', 'metadata', {'version': v.name});
    }
    stdout.writeln(
      'Push to the Play listing: text, feature graphic and screenshots from fastlane/metadata/android.',
    );
    return _fastlane('android', 'metadata', {});
  }

  // ------------------------------------------------------------- preview

  /// App Store preview type for the 886x1920 cut (6.9" slot; Apple scales
  /// it down for the smaller iPhones).
  static const String iphonePreviewType = 'IPHONE_67';

  /// `HH:MM:SS:FF` at 30 fps, the format of `previewFrameTimeCode`.
  static String timeCode(double seconds) {
    final frames = (seconds * 30).round();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(frames ~/ 108000)}:${two(frames ~/ 1800 % 60)}:'
        '${two(frames ~/ 30 % 60)}:${two(frames % 30)}';
  }

  /// Uploads [file] as the en-US iPhone App Preview of the current version,
  /// replacing the previews that are there once the new one is processed.
  /// fastlane (deliver) can't upload previews, so this talks to the API.
  Future<int> preview(String file, double poster) async {
    final video = File(file);
    if (!video.existsSync()) {
      stderr.writeln('No such file: $file');
      return 1;
    }
    final v = project.version;
    final asc = AppStore.connect();
    final version = await asc.version(v.name);
    if (version == null) {
      stderr.writeln('No App Store version ${v.name} on App Store Connect.');
      return 1;
    }
    final state = (version['attributes'] as Map)['appStoreState'];
    final locId = await asc.localizationId('${version['id']}', 'en-US');
    if (locId == null) {
      stderr.writeln('Version ${v.name} has no en-US localization.');
      return 1;
    }
    final setId = await asc.previewSetId(locId, iphonePreviewType);
    final existing = setId == null ? const [] : await asc.previews(setId);
    final code = timeCode(poster);
    final mb = (video.lengthSync() / 1e6).toStringAsFixed(1);
    stdout.writeln(
      'Upload ${video.uri.pathSegments.last} ($mb MB, poster $code) as the '
      'en-US $iphonePreviewType App Preview of ${v.name} ($state)'
      '${existing.isEmpty ? '.' : ', replacing ${existing.length} preview(s) once it is processed.'}',
    );
    if (!yes) {
      stdout.writeln('\nDRY RUN - re-run with --yes to do it.');
      return 0;
    }

    final targetSet =
        setId ?? await asc.createPreviewSet(locId, iphonePreviewType);
    stdout.writeln('  uploading ...');
    final result = await asc.uploadPreview(
      targetSet,
      video,
      posterTimeCode: code,
    );
    stdout.writeln('  preview ${result.id}: ${result.state}');
    if (result.state != 'COMPLETE') {
      if (result.errors.isNotEmpty) stderr.writeln('  ${result.errors}');
      stderr.writeln(
        result.state == 'FAILED'
            ? 'Apple rejected the preview; the old previews stay.'
            : 'Still processing; check App Store Connect. The old previews stay.',
      );
      return 1;
    }
    for (final p in existing) {
      await asc.deletePreview('${p['id']}');
      stdout.writeln('  removed old preview ${p['id']}');
    }
    return 0;
  }

  // -------------------------------------------------------------- submit

  Future<int> submit() async {
    final v = project.version;
    final asc = AppStore.connect();
    final build = (await asc.builds()).firstWhere(
      (b) => '${(b['attributes'] as Map)['version']}' == '${v.build}',
      orElse: () => const {},
    );
    if (build.isEmpty ||
        (build['attributes'] as Map)['processingState'] != 'VALID') {
      stderr.writeln(
        'Build ${v.build} is not uploaded/processed on App Store Connect yet - run: release beta ios',
      );
      return 1;
    }
    final pending = (await asc.subscriptions())
        .where((s) => (s['attributes'] as Map)['state'] == 'READY_TO_SUBMIT')
        .toList();
    stdout.writeln(
      'Submit ${v.name} (${v.build}) for App Review. Once approved it waits for: release publish ios',
    );
    if (pending.isNotEmpty) {
      stdout.writeln(
        'Subscriptions submitted with it: '
        '${pending.map((s) => (s['attributes'] as Map)['productId']).join(', ')}',
      );
    }
    final version = await asc.version(v.name);
    if (version == null) {
      stderr.writeln('No App Store version ${v.name} on App Store Connect.');
      return 1;
    }
    if (!yes) {
      stdout.writeln('\nDRY RUN - re-run with --yes to do it.');
      return 0;
    }

    // Nothing reaches App Review before the last step: build + release
    // type, a draft review submission with the version, the subscriptions
    // (as their subscription versions, plus the group version while the
    // group was never approved), then the submission is sent.
    final versionId = '${version['id']}';
    await asc.prepareVersion(versionId, '${build['id']}');
    stdout.writeln('  build ${v.build} attached, manual release');
    final submission = await asc.draftReviewSubmission();
    final inReview = await asc.reviewItemIds(submission);
    if (!inReview.contains(versionId)) {
      await asc.addVersionToReview(submission, versionId);
      inReview.addAll(await asc.reviewItemIds(submission));
    }
    stdout.writeln('  review submission $submission has ${v.name}');
    for (final s in pending) {
      final name = (s['attributes'] as Map)['productId'];
      final subVersion = await asc.subscriptionVersionId('${s['id']}');
      if (subVersion == null) {
        stderr.writeln('$name has no version to submit - nothing was sent.');
        return 1;
      }
      if (!inReview.contains(subVersion)) {
        await asc.addSubscriptionToReview(submission, subVersion);
      }
      stdout.writeln('  $name in the submission');
    }
    if (pending.isNotEmpty) {
      for (final group in await asc.subscriptionGroupVersionsToSubmit()) {
        if (!inReview.contains(group)) {
          await asc.addSubscriptionGroupToReview(submission, group);
        }
        stdout.writeln('  subscription group version $group in the submission');
      }
    }
    await asc.sendReviewSubmission(submission);
    stdout.writeln('  submitted for review');
    return 0;
  }

  /// Releases the approved version (manual release) to everyone.
  /// [versionName] defaults to pubspec's - pass it when the repo already
  /// moved on to the next version while this one waited for review.
  Future<int> publish([String? versionName]) async {
    final v = (name: versionName ?? project.version.name);
    final asc = AppStore.connect();
    final version = await asc.version(v.name);
    final state = version == null
        ? null
        : (version['attributes'] as Map)['appStoreState'];
    if (state != 'PENDING_DEVELOPER_RELEASE') {
      stderr.writeln(
        'App Store version ${v.name} is ${state ?? 'missing'}, not approved '
        'and waiting (PENDING_DEVELOPER_RELEASE).',
      );
      return 1;
    }
    stdout.writeln('Release App Store version ${v.name} to everyone now.');
    if (!yes) {
      stdout.writeln('\nDRY RUN - re-run with --yes to do it.');
      return 0;
    }
    await asc.releaseVersion('${version!['id']}');
    stdout.writeln('  release requested');
    return 0;
  }

  // ----------------------------------------------------- promote / halt

  Future<int> promote(String rollout) async {
    final v = project.version;
    final fraction = double.parse(rollout);
    stdout.writeln(
      'Promote Play internal ${v.name} (${v.build}) to production at ${(fraction * 100).round()}% of users.',
    );
    return _fastlane('android', 'promote', {
      'version_code': '${v.build}',
      'rollout': rollout,
    });
  }

  Future<int> halt() async {
    final v = project.version;
    stdout.writeln(
      'Halt the Play production rollout of ${v.name} (${v.build}).',
    );
    return _fastlane('android', 'halt', {'version_code': '${v.build}'});
  }
}
