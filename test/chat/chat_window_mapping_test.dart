import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';

void main() {
  test('twitchChatWindowStatus maps every connection state when logged in',
      () {
    expect(
      twitchChatWindowStatus(TwitchChatConnectionState.live, true),
      NativeChatConnectionStatus.live,
    );
    expect(
      twitchChatWindowStatus(TwitchChatConnectionState.connecting, true),
      NativeChatConnectionStatus.connecting,
    );
    expect(
      twitchChatWindowStatus(TwitchChatConnectionState.reconnecting, true),
      NativeChatConnectionStatus.reconnecting,
    );
    expect(
      twitchChatWindowStatus(TwitchChatConnectionState.failed, true),
      NativeChatConnectionStatus.failed,
    );
    expect(
      twitchChatWindowStatus(TwitchChatConnectionState.disconnected, true),
      NativeChatConnectionStatus.offline,
    );
  });

  test('logged out always maps to offline', () {
    for (final state in TwitchChatConnectionState.values) {
      expect(
        twitchChatWindowStatus(state, false),
        NativeChatConnectionStatus.offline,
      );
    }
  });

  test('youTubeChatWindowStatus maps every connection state when configured',
      () {
    expect(
      youTubeChatWindowStatus(YouTubeChatConnectionState.connected, true),
      NativeChatConnectionStatus.live,
    );
    expect(
      youTubeChatWindowStatus(YouTubeChatConnectionState.connecting, true),
      NativeChatConnectionStatus.connecting,
    );
    expect(
      youTubeChatWindowStatus(YouTubeChatConnectionState.error, true),
      NativeChatConnectionStatus.failed,
    );
    expect(
      youTubeChatWindowStatus(YouTubeChatConnectionState.offline, true),
      NativeChatConnectionStatus.offline,
    );
    expect(
      youTubeChatWindowStatus(YouTubeChatConnectionState.idle, true),
      NativeChatConnectionStatus.offline,
    );
  });

  test('youTubeChatWindowStatus maps to offline when no API key is set', () {
    for (final state in YouTubeChatConnectionState.values) {
      expect(
        youTubeChatWindowStatus(state, false),
        NativeChatConnectionStatus.offline,
      );
    }
  });
}
