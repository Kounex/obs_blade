import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_chrome.dart';
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
  String? selfUserId,
}) => NativeChatWindow(
  chatType: ChatType.Twitch,
  status: status,
  statusDetail: statusDetail,
  accountLabel: accountLabel,
  connectedAt: connectedAt,
  onRetry: onRetry,
  onLogout: onLogout,
  onConnect: onConnect,
  selfUserId: selfUserId,
  child: const Center(child: Text('chat content')),
);

void main() {
  testWidgets('renders window label, child and per-status labels', (
    tester,
  ) async {
    for (final (status, label) in [
      (NativeChatConnectionStatus.offline, 'offline'),
      (NativeChatConnectionStatus.connecting, 'connecting…'),
      (NativeChatConnectionStatus.reconnecting, 'reconnecting…'),
      (NativeChatConnectionStatus.failed, 'failed'),
    ]) {
      await tester.pumpWidget(wrap(buildWindow(status: status)));
      await tester.pumpAndSettle();
      expect(find.text('Stream Chat'), findsOneWidget);
      expect(find.text(label), findsOneWidget);
      expect(find.text('chat content'), findsOneWidget);
    }
  });

  testWidgets('connected is quiet: no label, and never the live green', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(buildWindow(status: NativeChatConnectionStatus.live)),
    );
    await tester.pumpAndSettle();

    expect(find.text('connected'), findsNothing);
    final green = AppStatusColors.standard.live;
    final greenDots = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
          (w.decoration! as BoxDecoration).color == green,
    );
    expect(greenDots, findsNothing);
  });

  testWidgets('LIVE/Mod chips sit after the title, before connection status', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        NativeChatWindow(
          chatType: ChatType.Twitch,
          status: NativeChatConnectionStatus.live,
          channelIsLive: true,
          channelViewerCount: 1200,
          channelIsMod: true,
          child: const Center(child: Text('chat content')),
        ),
      ),
    );

    final titleX = tester.getTopLeft(find.text('Stream Chat')).dx;
    final liveX = tester
        .getTopLeft(find.byKey(const Key('chat-header-live')))
        .dx;
    final modX = tester.getTopLeft(find.byKey(const Key('chat-header-mod'))).dx;
    final statusX = tester
        .getTopLeft(find.byKey(const Key('chat-header-status')))
        .dx;

    expect(titleX, lessThan(liveX));
    expect(liveX, lessThan(modX));
    expect(modX, lessThan(statusX));
    expect(find.text('LIVE · '), findsOneWidget);
    expect(find.text('1.2k'), findsOneWidget);
  });

  group('formatChatViewerCount', () {
    test('formats compact counts', () {
      expect(formatChatViewerCount(42), '42');
      expect(formatChatViewerCount(999), '999');
      expect(formatChatViewerCount(1000), '1k');
      expect(formatChatViewerCount(1200), '1.2k');
      expect(formatChatViewerCount(3400), '3.4k');
      expect(formatChatViewerCount(10500), '10.5k');
      expect(formatChatViewerCount(1000000), '1M');
      expect(formatChatViewerCount(12500000), '12.5M');
    });
  });

  testWidgets('offline without selfUserId keeps the connect-only sheet', (
    tester,
  ) async {
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
    expect(find.text('Twitch chat'), findsOneWidget);
    await tester.tap(find.text('Connect Twitch'));
    await tester.pumpAndSettle();
    expect(connected, isTrue);
  });

  testWidgets('offline chat with a note: signed in, explains the chat, '
      'offers sign-out instead of connect', (tester) async {
    var signedOut = false;
    await tester.pumpWidget(
      wrap(
        NativeChatWindow(
          chatType: ChatType.YouTube,
          status: NativeChatConnectionStatus.offline,
          accountLabel: 'Brand Channel',
          offlineNote: 'Brand Channel isn\'t live right now.',
          onLogout: () => signedOut = true,
          child: const Center(child: Text('chat content')),
        ),
      ),
    );

    await tester.tap(find.text('offline'));
    await tester.pumpAndSettle();

    expect(find.text('Signed in as Brand Channel'), findsOneWidget);
    expect(find.text('Brand Channel isn\'t live right now.'), findsOneWidget);
    expect(find.textContaining('Not connected'), findsNothing);
    expect(find.text('Connect YouTube'), findsNothing);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
  });

  testWidgets('offline chat with a note, read-only: the connect action '
      'uses its own label', (tester) async {
    await tester.pumpWidget(
      wrap(
        NativeChatWindow(
          chatType: ChatType.YouTube,
          status: NativeChatConnectionStatus.offline,
          offlineNote: 'No live chat right now.',
          onConnect: () {},
          connectLabel: 'Sign in to write and moderate',
          child: const Center(child: Text('chat content')),
        ),
      ),
    );

    await tester.tap(find.text('offline'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Signed in as'), findsNothing);
    expect(find.text('Sign in to write and moderate'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('failed without selfUserId keeps the connection sheet', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      wrap(
        buildWindow(
          status: NativeChatConnectionStatus.failed,
          statusDetail: 'Could not connect to Twitch chat',
          onRetry: () => retried = true,
        ),
      ),
    );

    await tester.tap(find.text('failed'));
    await tester.pumpAndSettle();
    expect(find.text('Could not connect to Twitch chat'), findsOneWidget);
    expect(find.text('Twitch chat'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(retried, isTrue);
  });

  /// The chat bar has no account chip - signing out of a healthy chat
  /// happens in this sheet (YouTube / Kick; Twitch's header opens its
  /// self card, which has its own Log out)
  testWidgets('live: the sheet shows the account and signs out', (
    tester,
  ) async {
    var signedOut = false;
    await tester.pumpWidget(
      wrap(
        buildWindow(accountLabel: 'kounex', onLogout: () => signedOut = true),
      ),
    );
    await tester.tap(find.text('Stream Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Connected as kounex'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
  });

  testWidgets('degraded without a session offers no sign-out', (tester) async {
    await tester.pumpWidget(
      wrap(buildWindow(status: NativeChatConnectionStatus.failed)),
    );
    await tester.tap(find.text('failed'));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('live with selfUserId routes through the merged card entry', (
    tester,
  ) async {
    var mergedCard = false;
    await tester.pumpWidget(
      wrap(
        NativeChatWindow(
          chatType: ChatType.Twitch,
          status: NativeChatConnectionStatus.live,
          accountLabel: 'Kounex',
          selfUserId: 'self-1',
          onStatusTapOverride: () => mergedCard = true,
          child: const Center(child: Text('chat content')),
        ),
      ),
    );

    await tester.tap(find.text('Stream Chat'));
    expect(mergedCard, isTrue);
  });

  group('formatChatUptime', () {
    test('m:ss under an hour', () {
      expect(formatChatUptime(Duration.zero), '0:00');
      expect(formatChatUptime(const Duration(seconds: 5)), '0:05');
      expect(formatChatUptime(const Duration(minutes: 1, seconds: 5)), '1:05');
      expect(
        formatChatUptime(const Duration(minutes: 59, seconds: 59)),
        '59:59',
      );
    });

    test('h:mm:ss beyond an hour', () {
      expect(formatChatUptime(const Duration(hours: 1)), '1:00:00');
      expect(
        formatChatUptime(const Duration(hours: 1, minutes: 2, seconds: 5)),
        '1:02:05',
      );
    });
  });

  testWidgets('renders the input slot below the content when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        NativeChatWindow(
          chatType: ChatType.Twitch,
          status: NativeChatConnectionStatus.live,
          input: const Text('dock'),
          child: const Center(child: Text('chat content')),
        ),
      ),
    );

    expect(find.text('chat content'), findsOneWidget);
    expect(find.text('dock'), findsOneWidget);
  });
}
