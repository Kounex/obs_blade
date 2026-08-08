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

  late final _$sendingChatAtom = Atom(
    name: '_TwitchChatStore.sendingChat',
    context: context,
  );

  @override
  bool get sendingChat {
    _$sendingChatAtom.reportRead();
    return super.sendingChat;
  }

  @override
  set sendingChat(bool value) {
    _$sendingChatAtom.reportWrite(value, super.sendingChat, () {
      super.sendingChat = value;
    });
  }

  late final _$sendChatErrorAtom = Atom(
    name: '_TwitchChatStore.sendChatError',
    context: context,
  );

  @override
  String? get sendChatError {
    _$sendChatErrorAtom.reportRead();
    return super.sendChatError;
  }

  @override
  set sendChatError(String? value) {
    _$sendChatErrorAtom.reportWrite(value, super.sendChatError, () {
      super.sendChatError = value;
    });
  }

  late final _$selectedChannelIdAtom = Atom(
    name: '_TwitchChatStore.selectedChannelId',
    context: context,
  );

  @override
  String? get selectedChannelId {
    _$selectedChannelIdAtom.reportRead();
    return super.selectedChannelId;
  }

  @override
  set selectedChannelId(String? value) {
    _$selectedChannelIdAtom.reportWrite(value, super.selectedChannelId, () {
      super.selectedChannelId = value;
    });
  }

  late final _$lifecycleVersionAtom = Atom(
    name: '_TwitchChatStore.lifecycleVersion',
    context: context,
  );

  @override
  int get lifecycleVersion {
    _$lifecycleVersionAtom.reportRead();
    return super.lifecycleVersion;
  }

  @override
  set lifecycleVersion(int value) {
    _$lifecycleVersionAtom.reportWrite(value, super.lifecycleVersion, () {
      super.lifecycleVersion = value;
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

  late final _$addChannelAsyncAction = AsyncAction(
    '_TwitchChatStore.addChannel',
    context: context,
  );

  @override
  Future<void> addChannel(TwitchChannelRef ref) {
    return _$addChannelAsyncAction.run(() => super.addChannel(ref));
  }

  late final _$removeChannelAsyncAction = AsyncAction(
    '_TwitchChatStore.removeChannel',
    context: context,
  );

  @override
  Future<void> removeChannel(String id) {
    return _$removeChannelAsyncAction.run(() => super.removeChannel(id));
  }

  late final _$selectChannelAsyncAction = AsyncAction(
    '_TwitchChatStore.selectChannel',
    context: context,
  );

  @override
  Future<void> selectChannel(String? id) {
    return _$selectChannelAsyncAction.run(() => super.selectChannel(id));
  }

  late final _$sendChatMessageAsyncAction = AsyncAction(
    '_TwitchChatStore.sendChatMessage',
    context: context,
  );

  @override
  Future<bool> sendChatMessage(String text) {
    return _$sendChatMessageAsyncAction.run(() => super.sendChatMessage(text));
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
  void applyMessageDelete(ChatMessageDeleteEvent event) {
    final _$actionInfo = _$_TwitchChatStoreActionController.startAction(
      name: '_TwitchChatStore.applyMessageDelete',
    );
    try {
      return super.applyMessageDelete(event);
    } finally {
      _$_TwitchChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void applyModerationDelete(String messageId, String actorName) {
    final _$actionInfo = _$_TwitchChatStoreActionController.startAction(
      name: '_TwitchChatStore.applyModerationDelete',
    );
    try {
      return super.applyModerationDelete(messageId, actorName);
    } finally {
      _$_TwitchChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void applyClearUserMessages(String targetUserId) {
    final _$actionInfo = _$_TwitchChatStoreActionController.startAction(
      name: '_TwitchChatStore.applyClearUserMessages',
    );
    try {
      return super.applyClearUserMessages(targetUserId);
    } finally {
      _$_TwitchChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void applyChatClear() {
    final _$actionInfo = _$_TwitchChatStoreActionController.startAction(
      name: '_TwitchChatStore.applyChatClear',
    );
    try {
      return super.applyChatClear();
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
sendingChat: ${sendingChat},
sendChatError: ${sendChatError},
selectedChannelId: ${selectedChannelId},
lifecycleVersion: ${lifecycleVersion},
isLoggedIn: ${isLoggedIn}
    ''';
  }
}
