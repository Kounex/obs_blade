// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_chat.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$YouTubeChatStore on _YouTubeChatStore, Store {
  Computed<bool>? _$isSignedInStateComputed;

  @override
  bool get isSignedInState => (_$isSignedInStateComputed ??= Computed<bool>(
    () => super.isSignedInState,
    name: '_YouTubeChatStore.isSignedInState',
  )).value;

  late final _$authStateAtom = Atom(
    name: '_YouTubeChatStore.authState',
    context: context,
  );

  @override
  YouTubeAuthState get authState {
    _$authStateAtom.reportRead();
    return super.authState;
  }

  @override
  set authState(YouTubeAuthState value) {
    _$authStateAtom.reportWrite(value, super.authState, () {
      super.authState = value;
    });
  }

  late final _$authErrorAtom = Atom(
    name: '_YouTubeChatStore.authError',
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
    name: '_YouTubeChatStore.pendingUserCode',
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

  late final _$pendingVerificationUrlAtom = Atom(
    name: '_YouTubeChatStore.pendingVerificationUrl',
    context: context,
  );

  @override
  String? get pendingVerificationUrl {
    _$pendingVerificationUrlAtom.reportRead();
    return super.pendingVerificationUrl;
  }

  @override
  set pendingVerificationUrl(String? value) {
    _$pendingVerificationUrlAtom.reportWrite(
      value,
      super.pendingVerificationUrl,
      () {
        super.pendingVerificationUrl = value;
      },
    );
  }

  late final _$chatConnectionAtom = Atom(
    name: '_YouTubeChatStore.chatConnection',
    context: context,
  );

  @override
  YouTubeChatConnectionState get chatConnection {
    _$chatConnectionAtom.reportRead();
    return super.chatConnection;
  }

  @override
  set chatConnection(YouTubeChatConnectionState value) {
    _$chatConnectionAtom.reportWrite(value, super.chatConnection, () {
      super.chatConnection = value;
    });
  }

  late final _$chatErrorAtom = Atom(
    name: '_YouTubeChatStore.chatError',
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

  late final _$chatQuotaExhaustedAtom = Atom(
    name: '_YouTubeChatStore.chatQuotaExhausted',
    context: context,
  );

  @override
  bool get chatQuotaExhausted {
    _$chatQuotaExhaustedAtom.reportRead();
    return super.chatQuotaExhausted;
  }

  @override
  set chatQuotaExhausted(bool value) {
    _$chatQuotaExhaustedAtom.reportWrite(value, super.chatQuotaExhausted, () {
      super.chatQuotaExhausted = value;
    });
  }

  late final _$sendingChatAtom = Atom(
    name: '_YouTubeChatStore.sendingChat',
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
    name: '_YouTubeChatStore.sendChatError',
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

  late final _$moderationErrorAtom = Atom(
    name: '_YouTubeChatStore.moderationError',
    context: context,
  );

  @override
  String? get moderationError {
    _$moderationErrorAtom.reportRead();
    return super.moderationError;
  }

  @override
  set moderationError(String? value) {
    _$moderationErrorAtom.reportWrite(value, super.moderationError, () {
      super.moderationError = value;
    });
  }

  late final _$selectedChannelLabelAtom = Atom(
    name: '_YouTubeChatStore.selectedChannelLabel',
    context: context,
  );

  @override
  String? get selectedChannelLabel {
    _$selectedChannelLabelAtom.reportRead();
    return super.selectedChannelLabel;
  }

  @override
  set selectedChannelLabel(String? value) {
    _$selectedChannelLabelAtom.reportWrite(
      value,
      super.selectedChannelLabel,
      () {
        super.selectedChannelLabel = value;
      },
    );
  }

  late final _$initAsyncAction = AsyncAction(
    '_YouTubeChatStore.init',
    context: context,
  );

  @override
  Future<void> init() {
    return _$initAsyncAction.run(() => super.init());
  }

  late final _$startLoginAsyncAction = AsyncAction(
    '_YouTubeChatStore.startLogin',
    context: context,
  );

  @override
  Future<void> startLogin() {
    return _$startLoginAsyncAction.run(() => super.startLogin());
  }

  late final _$logoutAsyncAction = AsyncAction(
    '_YouTubeChatStore.logout',
    context: context,
  );

  @override
  Future<void> logout() {
    return _$logoutAsyncAction.run(() => super.logout());
  }

  late final _$selectChannelAsyncAction = AsyncAction(
    '_YouTubeChatStore.selectChannel',
    context: context,
  );

  @override
  Future<void> selectChannel(String? label) {
    return _$selectChannelAsyncAction.run(() => super.selectChannel(label));
  }

  late final _$sendChatMessageAsyncAction = AsyncAction(
    '_YouTubeChatStore.sendChatMessage',
    context: context,
  );

  @override
  Future<bool> sendChatMessage(String text) {
    return _$sendChatMessageAsyncAction.run(() => super.sendChatMessage(text));
  }

  late final _$deleteMessageAsyncAction = AsyncAction(
    '_YouTubeChatStore.deleteMessage',
    context: context,
  );

  @override
  Future<bool> deleteMessage(String messageId) {
    return _$deleteMessageAsyncAction.run(() => super.deleteMessage(messageId));
  }

  late final _$banUserAsyncAction = AsyncAction(
    '_YouTubeChatStore.banUser',
    context: context,
  );

  @override
  Future<bool> banUser(String channelId, {int? durationSeconds}) {
    return _$banUserAsyncAction.run(
      () => super.banUser(channelId, durationSeconds: durationSeconds),
    );
  }

  late final _$unbanUserAsyncAction = AsyncAction(
    '_YouTubeChatStore.unbanUser',
    context: context,
  );

  @override
  Future<bool> unbanUser(String banId) {
    return _$unbanUserAsyncAction.run(() => super.unbanUser(banId));
  }

  late final _$_YouTubeChatStoreActionController = ActionController(
    name: '_YouTubeChatStore',
    context: context,
  );

  @override
  void cancelLogin() {
    final _$actionInfo = _$_YouTubeChatStoreActionController.startAction(
      name: '_YouTubeChatStore.cancelLogin',
    );
    try {
      return super.cancelLogin();
    } finally {
      _$_YouTubeChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void connectChat() {
    final _$actionInfo = _$_YouTubeChatStoreActionController.startAction(
      name: '_YouTubeChatStore.connectChat',
    );
    try {
      return super.connectChat();
    } finally {
      _$_YouTubeChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _applyTombstone(String label, YouTubeChatMessage tombstone) {
    final _$actionInfo = _$_YouTubeChatStoreActionController.startAction(
      name: '_YouTubeChatStore._applyTombstone',
    );
    try {
      return super._applyTombstone(label, tombstone);
    } finally {
      _$_YouTubeChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _applyUserBanned(String label, YouTubeChatMessage event) {
    final _$actionInfo = _$_YouTubeChatStoreActionController.startAction(
      name: '_YouTubeChatStore._applyUserBanned',
    );
    try {
      return super._applyUserBanned(label, event);
    } finally {
      _$_YouTubeChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reloadChannels() {
    final _$actionInfo = _$_YouTubeChatStoreActionController.startAction(
      name: '_YouTubeChatStore.reloadChannels',
    );
    try {
      return super.reloadChannels();
    } finally {
      _$_YouTubeChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
authState: ${authState},
authError: ${authError},
pendingUserCode: ${pendingUserCode},
pendingVerificationUrl: ${pendingVerificationUrl},
chatConnection: ${chatConnection},
chatError: ${chatError},
chatQuotaExhausted: ${chatQuotaExhausted},
sendingChat: ${sendingChat},
sendChatError: ${sendChatError},
moderationError: ${moderationError},
selectedChannelLabel: ${selectedChannelLabel},
isSignedInState: ${isSignedInState}
    ''';
  }
}
