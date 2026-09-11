import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/redesign/obs/obs_scene_controller.dart';
import 'package:obs_blade/redesign/obs/obs_workspace_session.dart';

import 'support/obs_peer.dart';

void main() {
  test(
    'production handshake, refresh, Preview and Take over a real socket',
    () async {
      final peer = await ObsPeer.start();
      final session = ObsWorkspaceSession();
      try {
        await session.connect(
          peer.connection,
          timeout: const Duration(seconds: 1),
        );
        final scenes = session.scenes!;
        expect(scenes.phase, ObsScenePhase.ready);
        expect(scenes.program, 'Camera');
        scenes.inspect('Desktop');
        expect(
          peer.requests.every(
            (r) => (r['requestType'] as String).startsWith('Get'),
          ),
          isTrue,
        );
        await scenes.previewScene('Desktop');
        expect(scenes.preview, 'Desktop');
        expect(scenes.program, 'Camera');
        await scenes.take();
        expect(scenes.program, 'Desktop');
        expect(scenes.preview, 'Camera');
        expect(
          peer.requests.where(
            (r) => r['requestType'] == 'TriggerStudioModeTransition',
          ),
          hasLength(1),
        );
      } finally {
        session.dispose();
        await peer.close();
      }
    },
  );

  test(
    'cancelled handshake cannot replace or close the following session',
    () async {
      final slow = await ObsPeer.start(identify: false);
      final next = await ObsPeer.start();
      final session = ObsWorkspaceSession();
      try {
        final firstAttempt = session.connect(
          slow.connection,
          timeout: const Duration(milliseconds: 150),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(session.scenes, isNull); // socket exists but is not identified
        session.disconnect();
        await session.connect(
          next.connection,
          timeout: const Duration(seconds: 1),
        );
        final active = session.scenes;
        await firstAttempt;
        expect(identical(session.scenes, active), isTrue);
        expect(active!.phase, ObsScenePhase.ready);
        await active.take();
        expect(active.program, 'Break');
      } finally {
        session.dispose();
        await slow.close();
        await next.close();
      }
    },
  );

  test('authentication failure cannot expose scene controls', () async {
    final peer = await ObsPeer.start(rejectAuth: true);
    final session = ObsWorkspaceSession();
    try {
      await session.connect(
        peer.connection,
        timeout: const Duration(seconds: 1),
      );
      expect(session.failure?.isAuthenticationFailure, isTrue);
      expect(session.scenes, isNull);
      expect(peer.requests, isEmpty);
    } finally {
      session.dispose();
      await peer.close();
    }
  });
}
