import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

NativeChatWindow buildWindow({
  NativeChatConnectionStatus status = NativeChatConnectionStatus.live,
  String? statusDetail,
  String? accountLabel,
  DateTime? connectedAt,
  VoidCallback? onRetry,
  VoidCallback? onLogout,
  VoidCallback? onConnect,
}) =>
    NativeChatWindow(
      chatType: ChatType.Twitch,
      status: status,
      statusDetail: statusDetail,
      accountLabel: accountLabel,
      connectedAt: connectedAt,
      onRetry: onRetry,
      onLogout: onLogout,
      onConnect: onConnect,
      child: const Center(child: Text('chat content')),
    );

void main() {
  testWidgets('renders platform label, child and per-status labels',
      (tester) async {
    for (final (status, label) in [
      (NativeChatConnectionStatus.offline, 'offline'),
      (NativeChatConnectionStatus.connecting, 'connecting…'),
      (NativeChatConnectionStatus.live, 'connected'),
      (NativeChatConnectionStatus.reconnecting, 'reconnecting…'),
      (NativeChatConnectionStatus.failed, 'failed'),
    ]) {
      await tester.pumpWidget(wrap(buildWindow(status: status)));
      expect(find.text('Stream Chat'), findsOneWidget);
      expect(find.text(label), findsOneWidget);
      expect(find.text('chat content'), findsOneWidget);
    }
  });

  testWidgets('live: tapping the status row shows account and uptime',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        buildWindow(
          status: NativeChatConnectionStatus.live,
          accountLabel: 'Kounex',
          connectedAt: DateTime.now().subtract(const Duration(seconds: 90)),
        ),
      ),
    );

    await tester.tap(find.text('connected'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Twitch chat'), findsOneWidget);
    expect(find.text('Connected as Kounex'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'Connected for \d+:\d{2}')),
      findsOneWidget,
    );

    final before =
        tester.widget<Text>(find.textContaining('Connected for')).data!;
    await tester.pump(const Duration(seconds: 2));
    final after =
        tester.widget<Text>(find.textContaining('Connected for')).data!;
    expect(after, isNot(equals(before)));

    await tester.tapAt(const Offset(400, 100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('failed: sheet shows the error and fires retry + logout',
      (tester) async {
    var retried = false;
    var loggedOut = false;
    await tester.pumpWidget(
      wrap(
        buildWindow(
          status: NativeChatConnectionStatus.failed,
          statusDetail: 'Could not connect to Twitch chat',
          onRetry: () => retried = true,
          onLogout: () => loggedOut = true,
        ),
      ),
    );

    await tester.tap(find.text('failed'));
    await tester.pumpAndSettle();
    expect(find.text('Could not connect to Twitch chat'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(retried, isTrue);

    await tester.tap(find.text('failed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(loggedOut, isTrue);
  });

  testWidgets('offline: sheet fires connect', (tester) async {
    var connected = false;
    await tester.pumpWidget(
      wrap(
        buildWindow(
          status: NativeChatConnectionStatus.offline,
          onConnect: () => connected = true,
        ),
      ),
    );

    await tester.tap(find.text('offline'));
    await tester.pumpAndSettle();

    expect(find.text('Connect Twitch'), findsOneWidget);
    await tester.tap(find.text('Connect Twitch'));
    await tester.pumpAndSettle();
    expect(connected, isTrue);
  });

  group('formatChatUptime', () {
    test('m:ss under an hour', () {
      expect(formatChatUptime(Duration.zero), '0:00');
      expect(formatChatUptime(const Duration(seconds: 5)), '0:05');
      expect(
        formatChatUptime(const Duration(minutes: 1, seconds: 5)),
        '1:05',
      );
      expect(
        formatChatUptime(const Duration(minutes: 59, seconds: 59)),
        '59:59',
      );
    });

    test('h:mm:ss beyond an hour', () {
      expect(formatChatUptime(const Duration(hours: 1)), '1:00:00');
      expect(
        formatChatUptime(
          const Duration(hours: 1, minutes: 2, seconds: 5),
        ),
        '1:02:05',
      );
    });
  });

  testWidgets('live sheet uptime ticks while open', (tester) async {
    await tester.pumpWidget(
      wrap(
        buildWindow(
          status: NativeChatConnectionStatus.live,
          accountLabel: 'Kounex',
          connectedAt: DateTime.now().subtract(const Duration(seconds: 90)),
        ),
      ),
    );

    await tester.tap(find.text('connected'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final before =
        tester.widget<Text>(find.textContaining('Connected for')).data!;
    await tester.pump(const Duration(seconds: 2));
    final after =
        tester.widget<Text>(find.textContaining('Connected for')).data!;

    expect(after, isNot(equals(before)));

    await tester.tapAt(const Offset(400, 100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  });
}
