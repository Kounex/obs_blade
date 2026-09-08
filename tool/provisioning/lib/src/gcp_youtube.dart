import 'dart:convert';
import 'dart:io';

/// Idempotent GCP setup for the YouTube native chat work: project,
/// YouTube Data API v3, and an API key restricted to that API. Shells out
/// to the (GA) `gcloud services api-keys` surface — the CLI is injected so
/// the flow is unit-testable without gcloud installed.

class GcloudResult {
  const GcloudResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;
}

/// One gcloud invocation. [args] excludes the leading `gcloud`.
typedef GcloudRunner = Future<GcloudResult> Function(List<String> args);

Future<GcloudResult> realGcloudRunner(List<String> args) async {
  final result = await Process.run('gcloud', args);
  return GcloudResult(result.exitCode, result.stdout, result.stderr);
}

class GcpYoutubeProvisioner {
  GcpYoutubeProvisioner({
    required this.projectId,
    required GcloudRunner gcloud,
    this.keyDisplayName = 'obs-blade-youtube',
    this.dryRun = false,
    void Function(String)? log,
  }) : _gcloud = gcloud,
       _log = log ?? print;

  final String projectId;
  final String keyDisplayName;
  final bool dryRun;
  final GcloudRunner _gcloud;
  final void Function(String) _log;

  static const youtubeService = 'youtube.googleapis.com';

  /// Ensures project + API + key. Returns the API key string, or null in
  /// dry-run mode (where nothing is actually created).
  ///
  /// The key string is returned exactly once to the caller and never
  /// logged — the caller decides whether it goes to stdout or a
  /// chmod-600 file.
  Future<String?> run() async {
    await _ensureProject();
    await _enableYoutubeApi();
    return _ensureApiKey();
  }

  Future<GcloudResult> _run(List<String> args, {String? what}) async {
    if (dryRun) {
      _log('[dry-run] gcloud ${args.join(' ')}');
      return const GcloudResult(0, '', '');
    }
    final result = await _gcloud(args);
    if (result.exitCode != 0) {
      throw GcpException(what ?? args.first, args, result);
    }
    return result;
  }

  Future<void> _ensureProject() async {
    final args = ['projects', 'describe', projectId, '--format=json'];
    if (dryRun) {
      _log('[dry-run] gcloud ${args.join(' ')}');
      _log('[dry-run] gcloud projects create $projectId  # if describe fails');
      return;
    }
    final describe = await _gcloud(args);
    if (describe.exitCode == 0) {
      _log('project $projectId already exists — skipping create');
      return;
    }
    if (describe.stderr.contains('PERMISSION_DENIED') ||
        describe.stderr.contains('not authorized') ||
        describe.stderr.contains('Re-authenticate') ||
        describe.stderr.contains('login')) {
      throw GcpException(
        'projects describe',
        args,
        describe,
        hint: 'Run `gcloud auth login` first, then re-run this command.',
      );
    }
    await _run(['projects', 'create', projectId], what: 'projects create');
    _log('created project $projectId');
  }

  Future<void> _enableYoutubeApi() async {
    // `services enable` is itself idempotent (no-op when already enabled).
    await _run([
      'services',
      'enable',
      youtubeService,
      '--project',
      projectId,
    ], what: 'services enable');
    _log('enabled $youtubeService on $projectId');
  }

  Future<String?> _ensureApiKey() async {
    if (dryRun) {
      _log(
        '[dry-run] gcloud services api-keys list '
        '--project $projectId '
        '--filter="displayName:$keyDisplayName" --format=json',
      );
      _log(
        '[dry-run] gcloud services api-keys create '
        '--display-name=$keyDisplayName '
        '--api-target=service=$youtubeService '
        '--project $projectId --format=json  # if list is empty',
      );
      _log(
        '[dry-run] gcloud services api-keys get-key-string <name> '
        '--project $projectId --format=json',
      );
      return null;
    }

    final list = await _run([
      'services',
      'api-keys',
      'list',
      '--project',
      projectId,
      '--filter',
      'displayName:$keyDisplayName',
      '--format=json',
    ], what: 'api-keys list');
    final keys = jsonDecode(list.stdout) as List;

    String keyName;
    if (keys.isNotEmpty) {
      keyName = (keys.first as Map)['name'] as String;
      _log('API key "$keyDisplayName" already exists ($keyName) — reusing');
    } else {
      final created = await _run([
        'services',
        'api-keys',
        'create',
        '--display-name',
        keyDisplayName,
        '--api-target',
        'service=$youtubeService',
        '--project',
        projectId,
        '--format=json',
      ], what: 'api-keys create');
      // With --format=json the result may be the key resource itself (has
      // `name` + `uid`) or just the long-running operation — in that case
      // (and on any empty name) re-list by display name, with a few retries
      // since key creation is eventually consistent.
      final decoded = jsonDecode(created.stdout);
      keyName = decoded is Map ? decoded['name'] as String? ?? '' : '';
      var unresolved = keyName.isEmpty || keyName.contains('/operations/');
      if (unresolved) {
        for (var attempt = 1; attempt <= 5 && unresolved; attempt++) {
          await Future.delayed(Duration(seconds: 2 * attempt));
          final relist = await _run([
            'services',
            'api-keys',
            'list',
            '--project',
            projectId,
            '--filter',
            'displayName:$keyDisplayName',
            '--format=json',
          ], what: 'api-keys list');
          final listed = jsonDecode(relist.stdout) as List;
          if (listed.isNotEmpty) {
            keyName = (listed.first as Map)['name'] as String;
            unresolved = false;
          }
        }
        if (unresolved) {
          throw GcpException(
            'api-keys list (post-create)',
            const [],
            const GcloudResult(1, '', 'key not visible after create'),
            hint:
                'The key was created but is not listed yet — re-run '
                'this command; it reuses the existing key.',
          );
        }
      }
      _log(
        'created API key "$keyDisplayName" restricted to '
        '$youtubeService ($keyName)',
      );
    }

    final keyString = await _run([
      'services',
      'api-keys',
      'get-key-string',
      keyName,
      '--project',
      projectId,
      '--format=json',
    ], what: 'api-keys get-key-string');
    final decoded = jsonDecode(keyString.stdout) as Map;
    return decoded['keyString'] as String;
  }
}

class GcpException implements Exception {
  GcpException(this.step, this.args, this.result, {this.hint});

  final String step;
  final List<String> args;
  final GcloudResult result;
  final String? hint;

  @override
  String toString() {
    final buffer = StringBuffer(
      'gcloud $step failed (exit '
      '${result.exitCode}): ${result.stderr.trim()}',
    );
    if (hint != null) buffer.write('\n$hint');
    return buffer.toString();
  }
}
