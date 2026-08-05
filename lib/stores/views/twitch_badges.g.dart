// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'twitch_badges.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$TwitchBadgeStore on _TwitchBadgeStore, Store {
  late final _$isLoadingAtom = Atom(
    name: '_TwitchBadgeStore.isLoading',
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
    '_TwitchBadgeStore.fetch',
    context: context,
  );

  @override
  Future<void> fetch({
    required String accessToken,
    required String broadcasterId,
  }) {
    return _$fetchAsyncAction.run(
      () => super.fetch(accessToken: accessToken, broadcasterId: broadcasterId),
    );
  }

  late final _$_TwitchBadgeStoreActionController = ActionController(
    name: '_TwitchBadgeStore',
    context: context,
  );

  @override
  void clear() {
    final _$actionInfo = _$_TwitchBadgeStoreActionController.startAction(
      name: '_TwitchBadgeStore.clear',
    );
    try {
      return super.clear();
    } finally {
      _$_TwitchBadgeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading}
    ''';
  }
}
