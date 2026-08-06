// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'third_party_emotes.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ThirdPartyEmoteStore on _ThirdPartyEmoteStore, Store {
  late final _$catalogVersionAtom = Atom(
    name: '_ThirdPartyEmoteStore.catalogVersion',
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

  late final _$fetchAsyncAction = AsyncAction(
    '_ThirdPartyEmoteStore.fetch',
    context: context,
  );

  @override
  Future<void> fetch({required String broadcasterId}) {
    return _$fetchAsyncAction.run(
      () => super.fetch(broadcasterId: broadcasterId),
    );
  }

  late final _$_ThirdPartyEmoteStoreActionController = ActionController(
    name: '_ThirdPartyEmoteStore',
    context: context,
  );

  @override
  void clear() {
    final _$actionInfo = _$_ThirdPartyEmoteStoreActionController.startAction(
      name: '_ThirdPartyEmoteStore.clear',
    );
    try {
      return super.clear();
    } finally {
      _$_ThirdPartyEmoteStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
catalogVersion: ${catalogVersion}
    ''';
  }
}
