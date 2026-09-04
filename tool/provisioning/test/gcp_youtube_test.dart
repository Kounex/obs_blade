import 'package:provisioning/src/gcp_youtube.dart';
import 'package:test/test.dart';

/// Fake gcloud CLI: records invocations, answers from a handler.
class FakeGcloud {
  final calls = <List<String>>[];
  GcloudResult Function(List<String> args)? handler;

  Future<GcloudResult> call(List<String> args) async {
    calls.add(List.of(args));
    return handler?.call(args) ?? const GcloudResult(0, '', '');
  }
}

void main() {
  group('GcpYoutubeProvisioner', () {
    test('creates project + key when nothing exists', () async {
      final gcloud = FakeGcloud();
      gcloud.handler = (args) {
        final joined = args.join(' ');
        if (joined.startsWith('projects describe')) {
          return const GcloudResult(1, '', 'NOT_FOUND');
        }
        if (joined.startsWith('services api-keys list')) {
          return const GcloudResult(0, '[]', '');
        }
        if (joined.startsWith('services api-keys create')) {
          return const GcloudResult(0,
              '{"name": "projects/p1/locations/global/keys/k1"}', '');
        }
        if (joined.startsWith('services api-keys get-key-string')) {
          return const GcloudResult(0, '{"keyString": "AIza-test"}', '');
        }
        return const GcloudResult(0, '', '');
      };

      final provisioner = GcpYoutubeProvisioner(
          projectId: 'obs-blade-youtube', gcloud: gcloud.call);
      final key = await provisioner.run();

      expect(key, 'AIza-test');
      expect(
          gcloud.calls.any((c) => c.join(' ') ==
              'projects create obs-blade-youtube'),
          isTrue);
      final create = gcloud.calls
          .firstWhere((c) => c.join(' ').startsWith('services api-keys create'));
      expect(create, contains('--api-target'));
      expect(create, contains('service=youtube.googleapis.com'));
      expect(gcloud.calls.any((c) => c.contains('services') && c.contains('enable')),
          isTrue);
    });

    test('reuses existing project + key (no create calls)', () async {
      final gcloud = FakeGcloud();
      gcloud.handler = (args) {
        final joined = args.join(' ');
        if (joined.startsWith('projects describe')) {
          return const GcloudResult(0, '{}', '');
        }
        if (joined.startsWith('services api-keys list')) {
          return const GcloudResult(0,
              '[{"name": "projects/p1/locations/global/keys/k1"}]', '');
        }
        if (joined.startsWith('services api-keys get-key-string')) {
          return const GcloudResult(0, '{"keyString": "AIza-existing"}', '');
        }
        return const GcloudResult(0, '', '');
      };

      final provisioner = GcpYoutubeProvisioner(
          projectId: 'obs-blade-youtube', gcloud: gcloud.call);
      final key = await provisioner.run();

      expect(key, 'AIza-existing');
      expect(gcloud.calls.any((c) => c.contains('create')), isFalse,
          reason: 're-run must be a no-op apart from reads/enable');
    });

    test('dry-run issues no gcloud calls and returns null', () async {
      final gcloud = FakeGcloud();
      final logs = <String>[];
      final provisioner = GcpYoutubeProvisioner(
          projectId: 'obs-blade-youtube',
          gcloud: gcloud.call,
          dryRun: true,
          log: logs.add);
      final key = await provisioner.run();

      expect(key, isNull);
      expect(gcloud.calls, isEmpty);
      expect(logs.where((l) => l.startsWith('[dry-run]')), isNotEmpty);
    });

    test('auth errors surface the gcloud auth login hint', () async {
      final gcloud = FakeGcloud();
      gcloud.handler = (args) => const GcloudResult(
          1, '', 'ERROR: (gcloud.projects.describe) PERMISSION_DENIED');

      final provisioner = GcpYoutubeProvisioner(
          projectId: 'obs-blade-youtube', gcloud: gcloud.call);
      expect(
          () => provisioner.run(),
          throwsA(isA<GcpException>()
              .having((e) => e.hint, 'hint', contains('gcloud auth login'))));
    });
  });
}
