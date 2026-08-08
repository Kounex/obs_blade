// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'twitch_emotes.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$TwitchEmoteStore on _TwitchEmoteStore, Store {
  late final _$catalogVersionAtom = Atom(
    name: '_TwitchEmoteStore.catalogVersion',
    context: context,
  );

  @override
  int get catalogVersion {
    _$catalogVersionAtom.reportRead();
    return super.catalogVersion;
  }

  @override
  set catalogVersion(int value) {
    _$catalogVersionAtom.reportWrite(value, super.catalogVersion, () {
      super.catalogVersion = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_TwitchEmoteStore.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$fetchAsyncAction = AsyncAction(
    '_TwitchEmoteStore.fetch',
    context: context,
  );

  @override
  Future<void> fetch({
    required String accessToken,
    required String userId,
    required String broadcasterId,
  }) {
    return _$fetchAsyncAction.run(
      () => super.fetch(
        accessToken: accessToken,
        userId: userId,
        broadcasterId: broadcasterId,
      ),
    );
  }

  late final _$_TwitchEmoteStoreActionController = ActionController(
    name: '_TwitchEmoteStore',
    context: context,
  );

  @override
  void clear() {
    final _$actionInfo = _$_TwitchEmoteStoreActionController.startAction(
      name: '_TwitchEmoteStore.clear',
    );
    try {
      return super.clear();
    } finally {
      _$_TwitchEmoteStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
catalogVersion: ${catalogVersion},
isLoading: ${isLoading}
    ''';
  }
}
