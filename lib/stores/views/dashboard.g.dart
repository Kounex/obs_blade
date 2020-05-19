// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$DashboardStore on _DashboardStore, Store {
  final _$isLiveAtom = Atom(name: '_DashboardStore.isLive');

  @override
  bool get isLive {
    _$isLiveAtom.context.enforceReadPolicy(_$isLiveAtom);
    _$isLiveAtom.reportObserved();
    return super.isLive;
  }

  @override
  set isLive(bool value) {
    _$isLiveAtom.context.conditionallyRunInAction(() {
      super.isLive = value;
      _$isLiveAtom.reportChanged();
    }, _$isLiveAtom, name: '${_$isLiveAtom.name}_set');
  }

  final _$goneLiveInMSAtom = Atom(name: '_DashboardStore.goneLiveInMS');

  @override
  int get goneLiveInMS {
    _$goneLiveInMSAtom.context.enforceReadPolicy(_$goneLiveInMSAtom);
    _$goneLiveInMSAtom.reportObserved();
    return super.goneLiveInMS;
  }

  @override
  set goneLiveInMS(int value) {
    _$goneLiveInMSAtom.context.conditionallyRunInAction(() {
      super.goneLiveInMS = value;
      _$goneLiveInMSAtom.reportChanged();
    }, _$goneLiveInMSAtom, name: '${_$goneLiveInMSAtom.name}_set');
  }

  final _$streamStatsAtom = Atom(name: '_DashboardStore.streamStats');

  @override
  StreamStats get streamStats {
    _$streamStatsAtom.context.enforceReadPolicy(_$streamStatsAtom);
    _$streamStatsAtom.reportObserved();
    return super.streamStats;
  }

  @override
  set streamStats(StreamStats value) {
    _$streamStatsAtom.context.conditionallyRunInAction(() {
      super.streamStats = value;
      _$streamStatsAtom.reportChanged();
    }, _$streamStatsAtom, name: '${_$streamStatsAtom.name}_set');
  }

  final _$activeSceneNameAtom = Atom(name: '_DashboardStore.activeSceneName');

  @override
  String get activeSceneName {
    _$activeSceneNameAtom.context.enforceReadPolicy(_$activeSceneNameAtom);
    _$activeSceneNameAtom.reportObserved();
    return super.activeSceneName;
  }

  @override
  set activeSceneName(String value) {
    _$activeSceneNameAtom.context.conditionallyRunInAction(() {
      super.activeSceneName = value;
      _$activeSceneNameAtom.reportChanged();
    }, _$activeSceneNameAtom, name: '${_$activeSceneNameAtom.name}_set');
  }

  final _$scenesAtom = Atom(name: '_DashboardStore.scenes');

  @override
  ObservableList<Scene> get scenes {
    _$scenesAtom.context.enforceReadPolicy(_$scenesAtom);
    _$scenesAtom.reportObserved();
    return super.scenes;
  }

  @override
  set scenes(ObservableList<Scene> value) {
    _$scenesAtom.context.conditionallyRunInAction(() {
      super.scenes = value;
      _$scenesAtom.reportChanged();
    }, _$scenesAtom, name: '${_$scenesAtom.name}_set');
  }

  final _$_DashboardStoreActionController =
      ActionController(name: '_DashboardStore');

  @override
  dynamic updateActiveScene(String name) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction();
    try {
      return super.updateActiveScene(name);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  dynamic setScenes(Iterable<Scene> scenes) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction();
    try {
      return super.setScenes(scenes);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  dynamic _handleEvent(BaseEvent event) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction();
    try {
      return super._handleEvent(event);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  dynamic _handleResponse(BaseResponse response) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction();
    try {
      return super._handleResponse(response);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    final string =
        'isLive: ${isLive.toString()},goneLiveInMS: ${goneLiveInMS.toString()},streamStats: ${streamStats.toString()},activeSceneName: ${activeSceneName.toString()},scenes: ${scenes.toString()}';
    return '{$string}';
  }
}
