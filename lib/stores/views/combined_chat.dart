import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/combined/combined_combo.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
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

  /// A saved combo's source that its platform can't show right now (not
  /// signed in to Twitch, YouTube not set up) — kept in the combo, shown
  /// as needing setup, skipped when selecting.
  final bool unavailable;

  const CombinedSource({
    required this.platform,
    required this.key,
    required this.label,
    this.unavailable = false,
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

  /// Saved combos (persisted as [SettingsKeys.CombinedChatCombos]).
  final ObservableList<CombinedCombo> combos = ObservableList<CombinedCombo>();

  /// The combo the combined view shows — [kMyChatsComboId] or a saved
  /// combo's id (persisted as [SettingsKeys.SelectedCombinedCombo]).
  @observable
  String selectedComboId = kMyChatsComboId;

  /// The saved combo being shown, null for "My chats".
  @computed
  CombinedCombo? get selectedCombo {
    for (final combo in this.combos) {
      if (combo.id == this.selectedComboId) return combo;
    }
    return null;
  }

  /// What the combined view merges: "My chats" or the selected combo's
  /// sources.
  @computed
  List<CombinedSource> get activeSources {
    final combo = this.selectedCombo;
    return combo == null ? this.mySources : this._sourcesOf(combo);
  }

  /// [combo]'s sources resolved against the platform stores (the sheets
  /// show a combo that isn't the one on screen too).
  List<CombinedSource> sourcesOf(CombinedCombo combo) => this._sourcesOf(combo);

  List<CombinedSource> _sourcesOf(CombinedCombo combo) {
    final twitch = this._twitch();
    final youTube = this._youTube();
    return [
      if (combo.twitch case final ref?)
        CombinedSource(
          platform: ChatType.Twitch,
          key: ref.id == twitch.user?.id ? null : ref.id,
          label: ref.displayName,
          unavailable: !twitch.isLoggedIn,
        ),
      if (combo.youTube case final source?)
        CombinedSource(
          platform: ChatType.YouTube,
          key: source.label,
          label: source.label,
          unavailable: youTube.authState == YouTubeAuthState.unconfigured,
        ),
      if (combo.kickSlug case final slug?)
        CombinedSource(platform: ChatType.Kick, key: slug, label: slug),
    ];
  }

  /// Selections the platform stores had before [activate] — put back by
  /// [deactivate]. Twitch/YouTube/Kick keys as their `selectChannel`
  /// takes them.
  final Map<ChatType, String?> _restore = <ChatType, String?>{};

  /// Bumped by every [activate] / [deactivate] — a superseded activation
  /// (the user left Combined while it was still switching stores) stops
  /// selecting instead of undoing the restore.
  int _generation = 0;

  bool _settingsLoaded = false;

  /// Set while the user jumped from the combined view into one platform
  /// (tapping a source): that platform keeps showing the combo's channel,
  /// shows a "↩ Combined" chip, and leaving it does NOT restore — the
  /// user is expected back. Transient (not persisted).
  @observable
  ChatType? focusedPlatform;

  /// The chat type switch [focus] is doing right now — the chat-type
  /// watcher must not treat it as leaving Combined.
  bool _focusSwitch = false;

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
      if (type == ChatType.Combined) {
        unawaited(this.activate());
      } else if (this._focusSwitch || type == this.focusedPlatform) {
        /// Focus jump: the combo stays owned, only YouTube pauses.
        this._focusSwitch = false;
        this._pauseBackground(except: type is ChatType ? type : null);
      } else {
        /// Any other type switch leaves Combined for real.
        this.focusedPlatform = null;
        unawaited(this.deactivate());
      }
    }

    this._chatTypeSub = box
        .watch(key: SettingsKeys.SelectedChatType.name)
        .listen((_) => sync());
    this._sourcesReaction = reaction<List<CombinedSource>>(
      (_) => this.activeSources,
      (_) {
        /// Not during a focus jump: activate() ends the focus and resumes
        /// YouTube while the user is still on the other platform — the
        /// way back ("↩ Combined") re-activates anyway.
        if (this.active && this.focusedPlatform == null) {
          unawaited(this.activate());
        }
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

  /// Health of each source in [activeSources].
  @computed
  Map<ChatType, CombinedSourceStatus> get sourceStatus => {
    for (final source in this.activeSources)
      source.platform: source.unavailable
          ? CombinedSourceStatus.needsSetup
          : this._statusOf(source.platform),
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
      for (final source in this.activeSources)
        if (!source.unavailable)
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

  /// The user's last pick of the input's target chip (persisted as
  /// [SettingsKeys.CombinedChatSendTarget]); only honored while that
  /// platform is writable.
  @observable
  ChatType? sendTargetChoice;

  /// Active sources the signed-in accounts may write to, in source order —
  /// what the target chip offers.
  @computed
  List<ChatType> get writableTargets => [
    for (final source in this.activeSources)
      if (!source.unavailable && this._canWrite(source.platform))
        source.platform,
  ];

  bool _canWrite(ChatType platform) => switch (platform) {
    ChatType.Twitch => this._twitch().isLoggedIn && this._twitch().canWriteChat,
    ChatType.YouTube =>
      this._youTube().isSignedInState && this._youTube().canWrite,
    ChatType.Kick => this._kick().isSignedInState && this._kick().canWrite,
    ChatType.Owncast || ChatType.Combined => false,
  };

  /// The platform with a pending reply (Twitch / Kick — YouTube has no
  /// replies), when it is a writable source here.
  @computed
  ChatType? get replyPlatform {
    final writable = this.writableTargets;
    if (writable.contains(ChatType.Twitch) &&
        this._twitch().replyTarget != null) {
      return ChatType.Twitch;
    }
    if (writable.contains(ChatType.Kick) && this._kick().replyTarget != null) {
      return ChatType.Kick;
    }
    return null;
  }

  /// Where the input sends: a pending reply's platform, else the user's
  /// last pick, else the first writable source. Null = nothing writable.
  @computed
  ChatType? get sendTarget {
    final writable = this.writableTargets;
    if (writable.isEmpty) return null;
    final reply = this.replyPlatform;
    if (reply != null) return reply;
    final choice = this.sendTargetChoice;
    if (choice != null && writable.contains(choice)) return choice;
    return writable.first;
  }

  /// The target store's send state (dock spinner / error line).
  @computed
  bool get sendingChat => switch (this.sendTarget) {
    ChatType.Twitch => this._twitch().sendingChat,
    ChatType.YouTube => this._youTube().sendingChat,
    ChatType.Kick => this._kick().sendingChat,
    _ => false,
  };

  @computed
  String? get sendChatError => switch (this.sendTarget) {
    ChatType.Twitch => this._twitch().sendChatError,
    ChatType.YouTube => this._youTube().sendChatError,
    ChatType.Kick => this._kick().sendChatError,
    _ => null,
  };

  /// Pick the target chip's platform (remembered across sessions). A
  /// pending reply elsewhere is dropped — the reply locks its platform.
  @action
  void selectSendTarget(ChatType platform) {
    this._ensureSettingsLoaded();
    if (platform != this.replyPlatform) this.clearReplyTarget();
    this.sendTargetChoice = platform;
    try {
      Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.CombinedChatSendTarget.name, platform.name);
    } catch (e) {
      GeneralHelper.advLog('Combined chat send target persist failed - $e');
    }
  }

  /// Reply to a merged-timeline message: its platform's store takes the
  /// target (and sends it along), any other platform's pending reply is
  /// dropped so only one reply strip shows.
  @action
  void setReplyTarget(Object payload) {
    switch (payload) {
      case ChatMessageEvent():
        this._kick().clearReplyTarget();
        this._twitch().setReplyTarget(payload);
      case KickChatMessage():
        this._twitch().clearReplyTarget();
        this._kick().setReplyTarget(payload);
    }
  }

  @action
  void clearReplyTarget() {
    this._twitch().clearReplyTarget();
    this._kick().clearReplyTarget();
  }

  /// Send [text] to [sendTarget] (with its pending reply). Never throws;
  /// failures surface in [sendChatError].
  Future<bool> send(String text) async {
    switch (this.sendTarget) {
      case ChatType.Twitch:
        return this._twitch().sendChatMessage(text);
      case ChatType.YouTube:
        return this._youTube().sendChatMessage(text);
      case ChatType.Kick:
        return this._kick().sendChatMessage(text);
      case ChatType.Owncast:
      case ChatType.Combined:
      case null:
        return false;
    }
  }

  /// Jump from the combined view into [platform]'s own chat, still on the
  /// combo's channel ("↩ Combined" brings the user back). The other
  /// sources stay selected: Twitch / Kick keep running, YouTube pauses.
  @action
  void focus(ChatType platform) {
    if (!this.active) return;
    this.focusedPlatform = platform;
    this._focusSwitch = true;
    Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.SelectedChatType.name, platform);
  }

  /// Back from a [focus] jump to the combined view.
  @action
  void returnToCombined() {
    Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.SelectedChatType.name, ChatType.Combined);
  }

  /// YouTube polls on quota — pause it while the user looks at another
  /// platform. Twitch / Kick connections cost nothing and keep running,
  /// so the combined timeline stays complete for the way back.
  void _pauseBackground({ChatType? except}) {
    if (except == ChatType.YouTube) return;
    if (this.activeSources.any((s) => s.platform == ChatType.YouTube)) {
      this._youTube().pausePolling();
    }
  }

  /// Point every source's platform store at the source (remembering the
  /// previous selection once). Idempotent — re-run it when [mySources]
  /// changes while active (a sign-in adds a source live).
  @action
  Future<void> activate() async {
    this._ensureSettingsLoaded();
    this.focusedPlatform = null;
    this._youTube().resumePolling();
    final generation = ++this._generation;
    this.active = true;
    for (final source in this.activeSources) {
      if (generation != this._generation) return;
      if (source.unavailable) continue;
      await this._select(source);
    }
  }

  /// Put back what each platform store showed before [activate].
  @action
  Future<void> deactivate() async {
    this._ensureSettingsLoaded();
    this.focusedPlatform = null;
    this._youTube().resumePolling();
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
    if (enabled && this.active && this.selectedCombo == null) {
      for (final source in this.mySources) {
        if (source.platform == platform) await this._select(source);
      }
    }
  }

  /// Show [comboId] ("My chats" or a saved combo). While active the new
  /// sources are selected right away; the restore point stays the one
  /// taken when Combined was entered.
  @action
  Future<void> selectCombo(String comboId) async {
    this._ensureSettingsLoaded();
    if (comboId != kMyChatsComboId &&
        !this.combos.any((combo) => combo.id == comboId)) {
      comboId = kMyChatsComboId;
    }
    if (comboId == this.selectedComboId) return;
    this.selectedComboId = comboId;
    this._persistSelectedCombo();
    final combo = this.selectedCombo;
    if (combo != null) this._registerSources(combo);
    if (this.active) await this.activate();
  }

  /// Create or update a combo (matched by id) and show it. Its sources
  /// are added to their platform's own channel list first — the platform
  /// stores can only show channels they list.
  @action
  Future<void> saveCombo(CombinedCombo combo) async {
    this._ensureSettingsLoaded();
    final index = this.combos.indexWhere((c) => c.id == combo.id);
    if (index >= 0) {
      this.combos[index] = combo;
    } else {
      this.combos.add(combo);
    }
    this._persistCombos();
    this._registerSources(combo);
    if (this.selectedComboId == combo.id) {
      if (this.active) await this.activate();
    } else {
      await this.selectCombo(combo.id);
    }
  }

  /// Drop a saved combo; showing it falls back to "My chats". The
  /// channels stay in the platform lists (the user may use them there).
  @action
  Future<void> deleteCombo(String comboId) async {
    this._ensureSettingsLoaded();
    this.combos.removeWhere((combo) => combo.id == comboId);
    this._persistCombos();
    if (this.selectedComboId == comboId) {
      await this.selectCombo(kMyChatsComboId);
    }
  }

  /// Put every source of [combo] into its platform's channel list
  /// (idempotent; a YouTube entry deleted meanwhile is re-created).
  void _registerSources(CombinedCombo combo) {
    try {
      if (combo.twitch case final ref?) this._twitch().ensureChannel(ref);
      final box = Hive.box(HiveKeys.Settings.name);
      if (combo.youTube case final source?) {
        final entries = Map<String, String>.from(
          box.get(
            SettingsKeys.YouTubeUsernames.name,
            defaultValue: <String, String>{},
          ),
        );
        if (entries[source.label] != source.value) {
          entries[source.label] = source.value;
          box.put(SettingsKeys.YouTubeUsernames.name, entries);
          this._youTube().reloadChannels();
        }
      }
      if (combo.kickSlug case final slug?) {
        final kick = this._kick();
        if (!kick.isOwnChannel(slug)) {
          final slugs = List<String>.from(
            box.get(SettingsKeys.KickUsernames.name, defaultValue: <String>[]),
          );
          if (!slugs.contains(slug)) {
            slugs.add(slug);
            box.put(SettingsKeys.KickUsernames.name, slugs);
            kick.reloadChannels();
          }
        }
      }
    } catch (e) {
      GeneralHelper.advLog('Combined chat source registration failed - $e');
    }
  }

  void _ensureSettingsLoaded() {
    if (this._settingsLoaded) return;
    this._settingsLoaded = true;
    try {
      final box = Hive.box(HiveKeys.Settings.name);
      this.combos.addAll(
        parseCombinedCombos(box.get(SettingsKeys.CombinedChatCombos.name)),
      );
      final selected = box.get(SettingsKeys.SelectedCombinedCombo.name);
      if (selected is String &&
          this.combos.any((combo) => combo.id == selected)) {
        this.selectedComboId = selected;
      }
    } catch (e) {
      GeneralHelper.advLog('Combined chat combos load failed - $e');
    }
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
      final target = Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.CombinedChatSendTarget.name);
      for (final type in ChatType.values) {
        if (type.name == target) this.sendTargetChoice = type;
      }
    } catch (e) {
      GeneralHelper.advLog('Combined chat send target load failed - $e');
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

  void _persistCombos() {
    try {
      Hive.box(HiveKeys.Settings.name).put(
        SettingsKeys.CombinedChatCombos.name,
        [for (final combo in this.combos) combo.toJson()],
      );
    } catch (e) {
      GeneralHelper.advLog('Combined chat combos persist failed - $e');
    }
  }

  void _persistSelectedCombo() {
    try {
      Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.SelectedCombinedCombo.name, this.selectedComboId);
    } catch (e) {
      GeneralHelper.advLog('Combined chat combo selection persist failed - $e');
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
