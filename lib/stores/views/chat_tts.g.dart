// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_tts.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ChatTtsStore on _ChatTtsStore, Store {
  late final _$enabledAtom = Atom(
    name: '_ChatTtsStore.enabled',
    context: context,
  );

  @override
  bool get enabled {
    _$enabledAtom.reportRead();
    return super.enabled;
  }

  @override
  set enabled(bool value) {
    _$enabledAtom.reportWrite(value, super.enabled, () {
      super.enabled = value;
    });
  }

  late final _$waitingAtom = Atom(
    name: '_ChatTtsStore.waiting',
    context: context,
  );

  @override
  int get waiting {
    _$waitingAtom.reportRead();
    return super.waiting;
  }

  @override
  set waiting(int value) {
    _$waitingAtom.reportWrite(value, super.waiting, () {
      super.waiting = value;
    });
  }

  late final _$speakingAtom = Atom(
    name: '_ChatTtsStore.speaking',
    context: context,
  );

  @override
  bool get speaking {
    _$speakingAtom.reportRead();
    return super.speaking;
  }

  @override
  set speaking(bool value) {
    _$speakingAtom.reportWrite(value, super.speaking, () {
      super.speaking = value;
    });
  }

  late final _$voicesAtom = Atom(
    name: '_ChatTtsStore.voices',
    context: context,
  );

  @override
  List<ChatTtsVoice>? get voices {
    _$voicesAtom.reportRead();
    return super.voices;
  }

  @override
  set voices(List<ChatTtsVoice>? value) {
    _$voicesAtom.reportWrite(value, super.voices, () {
      super.voices = value;
    });
  }

  late final _$_ChatTtsStoreActionController = ActionController(
    name: '_ChatTtsStore',
    context: context,
  );

  @override
  void setEnabled(bool on, {bool persist = true}) {
    final _$actionInfo = _$_ChatTtsStoreActionController.startAction(
      name: '_ChatTtsStore.setEnabled',
    );
    try {
      return super.setEnabled(on, persist: persist);
    } finally {
      _$_ChatTtsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _syncQueueState() {
    final _$actionInfo = _$_ChatTtsStoreActionController.startAction(
      name: '_ChatTtsStore._syncQueueState',
    );
    try {
      return super._syncQueueState();
    } finally {
      _$_ChatTtsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
enabled: ${enabled},
waiting: ${waiting},
speaking: ${speaking},
voices: ${voices}
    ''';
  }
}
