import 'dart:async';
import 'dart:io';

import 'package:obs_blade/types/classes/twitch/third_party_emote.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_search_result.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/types/classes/twitch/twitch_device_code.dart';
import 'package:obs_blade/types/classes/twitch/twitch_send_result.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user_emote.dart';
import 'package:obs_blade/utils/twitch/third_party_emote_service.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_badge_service.dart';
import 'package:obs_blade/utils/twitch/twitch_channel_service.dart';
import 'package:obs_blade/utils/twitch/twitch_emote_service.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';
import 'package:obs_blade/utils/twitch/twitch_message_service.dart';
import 'package:obs_blade/utils/twitch/twitch_moderation_service.dart';

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

  @override
  Future<TwitchSendResult> sendChatMessage({
    required String accessToken,
    required String senderId,
    required String broadcasterId,
    required String message,
  }) async {
    this.calls++;
    this.lastMessage = message;
    this.lastSenderId = senderId;
    this.lastBroadcasterId = broadcasterId;
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

  /// Ids returned as live from [getLiveBroadcasterIds] (intersected with
  /// the requested set). Empty by default — picker tests that need LIVE
  /// chips set this explicitly.
  Set<String> liveBroadcasterIds = const {};

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
  Future<Set<String>> getLiveBroadcasterIds({
    required String accessToken,
    required Iterable<String> broadcasterIds,
  }) async {
    this.liveCalls++;
    this.lastLiveBroadcasterIds = broadcasterIds.toList();
    if (this.liveThrows != null) throw this.liveThrows!;
    final requested = broadcasterIds.toSet();
    return this.liveBroadcasterIds.intersection(requested);
  }
}

/// Records delete/ban calls; [deleteThrows] / [banThrows] simulate the
/// Helix failure paths (store must leave local state untouched).
class FakeTwitchModerationService extends TwitchModerationService {
  Object? deleteThrows;
  Object? banThrows;

  int deleteCalls = 0;
  int banCalls = 0;
  String? lastDeleteBroadcasterId;
  String? lastDeleteModeratorId;
  String? lastDeleteMessageId;
  String? lastBanBroadcasterId;
  String? lastBanModeratorId;
  String? lastBanUserId;
  int? lastBanDurationSeconds;

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
}
