import 'dart:async';
import 'dart:io';

import 'package:obs_blade/types/classes/twitch/twitch_device_code.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';

class FakeTwitchAuthService extends TwitchAuthService {
  bool validateResult = true;

  /// When set, [validate] throws this error (e.g. a [SocketException] for
  /// offline or a [TwitchAuthException] for a Twitch 5xx).
  Object? validateThrows;
  TwitchAuthException? failPollWith;

  /// When set, [pollForToken] parks on this completer instead of returning
  /// immediately — lets a test resolve the poll at a chosen moment.
  Completer<TwitchToken>? pollGate;
  String? revokedToken;

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
    return token;
  }

  @override
  Future<TwitchUser> fetchOwnUser(String accessToken) async => user;

  @override
  Future<bool> validate(String accessToken) async {
    if (this.validateThrows != null) throw this.validateThrows!;
    return this.validateResult;
  }

  @override
  Future<TwitchToken> refreshToken(String refreshToken) async => token;

  @override
  Future<void> revoke(String accessToken) async {
    this.revokedToken = accessToken;
  }
}

class FakeTwitchEventSubService extends TwitchEventSubService {
  bool connectCalled = false;
  String? lastAccessToken;
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
  }) async {
    this.connectCalled = true;
    this.lastAccessToken = accessToken;
  }

  @override
  Future<void> dispose() async {
    this.disposeCalled = true;
  }
}
