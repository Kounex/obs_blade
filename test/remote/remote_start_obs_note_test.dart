import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/remote/remote_relay_client.dart';
import 'package:obs_blade/views/home/widgets/saved_connections/connection_box.dart';

RemoteBridgeInfo _info({String latest = '0.4.3', bool available = true}) =>
    RemoteBridgeInfo(
      id: 'b_1',
      name: 'GAMING-PC',
      kind: 'standalone',
      version: '0.4.1',
      online: true,
      lastSeen: null,
      obsState: 'running',
      updateRequired: false,
      latestVersion: latest,
      updateAvailable: available,
      devices: const [],
    );

/// Relay log 2026-11-20..22: a PC before 0.4.2 answered "OBS not running"
/// while OBS ran - the Start OBS dialog names the update that fixes it
void main() {
  test('a newer OBS Blade Remote is named with where to get it', () {
    expect(
      remoteStartObsUpdateNote(_info(), 'GAMING-PC'),
      '\n\nOBS Blade Remote 0.4.3 is available for GAMING-PC (it has 0.4.1) '
      '- get it at obs-blade.kounex.com/remote.',
    );
  });

  test('nothing newer, or an older relay without the version: no note', () {
    expect(remoteStartObsUpdateNote(_info(available: false), 'PC'), '');
    expect(remoteStartObsUpdateNote(_info(latest: ''), 'PC'), '');
  });
}
