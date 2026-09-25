import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/text_source_sheet.dart';

import '../persistence/support/hive_test_harness.dart';
import '../websocket/support/fake_obs_peer.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeObsPeer peer;
  late NetworkStore networkStore;
  late DashboardStore dashboardStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('text_source_sheet');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    peer = await FakeObsPeer.start();
    networkStore = NetworkStore();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
  });

  tearDown(() async {
    dashboardStore.disposeListeners();
    networkStore.closeSession();
    await peer.close();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('text kinds are detected across OBS platform variants', () {
    expect(isTextInputKind('text_gdiplus_v3'), isTrue);
    expect(isTextInputKind('text_ft2_source_v2'), isTrue);
    expect(isTextInputKind('ffmpeg_source'), isFalse);
    expect(isTextInputKind(null), isFalse);
  });

  testWidgets('loads the current text and saves it with overlay', (
    tester,
  ) async {
    peer.responseData['GetInputSettings'] = {
      'inputSettings': {'text': 'Starting soon', 'font': 'x'},
      'inputKind': 'text_ft2_source_v2',
    };

    await tester.runAsync(() async {
      final closeCode = await networkStore.setOBSWebSocket(peer.connection);
      expect(closeCode, WebSocketCloseCode.DontClose);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          cupertinoOverrideTheme: const CupertinoThemeData(),
          extensions: const [AppStatusColors.standard, AppTextColors.standard],
        ),
        home: const Scaffold(body: TextSourceSheet(inputName: 'Title')),
      ),
    );

    await tester.runAsync(() async {
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
        if (find.text('Starting soon').evaluate().isNotEmpty) break;
      }
    });
    expect(find.text('Starting soon'), findsOneWidget);

    await tester.enterText(find.byType(CupertinoTextField), 'Be right back');
    await tester.runAsync(() async {
      await tester.tap(find.text('Update'));
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (peer.requests.any(
          (request) => request['requestType'] == 'SetInputSettings',
        )) {
          break;
        }
      }
    });

    final set = peer.requests.lastWhere(
      (request) => request['requestType'] == 'SetInputSettings',
    );
    expect(set['requestData'], {
      'inputName': 'Title',
      'inputSettings': {'text': 'Be right back'},
      'overlay': true,
    });
  });
}
