// Live check against a REAL local OBS (macOS, docs/local-obs-e2e.md): the
// real DashboardStore fetches the source colors (Sources dock -> Set Color)
// of the current program scene's items. Read-only - changes nothing in OBS.
// Give an item a color in OBS first; the test prints what the store holds
// and fails when an item OBS reports a color for stays uncolored.
// Not part of any suite - run by hand:
//   flutter test tool/obs_local/source_colors_live_test.dart
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:obs_blade/utils/scene_item_color.dart';

import '../../test/persistence/support/hive_test_harness.dart';

void main() {
  test('live: source colors against local OBS', () async {
    final tempDir = await Directory.systemTemp.createTemp('colors_live');
    final harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();

    final cfg =
        jsonDecode(
              File(
                '${Platform.environment['HOME']}/Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final networkStore = NetworkStore();
    final store = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(store);
    final code = await networkStore.setOBSWebSocket(
      Connection(
        '127.0.0.1',
        cfg['server_port'] as int? ?? 4455,
        cfg['server_password'] as String?,
      ),
    );
    expect(code, WebSocketCloseCode.DontClose);
    store.handleStream();
    store.initialRequests();
    final socket = networkStore.activeSession!.socket;

    await Future<void>.delayed(const Duration(seconds: 3));

    print('activeSceneName=${store.activeSceneName}');
    print('sceneItemsSceneName=${store.sceneItemsSceneName}');
    print(
      'supports GetSceneItemPrivateSettings='
      '${store.supportsRequest(RequestType.GetSceneItemPrivateSettings)}',
    );
    print('sceneItemColors=${Map.of(store.sceneItemColors)}');

    /// What OBS itself says, item by item, vs. what the store holds
    final missing = <String>[];
    for (final item in store.currentSceneItems) {
      final scene = item.parentGroupName ?? store.activeSceneName!;
      final answer = await NetworkHelper.makeScopedRequest(
        socket,
        RequestType.GetSceneItemPrivateSettings,
        {'sceneName': scene, 'sceneItemId': item.sceneItemId},
      );
      final settings =
          (answer.responseData?['sceneItemSettings'] as Map?)
              ?.cast<String, dynamic>() ??
          {};
      final expected = sceneItemColor(settings);
      final held =
          store.sceneItemColors[sceneItemColorKey(scene, item.sceneItemId!)];
      print(
        '  $scene / #${item.sceneItemId} "${item.sourceName}": '
        'OBS=$settings -> $expected, store=$held',
      );
      if (expected != held) missing.add('${item.sourceName}');
    }

    networkStore.closeSession();
    await harness.close();
    expect(missing, isEmpty, reason: 'store colors differ from OBS');
  });
}
