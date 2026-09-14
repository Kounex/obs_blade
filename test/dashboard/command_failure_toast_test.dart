import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/command_failure_notice.dart';
import 'package:obs_blade/types/classes/obs_request_ack.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/views/dashboard/widgets/command_failure_toast.dart';

import '../persistence/support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late DashboardStore dashboardStore;

  Widget wrap() => MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      cupertinoOverrideTheme: const CupertinoThemeData(),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    home: const Scaffold(body: Center(child: CommandFailureToast())),
  );

  /// BaseCard reads the settings box (custom theme check)
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('command_failure_toast');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);

    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('shows a new notice and auto-dismisses', (tester) async {
    const message = 'Scene switch failed - OBS rejected the command';

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text(message), findsNothing);

    dashboardStore.commandFailureNotice = CommandFailureNotice(
      message: message,
      ack: const ObsRequestAck.rejected(
        RequestType.SetCurrentProgramScene,
        602,
        'No source with that name',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text(message), findsOneWidget);
    final toastFade = find.descendant(
      of: find.byType(CommandFailureToast),
      matching: find.byType(FadeTransition),
    );
    expect(
      tester.widget<FadeTransition>(toastFade).opacity.value,
      greaterThan(0.99),
    );

    /// 4s visible, then the reverse animation - a restarted ticker only
    /// moves the value from its second frame on, hence the extra pumps
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      tester.widget<FadeTransition>(toastFade).opacity.value,
      lessThan(0.01),
    );
  });

  testWidgets('a newer notice replaces the shown message', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    dashboardStore.commandFailureNotice = CommandFailureNotice(
      message: 'First failure',
      ack: const ObsRequestAck.timeout(RequestType.SetInputMute),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('First failure'), findsOneWidget);

    dashboardStore.commandFailureNotice = CommandFailureNotice(
      message: 'Second failure',
      ack: const ObsRequestAck.timeout(RequestType.SetInputVolume),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('First failure'), findsNothing);
    expect(find.text('Second failure'), findsOneWidget);
  });
}
