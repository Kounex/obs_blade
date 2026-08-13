import 'dart:async';
import 'dart:io';

import 'package:obs_blade/types/classes/twitch/chat_settings.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/third_party_emote.dart';
import 'package:obs_blade/types/classes/twitch/twitch_banned_user.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_search_result.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/types/classes/twitch/twitch_device_code.dart';
import 'package:obs_blade/types/classes/twitch/twitch_pinned_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_send_result.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user_emote.dart';
import 'package:obs_blade/types/classes/twitch/twitch_warning.dart';
import 'package:obs_blade/utils/twitch/third_party_emote_service.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_badge_service.dart';
import 'package:obs_blade/utils/twitch/twitch_channel_service.dart';
import 'package:obs_blade/utils/twitch/twitch_emote_service.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';
import 'package:obs_blade/utils/twitch/twitch_message_service.dart';
import 'package:obs_blade/utils/twitch/twitch_irc_sidecar.dart';
import 'package:obs_blade/utils/twitch/twitch_moderation_service.dart';
import 'package:obs_blade/utils/twitch/twitch_user_service.dart';

class FakeTwitchAuthService extends TwitchAuthService {
  bool validateResult = true;

  /// When set, [validate] throws this error (e.g. a [SocketException] for
  /// offline or a [TwitchAuthException] for a Twitch 5xx).
  Object? validateThrows;
  TwitchAuthException? failPollWith;

  /// When set, [refreshToken] throws this instead of returning a fresh
  /// token (e.g. a transient Twitch 5xx or a definitive 401).
  TwitchAuthException? failRefreshWith;

  /// When set, [pollForToken] parks on this completer instead of returning
  /// immediately — lets a test resolve the poll at a chosen moment.
  Completer<TwitchToken>? pollGate;
  String? revokedToken;

  /// Scopes the returned [TwitchToken] carries (default: read-only).
  List<String> tokenScopes = const ['user:read:chat'];

  static const token = TwitchToken(
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    expiresIn: 14400,
    scope: ['user:read:chat'],
  );

  static const user = TwitchUser(
    id: 'user-1',
    login: 'kounex',
    displayName: 'Kounex',
  );

  @override
  Future<TwitchDeviceCode> requestDeviceCode() async =>
      const TwitchDeviceCode(
        deviceCode: 'dev',
        userCode: 'ABCD',
        verificationUri: 'https://www.twitch.tv/activate',
        expiresIn: 1800,
        interval: 0,
      );

  @override
  Future<TwitchToken> pollForToken(
    TwitchDeviceCode deviceCode, {
    required FutureOr<void> Function() onPending,
    required bool Function() isCancelled,
  }) async {
    if (isCancelled()) throw const TwitchAuthException('Login cancelled');
    if (this.failPollWith != null) throw this.failPollWith!;
    if (this.pollGate != null) return this.pollGate!.future;
    return TwitchToken(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      expiresIn: token.expiresIn,
      scope: this.tokenScopes,
    );
  }

  @override
  Future<TwitchUser> fetchOwnUser(String accessToken) async => user;

  @override
  Future<bool> validate(String accessToken) async {
    if (this.validateThrows != null) throw this.validateThrows!;
    return this.validateResult;
  }

  @override
  Future<TwitchToken> refreshToken(String refreshToken) async {
    if (this.failRefreshWith != null) throw this.failRefreshWith!;
    return TwitchToken(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      expiresIn: token.expiresIn,
      scope: this.tokenScopes,
    );
  }

  @override
  Future<void> revoke(String accessToken) async {
    this.revokedToken = accessToken;
  }
}

class FakeTwitchEventSubService extends TwitchEventSubService {
  bool connectCalled = false;
  String? lastAccessToken;
  bool? lastIncludeModeration;
  String? lastUserId;
  String? lastBroadcasterId;
  int switchChannelCalls = 0;
  String? lastSwitchBroadcasterId;

  /// When set, [switchChannel] throws this error (subscription failure on
  /// switch — the chat pane's error path).
  Object? switchChannelThrows;

  /// Invoked inside [switchChannel] after bookkeeping — lets tests inject
  /// EventSub arrivals mid-switch (buffer race).
  Future<void> Function(String broadcasterId)? onSwitchChannel;
  bool disposeCalled = false;

  FakeTwitchEventSubService()
      : super(
          onChatMessage: (_) {},
          onStateChanged: (_) {},
          onRevoked: (_) {},
        );

  @override
  Future<void> connect({
    required String accessToken,
    required String userId,
    required String broadcasterId,
    bool includeModeration = false,
  }) async {
    this.connectCalled = true;
    this.lastAccessToken = accessToken;
    this.lastUserId = userId;
    this.lastBroadcasterId = broadcasterId;
    this.lastIncludeModeration = includeModeration;
  }

  @override
  Future<void> switchChannel(String broadcasterId) async {
    this.switchChannelCalls++;
    this.lastSwitchBroadcasterId = broadcasterId;
    if (this.switchChannelThrows != null) throw this.switchChannelThrows!;
    final hook = this.onSwitchChannel;
    if (hook != null) await hook(broadcasterId);
  }

  @override
  Future<void> dispose() async {
    this.disposeCalled = true;
  }
}

class FakeTwitchBadgeService extends TwitchBadgeService {
  List<TwitchBadgeSet> globalSets = const [];
  List<TwitchBadgeSet> channelSets = const [];

  /// When set, the matching fetch throws this error.
  Object? globalThrows;
  Object? channelThrows;

  /// When set, [fetchGlobalBadges] parks on this completer — lets a test
  /// resolve the fetch at a chosen moment (stale-fetch tests).
  Completer<List<TwitchBadgeSet>>? globalGate;

  String? lastAccessToken;
  String? lastBroadcasterId;
  int globalCalls = 0;
  int channelCalls = 0;

  static const moderatorSet = TwitchBadgeSet(
    setId: 'moderator',
    versions: [
      TwitchBadgeVersion(
        id: '1',
        imageUrl1x: 'https://badges.example/mod/1x.png',
        imageUrl2x: 'https://badges.example/mod/2x.png',
        imageUrl4x: 'https://badges.example/mod/4x.png',
        title: 'Moderator',
      ),
    ],
  );

  static const subscriberSet = TwitchBadgeSet(
    setId: 'subscriber',
    versions: [
      TwitchBadgeVersion(
        id: '12',
        imageUrl1x: 'https://badges.example/sub/1x.png',
        imageUrl2x: 'https://badges.example/sub/2x.png',
        imageUrl4x: 'https://badges.example/sub/4x.png',
        title: 'Subscriber',
      ),
    ],
  );

  /// Same set id as [moderatorSet], different image — used to prove the
  /// channel catalog wins over the global one.
  static const moderatorChannelOverrideSet = TwitchBadgeSet(
    setId: 'moderator',
    versions: [
      TwitchBadgeVersion(
        id: '1',
        imageUrl1x: 'https://badges.example/mod-override/1x.png',
        imageUrl2x: 'https://badges.example/mod-override/2x.png',
        imageUrl4x: 'https://badges.example/mod-override/4x.png',
        title: 'Moderator',
      ),
    ],
  );

  @override
  Future<List<TwitchBadgeSet>> fetchGlobalBadges(String accessToken) async {
    this.globalCalls++;
    this.lastAccessToken = accessToken;
    if (this.globalThrows != null) throw this.globalThrows!;
    if (this.globalGate != null) return this.globalGate!.future;
    return this.globalSets;
  }

  @override
  Future<List<TwitchBadgeSet>> fetchChannelBadges(
    String accessToken,
    String broadcasterId,
  ) async {
    this.channelCalls++;
    this.lastBroadcasterId = broadcasterId;
    if (this.channelThrows != null) throw this.channelThrows!;
    return this.channelSets;
  }
}

class FakeTwitchMessageService extends TwitchMessageService {
  TwitchSendResult result = const TwitchSendResult(
    messageId: 'msg-1',
    isSent: true,
  );

  /// When set, [sendChatMessage] throws this error.
  Object? sendThrows;

  /// When set, [sendChatMessage] parks on this completer — lets a test
  /// resolve the send at a chosen moment (in-flight tests).
  Completer<TwitchSendResult>? sendGate;

  int calls = 0;
  String? lastMessage;
  String? lastSenderId;
  String? lastBroadcasterId;
  String? lastReplyParentMessageId;

  @override
  Future<TwitchSendResult> sendChatMessage({
    required String accessToken,
    required String senderId,
    required String broadcasterId,
    required String message,
    String? replyParentMessageId,
  }) async {
    this.calls++;
    this.lastMessage = message;
    this.lastSenderId = senderId;
    this.lastBroadcasterId = broadcasterId;
    this.lastReplyParentMessageId = replyParentMessageId;
    if (this.sendThrows != null) throw this.sendThrows!;
    if (this.sendGate != null) return this.sendGate!.future;
    return this.result;
  }
}

class FakeThirdPartyEmoteService extends ThirdPartyEmoteService {
  Map<String, ThirdPartyEmote> sevenTvGlobal = const {};
  Map<String, ThirdPartyEmote> sevenTvChannel = const {};
  Map<String, ThirdPartyEmote> bttvGlobal = const {};
  Map<String, ThirdPartyEmote> bttvChannel = const {};

  /// When set, the matching fetch throws this error.
  Object? sevenTvGlobalThrows;
  Object? bttvChannelThrows;

  /// When set, [fetchSevenTvGlobal] parks on this completer — lets a test
  /// resolve the fetch at a chosen moment (stale-fetch tests).
  Completer<Map<String, ThirdPartyEmote>>? sevenTvGlobalGate;

  String? lastBroadcasterId;
  int sevenTvGlobalCalls = 0;
  int sevenTvChannelCalls = 0;
  int bttvGlobalCalls = 0;
  int bttvChannelCalls = 0;

  static const peepo = ThirdPartyEmote(
    name: 'peepoHappy',
    imageUrl: 'https://cdn.7tv.app/emote/peepo/2x.webp',
  );

  /// Same name as [peepo], different image — proves channel > global.
  static const peepoChannelOverride = ThirdPartyEmote(
    name: 'peepoHappy',
    imageUrl: 'https://cdn.7tv.app/emote/peepo-override/2x.webp',
  );

  static const monka = ThirdPartyEmote(
    name: 'monkaS',
    imageUrl: 'https://cdn.betterttv.net/emote/monka/2x',
  );

  /// Same name as [monka], 7TV image — proves 7TV > BTTV same-scope ties.
  static const monkaSevenTv = ThirdPartyEmote(
    name: 'monkaS',
    imageUrl: 'https://cdn.7tv.app/emote/monka-7tv/2x.webp',
  );

  @override
  Future<Map<String, ThirdPartyEmote>> fetchSevenTvGlobal() async {
    this.sevenTvGlobalCalls++;
    if (this.sevenTvGlobalThrows != null) throw this.sevenTvGlobalThrows!;
    if (this.sevenTvGlobalGate != null) return this.sevenTvGlobalGate!.future;
    return this.sevenTvGlobal;
  }

  @override
  Future<Map<String, ThirdPartyEmote>> fetchSevenTvChannel(
      String broadcasterId) async {
    this.sevenTvChannelCalls++;
    this.lastBroadcasterId = broadcasterId;
    return this.sevenTvChannel;
  }

  @override
  Future<Map<String, ThirdPartyEmote>> fetchBttvGlobal() async {
    this.bttvGlobalCalls++;
    return this.bttvGlobal;
  }

  @override
  Future<Map<String, ThirdPartyEmote>> fetchBttvChannel(
      String broadcasterId) async {
    this.bttvChannelCalls++;
    this.lastBroadcasterId = broadcasterId;
    if (this.bttvChannelThrows != null) throw this.bttvChannelThrows!;
    return this.bttvChannel;
  }
}

class FakeTwitchEmoteService extends TwitchEmoteService {
  List<TwitchUserEmote> emotes = const [];

  /// When set, the fetch throws this error.
  Object? fetchThrows;

  /// When set, the fetch parks on this completer — lets a test resolve the
  /// fetch at a chosen moment (stale-fetch tests).
  Completer<List<TwitchUserEmote>>? fetchGate;

  int calls = 0;
  String? lastAccessToken;
  String? lastUserId;
  String? lastBroadcasterId;

  static const channelEmote = TwitchUserEmote(
    id: '25',
    name: 'Kappa',
    ownerId: 'user-1',
    emoteType: 'subscriptions',
    emoteSetId: 'set-1',
  );

  static const globalEmote = TwitchUserEmote(
    id: '88',
    name: 'PogChamp',
    ownerId: 'twitch',
  );

  /// Sorts before [channelEmote] alphabetically — proves alpha ordering.
  static const anotherChannelEmote = TwitchUserEmote(
    id: '4',
    name: 'BabyRage',
    ownerId: 'user-1',
    emoteType: 'subscriptions',
    emoteSetId: 'set-1',
  );

  @override
  Future<List<TwitchUserEmote>> fetchUserEmotes(
    String accessToken, {
    required String userId,
    required String broadcasterId,
  }) async {
    this.calls++;
    this.lastAccessToken = accessToken;
    this.lastUserId = userId;
    this.lastBroadcasterId = broadcasterId;
    if (this.fetchThrows != null) throw this.fetchThrows!;
    if (this.fetchGate != null) return this.fetchGate!.future;
    return this.emotes;
  }
}

class FakeTwitchChannelService extends TwitchChannelService {
  List<TwitchChannelRef> moderatedChannels = const [];
  List<TwitchChannelRef> followedChannels = const [];
  List<TwitchChannelSearchResult> searchResults = const [];

  /// Live streams returned from [getLiveBroadcasterIds] (intersected with
  /// the requested set). Empty by default — picker tests that need LIVE
  /// chips set this explicitly (id → viewer count).
  Map<String, int> liveStreams = const {};

  /// When set, the matching call throws this error (picker section /
  /// login fetch failure paths).
  Object? moderatedThrows;
  Object? followedThrows;
  Object? searchThrows;
  Object? liveThrows;

  int moderatedCalls = 0;
  int followedCalls = 0;
  int searchCalls = 0;
  int liveCalls = 0;
  String? lastModeratedUserId;
  String? lastFollowedUserId;
  String? lastQuery;
  List<String>? lastLiveBroadcasterIds;

  static TwitchChannelRef channel(String id) => TwitchChannelRef(
        id: id,
        login: 'login-$id',
        displayName: 'Channel $id',
        addedAt: DateTime.utc(2026, 8, 9),
      );

  @override
  Future<List<TwitchChannelRef>> getModeratedChannels({
    required String accessToken,
    required String userId,
  }) async {
    this.moderatedCalls++;
    this.lastModeratedUserId = userId;
    if (this.moderatedThrows != null) throw this.moderatedThrows!;
    return this.moderatedChannels;
  }

  @override
  Future<List<TwitchChannelRef>> getFollowedChannels({
    required String accessToken,
    required String userId,
  }) async {
    this.followedCalls++;
    this.lastFollowedUserId = userId;
    if (this.followedThrows != null) throw this.followedThrows!;
    return this.followedChannels;
  }

  @override
  Future<List<TwitchChannelSearchResult>> searchChannels({
    required String accessToken,
    required String query,
  }) async {
    this.searchCalls++;
    this.lastQuery = query;
    if (this.searchThrows != null) throw this.searchThrows!;
    return this.searchResults;
  }

  @override
  Future<Map<String, int>> getLiveBroadcasterIds({
    required String accessToken,
    required Iterable<String> broadcasterIds,
  }) async {
    this.liveCalls++;
    this.lastLiveBroadcasterIds = broadcasterIds.toList();
    if (this.liveThrows != null) throw this.liveThrows!;
    final requested = broadcasterIds.toSet();
    return {
      for (final entry in this.liveStreams.entries)
        if (requested.contains(entry.key)) entry.key: entry.value,
    };
  }
}

class FakeTwitchModerationService extends TwitchModerationService {
  Object? deleteThrows;
  Object? banThrows;
  Object? clearThrows;
  Object? getSettingsThrows;
  Object? updateSettingsThrows;
  Object? getShieldThrows;
  Object? updateShieldThrows;
  Object? announceThrows;
  Object? getPinnedThrows;
  Object? pinThrows;
  Object? unpinThrows;
  Object? getBansThrows;
  Object? unbanThrows;
  Object? unbanRequestsThrows;
  Object? resolveUnbanRequestThrows;
  Object? warnThrows;
  Object? getWarningsThrows;
  Object? autoModThrows;

  int deleteCalls = 0;
  int banCalls = 0;
  int clearCalls = 0;
  int getSettingsCalls = 0;
  int updateSettingsCalls = 0;
  int getShieldCalls = 0;
  int updateShieldCalls = 0;
  int announceCalls = 0;
  int getPinnedCalls = 0;
  int pinCalls = 0;
  int unpinCalls = 0;
  int getBansCalls = 0;
  int unbanCalls = 0;
  int unbanRequestsCalls = 0;
  int resolveUnbanRequestCalls = 0;
  int warnCalls = 0;
  int getWarningsCalls = 0;
  int autoModCalls = 0;
  String? lastDeleteBroadcasterId;
  String? lastDeleteModeratorId;
  String? lastDeleteMessageId;
  String? lastBanBroadcasterId;
  String? lastBanModeratorId;
  String? lastBanUserId;
  int? lastBanDurationSeconds;
  String? lastClearBroadcasterId;
  String? lastClearModeratorId;
  String? lastSettingsBroadcasterId;
  String? lastSettingsModeratorId;
  bool? lastUpdateEmoteMode;
  bool? lastUpdateFollowerMode;
  int? lastUpdateFollowerDurationMinutes;
  bool? lastUpdateSubscriberMode;
  bool? lastUpdateSlowMode;
  int? lastUpdateSlowModeWaitSeconds;
  bool? lastUpdateUniqueChatMode;
  String? lastShieldBroadcasterId;
  String? lastShieldModeratorId;
  bool? lastShieldIsActive;
  String? lastAnnounceBroadcasterId;
  String? lastAnnounceModeratorId;
  String? lastAnnounceMessage;
  String? lastAnnounceColor;
  String? lastPinnedBroadcasterId;
  String? lastPinnedModeratorId;
  String? lastPinMessageId;
  String? lastUnpinMessageId;
  String? lastUnbanUserId;
  String? lastResolveUnbanRequestId;
  bool? lastResolveUnbanApproved;
  String? lastWarnBroadcasterId;
  String? lastWarnModeratorId;
  String? lastWarnUserId;
  String? lastWarnReason;
  String? lastWarningsBroadcasterId;
  String? lastWarningsUserId;
  String? lastAutoModModeratorId;
  String? lastAutoModMessageId;
  bool? lastAutoModAllow;

  /// Sample pinned message returned by [getPinnedChatMessage] when
  /// [pinnedMessageResult] is left untouched — assign a custom one (or
  /// null for the "nothing pinned" case) to steer a test.
  static final pinnedSample = TwitchPinnedMessage(
    messageId: 'msg-pinned',
    broadcasterId: 'user-1',
    senderUserId: 'user-2',
    senderUserLogin: 'chatter',
    senderUserName: 'Chatter',
    pinnedByUserId: 'user-1',
    pinnedByUserLogin: 'kounex',
    pinnedByUserName: 'Kounex',
    message: const ChatMessageText(text: 'remember the giveaway'),
  );

  /// Returned by [getPinnedChatMessage] — defaults to [pinnedSample];
  /// assign explicitly (incl. null) to steer a test.
  TwitchPinnedMessage? pinnedMessageResult = pinnedSample;

  /// Permanent-ban sample for the ban inbox.
  static const bannedSample = TwitchBannedUser(
    userId: 'bad-1',
    userLogin: 'troll',
    userName: 'Troll',
    reason: 'spam',
    moderatorName: 'Kounex',
  );

  /// Timeout sample (carries an expiry, unlike [bannedSample]).
  static final timeoutSample = TwitchBannedUser(
    userId: 'bad-2',
    userLogin: 'capslock',
    userName: 'CapsLock',
    reason: 'shouting',
    expiresAt: DateTime.utc(2026, 8, 20),
  );

  /// Pending unban request sample for [bannedSample]'s user.
  static const unbanRequestSample = TwitchUnbanRequest(
    id: 'req-1',
    userId: 'bad-1',
    userLogin: 'troll',
    userName: 'Troll',
    text: 'sorry, will behave',
  );

  /// Warning sample for the user-card warnings section.
  static final warningSample = TwitchWarning(
    userId: 'bad-1',
    userLogin: 'troll',
    userName: 'Troll',
    moderatorName: 'Kounex',
    reason: 'spoiling movies',
    warnedAt: DateTime.utc(2026, 8, 12),
  );

  /// Ban inbox results — assigned into the store by the refresh.
  List<TwitchBannedUser> bannedUsersResult = const [bannedSample];
  List<TwitchUnbanRequest> unbanRequestsResult = const [unbanRequestSample];

  /// Warnings returned by [getWarnings].
  List<TwitchWarning> warningsResult = [warningSample];

  TwitchChatSettings chatSettings = const TwitchChatSettings(
    emoteMode: false,
    followerMode: false,
    followerModeDurationMinutes: null,
    subscriberMode: false,
    slowMode: false,
    slowModeWaitTimeSeconds: null,
    uniqueChatMode: false,
  );

  bool shieldModeActive = false;

  @override
  Future<void> deleteChatMessage({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String messageId,
  }) async {
    this.deleteCalls++;
    this.lastDeleteBroadcasterId = broadcasterId;
    this.lastDeleteModeratorId = moderatorId;
    this.lastDeleteMessageId = messageId;
    if (this.deleteThrows != null) throw this.deleteThrows!;
  }

  @override
  Future<void> banUser({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String userId,
    int? durationSeconds,
  }) async {
    this.banCalls++;
    this.lastBanBroadcasterId = broadcasterId;
    this.lastBanModeratorId = moderatorId;
    this.lastBanUserId = userId;
    this.lastBanDurationSeconds = durationSeconds;
    if (this.banThrows != null) throw this.banThrows!;
  }

  @override
  Future<void> clearChat({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
  }) async {
    this.clearCalls++;
    this.lastClearBroadcasterId = broadcasterId;
    this.lastClearModeratorId = moderatorId;
    if (this.clearThrows != null) throw this.clearThrows!;
  }

  @override
  Future<TwitchChatSettings> getChatSettings({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
  }) async {
    this.getSettingsCalls++;
    this.lastSettingsBroadcasterId = broadcasterId;
    this.lastSettingsModeratorId = moderatorId;
    if (this.getSettingsThrows != null) throw this.getSettingsThrows!;
    return this.chatSettings;
  }

  @override
  Future<void> updateChatSettings({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    bool? emoteMode,
    bool? followerMode,
    int? followerModeDurationMinutes,
    bool? subscriberMode,
    bool? slowMode,
    int? slowModeWaitTimeSeconds,
    bool? uniqueChatMode,
  }) async {
    this.updateSettingsCalls++;
    this.lastSettingsBroadcasterId = broadcasterId;
    this.lastSettingsModeratorId = moderatorId;
    this.lastUpdateEmoteMode = emoteMode;
    this.lastUpdateFollowerMode = followerMode;
    this.lastUpdateFollowerDurationMinutes = followerModeDurationMinutes;
    this.lastUpdateSubscriberMode = subscriberMode;
    this.lastUpdateSlowMode = slowMode;
    this.lastUpdateSlowModeWaitSeconds = slowModeWaitTimeSeconds;
    this.lastUpdateUniqueChatMode = uniqueChatMode;
    if (this.updateSettingsThrows != null) throw this.updateSettingsThrows!;
    this.chatSettings = this.chatSettings.copyWithWithUpdates(
          emoteMode: emoteMode,
          followerMode: followerMode,
          followerModeDurationMinutes: followerModeDurationMinutes,
          subscriberMode: subscriberMode,
          slowMode: slowMode,
          slowModeWaitTimeSeconds: slowModeWaitTimeSeconds,
          uniqueChatMode: uniqueChatMode,
        );
  }

  @override
  Future<bool> getShieldModeStatus({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
  }) async {
    this.getShieldCalls++;
    this.lastShieldBroadcasterId = broadcasterId;
    this.lastShieldModeratorId = moderatorId;
    if (this.getShieldThrows != null) throw this.getShieldThrows!;
    return this.shieldModeActive;
  }

  @override
  Future<void> updateShieldModeStatus({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required bool isActive,
  }) async {
    this.updateShieldCalls++;
    this.lastShieldBroadcasterId = broadcasterId;
    this.lastShieldModeratorId = moderatorId;
    this.lastShieldIsActive = isActive;
    if (this.updateShieldThrows != null) throw this.updateShieldThrows!;
    this.shieldModeActive = isActive;
  }

  @override
  Future<void> sendChatAnnouncement({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String message,
    required String color,
  }) async {
    this.announceCalls++;
    this.lastAnnounceBroadcasterId = broadcasterId;
    this.lastAnnounceModeratorId = moderatorId;
    this.lastAnnounceMessage = message;
    this.lastAnnounceColor = color;
    if (this.announceThrows != null) throw this.announceThrows!;
  }

  @override
  Future<TwitchPinnedMessage?> getPinnedChatMessage({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
  }) async {
    this.getPinnedCalls++;
    this.lastPinnedBroadcasterId = broadcasterId;
    this.lastPinnedModeratorId = moderatorId;
    if (this.getPinnedThrows != null) throw this.getPinnedThrows!;
    return this.pinnedMessageResult;
  }

  @override
  Future<void> pinChatMessage({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String messageId,
  }) async {
    this.pinCalls++;
    this.lastPinnedBroadcasterId = broadcasterId;
    this.lastPinnedModeratorId = moderatorId;
    this.lastPinMessageId = messageId;
    if (this.pinThrows != null) throw this.pinThrows!;

    /// Mirror Helix: after a pin, the GET returns the newly pinned
    /// message (the store refetches right after a local pin).
    this.pinnedMessageResult = TwitchPinnedMessage(
      messageId: messageId,
      broadcasterId: broadcasterId,
      senderUserId: 'user-2',
      senderUserLogin: 'chatter',
      senderUserName: 'Chatter',
      pinnedByUserId: moderatorId,
      pinnedByUserLogin: 'kounex',
      pinnedByUserName: 'Kounex',
      message: const ChatMessageText(text: 'pinned text'),
    );
  }

  @override
  Future<void> unpinChatMessage({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String messageId,
  }) async {
    this.unpinCalls++;
    this.lastPinnedBroadcasterId = broadcasterId;
    this.lastPinnedModeratorId = moderatorId;
    this.lastUnpinMessageId = messageId;
    if (this.unpinThrows != null) throw this.unpinThrows!;
    this.pinnedMessageResult = null;
  }

  @override
  Future<List<TwitchBannedUser>> getBannedUsers({
    required String accessToken,
    required String broadcasterId,
  }) async {
    this.getBansCalls++;
    if (this.getBansThrows != null) throw this.getBansThrows!;
    return List.of(this.bannedUsersResult);
  }

  @override
  Future<void> unbanUser({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String userId,
  }) async {
    this.unbanCalls++;
    this.lastUnbanUserId = userId;
    if (this.unbanThrows != null) throw this.unbanThrows!;
    this.bannedUsersResult =
        this.bannedUsersResult.where((user) => user.userId != userId).toList();
    this.unbanRequestsResult = this
        .unbanRequestsResult
        .where((request) => request.userId != userId)
        .toList();
  }

  @override
  Future<List<TwitchUnbanRequest>> getPendingUnbanRequests({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
  }) async {
    this.unbanRequestsCalls++;
    if (this.unbanRequestsThrows != null) throw this.unbanRequestsThrows!;
    return List.of(this.unbanRequestsResult);
  }

  @override
  Future<void> resolveUnbanRequest({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String requestId,
    required bool approved,
    String? resolutionText,
  }) async {
    this.resolveUnbanRequestCalls++;
    this.lastResolveUnbanRequestId = requestId;
    this.lastResolveUnbanApproved = approved;
    if (this.resolveUnbanRequestThrows != null) {
      throw this.resolveUnbanRequestThrows!;
    }

    /// Mirror Helix: the request leaves the pending list, and an approval
    /// also lifts the ban.
    final matches = this
        .unbanRequestsResult
        .where((request) => request.id == requestId)
        .toList();
    final resolvedUserId = matches.isEmpty ? null : matches.first.userId;
    this.unbanRequestsResult = this
        .unbanRequestsResult
        .where((request) => request.id != requestId)
        .toList();
    if (approved && resolvedUserId != null) {
      this.bannedUsersResult = this
          .bannedUsersResult
          .where((user) => user.userId != resolvedUserId)
          .toList();
    }
  }

  @override
  Future<void> warnUser({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String userId,
    required String reason,
  }) async {
    this.warnCalls++;
    this.lastWarnBroadcasterId = broadcasterId;
    this.lastWarnModeratorId = moderatorId;
    this.lastWarnUserId = userId;
    this.lastWarnReason = reason;
    if (this.warnThrows != null) throw this.warnThrows!;
  }

  @override
  Future<List<TwitchWarning>> getWarnings({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String userId,
  }) async {
    this.getWarningsCalls++;
    this.lastWarningsBroadcasterId = broadcasterId;
    this.lastWarningsUserId = userId;
    if (this.getWarningsThrows != null) throw this.getWarningsThrows!;
    return List.of(this.warningsResult);
  }

  @override
  Future<void> handleAutoModMessage({
    required String accessToken,
    required String moderatorId,
    required String messageId,
    required bool allow,
  }) async {
    this.autoModCalls++;
    this.lastAutoModModeratorId = moderatorId;
    this.lastAutoModMessageId = messageId;
    this.lastAutoModAllow = allow;
    if (this.autoModThrows != null) throw this.autoModThrows!;
  }
}

class FakeTwitchUserService extends TwitchUserService {
  TwitchUser? userResult;
  DateTime? followResult;
  DateTime? selfFollowResult;
  TwitchSelfSubscription? selfSubResult;

  int fetchUserCalls = 0;
  String? lastUserId;

  @override
  Future<TwitchUser?> fetchUser({
    required String accessToken,
    required String userId,
  }) async {
    this.fetchUserCalls++;
    this.lastUserId = userId;
    return this.userResult;
  }

  @override
  Future<DateTime?> followerSince({
    required String accessToken,
    required String broadcasterId,
    required String userId,
  }) async =>
      this.followResult;

  @override
  Future<DateTime?> selfFollowedAt({
    required String accessToken,
    required String userId,
    required String broadcasterId,
  }) async =>
      this.selfFollowResult;

  @override
  Future<TwitchSelfSubscription?> selfSubscription({
    required String accessToken,
    required String broadcasterId,
  }) async =>
      this.selfSubResult;
}

/// No-op IRC sidecar so widget/store tests never open a real Twitch WS
/// (and never leave pending connect timers after dispose).
class FakeSilentIrcSidecar extends TwitchIrcSidecar {
  FakeSilentIrcSidecar()
      : super(
          onFirstMessage: (_) {},
          channelFactory: (_) => throw StateError('IRC disabled in tests'),
          sleep: (_) async {},
        );

  @override
  Future<void> connect({
    required String accessToken,
    required String login,
    required String channelLogin,
  }) async {}

  @override
  Future<void> switchChannel(String channelLogin) async {}

  @override
  Future<void> dispose() async {}
}
