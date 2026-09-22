import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/kick/kick_pusher_event.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';
import 'package:obs_blade/utils/kick/kick_pusher_service.dart';

class FakeKickChannelService extends KickChannelService {
  /// slug → channel info; a missing key resolves to null (channel not
  /// found).
  final Map<String, KickChannelInfo?> channels = <String, KickChannelInfo>{};
  int resolveCalls = 0;
  Object? resolveThrows;

  /// chatroom channel id → scripted history; a missing key resolves to
  /// an empty backfill.
  final Map<int, List<KickChatMessage>> backfills =
      <int, List<KickChatMessage>>{};
  int backfillCalls = 0;
  Object? backfillThrows;

  @override
  Future<KickChannelInfo?> resolveChannel(String slug) async {
    this.resolveCalls++;
    if (this.resolveThrows != null) throw this.resolveThrows!;
    return this.channels[slug];
  }

  @override
  Future<List<KickChatMessage>> backfillMessages(int channelId) async {
    this.backfillCalls++;
    if (this.backfillThrows != null) throw this.backfillThrows!;
    final messages = List<KickChatMessage>.of(
      this.backfills[channelId] ?? const [],
    );

    /// Same arrival-order contract as the real service.
    messages.sort(
      (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );
    return messages;
  }
}

class FakeKickPusherService extends KickPusherService {
  FakeKickPusherService({
    required super.onEvent,
    required super.onStateChanged,
  });

  /// Chatroom ids of every [connect] call.
  final List<int> connectCalls = <int>[];
  int disconnectCalls = 0;

  /// Whether [connect] reports the socket as connected immediately
  /// (tests drive state transitions via [emitState] when false).
  bool autoConnect = true;

  @override
  Future<void> connect({required int chatroomId}) async {
    this.connectCalls.add(chatroomId);
    if (this.autoConnect) {
      this.onStateChanged(KickPusherConnectionState.connected);
    }
  }

  @override
  Future<void> disconnect() async {
    this.disconnectCalls++;

    /// Intentionally no `disconnected` emission: the store's own flow
    /// guard owns the state on teardown (mirrors the real service's
    /// superseded-callback path).
  }

  void emitEvent(KickPusherEvent event) => this.onEvent(event);

  void emitState(KickPusherConnectionState state) => this.onStateChanged(state);
}
