// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logs.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$LogsStore on _LogsStore, Store {
  final _$logLevelAtom = Atom(name: '_LogsStore.logLevel');

  @override
  LogLevel? get logLevel {
    _$logLevelAtom.reportRead();
    return super.logLevel;
  }

  @override
  set logLevel(LogLevel? value) {
    _$logLevelAtom.reportWrite(value, super.logLevel, () {
      super.logLevel = value;
    });
  }

  final _$_LogsStoreActionController = ActionController(name: '_LogsStore');

  @override
  void setLogLevel(LogLevel logLevel) {
    final _$actionInfo = _$_LogsStoreActionController.startAction(
        name: '_LogsStore.setLogLevel');
    try {
      return super.setLogLevel(logLevel);
    } finally {
      _$_LogsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
logLevel: ${logLevel}
    ''';
  }
}
