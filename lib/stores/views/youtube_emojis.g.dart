// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_emojis.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$YouTubeEmojiStore on _YouTubeEmojiStore, Store {
  late final _$revisionAtom = Atom(
    name: '_YouTubeEmojiStore.revision',
    context: context,
  );

  @override
  int get revision {
    _$revisionAtom.reportRead();
    return super.revision;
  }

  @override
  set revision(int value) {
    _$revisionAtom.reportWrite(value, super.revision, () {
      super.revision = value;
    });
  }

  late final _$_YouTubeEmojiStoreActionController = ActionController(
    name: '_YouTubeEmojiStore',
    context: context,
  );

  @override
  void used(YouTubeEmoji emoji) {
    final _$actionInfo = _$_YouTubeEmojiStoreActionController.startAction(
      name: '_YouTubeEmojiStore.used',
    );
    try {
      return super.used(emoji);
    } finally {
      _$_YouTubeEmojiStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addAll(Iterable<YouTubeEmoji> emojis) {
    final _$actionInfo = _$_YouTubeEmojiStoreActionController.startAction(
      name: '_YouTubeEmojiStore.addAll',
    );
    try {
      return super.addAll(emojis);
    } finally {
      _$_YouTubeEmojiStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
revision: ${revision}
    ''';
  }
}
