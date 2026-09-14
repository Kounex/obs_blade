import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/redesign/chat/chat_lab_fixture.dart';
import 'package:obs_blade/redesign/chat/workspace_chat_timeline.dart';
import 'package:obs_blade/redesign/workspace/workspace_app.dart';
import 'package:obs_blade/redesign/workspace/workspace_model.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/youtube_chat_message_row.dart';

void main() {
  late ChatLabFixture fixture;
  late WorkspaceModel workspace;
  setUp(() async {
    fixture = await ChatLabFixture.create();
    workspace = WorkspaceModel()..setFocus(WorkspaceFocus.chat);
  });
  tearDown(() async {
    workspace.dispose();
    await fixture.dispose();
  });
  Future<void> mount(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      WorkspaceApp(
        model: workspace,
        chatPane: Builder(builder: fixture.buildPane),
      ),
    );
    await tester.pumpAndSettle();
  }

  final composer = find.byKey(const Key('workspace-chat-composer'));
  final channel = find.byKey(const Key('workspace-chat-channel'));

  testWidgets(
    'rich rows render without global services and send uses the adapter',
    (tester) async {
      await mount(tester);
      expect(find.byType(TwitchChatMessageRow), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.enterText(composer, 'Sent from the workspace');
      await tester.pump();
      await tester.tap(find.byKey(const Key('workspace-chat-send')));
      await tester.pumpAndSettle();
      expect(
        fixture.twitch.messages.last.message.text,
        'Sent from the workspace',
      );
      expect(tester.widget<TextField>(composer).controller!.text, isEmpty);
    },
  );

  testWidgets('buffer trimming cannot retarget a pending message hold', (
    tester,
  ) async {
    await mount(tester);
    final row = find.byWidgetPredicate(
      (widget) =>
          widget is TwitchChatMessageRow &&
          widget.event.messageId == 'studio-18',
    );
    expect(row, findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(row));
    await tester.pump(const Duration(milliseconds: 180));
    runInAction(() => fixture.twitch.messages.removeAt(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pumpAndSettle();
    // A row can move or disappear during the hold. Cancellation is acceptable;
    // opening actions for a replacement message is not.
    expect(find.text('Reply to Jules'), findsNothing);
    expect(find.text('Reply to River'), findsNothing);
  });

  testWidgets('channel picker keeps each draft and restores it on return', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(composer, 'For studio');
    await tester.tap(channel);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Community lounge').last);
    await tester.pumpAndSettle();
    expect(fixture.controller.conversation?.channel, 'lounge');
    expect(tester.widget<TextField>(composer).controller!.text, isEmpty);
    await tester.enterText(composer, 'For lounge');
    await tester.tap(channel);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Studio chat').last);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(composer).controller!.text, 'For studio');
    expect(tester.takeException(), isNull);
  });

  testWidgets('paused reading position survives a channel round trip', (
    tester,
  ) async {
    await mount(tester);
    final list = find.descendant(
      of: find.byType(WorkspaceChatTimeline),
      matching: find.byType(ListView),
    );
    await tester.drag(list, const Offset(0, 240));
    await tester.pumpAndSettle();
    expect(find.text('Return live'), findsOneWidget);
    ScrollPosition position() => tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(WorkspaceChatTimeline),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    final before = position().pixels;
    await tester.tap(channel);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Community lounge').last);
    await tester.pumpAndSettle();
    await tester.tap(channel);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Studio chat').last);
    await tester.pumpAndSettle();
    expect(find.text('Return live'), findsOneWidget);
    expect(position().pixels, closeTo(before, 1));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.text('Return live'), findsOneWidget);
    expect(position().pixels, closeTo(before, 1));
  });

  testWidgets(
    'following stays at the newest row after reply and keyboard resize',
    (tester) async {
      await mount(tester);
      ScrollPosition position() => tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(WorkspaceChatTimeline),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      expect(position().extentAfter, lessThan(1));
      fixture.controller.setReply(fixture.twitch.messages.last);
      await tester.pumpAndSettle();
      expect(position().extentAfter, lessThan(1));
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(position().extentAfter, lessThan(1));
      expect(find.text('Return live'), findsNothing);
    },
  );

  testWidgets(
    'reply and composer survive phone/tablet reparenting and OBS focus',
    (tester) async {
      await mount(tester);
      await tester.longPress(find.byType(TwitchChatMessageRow).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reply to River'));
      await tester.pumpAndSettle();
      expect(fixture.controller.reply?.messageId, 'studio-23');
      final hold = find.descendant(
        of: find.byType(TwitchChatMessageRow).last,
        matching: find.byType(ChatRowLongPressListener),
      );
      expect(
        tester
            .widget<ColoredBox>(
              find
                  .descendant(of: hold, matching: find.byType(ColoredBox))
                  .first,
            )
            .color,
        Colors.transparent,
      );
      await tester.enterText(composer, 'A reply draft');
      final editing = tester.widget<TextField>(composer).controller;
      workspace.setFocus(WorkspaceFocus.obs);
      await tester.pumpAndSettle();
      workspace.setFocus(WorkspaceFocus.chat);
      tester.view.physicalSize = const Size(1100, 844);
      await tester.pumpAndSettle();
      expect(
        identical(tester.widget<TextField>(composer).controller, editing),
        true,
      );
      expect(editing!.text, 'A reply draft');
      expect(fixture.controller.reply?.messageId, 'studio-23');

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Pro gate hides rows and restores the pending composition', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(composer, 'Keep this');
    fixture.pro.boughtPro = false;
    await tester.pumpAndSettle();
    expect(find.byType(TwitchChatMessageRow), findsNothing);
    expect(composer, findsNothing);
    fixture.pro.boughtPro = true;
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(composer).controller!.text, 'Keep this');
    expect(tester.takeException(), isNull);
  });

  testWidgets('losing write permission keeps reading and the draft', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(composer, 'Keep for later');
    runInAction(() => fixture.twitch.writeAllowed.value = false);
    await tester.pumpAndSettle();
    expect(find.byType(TwitchChatMessageRow), findsWidgets);
    expect(
      tester.widget<TextField>(composer).controller!.text,
      'Keep for later',
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('workspace-chat-send')))
          .onPressed,
      isNull,
    );
    await tester.enterText(composer, 'A revised draft');
    runInAction(() => fixture.twitch.writeAllowed.value = true);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(composer).controller!.text,
      'A revised draft',
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('workspace-chat-send')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('large text and keyboard keep the composer bounded', (
    tester,
  ) async {
    await mount(tester, width: 360);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final send = tester.getRect(find.byKey(const Key('workspace-chat-send')));
    expect(send.bottom, lessThanOrEqualTo(844 - 260));
    expect(send.top, greaterThan(0));
  });

  testWidgets('YouTube uses its specialized paid-message row', (tester) async {
    await mount(tester);
    fixture.controller.setPresentation(ChatType.YouTube, ChatEngine.native);
    await tester.pumpAndSettle();
    expect(find.byType(YouTubeChatMessageRow), findsOneWidget);
    expect(find.textContaining('€5.00'), findsWidgets);
    final amount = tester.widget<Text>(find.text('€5.00'));
    final theme = Theme.of(tester.element(find.byType(YouTubeChatMessageRow)));
    final background = Color.alphaBlend(
      youTubeSuperChatTierColor(1).withValues(alpha: .15),
      theme.scaffoldBackgroundColor,
    );
    final luminances = [
      amount.style!.color!.computeLuminance(),
      background.computeLuminance(),
    ]..sort();
    expect(
      (luminances.last + .05) / (luminances.first + .05),
      greaterThanOrEqualTo(4.5),
    );
    expect(tester.takeException(), isNull);
  });
}
