// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kick_chat.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$KickChatStore on _KickChatStore, Store {
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

  late final _$initAsyncAction = AsyncAction(
    '_KickChatStore.init',
    context: context,
  );

  @override
  Future<void> init() {
    return _$initAsyncAction.run(() => super.init());
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
selectedChannelSlug: ${selectedChannelSlug}
    ''';
  }
}
