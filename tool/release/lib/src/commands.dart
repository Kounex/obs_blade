import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'project.dart';
import 'stores.dart';

/// What `assets` needs to know about a creative-asset video (ffprobe).
typedef VideoFacts = ({int w, int h, double fps, double duration, bool audio});

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
          final repoLangs = Directory(project.path('fastlane/metadata/android'))
              .listSync()
              .whereType<Directory>()
              .map((d) => d.path.split('/').last)
              .toSet();
          final extra = (await play.languages()).difference(repoLangs);
          check(
            extra.isEmpty,
            'Android: Play listing languages match fastlane/metadata/android',
            'store has extra: ${extra.join(', ')} - delete store-side, stale listings outlive the repo copy',
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

  /// `HH:MM:SS:FF` (frames at [fps], default 30), the format of
  /// `previewFrameTimeCode`.
  static String timeCode(double seconds, {int fps = 30}) {
    final frames = (seconds * fps).round();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(frames ~/ (3600 * fps))}:${two(frames ~/ (60 * fps) % 60)}:'
        '${two(frames ~/ fps % 60)}:${two(frames % fps)}';
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

  // -------------------------------------------------------------- assets

  /// Creative-asset placements on the product page (iOS 27+): the header,
  /// and the search results card. One image serves one or both, depending
  /// on its spec (dedicated 21:9 header, 3:2 search, or 16:9 universal).
  static const List<String> creativePlacements = [
    'PRODUCT_PAGE_HEADER_ASSET',
    'APP_STORE_SEARCH_RESULTS_ASSET',
  ];

  static const Set<String> videoExtensions = {'.mp4', '.m4v', '.mov'};

  static bool isVideo(String path) =>
      videoExtensions.any(path.toLowerCase().endsWith);

  /// What ffprobe reports about [file], null when it can't read it.
  static Future<VideoFacts?> probeVideo(File file) async {
    final r = await Process.run('ffprobe', [
      '-v',
      'error',
      '-show_entries',
      'stream=codec_type,width,height,r_frame_rate:format=duration',
      '-of',
      'json',
      file.path,
    ]);
    if (r.exitCode != 0) return null;
    final j = jsonDecode('${r.stdout}') as Map<String, Object?>;
    final streams = ((j['streams'] as List?) ?? const []).cast<Map>();
    final v = streams.where((s) => s['codec_type'] == 'video').firstOrNull;
    if (v == null) return null;
    final rate = '${v['r_frame_rate']}'.split('/');
    final fps = rate.length == 2
        ? double.parse(rate[0]) / double.parse(rate[1])
        : double.parse(rate[0]);
    return (
      w: v['width'] as int,
      h: v['height'] as int,
      fps: fps,
      duration: double.parse('${(j['format'] as Map)['duration']}'),
      audio: streams.any((s) => s['codec_type'] == 'audio'),
    );
  }

  /// Seconds of an ISO 8601 duration as the ref data writes them (`PT5S`,
  /// `PT30S`, `PT1M`), null when it isn't one.
  static double? isoSeconds(Object? value) {
    final m = RegExp(
      r'^PT(?:(\d+)M)?(?:([\d.]+)S)?$',
    ).firstMatch('${value ?? ''}');
    if (m == null || (m.group(1) == null && m.group(2) == null)) return null;
    return int.parse(m.group(1) ?? '0') * 60 + double.parse(m.group(2) ?? '0');
  }

  /// Why [video] misses a video [spec] from the ref data, null when it fits.
  static String? videoSpecMiss(
    Map<String, Object?> spec,
    VideoFacts video, {
    required int bytes,
    required String fileName,
  }) {
    if (!fitsSpec(spec, (video.w, video.h)))
      return 'size ${video.w}x${video.h}';
    final rates = ((spec['frameRates'] as List?) ?? const []).cast<Map>();
    if (rates.isNotEmpty &&
        !rates.any(
          (r) =>
              video.fps >= (r['minFps'] as num) - 0.01 &&
              video.fps <= (r['maxFps'] as num) + 0.01,
        )) {
      return '${video.fps.toStringAsFixed(2)} fps';
    }
    final d = (spec['duration'] as Map?) ?? const {};
    final lo = isoSeconds(d['min']), hi = isoSeconds(d['max']);
    // container durations run a frame or so past the cut
    if ((lo != null && video.duration < lo - 0.05) ||
        (hi != null && video.duration > hi + 0.1)) {
      return '${video.duration.toStringAsFixed(2)} s (${d['min']}-${d['max']})';
    }
    final max = spec['maxFileSize'] as num?;
    if (max != null && bytes > max) return '${bytes ~/ 1000000} MB';
    final exts = ((spec['fileExtensions'] as List?) ?? const []).cast<String>();
    if (exts.isNotEmpty &&
        !exts.any((e) => fileName.toLowerCase().endsWith(e))) {
      return 'file type (${exts.join(' ')})';
    }
    if (spec['audioRequired'] == true && !video.audio) return 'no audio track';
    return null;
  }

  /// The committed creative assets `assets ios` uploads by default.
  static const List<String> defaultCreativeAssets = [
    'fastlane/assets/ios/header.png',
    'fastlane/assets/ios/search.png',
  ];

  /// Width × height of a PNG (from its IHDR), null when [file] isn't one.
  static (int, int)? _pngSize(File file) {
    const sig = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    final raf = file.openSync();
    try {
      final head = raf.readSync(24);
      if (head.length < 24 ||
          !List.generate(8, (i) => head[i] == sig[i]).every((ok) => ok) ||
          String.fromCharCodes(head.sublist(12, 16)) != 'IHDR') {
        return null;
      }
      final data = ByteData.sublistView(head);
      return (data.getUint32(16), data.getUint32(20));
    } finally {
      raf.closeSync();
    }
  }

  /// Image (or, with [video], video) specs from the ref data that may serve
  /// [placement].
  static List<Map<String, Object?>> _specsFor(
    Map<String, Object?> refData,
    String placement, {
    bool video = false,
  }) => ((refData[video ? 'videoSpecs' : 'imageSpecs'] as List?) ?? const [])
      .whereType<Map<String, Object?>>()
      .where(
        (s) => ((s['compatiblePlacementTypes'] as List?) ?? const []).contains(
          placement,
        ),
      )
      .toList();

  /// Whether [size] fits [spec]'s dimension bounds and its aspect ratio:
  /// the bounds alone are a box (search is 1920-3840 x 1280-2560), so a
  /// 3840x1646 header would pass them - `aspectRatio` (`"3:2"`) decides.
  static bool fitsSpec(Map<String, Object?> spec, (int, int) size) {
    final d = (spec['dimensions'] as Map?) ?? const {};
    num bound(String key) => (d[key] as num?) ?? -1;
    final ratio = RegExp(
      r'^(\d+):(\d+)$',
    ).firstMatch('${spec['aspectRatio'] ?? ''}');
    if (ratio != null) {
      final want = int.parse(ratio.group(1)!) / int.parse(ratio.group(2)!);
      // Apple's own sizes round (5244x2950 is "16:9", 3840x1646 "21:9")
      if ((size.$1 / size.$2 - want).abs() / want > 0.01) return false;
    }
    return size.$1 >= bound('minWidth') &&
        size.$1 <= bound('maxWidth') &&
        size.$2 >= bound('minHeight') &&
        size.$2 <= bound('maxHeight');
  }

  /// The creative placements [spec] serves.
  static List<String> _placementsOf(Map<String, Object?> spec) =>
      creativePlacements
          .where(
            ((spec['compatiblePlacementTypes'] as List?) ?? const []).contains,
          )
          .toList();

  /// Uploads creative assets (default: the header and the search results
  /// image) to the Asset Library and submits them for review together, on
  /// their own (no app version needed). PNGs and videos (mp4 / m4v / mov)
  /// both work: each file must fit one of Apple's creative specs, and which
  /// placement it serves follows from its size. A video's [poster] (seconds)
  /// is the frame shown before it plays. Once Apple approves them, `attach`
  /// places them on the live version.
  Future<int> assets(List<String> files, {double poster = 0}) async {
    final paths = [
      for (final f in files.isEmpty ? defaultCreativeAssets : files)
        files.isEmpty ? project.path(f) : f,
    ];
    final sizes = <String, (int, int)>{};
    final videos = <String, VideoFacts>{};
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) {
        stderr.writeln('No such file: $path');
        return 1;
      }
      if (isVideo(path)) {
        final facts = await probeVideo(file);
        if (facts == null) {
          stderr.writeln('$path: ffprobe can\'t read it as a video.');
          return 1;
        }
        if (poster < 0 || poster >= facts.duration) {
          stderr.writeln(
            '$path: poster ${poster}s is outside the video (0..${facts.duration.toStringAsFixed(2)} s).',
          );
          return 1;
        }
        videos[path] = facts;
        sizes[path] = (facts.w, facts.h);
      } else {
        final size = _pngSize(file);
        if (size == null) {
          stderr.writeln('$path is not a PNG or a video (mp4 / m4v / mov).');
          return 1;
        }
        sizes[path] = size;
      }
    }
    final asc = AppStore.connect();
    final refData = await asc.assetRefData();
    List<Map<String, Object?>> specs({required bool video}) => {
      for (final p in creativePlacements)
        ..._specsFor(refData, p, video: video),
    }.toList();
    final imageSpecs = specs(video: false), videoSpecs = specs(video: true);
    final existingImages = videos.length == paths.length
        ? const <Map<String, Object?>>[]
        : await asc.assetImages();
    final existingVideos = videos.isEmpty
        ? const <Map<String, Object?>>[]
        : await asc.assetVideos();

    stdout.writeln(
      'Upload to the Asset Library and submit for review (standalone, no app '
      'version). Once approved: release attach ios',
    );
    final toUpload = <String>[];
    final inFlight = <(String, bool)>[]; // (asset id, video)
    for (final path in paths) {
      final file = File(path);
      final size = sizes[path]!;
      final name = file.uri.pathSegments.last;
      final facts = videos[path];
      final bytes = file.lengthSync();
      Map<String, Object?>? spec;
      if (facts != null) {
        final misses = <String>[];
        for (final s in videoSpecs) {
          final miss = videoSpecMiss(s, facts, bytes: bytes, fileName: name);
          if (miss == null) {
            spec = s;
            break;
          }
          misses.add('${s['shortName']}: $miss');
        }
        if (spec == null) {
          stderr.writeln(
            '$name: fits no header / search results video spec\n  ${misses.join('\n  ')}',
          );
          return 1;
        }
      } else {
        spec = imageSpecs.where((s) => fitsSpec(s, size)).firstOrNull;
        if (spec == null) {
          stderr.writeln(
            '$name: ${size.$1}x${size.$2} fits no header / search results spec.',
          );
          return 1;
        }
      }
      final mb = (bytes / 1e6).toStringAsFixed(1);
      final what = facts == null
          ? ''
          : ', ${facts.fps.round()} fps, ${facts.duration.toStringAsFixed(1)} s, '
                'poster ${timeCode(poster, fps: facts.fps.round())}';
      stdout.write(
        '  $name (${size.$1}x${size.$2}$what, $mb MB, spec ${spec['shortName']}) '
        '-> ${_placementsOf(spec).join(' + ')}',
      );
      // Same file name and byte size, still on its way or already through
      // review: this file was uploaded before. A re-render under the same
      // name differs in size and is uploaded again.
      final before = (facts != null ? existingVideos : existingImages).where((
        i,
      ) {
        final a = i['attributes'] as Map;
        return a['fileName'] == name &&
            a['fileSize'] == bytes &&
            !{'FAILED', 'REJECTED', 'ARCHIVED'}.contains(a['state']);
      }).firstOrNull;
      final state = (before?['attributes'] as Map?)?['state'];
      if (state == 'WAITING_FOR_REVIEW' || state == 'IN_REVIEW') {
        stdout.writeln('  - already $state');
      } else if (state == 'APPROVED' || state == 'ACCEPTED') {
        stdout.writeln('  - already approved, run: release attach ios');
      } else if (before != null) {
        stdout.writeln('  - uploaded before ($state), submitting that one');
        inFlight.add(('${before['id']}', facts != null));
      } else {
        stdout.writeln();
        toUpload.add(path);
      }
    }
    if (toUpload.isEmpty && inFlight.isEmpty) {
      stdout.writeln('  nothing to do.');
      return 0;
    }
    if (!yes) {
      stdout.writeln('\nDRY RUN - re-run with --yes to do it.');
      return 0;
    }

    final assetIds = [...inFlight];
    for (final path in toUpload) {
      final file = File(path);
      final name = file.uri.pathSegments.last;
      final facts = videos[path];
      stdout.writeln('  uploading $name ...');
      // Apple wants reference names unique across the Asset Library
      final reference =
          'Creative asset $name ${DateTime.now().toUtc().toIso8601String().substring(0, 16)}Z';
      final result = facts != null
          ? await asc.uploadAssetVideo(
              file,
              referenceName: reference,
              posterTimeCode: timeCode(poster, fps: facts.fps.round()),
            )
          : await asc.uploadAssetImage(file, referenceName: reference);
      stdout.writeln('  asset ${result.id}: ${result.state}');
      if (result.state == 'FAILED') {
        if (result.errors.isNotEmpty) stderr.writeln('  ${result.errors}');
        throw StateError('Apple rejected the upload of $name.');
      }
      assetIds.add((result.id, facts != null));
    }

    final submission = await asc.draftReviewSubmission();
    final inReview = await asc.reviewItemIds(submission);
    for (final (id, video) in assetIds) {
      if (!inReview.contains(id)) {
        await asc.addAssetToReview(submission, id, video: video);
      }
    }
    await asc.sendReviewSubmission(submission);
    stdout.writeln('  submitted for review (submission $submission)');
    return 0;
  }

  /// Places the newest approved creative asset for each placement (product
  /// page header, search results) on every localization of the live
  /// version, replacing what was placed there before. On a version that is
  /// already on the App Store this publishes right away, no new version
  /// needed.
  Future<int> attach() async {
    final asc = AppStore.connect();
    final live = await asc.liveVersion();
    if (live == null) {
      stderr.writeln(
        'No live (READY_FOR_SALE) iOS version on App Store Connect.',
      );
      return 1;
    }
    final versionName = (live['attributes'] as Map)['versionString'];
    final refData = await asc.assetRefData();
    // images and videos, newest first; `video` marks the kind
    final assets =
        [
          for (final i in await asc.assetImages()) (asset: i, video: false),
          for (final v in await asc.assetVideos()) (asset: v, video: true),
        ]..sort(
          (a, b) => '${(b.asset['attributes'] as Map)['createdDate']}'
              .compareTo('${(a.asset['attributes'] as Map)['createdDate']}'),
        );
    final approved = assets.where((x) {
      final state = (x.asset['attributes'] as Map)['state'];
      return state == 'APPROVED' || state == 'ACCEPTED';
    }).toList();
    // placement type -> newest approved image or video serving it
    final chosen = <String, ({Map<String, Object?> asset, bool video})>{};
    for (final type in creativePlacements) {
      final specIds = {
        for (final s in [
          ..._specsFor(refData, type),
          ..._specsFor(refData, type, video: true),
        ])
          '${s['specId']}',
      };
      final pick = approved
          .where(
            (x) =>
                specIds.contains('${(x.asset['attributes'] as Map)['specId']}'),
          )
          .firstOrNull;
      if (pick != null) chosen[type] = pick;
    }
    if (chosen.isEmpty) {
      stderr.writeln(
        'No approved creative asset yet - upload + submit with: release assets ios',
      );
      return 1;
    }

    // What is placed now: (type, localization) -> (placement id, asset id)
    final current = <(String, String), (String, String)>{};
    for (final (:asset, :video) in assets) {
      for (final p in await asc.assetPlacements(
        '${asset['id']}',
        video: video,
      )) {
        final rel =
            ((p['relationships'] as Map?)?['appStoreVersionLocalization']
                    as Map?)?['data']
                as Map?;
        if (rel == null) continue;
        current[(
          '${(p['attributes'] as Map)['placementType']}',
          '${rel['id']}',
        )] = (
          '${p['id']}',
          '${asset['id']}',
        );
      }
    }

    stdout.writeln('Attach to the live version $versionName:');
    final todo = <(String, String, bool, String, String?)>[];
    final locs = await asc.localizations('${live['id']}');
    for (final MapEntry(key: type, value: (:asset, :video)) in chosen.entries) {
      final a = asset['attributes'] as Map;
      final imageId = '${asset['id']}';
      for (final loc in locs) {
        final locId = '${loc['id']}';
        final now = current[(type, locId)];
        final done = now?.$2 == imageId;
        stdout.writeln(
          '  ${(loc['attributes'] as Map)['locale']}  $type  '
          '${video ? 'video' : 'image'} "${a['referenceName'] ?? a['fileName']}"'
          '${done
              ? '  (already placed)'
              : now != null
              ? '  (replaces ${now.$2})'
              : ''}',
        );
        if (!done) todo.add((type, imageId, video, locId, now?.$1));
      }
    }
    if (todo.isEmpty) {
      stdout.writeln('  nothing to do.');
      return 0;
    }
    if (!yes) {
      stdout.writeln('\nDRY RUN - re-run with --yes to do it.');
      return 0;
    }
    // Each placement holds one asset (refData groupLimits maxCount 1) and
    // placements can't be edited, so the old one goes first.
    for (final (type, assetId, video, locId, old) in todo) {
      if (old != null) {
        await asc.deleteAssetPlacement(old);
        stdout.writeln('  removed $type ($old)');
      }
      final id = await asc.createAssetPlacement(
        placementType: type,
        assetId: assetId,
        video: video,
        localizationId: locId,
      );
      stdout.writeln('  placed $type ($id)');
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
