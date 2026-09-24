import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/general_helper.dart';

part 'combined_chat.g.dart';

/// Per-source health, rendered as the combined chat's status dots.
enum CombinedSourceStatus {
  live,
  connecting,

  /// Reachable but nothing to show (stream offline, channel between
  /// streams, not selected yet).
  offline,

  /// The platform needs the user first (sign in, API key).
  needsSetup,
  error,
}

/// One channel feeding the combined timeline. Wave 1 only builds these
/// from the signed-in "You" entries; [key] is what the platform store's
/// `selectChannel` takes (Twitch: null = own channel).
class CombinedSource {
  final ChatType platform;
  final String? key;
  final String label;

  const CombinedSource({
    required this.platform,
    required this.key,
    required this.label,
  });

  @override
  bool operator ==(Object other) =>
      other is CombinedSource &&
      other.platform == this.platform &&
      other.key == this.key;

  @override
  int get hashCode => Object.hash(this.platform, this.key);
}

/// One row of the merged timeline: a platform store's own item (Twitch
/// message / notice, YouTube message, Kick message) plus its sort time.
class CombinedItem {
  final ChatType platform;

  /// The platform's own model — rendered by that platform's row widget.
  final Object payload;

  /// Platform timestamp; null only for Twitch notices and undated rows
  /// (they inherit their stream predecessor's time for sorting).
  final DateTime? at;

  /// Stable identity across rebuilds (row keys, zebra parity, the
  /// stick-to-bottom newest check).
  final String key;

  const CombinedItem({
    required this.platform,
    required this.payload,
    required this.at,
    required this.key,
  });
}

class CombinedChatStore = _CombinedChatStore with _$CombinedChatStore;

/// Merges the three native chat stores into one read-only timeline.
///
/// "Shared" coupling (spec): the combined view does not open connections
/// of its own — [activate] points each platform store at the combo's
/// channel and [deactivate] puts back whatever it showed before.
abstract class _CombinedChatStore with Store {
  /// Merged view cap — each store keeps its own 500-row buffer.
  static const int kMaxItems = 500;

  final TwitchChatStore Function() _twitch;
  final YouTubeChatStore Function() _youTube;
  final KickChatStore Function() _kick;

  _CombinedChatStore({
    TwitchChatStore Function()? twitchStore,
    YouTubeChatStore Function()? youTubeStore,
    KickChatStore Function()? kickStore,
  }) : _twitch = twitchStore ?? (() => GetIt.instance<TwitchChatStore>()),
       _youTube = youTubeStore ?? (() => GetIt.instance<YouTubeChatStore>()),
       _kick = kickStore ?? (() => GetIt.instance<KickChatStore>());

  /// Whether the combined view currently owns the platform stores'
  /// selections.
  @observable
  bool active = false;

  /// Platforms switched off in "My chats" (persisted as
  /// [SettingsKeys.MyChatsDisabledPlatforms]).
  @observable
  ObservableSet<ChatType> disabledPlatforms = ObservableSet<ChatType>();

  /// Selections the platform stores had before [activate] — put back by
  /// [deactivate]. Twitch/YouTube/Kick keys as their `selectChannel`
  /// takes them.
  final Map<ChatType, String?> _restore = <ChatType, String?>{};

  /// Bumped by every [activate] / [deactivate] — a superseded activation
  /// (the user left Combined while it was still switching stores) stops
  /// selecting instead of undoing the restore.
  int _generation = 0;

  bool _settingsLoaded = false;

  StreamSubscription<BoxEvent>? _chatTypeSub;
  ReactionDisposer? _sourcesReaction;

  /// Follow the persisted chat type app-wide: Combined selected →
  /// [activate], anything else → [deactivate]. One owner for every host
  /// (Chat tab, streaming mode) — widgets never drive activation. While
  /// active, a source appearing (sign-in) is selected right away.
  void bindToChatType() {
    if (this._chatTypeSub != null) return;
    final box = Hive.box(HiveKeys.Settings.name);
    void sync() {
      final type = box.get(SettingsKeys.SelectedChatType.name);
      unawaited(
        type == ChatType.Combined ? this.activate() : this.deactivate(),
      );
    }

    this._chatTypeSub = box
        .watch(key: SettingsKeys.SelectedChatType.name)
        .listen((_) => sync());
    this._sourcesReaction = reaction<List<CombinedSource>>(
      (_) => this.mySources,
      (_) {
        if (this.active) unawaited(this.activate());
      },
    );
    sync();
  }

  Future<void> dispose() async {
    await this._chatTypeSub?.cancel();
    this._chatTypeSub = null;
    this._sourcesReaction?.call();
    this._sourcesReaction = null;
  }

  /// The signed-in account's own channel on each platform ("You"
  /// entries), minus the ones switched off.
  @computed
  List<CombinedSource> get mySources => [
    for (final source in this.availableSources)
      if (!this.disabledPlatforms.contains(source.platform)) source,
  ];

  /// Every platform with a "You" entry, switched off or not — the
  /// per-platform toggles list these.
  @computed
  List<CombinedSource> get availableSources {
    final twitch = this._twitch();
    final youTube = this._youTube();
    final kick = this._kick();
    final user = twitch.user;
    final ownYouTube = youTube.ownChannel;
    final ownKick = kick.ownChannelSlug;
    return [
      if (twitch.isLoggedIn && user != null)
        CombinedSource(
          platform: ChatType.Twitch,
          key: null,
          label: user.displayName ?? user.login,
        ),
      if (ownYouTube != null)
        CombinedSource(
          platform: ChatType.YouTube,
          key: ownYouTube.label,
          label: ownYouTube.displayName,
        ),
      if (ownKick != null)
        CombinedSource(platform: ChatType.Kick, key: ownKick, label: ownKick),
    ];
  }

  /// Health of each source in [mySources].
  @computed
  Map<ChatType, CombinedSourceStatus> get sourceStatus => {
    for (final source in this.mySources)
      source.platform: this._statusOf(source.platform),
  };

  CombinedSourceStatus _statusOf(ChatType platform) {
    switch (platform) {
      case ChatType.Twitch:
        final store = this._twitch();
        if (!store.isLoggedIn) return CombinedSourceStatus.needsSetup;
        return switch (store.chatConnection) {
          TwitchChatConnectionState.live => CombinedSourceStatus.live,
          TwitchChatConnectionState.connecting ||
          TwitchChatConnectionState.reconnecting =>
            CombinedSourceStatus.connecting,
          TwitchChatConnectionState.failed => CombinedSourceStatus.error,
          TwitchChatConnectionState.disconnected =>
            CombinedSourceStatus.offline,
        };
      case ChatType.YouTube:
        final store = this._youTube();
        if (store.authState == YouTubeAuthState.unconfigured) {
          return CombinedSourceStatus.needsSetup;
        }
        if (store.awaitingLiveStream) return CombinedSourceStatus.offline;
        return switch (store.chatConnection) {
          YouTubeChatConnectionState.connected => CombinedSourceStatus.live,
          YouTubeChatConnectionState.connecting =>
            CombinedSourceStatus.connecting,
          YouTubeChatConnectionState.error => CombinedSourceStatus.error,
          YouTubeChatConnectionState.idle ||
          YouTubeChatConnectionState.offline => CombinedSourceStatus.offline,
        };
      case ChatType.Kick:
        return switch (this._kick().chatConnection) {
          KickChatConnectionState.connected => CombinedSourceStatus.live,
          KickChatConnectionState.connecting ||
          KickChatConnectionState.reconnecting =>
            CombinedSourceStatus.connecting,
          KickChatConnectionState.error => CombinedSourceStatus.error,
          KickChatConnectionState.idle ||
          KickChatConnectionState.offline => CombinedSourceStatus.offline,
        };
      case ChatType.Owncast:
      case ChatType.Combined:
        return CombinedSourceStatus.offline;
    }
  }

  /// The merged timeline: each active source's visible items, interleaved
  /// by platform timestamp. A platform's own order never changes (undated
  /// items inherit their predecessor's time; ties keep stream order), and
  /// only the newest [kMaxItems] are kept.
  @computed
  List<CombinedItem> get timeline {
    final streams = <List<CombinedItem>>[
      for (final source in this.mySources)
        switch (source.platform) {
          ChatType.Twitch => this._twitchItems(),
          ChatType.YouTube => this._youTubeItems(),
          ChatType.Kick => this._kickItems(),
          ChatType.Owncast || ChatType.Combined => const <CombinedItem>[],
        },
    ];
    final merged = mergeCombinedStreams(streams);
    return merged.length > kMaxItems
        ? merged.sublist(merged.length - kMaxItems)
        : merged;
  }

  List<CombinedItem> _twitchItems() {
    final store = this._twitch();

    /// Notices live in plain lists — this version read is their only
    /// reactivity trigger (same as the Twitch view).
    store.lifecycleVersion;
    DateTime? last;
    return [
      for (final item in store.messagesWithNotices())
        CombinedItem(
          platform: ChatType.Twitch,
          payload: item,
          at: item is ChatMessageEvent
              ? (last = item.receivedAt ?? last)
              : last,
          key: switch (item) {
            final ChatMessageEvent event => 'twitch:${event.messageId}',

            /// Notices by what they are, not by object identity — the
            /// store replaces a notice object on a same-id update, and a
            /// changed key would re-tint the zebra and fake an arrival.
            final ChatNotificationNotice notice =>
              'twitch:notice:${notice.event.messageId}',
            final ChatSystemNotice notice =>
              'twitch:system:${notice.kind.name}:${notice.afterSeq}',
            _ => 'twitch:other:${identityHashCode(item)}',
          },
        ),
    ];
  }

  List<CombinedItem> _youTubeItems() => [
    for (final message in this._youTube().messages)
      CombinedItem(
        platform: ChatType.YouTube,
        payload: message,
        at: message.publishedAt,
        key: 'youtube:${message.id}',
      ),
  ];

  List<CombinedItem> _kickItems() {
    DateTime? last;
    return [
      for (final message in this._kick().messages)
        CombinedItem(
          platform: ChatType.Kick,
          payload: message,
          at: last = message.createdAt ?? last,
          key: 'kick:${message.id}',
        ),
    ];
  }

  /// Point every source's platform store at the source (remembering the
  /// previous selection once). Idempotent — re-run it when [mySources]
  /// changes while active (a sign-in adds a source live).
  @action
  Future<void> activate() async {
    this._ensureSettingsLoaded();
    final generation = ++this._generation;
    this.active = true;
    for (final source in this.mySources) {
      if (generation != this._generation) return;
      await this._select(source);
    }
  }

  /// Put back what each platform store showed before [activate].
  @action
  Future<void> deactivate() async {
    this._ensureSettingsLoaded();
    if (!this.active && this._restore.isEmpty) return;
    this._generation++;
    this.active = false;
    final restore = Map<ChatType, String?>.of(this._restore);
    this._restore.clear();
    this._persistRestore();
    for (final entry in restore.entries) {
      try {
        switch (entry.key) {
          case ChatType.Twitch:
            await this._twitch().selectChannel(entry.value);
          case ChatType.YouTube:
            await this._youTube().selectChannel(entry.value);
          case ChatType.Kick:
            await this._kick().selectChannel(entry.value);
          case ChatType.Owncast:
          case ChatType.Combined:
            break;
        }
      } catch (e) {
        GeneralHelper.advLog('Combined chat restore failed - $e');
      }
    }
  }

  /// Remember [platform]'s pre-combo selection once, durably — a restart
  /// while Combined is active must still restore it later.
  void _remember(ChatType platform, String? selection) {
    if (this._restore.containsKey(platform)) return;
    this._restore[platform] = selection;
    this._persistRestore();
  }

  Future<void> _select(CombinedSource source) async {
    switch (source.platform) {
      case ChatType.Twitch:
        final store = this._twitch();
        this._remember(ChatType.Twitch, store.selectedChannelId);
        await store.selectChannel(source.key);
      case ChatType.YouTube:
        final store = this._youTube();
        this._remember(ChatType.YouTube, store.selectedChannelLabel);
        await store.selectChannel(source.key);
      case ChatType.Kick:
        final store = this._kick();
        this._remember(ChatType.Kick, store.selectedChannelSlug);
        await store.selectChannel(source.key);
      case ChatType.Owncast:
      case ChatType.Combined:
        break;
    }
  }

  /// Switch a platform on/off in "My chats" (persisted). Turning one on
  /// while active selects its own channel right away; turning one off
  /// leaves the store where it is until [deactivate] restores it.
  @action
  Future<void> setPlatformEnabled(ChatType platform, bool enabled) async {
    this._ensureSettingsLoaded();
    if (enabled) {
      this.disabledPlatforms.remove(platform);
    } else {
      this.disabledPlatforms.add(platform);
    }
    this._persistDisabled();
    if (enabled && this.active) {
      for (final source in this.mySources) {
        if (source.platform == platform) await this._select(source);
      }
    }
  }

  void _ensureSettingsLoaded() {
    if (this._settingsLoaded) return;
    this._settingsLoaded = true;
    try {
      /// Restore point of a session that ended while Combined was active
      /// (map of `ChatType.name` → selection, null = the store's default).
      final restore = Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.CombinedChatRestore.name);
      if (restore is Map) {
        for (final type in ChatType.values) {
          if (restore.containsKey(type.name)) {
            final value = restore[type.name];
            this._restore[type] = value is String ? value : null;
          }
        }
      }
    } catch (e) {
      GeneralHelper.advLog('Combined chat restore load failed - $e');
    }
    try {
      final raw = Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.MyChatsDisabledPlatforms.name);
      if (raw is List) {
        for (final name in raw) {
          for (final type in ChatType.values) {
            if (type.name == name) this.disabledPlatforms.add(type);
          }
        }
      }
    } catch (e) {
      GeneralHelper.advLog('Combined chat settings load failed - $e');
    }
  }

  void _persistRestore() {
    try {
      final box = Hive.box(HiveKeys.Settings.name);
      if (this._restore.isEmpty) {
        box.delete(SettingsKeys.CombinedChatRestore.name);
      } else {
        box.put(SettingsKeys.CombinedChatRestore.name, {
          for (final entry in this._restore.entries)
            entry.key.name: entry.value,
        });
      }
    } catch (e) {
      GeneralHelper.advLog('Combined chat restore persist failed - $e');
    }
  }

  void _persistDisabled() {
    try {
      Hive.box(HiveKeys.Settings.name).put(
        SettingsKeys.MyChatsDisabledPlatforms.name,
        [for (final type in this.disabledPlatforms) type.name],
      );
    } catch (e) {
      GeneralHelper.advLog('Combined chat settings persist failed - $e');
    }
  }
}

/// Stable k-way merge of per-platform streams by [CombinedItem.at]. Each
/// stream stays in its own order: an item never overtakes an earlier item
/// of its own stream, even with skewed or missing timestamps; on equal
/// times the earlier stream in [streams] goes first.
List<CombinedItem> mergeCombinedStreams(List<List<CombinedItem>> streams) {
  final cursors = List<int>.filled(streams.length, 0);
  final total = streams.fold<int>(0, (sum, stream) => sum + stream.length);
  final merged = <CombinedItem>[];
  while (merged.length < total) {
    int? pick;
    for (var i = 0; i < streams.length; i++) {
      if (cursors[i] >= streams[i].length) continue;
      if (pick == null) {
        pick = i;
        continue;
      }
      final candidate = streams[i][cursors[i]].at;
      final best = streams[pick][cursors[pick]].at;

      /// Undated heads go first: they belong right after whatever their
      /// stream emitted last.
      if (candidate == null && best != null) {
        pick = i;
      } else if (candidate != null &&
          best != null &&
          candidate.isBefore(best)) {
        pick = i;
      }
    }
    merged.add(streams[pick!][cursors[pick]++]);
  }
  return merged;
}
