import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/redesign/workspace/audio_input_control.dart';
import 'package:obs_blade/redesign/workspace/workspace_audio.dart';
import 'package:obs_blade/redesign/workspace/workspace_model.dart';

void main() {
  testWidgets('gain above unity remains visible without changing OBS', (
    tester,
  ) async {
    final model = _AudioFixture();
    addTearDown(model.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(child: WorkspaceAudio(model: model)),
          ),
        ),
      ),
    );
    expect(find.text('OBS level 140% · slider range 0–100%'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 1);
    expect(model.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh cancels a local drag without leaving a false level', (
    tester,
  ) async {
    final model = _AudioFixture();
    addTearDown(model.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: model,
            builder: (_, _) => WorkspaceAudio(model: model),
          ),
        ),
      ),
    );
    final slider = find.byType(Slider);
    final gesture = await tester.startGesture(tester.getCenter(slider));
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    model.change(ready: false);
    await tester.pump();
    await gesture.up();
    model.change(ready: true, volume: .7);
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(slider).value, .7);
    expect(model.writes, isEmpty);
  });
}

class _AudioFixture extends WorkspaceModel {
  bool ready = true;
  double level = 1.4;
  final writes = <double>[];

  @override
  bool get audioReady => ready;
  @override
  List<AudioInputControl> get audioInputs => [
    AudioInputControl(
      name: 'Music',
      volume: level,
      muted: false,
      fresh: ready,
      busy: false,
    ),
  ];
  @override
  Future<void> setInputVolume(String name, double volume) async =>
      writes.add(volume);

  void change({required bool ready, double? volume}) {
    this.ready = ready;
    level = volume ?? level;
    notifyListeners();
  }
}
