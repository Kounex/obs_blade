// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kick_chat.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$KickChatStore on _KickChatStore, Store {
  Computed<List<String>>? _$nativeChannelsComputed;

  @override
  List<String> get nativeChannels =>
      (_$nativeChannelsComputed ??= Computed<List<String>>(
        () => super.nativeChannels,
        name: '_KickChatStore.nativeChannels',
      )).value;
  Computed<bool>? _$isSignedInStateComputed;

  @override
  bool get isSignedInState => (_$isSignedInStateComputed ??= Computed<bool>(
    () => super.isSignedInState,
    name: '_KickChatStore.isSignedInState',
  )).value;

  late final _$chatConnectionAtom = Atom(
    name: '_KickChatStore.chatConnection',
    context: context,
  );

  @override
  KickChatConnectionState get chatConnection {
    _$chatConnectionAtom.reportRead();
    return super.chatConnection;
  }

  @override
  set chatConnection(KickChatConnectionState value) {
    _$chatConnectionAtom.reportWrite(value, super.chatConnection, () {
      super.chatConnection = value;
    });
  }

  late final _$chatErrorAtom = Atom(
    name: '_KickChatStore.chatError',
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
    name: '_KickChatStore.chatConnectedAt',
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

  late final _$channelInfoAtom = Atom(
    name: '_KickChatStore.channelInfo',
    context: context,
  );

  @override
  KickChannelInfo? get channelInfo {
    _$channelInfoAtom.reportRead();
    return super.channelInfo;
  }

  @override
  set channelInfo(KickChannelInfo? value) {
    _$channelInfoAtom.reportWrite(value, super.channelInfo, () {
      super.channelInfo = value;
    });
  }

  late final _$ownChannelSlugAtom = Atom(
    name: '_KickChatStore.ownChannelSlug',
    context: context,
  );

  @override
  String? get ownChannelSlug {
    _$ownChannelSlugAtom.reportRead();
    return super.ownChannelSlug;
  }

  @override
  set ownChannelSlug(String? value) {
    _$ownChannelSlugAtom.reportWrite(value, super.ownChannelSlug, () {
      super.ownChannelSlug = value;
    });
  }

  late final _$selectedChannelSlugAtom = Atom(
    name: '_KickChatStore.selectedChannelSlug',
    context: context,
  );

  @override
  String? get selectedChannelSlug {
    _$selectedChannelSlugAtom.reportRead();
    return super.selectedChannelSlug;
  }

  @override
  set selectedChannelSlug(String? value) {
    _$selectedChannelSlugAtom.reportWrite(value, super.selectedChannelSlug, () {
      super.selectedChannelSlug = value;
    });
  }

  late final _$authStateAtom = Atom(
    name: '_KickChatStore.authState',
    context: context,
  );

  @override
  KickAuthState get authState {
    _$authStateAtom.reportRead();
    return super.authState;
  }

  @override
  set authState(KickAuthState value) {
    _$authStateAtom.reportWrite(value, super.authState, () {
      super.authState = value;
    });
  }

  late final _$authErrorAtom = Atom(
    name: '_KickChatStore.authError',
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

  late final _$sendingChatAtom = Atom(
    name: '_KickChatStore.sendingChat',
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
    name: '_KickChatStore.sendChatError',
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

  late final _$modActionErrorAtom = Atom(
    name: '_KickChatStore.modActionError',
    context: context,
  );

  @override
  String? get modActionError {
    _$modActionErrorAtom.reportRead();
    return super.modActionError;
  }

  @override
  set modActionError(String? value) {
    _$modActionErrorAtom.reportWrite(value, super.modActionError, () {
      super.modActionError = value;
    });
  }

  late final _$modActionForbiddenAtom = Atom(
    name: '_KickChatStore.modActionForbidden',
    context: context,
  );

  @override
  bool get modActionForbidden {
    _$modActionForbiddenAtom.reportRead();
    return super.modActionForbidden;
  }

  @override
  set modActionForbidden(bool value) {
    _$modActionForbiddenAtom.reportWrite(value, super.modActionForbidden, () {
      super.modActionForbidden = value;
    });
  }

  late final _$pinnedMessageAtom = Atom(
    name: '_KickChatStore.pinnedMessage',
    context: context,
  );

  @override
  KickChatMessage? get pinnedMessage {
    _$pinnedMessageAtom.reportRead();
    return super.pinnedMessage;
  }

  @override
  set pinnedMessage(KickChatMessage? value) {
    _$pinnedMessageAtom.reportWrite(value, super.pinnedMessage, () {
      super.pinnedMessage = value;
    });
  }

  late final _$replyTargetAtom = Atom(
    name: '_KickChatStore.replyTarget',
    context: context,
  );

  @override
  KickChatMessage? get replyTarget {
    _$replyTargetAtom.reportRead();
    return super.replyTarget;
  }

  @override
  set replyTarget(KickChatMessage? value) {
    _$replyTargetAtom.reportWrite(value, super.replyTarget, () {
      super.replyTarget = value;
    });
  }

  late final _$initAsyncAction = AsyncAction(
    '_KickChatStore.init',
    context: context,
  );

  @override
  Future<void> init() {
    return _$initAsyncAction.run(() => super.init());
  }

  late final _$refreshChannelLivePreviewsAsyncAction = AsyncAction(
    '_KickChatStore.refreshChannelLivePreviews',
    context: context,
  );

  @override
  Future<void> refreshChannelLivePreviews() {
    return _$refreshChannelLivePreviewsAsyncAction.run(
      () => super.refreshChannelLivePreviews(),
    );
  }

  late final _$beginLoginAsyncAction = AsyncAction(
    '_KickChatStore.beginLogin',
    context: context,
  );

  @override
  Future<Uri?> beginLogin() {
    return _$beginLoginAsyncAction.run(() => super.beginLogin());
  }

  late final _$pollProxyLoginAsyncAction = AsyncAction(
    '_KickChatStore.pollProxyLogin',
    context: context,
  );

  @override
  Future<bool?> pollProxyLogin() {
    return _$pollProxyLoginAsyncAction.run(() => super.pollProxyLogin());
  }

  late final _$completeLoginAsyncAction = AsyncAction(
    '_KickChatStore.completeLogin',
    context: context,
  );

  @override
  Future<bool> completeLogin(String pastedRedirectUrl) {
    return _$completeLoginAsyncAction.run(
      () => super.completeLogin(pastedRedirectUrl),
    );
  }

  late final _$logoutAsyncAction = AsyncAction(
    '_KickChatStore.logout',
    context: context,
  );

  @override
  Future<void> logout() {
    return _$logoutAsyncAction.run(() => super.logout());
  }

  late final _$sendChatMessageAsyncAction = AsyncAction(
    '_KickChatStore.sendChatMessage',
    context: context,
  );

  @override
  Future<bool> sendChatMessage(String text, {String? replyToMessageId}) {
    return _$sendChatMessageAsyncAction.run(
      () => super.sendChatMessage(text, replyToMessageId: replyToMessageId),
    );
  }

  late final _$deleteChatMessageAsyncAction = AsyncAction(
    '_KickChatStore.deleteChatMessage',
    context: context,
  );

  @override
  Future<bool> deleteChatMessage(String messageId) {
    return _$deleteChatMessageAsyncAction.run(
      () => super.deleteChatMessage(messageId),
    );
  }

  late final _$unbanUserAsyncAction = AsyncAction(
    '_KickChatStore.unbanUser',
    context: context,
  );

  @override
  Future<bool> unbanUser(int userId) {
    return _$unbanUserAsyncAction.run(() => super.unbanUser(userId));
  }

  late final _$unbanUsernameAsyncAction = AsyncAction(
    '_KickChatStore.unbanUsername',
    context: context,
  );

  @override
  Future<bool> unbanUsername(String nameOrSlug) {
    return _$unbanUsernameAsyncAction.run(
      () => super.unbanUsername(nameOrSlug),
    );
  }

  late final _$selectChannelAsyncAction = AsyncAction(
    '_KickChatStore.selectChannel',
    context: context,
  );

  @override
  Future<void> selectChannel(String? slug) {
    return _$selectChannelAsyncAction.run(() => super.selectChannel(slug));
  }

  late final _$_KickChatStoreActionController = ActionController(
    name: '_KickChatStore',
    context: context,
  );

  @override
  void cancelLogin() {
    final _$actionInfo = _$_KickChatStoreActionController.startAction(
      name: '_KickChatStore.cancelLogin',
    );
    try {
      return super.cancelLogin();
    } finally {
      _$_KickChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void connectChat() {
    final _$actionInfo = _$_KickChatStoreActionController.startAction(
      name: '_KickChatStore.connectChat',
    );
    try {
      return super.connectChat();
    } finally {
      _$_KickChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setReplyTarget(KickChatMessage message) {
    final _$actionInfo = _$_KickChatStoreActionController.startAction(
      name: '_KickChatStore.setReplyTarget',
    );
    try {
      return super.setReplyTarget(message);
    } finally {
      _$_KickChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearReplyTarget() {
    final _$actionInfo = _$_KickChatStoreActionController.startAction(
      name: '_KickChatStore.clearReplyTarget',
    );
    try {
      return super.clearReplyTarget();
    } finally {
      _$_KickChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<bool> timeoutUser(int userId, int durationMinutes) {
    final _$actionInfo = _$_KickChatStoreActionController.startAction(
      name: '_KickChatStore.timeoutUser',
    );
    try {
      return super.timeoutUser(userId, durationMinutes);
    } finally {
      _$_KickChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<bool> banUser(int userId) {
    final _$actionInfo = _$_KickChatStoreActionController.startAction(
      name: '_KickChatStore.banUser',
    );
    try {
      return super.banUser(userId);
    } finally {
      _$_KickChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reloadChannels() {
    final _$actionInfo = _$_KickChatStoreActionController.startAction(
      name: '_KickChatStore.reloadChannels',
    );
    try {
      return super.reloadChannels();
    } finally {
      _$_KickChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
chatConnection: ${chatConnection},
chatError: ${chatError},
chatConnectedAt: ${chatConnectedAt},
channelInfo: ${channelInfo},
ownChannelSlug: ${ownChannelSlug},
selectedChannelSlug: ${selectedChannelSlug},
authState: ${authState},
authError: ${authError},
sendingChat: ${sendingChat},
sendChatError: ${sendChatError},
modActionError: ${modActionError},
modActionForbidden: ${modActionForbidden},
pinnedMessage: ${pinnedMessage},
replyTarget: ${replyTarget},
nativeChannels: ${nativeChannels},
isSignedInState: ${isSignedInState}
    ''';
  }
}
