import 'dart:io';

/// The app's repo as the release tool sees it: version, artifacts and the
/// files a store release reads.
class Project {
  Project(this.root);

  /// Walks up from this tool to the repo root (the dir with pubspec.yaml
  /// + ios/ + android/).
  factory Project.locate() {
    var dir = Directory.current.absolute;
    while (true) {
      if (File('${dir.path}/pubspec.yaml').existsSync() &&
          Directory('${dir.path}/ios').existsSync() &&
          Directory('${dir.path}/android').existsSync()) {
        return Project(dir.path);
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        throw StateError('run inside the obs_blade repo');
      }
      dir = parent;
    }
  }

  final String root;

  static const String bundleId = 'com.kounex.obsBlade';

  String path(String relative) => '$root/$relative';

  /// `version: 4.0.0+2026092501` from the app's pubspec.
  ({String name, int build}) get version {
    final line = File(
      path('pubspec.yaml'),
    ).readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    final value = line.substring('version:'.length).trim();
    final parts = value.split('+');
    return (name: parts.first, build: int.parse(parts.last));
  }

  /// Rewrites the pubspec build number (the version name stays).
  void setBuild(int build) {
    final file = File(path('pubspec.yaml'));
    final lines = file.readAsLinesSync();
    final i = lines.indexWhere((l) => l.startsWith('version:'));
    lines[i] = 'version: ${version.name}+$build';
    file.writeAsStringSync('${lines.join('\n')}\n');
  }

  /// Build numbers are `YYYYMMDDNN`: today, and the next free NN.
  static int nextBuild(int current, DateTime now) {
    final today =
        int.parse(
          '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}',
        ) *
        100;
    return current >= today + 1 ? current + 1 : today + 1;
  }

  String get ipaDir => path('build/ios/ipa');
  String get aab => path('build/app/outputs/bundle/release/app-release.aab');

  /// Written after a store build: which version + commit the artifact is.
  File stamp(String platform) => File(path('build/release/$platform.json'));

  String get iosReleaseNotes =>
      path('fastlane/metadata/ios/en-US/release_notes.txt');
  String get playReleaseNotes =>
      path('fastlane/metadata/android/en-US/changelogs/default.txt');

  /// App-owned Kick OAuth client (maintainer machines only).
  String get kickOauthDefines => path('docs/private/kick_oauth.json');
}
