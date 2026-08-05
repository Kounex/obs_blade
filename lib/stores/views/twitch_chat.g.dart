// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'twitch_chat.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$TwitchChatStore on _TwitchChatStore, Store {
  Computed<bool>? _$isLoggedInComputed;

  @override
  bool get isLoggedIn => (_$isLoggedInComputed ??= Computed<bool>(
    () => super.isLoggedIn,
    name: '_TwitchChatStore.isLoggedIn',
  )).value;

  late final _$authStateAtom = Atom(
    name: '_TwitchChatStore.authState',
    context: context,
  );

  @override
  TwitchAuthState get authState {
    _$authStateAtom.reportRead();
    return super.authState;
  }

  @override
  set authState(TwitchAuthState value) {
    _$authStateAtom.reportWrite(value, super.authState, () {
      super.authState = value;
    });
  }

  late final _$authErrorAtom = Atom(
    name: '_TwitchChatStore.authError',
    context: context,
  );

  @override
  String? get authError {
    _$authErrorAtom.reportRead();
    return super.authError;
  }

  @override
  set authError(String? value) {
    _$authErrorAtom.reportWrite(value, super.authError, () {
      super.authError = value;
    });
  }

  late final _$pendingUserCodeAtom = Atom(
    name: '_TwitchChatStore.pendingUserCode',
    context: context,
  );

  @override
  String? get pendingUserCode {
    _$pendingUserCodeAtom.reportRead();
    return super.pendingUserCode;
  }

  @override
  set pendingUserCode(String? value) {
    _$pendingUserCodeAtom.reportWrite(value, super.pendingUserCode, () {
      super.pendingUserCode = value;
    });
  }

  late final _$pendingVerificationUriAtom = Atom(
    name: '_TwitchChatStore.pendingVerificationUri',
    context: context,
  );

  @override
  String? get pendingVerificationUri {
    _$pendingVerificationUriAtom.reportRead();
    return super.pendingVerificationUri;
  }

  @override
  set pendingVerificationUri(String? value) {
    _$pendingVerificationUriAtom.reportWrite(
      value,
      super.pendingVerificationUri,
      () {
        super.pendingVerificationUri = value;
      },
    );
  }

  late final _$userAtom = Atom(name: '_TwitchChatStore.user', context: context);

  @override
  TwitchUser? get user {
    _$userAtom.reportRead();
    return super.user;
  }

  @override
  set user(TwitchUser? value) {
    _$userAtom.reportWrite(value, super.user, () {
      super.user = value;
    });
  }

  late final _$chatConnectionAtom = Atom(
    name: '_TwitchChatStore.chatConnection',
    context: context,
  );

  @override
  TwitchChatConnectionState get chatConnection {
    _$chatConnectionAtom.reportRead();
    return super.chatConnection;
  }

  @override
  set chatConnection(TwitchChatConnectionState value) {
    _$chatConnectionAtom.reportWrite(value, super.chatConnection, () {
      super.chatConnection = value;
    });
  }

  late final _$chatErrorAtom = Atom(
    name: '_TwitchChatStore.chatError',
    context: context,
  );

  @override
  String? get chatError {
    _$chatErrorAtom.reportRead();
    return super.chatError;
  }

  @override
  set chatError(String? value) {
    _$chatErrorAtom.reportWrite(value, super.chatError, () {
      super.chatError = value;
    });
  }

  late final _$chatConnectedAtAtom = Atom(
    name: '_TwitchChatStore.chatConnectedAt',
    context: context,
  );

  @override
  DateTime? get chatConnectedAt {
    _$chatConnectedAtAtom.reportRead();
    return super.chatConnectedAt;
  }

  @override
  set chatConnectedAt(DateTime? value) {
    _$chatConnectedAtAtom.reportWrite(value, super.chatConnectedAt, () {
      super.chatConnectedAt = value;
    });
  }

  late final _$initAsyncAction = AsyncAction(
    '_TwitchChatStore.init',
    context: context,
  );

  @override
  Future<void> init() {
    return _$initAsyncAction.run(() => super.init());
  }

  late final _$startLoginAsyncAction = AsyncAction(
    '_TwitchChatStore.startLogin',
    context: context,
  );

  @override
  Future<void> startLogin() {
    return _$startLoginAsyncAction.run(() => super.startLogin());
  }

  late final _$logoutAsyncAction = AsyncAction(
    '_TwitchChatStore.logout',
    context: context,
  );

  @override
  Future<void> logout() {
    return _$logoutAsyncAction.run(() => super.logout());
  }

  late final _$connectChatAsyncAction = AsyncAction(
    '_TwitchChatStore.connectChat',
    context: context,
  );

  @override
  Future<void> connectChat() {
    return _$connectChatAsyncAction.run(() => super.connectChat());
  }

  late final _$_TwitchChatStoreActionController = ActionController(
    name: '_TwitchChatStore',
    context: context,
  );

  @override
  void cancelLogin() {
    final _$actionInfo = _$_TwitchChatStoreActionController.startAction(
      name: '_TwitchChatStore.cancelLogin',
    );
    try {
      return super.cancelLogin();
    } finally {
      _$_TwitchChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _appendMessage(ChatMessageEvent event) {
    final _$actionInfo = _$_TwitchChatStoreActionController.startAction(
      name: '_TwitchChatStore._appendMessage',
    );
    try {
      return super._appendMessage(event);
    } finally {
      _$_TwitchChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void appendChatMessageForTest(ChatMessageEvent event) {
    final _$actionInfo = _$_TwitchChatStoreActionController.startAction(
      name: '_TwitchChatStore.appendChatMessageForTest',
    );
    try {
      return super.appendChatMessageForTest(event);
    } finally {
      _$_TwitchChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
authState: ${authState},
authError: ${authError},
pendingUserCode: ${pendingUserCode},
pendingVerificationUri: ${pendingVerificationUri},
user: ${user},
chatConnection: ${chatConnection},
chatError: ${chatError},
chatConnectedAt: ${chatConnectedAt},
isLoggedIn: ${isLoggedIn}
    ''';
  }
}
