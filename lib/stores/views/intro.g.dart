// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intro.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$IntroStore on _IntroStore, Store {
  final _$currentPageAtom = Atom(name: '_IntroStore.currentPage');

  @override
  int get currentPage {
    _$currentPageAtom.reportRead();
    return super.currentPage;
  }

  @override
  set currentPage(int value) {
    _$currentPageAtom.reportWrite(value, super.currentPage, () {
      super.currentPage = value;
    });
  }

  final _$_IntroStoreActionController = ActionController(name: '_IntroStore');

  @override
  void setCurrentPage(int currentPage) {
    final _$actionInfo = _$_IntroStoreActionController.startAction(
        name: '_IntroStore.setCurrentPage');
    try {
      return super.setCurrentPage(currentPage);
    } finally {
      _$_IntroStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
currentPage: ${currentPage}
    ''';
  }
}
