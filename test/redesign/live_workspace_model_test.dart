import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/redesign/obs/live_workspace_model.dart';
import 'package:obs_blade/redesign/workspace/workspace_model.dart';

import 'support/obs_peer.dart';

void main() {
  test(
    'live binding preserves local chat and focus through OBS disconnect',
    () async {
      final peer = await ObsPeer.start();
      final model = LiveWorkspaceModel(
        host: 'localhost',
        port: peer.server.port,
      );
      try {
        model.setFocus(WorkspaceFocus.chat);
        model.setDraft('Keep this draft');
        model.setReply('Synthetic viewer');
        await model.connect();
        expect(model.program, 'Camera');
        expect(model.hasObsDetails, isFalse);
        model.inspect('Desktop');
        await model.setPreview();
        await model.takeScene();
        expect(model.program, 'Desktop');
        model.disconnect();
        expect(model.connection, ObsConnection.disconnected);
        expect(model.draft, 'Keep this draft');
        expect(model.replyTo, 'Synthetic viewer');
        expect(model.focus, WorkspaceFocus.chat);
        expect(model.scenes, isEmpty);
      } finally {
        model.dispose();
        await peer.close();
      }
    },
  );
}
