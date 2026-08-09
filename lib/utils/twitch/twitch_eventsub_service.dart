import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_moderate_event.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/eventsub_envelope.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum TwitchEventSubState { disconnected, connecting, connected, reconnecting }

/// Dedicated EventSub WebSocket session for chat messages + moderation
/// lifecycle events (`message_delete`, `clear_user_messages`, `clear`,
/// optionally `channel.moderate` v2 for the deleting-mod reveal).
/// Completely separate from the OBS WebSocket — owns its socket, keepalive
/// watchdog and reconnect backoff. [channelFactory] and [sleep] are
/// injectable for tests.
class TwitchEventSubService {
  static const String _wsUrl =
      'wss://eventsub.wss.twitch.tv/ws?keepalive_timeout_seconds=30';
  static const String _subscriptionsUrl =
      'https://api.twitch.tv/helix/eventsub/subscriptions';

  /// No message (not even a keepalive) for this long → treat as dead
  static const Duration _watchdogWindow = Duration(seconds: 75);
  static const Duration _maxBackoff = Duration(seconds: 30);

  /// Subscription types created on a fresh session, in POST order.
  /// `channel.chat.message` is mandatory — a failure routes to [onRevoked].
  /// The three lifecycle types are best-effort: failures are logged and
  /// degrade tombstones, never chat.
  static const List<String> _kSubscriptionTypes = <String>[
    'channel.chat.message',
    'channel.chat.notification',
    'channel.chat.message_delete',
    'channel.chat.clear_user_messages',
    'channel.chat.clear',
  ];
  static const String _kMessageType = 'channel.chat.message';

  /// `channel.moderate` v2 — optional best-effort type after the channel
  /// chat suite, created only when [connect] passes `includeModeration`
  /// (the token must carry the full moderator:read bundle; condition
  /// uses `moderator_user_id`).
  static const String _kModerateType = 'channel.moderate';

  final http.Client _client;
  final WebSocketChannel Function(Uri) _channelFactory;
  final Future<void> Function(Duration) _sleep;

  final void Function(ChatMessageEvent event) onChatMessage;

  /// Chat notifications (subs, streaks, raids…) — best-effort; null skips.
  final void Function(ChatNotificationEvent event)? onChatNotification;

  /// Lifecycle callbacks — optional; a null callback skips parsing for
  /// that type (tests / non-lifecycle consumers).
  final void Function(ChatMessageDeleteEvent event)? onMessageDelete;
  final void Function(ChatClearUserMessagesEvent event)?
      onClearUserMessages;
  final void Function(ChatClearEvent event)? onChatClear;

  /// `channel.moderate` delete actions — (messageId, moderator display
  /// name). Optional; a null callback skips parsing for this type.
  final void Function(String messageId, String moderatorName)?
      onModerationDelete;

  final void Function(TwitchEventSubState state) onStateChanged;

  /// Subscription revoked by Twitch (e.g. `authorization_revoked`) or
  /// creation failed (`subscription_failed:<status>`)
  final void Function(String reason) onRevoked;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _watchdog;

  String? _accessToken;

  /// The session's authenticated user — keepalive of `user_id` in chat
  /// conditions and BOTH slots of the own-channel `channel.moderate` sub.
  String? _userId;

  /// The channel chat is read from / sent to — `broadcaster_user_id` in
  /// the chat + lifecycle conditions. Own id in single-chat mode, any
  /// added channel after a multi-chat [switchChannel].
  String? _broadcasterId;
  bool _includeModeration = false;
  String? _sessionId;

  /// Channel-scoped ids created on the current session (message +
  /// whichever lifecycle subscriptions succeeded) — resume check, channel
  /// switch teardown + best-effort cleanup. The moderate sub is tracked
  /// separately: it is own-channel and never channel-scoped.
  List<String> _subscriptionIds = <String>[];

  /// The own-channel `channel.moderate` v2 subscription id — untouched by
  /// [switchChannel], deleted on [dispose].
  String? _moderateSubscriptionId;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  TwitchEventSubService({
    required this.onChatMessage,
    this.onChatNotification,
    this.onMessageDelete,
    this.onClearUserMessages,
    this.onChatClear,
    this.onModerationDelete,
    required this.onStateChanged,
    required this.onRevoked,
    http.Client? client,
    WebSocketChannel Function(Uri)? channelFactory,
    Future<void> Function(Duration)? sleep,
  })  : _client = client ?? http.Client(),
        _channelFactory = channelFactory ?? WebSocketChannel.connect,
        _sleep = sleep ?? Future.delayed;

  Future<void> connect({
    required String accessToken,
    required String userId,
    required String broadcasterId,
    bool includeModeration = false,
  }) async {
    this._accessToken = accessToken;
    this._userId = userId;
    this._broadcasterId = broadcasterId;
    this._includeModeration = includeModeration;
    this._disposed = false;
    this._reconnectAttempts = 0;
    this._openSocket(Uri.parse(_wsUrl));
  }

  /// Move the chat to another channel ON THE SAME websocket session
  /// (multi-chat switch): the channel-scoped subscriptions are deleted
  /// best-effort and re-created with [broadcasterId]; the own-channel
  /// `channel.moderate` sub is not channel-scoped and stays untouched.
  Future<void> switchChannel(String broadcasterId) async {
    final subscriptionIds = List<String>.of(this._subscriptionIds);
    this._subscriptionIds = <String>[];
    final token = this._accessToken;
    if (token != null) {
      for (final id in subscriptionIds) {
        try {
          await this._client.delete(
            Uri.parse('$_subscriptionsUrl?id=$id'),
            headers: TwitchAuthService.helixHeaders(token),
          );
        } catch (_) {
          // best effort — Twitch drops them anyway once superseded
        }
      }
    }
    this._broadcasterId = broadcasterId;
    final subscribed = await this._createChannelSubscriptions();

    /// The store shows a connecting state during the switch — the socket
    /// never left the session, so a successful re-subscription is the live
    /// signal (a mandatory failure already routed to [onRevoked]).
    if (subscribed) this.onStateChanged(TwitchEventSubState.connected);
  }

  void _openSocket(Uri uri) {
    if (this._disposed) return;
    this.onStateChanged(
      this._reconnectAttempts == 0
          ? TwitchEventSubState.connecting
          : TwitchEventSubState.reconnecting,
    );
    this._channel = this._channelFactory(uri);
    this._socketSub = this._channel!.stream.listen(
      this._handleRawMessage,
      onDone: this._handleDisconnect,
      onError: (_) => this._handleDisconnect(),
      cancelOnError: true,
    );
    this._resetWatchdog();
  }

  void _handleRawMessage(dynamic raw) {
    this._resetWatchdog();

    Map<String, dynamic> decoded;
    try {
      decoded = json.decode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      GeneralHelper.advLog('Twitch EventSub: undecodable message — $e');
      return;
    }

    final envelope = EventSubEnvelope.fromJson(decoded);
    switch (envelope.metadata.messageType) {
      case 'session_welcome':
        this._handleWelcome(envelope.payload);
        break;
      case 'session_keepalive':
        break; // watchdog already reset
      case 'notification':
        this._handleNotification(envelope);
        break;
      case 'session_reconnect':
        this._handleReconnectRequest(envelope.payload);
        break;
      case 'revocation':
        this._handleRevocation(envelope.payload);
        break;
      default:
        GeneralHelper.advLog(
          'Twitch EventSub: unknown message_type '
          '${envelope.metadata.messageType}',
        );
    }
  }

  Future<void> _handleWelcome(Map<String, Object?> payload) async {
    final session = payload['session'] as Map<String, dynamic>;
    final sessionId = session['id'] as String;
    final resumed =
        sessionId == this._sessionId && this._subscriptionIds.isNotEmpty;
    this._sessionId = sessionId;
    this._reconnectAttempts = 0;
    this.onStateChanged(TwitchEventSubState.connected);

    /// A socket opened from `session_reconnect`'s reconnect_url resumes the
    /// session with subscriptions intact — only subscribe on fresh sessions.
    if (!resumed) {
      await this._createSubscriptions();
    }
  }

  void _handleNotification(EventSubEnvelope envelope) {
    final type = envelope.metadata.subscriptionType;
    try {
      switch (type) {
        case 'channel.chat.message':
          this.onChatMessage(
            ChatMessageEvent.fromJson(
              envelope.payload['event'] as Map<String, Object?>,
            ),
          );
        case 'channel.chat.notification':
          final callback = this.onChatNotification;
          if (callback != null) {
            callback(
              ChatNotificationEvent.fromJson(
                envelope.payload['event'] as Map<String, Object?>,
              ),
            );
          }
        case 'channel.chat.message_delete':
          final callback = this.onMessageDelete;
          if (callback != null) {
            callback(
              ChatMessageDeleteEvent.fromJson(
                envelope.payload['event'] as Map<String, Object?>,
              ),
            );
          }
        case 'channel.chat.clear_user_messages':
          final callback = this.onClearUserMessages;
          if (callback != null) {
            callback(
              ChatClearUserMessagesEvent.fromJson(
                envelope.payload['event'] as Map<String, Object?>,
              ),
            );
          }
        case 'channel.chat.clear':
          final callback = this.onChatClear;
          if (callback != null) {
            callback(
              ChatClearEvent.fromJson(
                envelope.payload['event'] as Map<String, Object?>,
              ),
            );
          }
        case 'channel.moderate':
          final callback = this.onModerationDelete;
          if (callback != null) {
            final event = ChannelModerateEvent.fromJson(
              envelope.payload['event'] as Map<String, Object?>,
            );
            final delete = event.delete;
            if (event.action == 'delete' && delete != null) {
              callback(delete.messageId, event.moderatorUserName);
            }
          }
      }
    } catch (e) {
      GeneralHelper.advLog('Twitch EventSub: could not parse $type event — $e');
    }
  }

  void _handleReconnectRequest(Map<String, Object?> payload) {
    final session = payload['session'] as Map<String, dynamic>;
    final reconnectUrl = session['reconnect_url'] as String?;
    if (reconnectUrl == null) {
      this._handleDisconnect();
      return;
    }
    this._closeSocket();
    this._openSocket(Uri.parse(reconnectUrl));
  }

  void _handleRevocation(Map<String, Object?> payload) {
    final subscription = payload['subscription'] as Map<String, dynamic>;
    final type = subscription['type'] as String?;
    if (type == null || type == _kMessageType) {
      /// A missing type is treated as the message subscription — the only
      /// one whose loss kills chat.
      this.onRevoked(subscription['status'] as String? ?? 'revoked');
    } else {
      GeneralHelper.advLog(
        'Twitch EventSub: lifecycle subscription $type revoked '
        '(${subscription['status']}) — tombstones degraded this session',
      );
    }
  }

  Future<void> _createSubscriptions() async {
    await this._createChannelSubscriptions();
    if (this._includeModeration) await this._createModerateSubscription();
  }

  /// The channel-scoped subs (message + notification + lifecycle) for the
  /// CURRENT [_broadcasterId] — run on a fresh session and on every
  /// [switchChannel]. `channel.chat.message` is mandatory — a failure
  /// routes to [onRevoked] and reports false. Notification + lifecycle
  /// types are best-effort: failures are logged and degrade features,
  /// never chat.
  Future<bool> _createChannelSubscriptions() async {
    final token = this._accessToken;
    final userId = this._userId;
    final broadcasterId = this._broadcasterId;
    final sessionId = this._sessionId;
    if (token == null ||
        userId == null ||
        broadcasterId == null ||
        sessionId == null) {
      return false;
    }

    final created = <String>[];
    for (final type in _kSubscriptionTypes) {
      final mandatory = type == _kMessageType;

      /// The socket-level failure path (DNS/socket/timeout) must not
      /// escape this unawaited future — surface it like a failed
      /// subscription.
      try {
        final response = await this._client.post(
          Uri.parse(_subscriptionsUrl),
          headers: {
            ...TwitchAuthService.helixHeaders(token),
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'type': type,
            'version': '1',
            'condition': {
              'broadcaster_user_id': broadcasterId,
              'user_id': userId,
            },
            'transport': {'method': 'websocket', 'session_id': sessionId},
          }),
        );

        if (response.statusCode == 202) {
          final data =
              (json.decode(response.body) as Map<String, dynamic>)['data'];
          final id = (data as List).first['id'] as String?;
          if (id != null) created.add(id);
        } else if (mandatory) {
          this.onRevoked('subscription_failed:${response.statusCode}');
          return false;
        } else {
          GeneralHelper.advLog(
            'Twitch EventSub: lifecycle subscription $type failed '
            '(${response.statusCode}) — tombstones degraded this session',
          );
        }
      } catch (e) {
        if (mandatory) {
          GeneralHelper.advLog(
              'Twitch EventSub: subscription POST failed — $e');
          this.onRevoked('subscription_failed:$e');
          return false;
        }
        GeneralHelper.advLog(
          'Twitch EventSub: lifecycle subscription $type failed — $e',
        );
      }
    }
    this._subscriptionIds = created;
    return true;
  }

  /// `channel.moderate` v2 — own-channel only (both condition slots are
  /// the session user), created once per session for the deleting-mod
  /// reveal. Best-effort: failures degrade the reveal, never chat.
  Future<void> _createModerateSubscription() async {
    final token = this._accessToken;
    final userId = this._userId;
    final sessionId = this._sessionId;
    if (token == null || userId == null || sessionId == null) return;

    try {
      final response = await this._client.post(
        Uri.parse(_subscriptionsUrl),
        headers: {
          ...TwitchAuthService.helixHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type': _kModerateType,
          'version': '2',
          'condition': {
            'broadcaster_user_id': userId,
            'moderator_user_id': userId,
          },
          'transport': {'method': 'websocket', 'session_id': sessionId},
        }),
      );

      if (response.statusCode == 202) {
        final data =
            (json.decode(response.body) as Map<String, dynamic>)['data'];
        this._moderateSubscriptionId = (data as List).first['id'] as String?;
      } else {
        GeneralHelper.advLog(
          'Twitch EventSub: lifecycle subscription $_kModerateType failed '
          '(${response.statusCode}) — tombstones degraded this session',
        );
      }
    } catch (e) {
      GeneralHelper.advLog(
        'Twitch EventSub: lifecycle subscription $_kModerateType failed — $e',
      );
    }
  }

  void _handleDisconnect() {
    if (this._disposed) return;
    this._closeSocket();
    this._reconnectAttempts++;
    this.onStateChanged(TwitchEventSubState.reconnecting);
    final backoff = Duration(
      seconds: (this._reconnectAttempts * 2).clamp(2, _maxBackoff.inSeconds),
    );
    this._sleep(backoff).then((_) {
      if (!this._disposed) this._openSocket(Uri.parse(_wsUrl));
    });
  }

  void _resetWatchdog() {
    this._watchdog?.cancel();
    this._watchdog = Timer(_watchdogWindow, this._handleDisconnect);
  }

  void _closeSocket() {
    this._watchdog?.cancel();
    this._socketSub?.cancel();
    this._socketSub = null;
    this._channel?.sink.close();
    this._channel = null;
  }

  /// Tear down the session. Deleting the subscriptions is best effort —
  /// Twitch drops them anyway once the session times out.
  Future<void> dispose() async {
    this._disposed = true;
    this._closeSocket();

    final subscriptionIds = <String>[
      ...this._subscriptionIds,
      if (this._moderateSubscriptionId != null) this._moderateSubscriptionId!,
    ];
    final token = this._accessToken;
    this._subscriptionIds = <String>[];
    this._moderateSubscriptionId = null;
    if (token != null) {
      for (final id in subscriptionIds) {
        try {
          await this._client.delete(
            Uri.parse('$_subscriptionsUrl?id=$id'),
            headers: TwitchAuthService.helixHeaders(token),
          );
        } catch (_) {
          // best effort
        }
      }
    }
  }
}
