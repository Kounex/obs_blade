import 'dart:async';

import 'package:obs_blade/utils/general_helper.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Parsed IRC PRIVMSG tags we care about for the EventSub merge.
class TwitchIrcPrivmsgMeta {
  final String messageId;
  final bool isFirstMessage;

  const TwitchIrcPrivmsgMeta({
    required this.messageId,
    required this.isFirstMessage,
  });
}

/// Tag map from an IRC line that starts with `@… `.
Map<String, String> parseIrcTags(String tagBlock) {
  final out = <String, String>{};
  for (final part in tagBlock.split(';')) {
    if (part.isEmpty) continue;
    final eq = part.indexOf('=');
    if (eq <= 0) {
      out[part] = '';
    } else {
      out[part.substring(0, eq)] = part.substring(eq + 1);
    }
  }
  return out;
}

/// Returns meta when [line] is a tagged PRIVMSG with an `id` tag.
TwitchIrcPrivmsgMeta? parseIrcPrivmsgMeta(String line) {
  if (!line.startsWith('@')) return null;
  final space = line.indexOf(' ');
  if (space <= 1) return null;
  final tags = parseIrcTags(line.substring(1, space));
  final rest = line.substring(space + 1);
  if (!rest.contains(' PRIVMSG ')) return null;
  final id = tags['id'];
  if (id == null || id.isEmpty) return null;
  return TwitchIrcPrivmsgMeta(
    messageId: id,
    isFirstMessage: tags['first-msg'] == '1',
  );
}

/// Read-only Twitch IRC WebSocket used only for `first-msg` tags.
/// Message bodies stay on EventSub; failures never fail chat.
class TwitchIrcSidecar {
  static const String _wsUrl = 'wss://irc-ws.chat.twitch.tv:443';

  final void Function(String messageId) onFirstMessage;
  final WebSocketChannel Function(Uri) _channelFactory;
  final Future<void> Function(Duration) _sleep;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  bool _disposed = false;
  int _reconnectAttempts = 0;

  String? _accessToken;
  String? _login;
  String? _channelLogin;

  TwitchIrcSidecar({
    required this.onFirstMessage,
    WebSocketChannel Function(Uri)? channelFactory,
    Future<void> Function(Duration)? sleep,
  })  : _channelFactory = channelFactory ?? WebSocketChannel.connect,
        _sleep = sleep ?? Future.delayed;

  Future<void> connect({
    required String accessToken,
    required String login,
    required String channelLogin,
  }) async {
    this._accessToken = accessToken;
    this._login = login.toLowerCase();
    this._channelLogin = channelLogin.toLowerCase();
    this._reconnectAttempts = 0;
    await this._open();
  }

  /// Leave the current IRC room and join [channelLogin] (multi-chat).
  Future<void> switchChannel(String channelLogin) async {
    final login = channelLogin.toLowerCase();
    final previous = this._channelLogin;
    this._channelLogin = login;
    final channel = this._channel;
    if (channel == null) {
      if (this._accessToken != null && this._login != null) {
        await this._open();
      }
      return;
    }
    try {
      if (previous != null && previous.isNotEmpty) {
        channel.sink.add('PART #$previous\r\n');
      }
      channel.sink.add('JOIN #$login\r\n');
    } catch (e) {
      GeneralHelper.advLog('Twitch IRC switchChannel failed — $e');
      await this._open();
    }
  }

  Future<void> dispose() async {
    this._disposed = true;
    await this._tearDownSocket();
  }

  Future<void> _open() async {
    if (this._disposed) return;
    final token = this._accessToken;
    final nick = this._login;
    final room = this._channelLogin;
    if (token == null || nick == null || room == null) return;

    await this._tearDownSocket();
    try {
      final channel = this._channelFactory(Uri.parse(_wsUrl));
      this._channel = channel;
      this._socketSub = channel.stream.listen(
        this._onData,
        onError: (Object e) {
          GeneralHelper.advLog('Twitch IRC socket error — $e');
          unawaited(this._scheduleReconnect());
        },
        onDone: () {
          unawaited(this._scheduleReconnect());
        },
        cancelOnError: false,
      );

      channel.sink.add('PASS oauth:$token\r\n');
      channel.sink.add('NICK $nick\r\n');
      channel.sink.add('CAP REQ :twitch.tv/tags twitch.tv/commands\r\n');
      channel.sink.add('JOIN #$room\r\n');
      this._reconnectAttempts = 0;
    } catch (e) {
      GeneralHelper.advLog('Twitch IRC connect failed — $e');
      await this._scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    final text = raw is String ? raw : raw.toString();
    for (final line in text.split(RegExp(r'\r?\n'))) {
      if (line.isEmpty) continue;
      if (line.startsWith('PING ')) {
        this._channel?.sink.add('PONG ${line.substring(5)}\r\n');
        continue;
      }
      final meta = parseIrcPrivmsgMeta(line);
      if (meta != null && meta.isFirstMessage) {
        this.onFirstMessage(meta.messageId);
      }
    }
  }

  Future<void> _scheduleReconnect() async {
    if (this._disposed || this._accessToken == null) return;
    this._reconnectAttempts++;
    final delay = Duration(
      seconds: (1 << (this._reconnectAttempts - 1).clamp(0, 4)).clamp(1, 30),
    );
    await this._sleep(delay);
    if (this._disposed) return;
    await this._open();
  }

  Future<void> _tearDownSocket() async {
    await this._socketSub?.cancel();
    this._socketSub = null;
    try {
      await this._channel?.sink.close();
    } catch (_) {}
    this._channel = null;
  }
}
