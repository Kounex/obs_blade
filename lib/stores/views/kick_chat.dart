import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/kick/kick_pusher_event.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';
import 'package:obs_blade/utils/kick/kick_pusher_service.dart';

part 'kick_chat.g.dart';

enum KickChatConnectionState {
  /// No selected channel (or not started yet).
  idle,
  connecting,
  connected,

  /// Socket dropped, reconnect with backoff in flight (messages stay).
  reconnecting,

  /// The channel does not resolve (bad slug / deleted channel) — not an
  /// error.
  offline,
  error,
}

class KickChatStore = _KickChatStore with _$KickChatStore;

/// In-memory per-channel chat snapshot — swapped in/out of the live
/// [messages] list on selectChannel so switching back restores recent
/// history and skips the backfill. Dies with the app session; never
/// persisted (chat content never touches Hive).
class _ChannelBuffer {
  List<KickChatMessage> messages;
  KickChannelInfo? channelInfo;

  _ChannelBuffer({List<KickChatMessage>? messages, this.channelInfo})
    : messages = messages ?? <KickChatMessage>[];
}

/// Factory seam for the realtime transport — tests substitute a fake
/// pusher; production uses [KickPusherService.new].
typedef KickPusherFactory =
    KickPusherService Function({
      required void Function(KickPusherEvent event) onEvent,
      required void Function(KickPusherConnectionState state) onStateChanged,
    });

/// Owns the native Kick chat: anonymous reads (channel resolution +
/// history backfill over REST, live events over Kick's public Pusher
/// socket) with per-channel buffers. No auth exists this wave — Kick has
/// no read credential, so there is no login state machine.
abstract class _KickChatStore with Store {
  static const int kMaxMessages = 500;

  final KickChannelService _channelService;
  final KickPusherFactory _pusherFactory;

  /// The live socket session for the selected channel; swapped on
  /// selectChannel, torn down on dispose.
  KickPusherService? _pusher;

  /// Identifies the active connection flow — selectChannel/dispose bump
  /// this so a stale flow's continuations (mid-resolve, mid-backfill or
  /// socket callbacks of the previous channel) bail out.
  int _connectFlow = 0;

  /// Whether [_ensureChannelsLoaded] already ran for this instance —
  /// the settings load is idempotent per store instance.
  bool _channelsLoaded = false;

  /// Pro entitlement read (test seam) - native chat "just doesn't work"
  /// without Pro: [connectChat] refuses, so neither a persisted engine
  /// selection nor the cold-start auto-select can connect behind the
  /// locked pane.
  final bool Function() _isProResolver;

  _KickChatStore({
    KickChannelService? channelService,
    KickPusherFactory? pusherFactory,
    bool Function()? isProResolver,
  }) : _channelService = channelService ?? KickChannelService(),
       _pusherFactory =
           pusherFactory ??
           (({required onEvent, required onStateChanged}) => KickPusherService(
             onEvent: onEvent,
             onStateChanged: onStateChanged,
           )),
       _isProResolver =
           isProResolver ?? (() => GetIt.instance<ProStore>().isPro);

  @observable
  KickChatConnectionState chatConnection = KickChatConnectionState.idle;

  @observable
  String? chatError;

  /// When the current session went live — feeds the connection sheet's
  /// uptime line.
  @observable
  DateTime? chatConnectedAt;

  /// The selected channel's resolution (chatroom modes, live status,
  /// viewer count) — drives the header LIVE chip.
  @observable
  KickChannelInfo? channelInfo;

  /// Native Kick channels — the [SettingsKeys.KickUsernames] slugs (the
  /// WebView list doubles as the native channel list; slug == identity).
  final ObservableList<String> channels = ObservableList<String>();

  /// Currently viewed channel slug, persisted as
  /// [SettingsKeys.SelectedKickUsername] (shared with the WebView path).
  /// Null = no selection.
  @observable
  String? selectedChannelSlug;

  /// Per-channel chat snapshots keyed by slug (in-memory only).
  final Map<String, _ChannelBuffer> _channelBuffers =
      <String, _ChannelBuffer>{};

  final ObservableList<KickChatMessage> messages =
      ObservableList<KickChatMessage>();

  /// Cold start: restore channels + selection, then connect (the
  /// entitlement gate sits in [connectChat]).
  @action
  Future<void> init() async {
    this._ensureChannelsLoaded();
    if (this.selectedChannelSlug == null && this.channels.isNotEmpty) {
      unawaited(this.selectChannel(this.channels.first));
    } else if (this.selectedChannelSlug != null) {
      this.connectChat();
    }
  }

  /// (Re)start the connection for the selected channel — called after
  /// init and by the UI retry action. Hard entitlement gate: without Pro
  /// the native engine never comes up, no matter which entry point asks
  /// (persisted engine selection, cold-start auto-select, UI retry).
  @action
  void connectChat() {
    if (!this._isProResolver()) return;
    if (this.selectedChannelSlug == null) {
      this.chatConnection = KickChatConnectionState.idle;
      return;
    }
    this._restartConnection();
  }

  void _restartConnection() {
    final slug = this.selectedChannelSlug;
    if (slug == null) return;
    final flow = ++this._connectFlow;
    this._disconnectPusher();
    this.chatConnection = KickChatConnectionState.connecting;
    this.chatError = null;
    unawaited(this._runConnection(slug, flow));
  }

  void _disconnectPusher() {
    final pusher = this._pusher;
    this._pusher = null;
    if (pusher != null) unawaited(pusher.disconnect());
  }

  /// The read pipeline: resolve the slug (cached in the channel buffer),
  /// backfill recent history (best-effort — only into an empty buffer),
  /// then subscribe to `chatrooms.{chatroomId}.v2` via the pusher socket
  /// (which owns keepalive + reconnect). A bumped [_connectFlow]
  /// (selectChannel / dispose) cancels the flow.
  Future<void> _runConnection(String slug, int flow) async {
    final buffer = this._channelBuffers.putIfAbsent(slug, _ChannelBuffer.new);

    bool superseded() =>
        flow != this._connectFlow || slug != this.selectedChannelSlug;

    var info = buffer.channelInfo;
    if (info == null) {
      try {
        info = await this._channelService.resolveChannel(slug);
      } catch (e) {
        if (superseded()) return;
        GeneralHelper.advLog('Kick channel resolve failed — $e');
        runInAction(() {
          this.chatConnection = KickChatConnectionState.error;
          this.chatError = 'Could not resolve the Kick channel';
        });
        return;
      }
      if (superseded()) return;
      if (info == null) {
        /// Unknown slug — a normal state, not an error.
        runInAction(() {
          this.channelInfo = null;
          this.chatConnection = KickChatConnectionState.offline;
        });
        return;
      }
      buffer.channelInfo = info;
    }
    runInAction(() => this.channelInfo = info);

    if (buffer.messages.isEmpty) {
      try {
        final history = await this._channelService.backfillMessages(info.id);
        if (superseded()) return;
        runInAction(() => this._applyBackfill(history));
      } catch (e) {
        if (superseded()) return;

        /// History is a nicety — a failure must not block the live feed.
        GeneralHelper.advLog('Kick chat backfill failed — $e');
      }
    }
    if (superseded()) return;

    final pusher = this._pusherFactory(
      onEvent: (event) {
        if (superseded()) return;
        runInAction(() => this._applyEvent(slug, event));
      },
      onStateChanged: (state) {
        if (superseded()) return;
        runInAction(() {
          switch (state) {
            case KickPusherConnectionState.connected:
              this.chatConnection = KickChatConnectionState.connected;
              this.chatConnectedAt = DateTime.now();
            case KickPusherConnectionState.connecting:
              this.chatConnection = KickChatConnectionState.connecting;
            case KickPusherConnectionState.reconnecting:
              this.chatConnection = KickChatConnectionState.reconnecting;
            case KickPusherConnectionState.disconnected:
              this.chatConnection = KickChatConnectionState.idle;
          }
        });
      },
    );
    this._pusher = pusher;
    await pusher.connect(chatroomId: info.chatroomId);
  }

  /// History lands below any live messages that beat it, deduped by id
  /// (the backfill window overlaps the first live frames).
  void _applyBackfill(List<KickChatMessage> history) {
    for (final message in history) {
      if (this.messages.any((existing) => existing.id == message.id)) {
        continue;
      }
      this.messages.add(message);
    }
    this._trimMessages();
  }

  /// Routes one chatroom event: lifecycle events (delete / ban / clear /
  /// modes update) mutate the buffer, messages append as rows (deduped by
  /// id). A malformed payload is logged and skipped — one bad event must
  /// not break the socket loop.
  void _applyEvent(String slug, KickPusherEvent event) {
    try {
      switch (event.kind) {
        case KickChatroomEventKind.message:
          final message = KickChatMessage.fromJson(event.data);
          if (this.messages.any((existing) => existing.id == message.id)) {
            return;
          }
          this.messages.add(message);
          this._trimMessages();
        case KickChatroomEventKind.messageDeleted:
          this._applyMessageDeleted(event);
        case KickChatroomEventKind.userBanned:
          this._applyUserBanned(event);
        case KickChatroomEventKind.chatroomClear:
          this._applyChatroomClear();
        case KickChatroomEventKind.chatroomUpdated:
          this._applyChatroomUpdated(slug, event);
        case KickChatroomEventKind.userUnbanned:

          /// Unbans don't resurrect tombstoned rows.
          break;
        case KickChatroomEventKind.pinnedMessage:
        case KickChatroomEventKind.unknown:
          break;
      }
    } catch (e) {
      GeneralHelper.advLog(
        'Kick chat event handling failed (${event.event}) — $e',
      );
    }
  }

  void _trimMessages() {
    while (this.messages.length > kMaxMessages) {
      this.messages.removeAt(0);
    }
  }

  /// `MessageDeletedEvent` — mark the buffered copy (dim + marker, same
  /// UX as Twitch); unknown ids are dropped.
  void _applyMessageDeleted(KickPusherEvent event) {
    final messageId = event.deletedMessageId;
    if (messageId == null) return;
    final index = this.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index < 0) return;
    this.messages[index] = this.messages[index].copyWith(isTombstoned: true);
  }

  /// `UserBannedEvent` (timeout when `expires_at` is set, permaban when
  /// null — both purge the same way) — tombstone every buffered message
  /// of the banned author (Twitch precedent: purge = tombstone, not
  /// removal).
  void _applyUserBanned(KickPusherEvent event) {
    final userId = event.targetUserId;
    if (userId == null) return;
    for (var i = 0; i < this.messages.length; i++) {
      final message = this.messages[i];
      if (message.sender?.id == userId && !message.isTombstoned) {
        this.messages[i] = message.copyWith(isTombstoned: true);
      }
    }
  }

  /// `ChatroomClearEvent` — drop the buffer and leave a system notice row
  /// (the Twitch engine's `/clear` banner equivalent).
  void _applyChatroomClear() {
    if (this.messages.isEmpty) return;
    this.messages.clear();
    this.messages.add(
      KickChatMessage(
        id: 'system-clear-${DateTime.now().microsecondsSinceEpoch}',
        type: KickChatMessageType.system,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// `ChatroomUpdatedEvent` — refresh the cached chatroom modes (payload
  /// is the chatroom object; it may omit the id, so fall back to the
  /// resolved one).
  void _applyChatroomUpdated(String slug, KickPusherEvent event) {
    final info = this.channelInfo;
    if (info == null) return;
    try {
      final chatroom = KickChatroom.fromJson(<String, Object?>{
        'id': info.chatroomId,
        ...event.data,
      });
      final updated = info.copyWith(chatroom: chatroom);
      this.channelInfo = updated;
      this._channelBuffers[slug]?.channelInfo = updated;
    } catch (e) {
      GeneralHelper.advLog('Kick chatroom update parse failed — $e');
    }
  }

  /// Multi-chat: switch the visible channel (null = no selection / stop).
  /// Only the visible channel is connected — the old channel's chat
  /// snapshot is buffered in memory and restored on switch-back.
  @action
  Future<void> selectChannel(String? slug) async {
    if (slug == this.selectedChannelSlug) return;

    // Cancel the running flow BEFORE touching state so its continuations
    // cannot write into the new channel's buffer.
    this._connectFlow++;
    this._disconnectPusher();

    final previousSlug = this.selectedChannelSlug;
    if (previousSlug != null) {
      final previous = this._channelBuffers.putIfAbsent(
        previousSlug,
        _ChannelBuffer.new,
      );
      previous.messages = List.of(this.messages);
    }

    this.selectedChannelSlug = slug;
    this._persistSelectedChannel();

    this.messages.clear();
    this.chatConnectedAt = null;
    this.chatError = null;
    if (slug != null) {
      final buffer = this._channelBuffers.putIfAbsent(slug, _ChannelBuffer.new);
      this.messages.addAll(buffer.messages);
      this.channelInfo = buffer.channelInfo;
      if (this._isProResolver()) {
        this.chatConnection = KickChatConnectionState.connecting;
        this.chatError = null;
        final flow = this._connectFlow;
        unawaited(this._runConnection(slug, flow));
      } else {
        /// Hard entitlement gate (mirrors [connectChat]): the selection
        /// is kept, but without Pro no connection starts.
        this.chatConnection = KickChatConnectionState.idle;
      }
    } else {
      this.channelInfo = null;
      this.chatConnection = KickChatConnectionState.idle;
    }
  }

  /// Re-read the channel list from settings (after the user edited
  /// [SettingsKeys.KickUsernames] outside this store). Slug == identity,
  /// so a re-edited entry simply retires the old slug's buffer. A
  /// vanished selection falls back to none.
  @action
  void reloadChannels() {
    final parsed = this._readChannelsFromSettings();
    final retired = {
      for (final slug in this.channels)
        if (!parsed.contains(slug)) slug,
    };
    final selected = this.selectedChannelSlug;
    final retireSelection =
        selected != null &&
        (retired.contains(selected) || !parsed.contains(selected));
    if (retireSelection) {
      // Invalidate in-flight reads before clearing their visible destination.
      // Do not call selectChannel: it would save the retired messages again.
      this._connectFlow++;
      this._disconnectPusher();
      this.messages.clear();
      this.chatConnectedAt = null;
      this.channelInfo = null;
      this.chatConnection = KickChatConnectionState.idle;
      this.chatError = null;
    }
    this.channels
      ..clear()
      ..addAll(parsed);
    this._channelBuffers.removeWhere(
      (slug, _) => retired.contains(slug) || !parsed.contains(slug),
    );
    if (retireSelection) {
      this.selectedChannelSlug = null;
      this._persistSelectedChannel();
    }
  }

  /// Idempotent settings load (init): restores [channels] and
  /// [selectedChannelSlug]. Missing keys degrade to empty/null; entries
  /// are re-validated through the slug extractor one by one. A persisted
  /// selection that no longer matches a stored channel falls back to none.
  void _ensureChannelsLoaded() {
    if (this._channelsLoaded) return;
    this._channelsLoaded = true;
    this.channels.addAll(this._readChannelsFromSettings());
    try {
      final selected = Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.SelectedKickUsername.name);
      if (selected is String && this.channels.contains(selected)) {
        this.selectedChannelSlug = selected;
      }
    } catch (e) {
      GeneralHelper.advLog('Kick chat selection load failed — $e');
    }
  }

  List<String> _readChannelsFromSettings() {
    final parsed = <String>[];
    try {
      final raw = Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.KickUsernames.name, defaultValue: <String>[]);
      if (raw is List) {
        for (final entry in raw) {
          if (entry is String && entry.isNotEmpty && !parsed.contains(entry)) {
            parsed.add(entry);
          }
        }
      }
    } catch (e) {
      GeneralHelper.advLog('Kick chat channels load failed — $e');
    }
    return parsed;
  }

  void _persistSelectedChannel() {
    try {
      final box = Hive.box(HiveKeys.Settings.name);
      if (this.selectedChannelSlug == null) {
        box.delete(SettingsKeys.SelectedKickUsername.name);
      } else {
        box.put(
          SettingsKeys.SelectedKickUsername.name,
          this.selectedChannelSlug,
        );
      }
    } catch (e) {
      GeneralHelper.advLog('Kick chat selection persist failed — $e');
    }
  }

  Future<void> dispose() async {
    this._connectFlow++;
    final pusher = this._pusher;
    this._pusher = null;
    if (pusher != null) await pusher.dispose();
  }
}
