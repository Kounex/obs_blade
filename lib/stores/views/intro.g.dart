// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intro.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$IntroStore on _IntroStore, Store {
  late final _$currentPageAtom =
      Atom(name: '_IntroStore.currentPage', context: context);

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

  late final _$lockedOnSlideAtom =
      Atom(name: '_IntroStore.lockedOnSlide', context: context);

  @override
  bool get lockedOnSlide {
    _$lockedOnSlideAtom.reportRead();
    return super.lockedOnSlide;
  }

  @override
  set lockedOnSlide(bool value) {
    _$lockedOnSlideAtom.reportWrite(value, super.lockedOnSlide, () {
      super.lockedOnSlide = value;
    });
  }

  late final _$slideLockSecondsLeftAtom =
      Atom(name: '_IntroStore.slideLockSecondsLeft', context: context);

  @override
  int get slideLockSecondsLeft {
    _$slideLockSecondsLeftAtom.reportRead();
    return super.slideLockSecondsLeft;
  }

  @override
  set slideLockSecondsLeft(int value) {
    _$slideLockSecondsLeftAtom.reportWrite(value, super.slideLockSecondsLeft,
        () {
      super.slideLockSecondsLeft = value;
    });
  }

  late final _$_IntroStoreActionController =
      ActionController(name: '_IntroStore', context: context);

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
  void setLockedOnSlide(bool lockedOnSlide, [int? secondsToLockSlide]) {
    final _$actionInfo = _$_IntroStoreActionController.startAction(
        name: '_IntroStore.setLockedOnSlide');
    try {
      return super.setLockedOnSlide(lockedOnSlide, secondsToLockSlide);
    } finally {
      _$_IntroStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
currentPage: ${currentPage},
lockedOnSlide: ${lockedOnSlide},
slideLockSecondsLeft: ${slideLockSecondsLeft}
    ''';
  }
}
