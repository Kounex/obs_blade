// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$DashboardStore on _DashboardStore, Store {
  Computed<ObservableList<SceneItem>> _$currentAudioSceneItemsComputed;

  @override
  ObservableList<SceneItem> get currentAudioSceneItems =>
      (_$currentAudioSceneItemsComputed ??= Computed<ObservableList<SceneItem>>(
              () => super.currentAudioSceneItems,
              name: '_DashboardStore.currentAudioSceneItems'))
          .value;

  final _$isLiveAtom = Atom(name: '_DashboardStore.isLive');

  @override
  bool get isLive {
    _$isLiveAtom.reportRead();
    return super.isLive;
  }

  @override
  set isLive(bool value) {
    _$isLiveAtom.reportWrite(value, super.isLive, () {
      super.isLive = value;
    });
  }

  final _$goneLiveInMSAtom = Atom(name: '_DashboardStore.goneLiveInMS');

  @override
  int get goneLiveInMS {
    _$goneLiveInMSAtom.reportRead();
    return super.goneLiveInMS;
  }

  @override
  set goneLiveInMS(int value) {
    _$goneLiveInMSAtom.reportWrite(value, super.goneLiveInMS, () {
      super.goneLiveInMS = value;
    });
  }

  final _$streamStatsAtom = Atom(name: '_DashboardStore.streamStats');

  @override
  StreamStats get streamStats {
    _$streamStatsAtom.reportRead();
    return super.streamStats;
  }

  @override
  set streamStats(StreamStats value) {
    _$streamStatsAtom.reportWrite(value, super.streamStats, () {
      super.streamStats = value;
    });
  }

  final _$activeSceneNameAtom = Atom(name: '_DashboardStore.activeSceneName');

  @override
  String get activeSceneName {
    _$activeSceneNameAtom.reportRead();
    return super.activeSceneName;
  }

  @override
  set activeSceneName(String value) {
    _$activeSceneNameAtom.reportWrite(value, super.activeSceneName, () {
      super.activeSceneName = value;
    });
  }

  final _$scenesAtom = Atom(name: '_DashboardStore.scenes');

  @override
  ObservableList<Scene> get scenes {
    _$scenesAtom.reportRead();
    return super.scenes;
  }

  @override
  set scenes(ObservableList<Scene> value) {
    _$scenesAtom.reportWrite(value, super.scenes, () {
      super.scenes = value;
    });
  }

  final _$currentSceneItemsAtom =
      Atom(name: '_DashboardStore.currentSceneItems');

  @override
  ObservableList<SceneItem> get currentSceneItems {
    _$currentSceneItemsAtom.reportRead();
    return super.currentSceneItems;
  }

  @override
  set currentSceneItems(ObservableList<SceneItem> value) {
    _$currentSceneItemsAtom.reportWrite(value, super.currentSceneItems, () {
      super.currentSceneItems = value;
    });
  }

  final _$obsTerminatedAtom = Atom(name: '_DashboardStore.obsTerminated');

  @override
  bool get obsTerminated {
    _$obsTerminatedAtom.reportRead();
    return super.obsTerminated;
  }

  @override
  set obsTerminated(bool value) {
    _$obsTerminatedAtom.reportWrite(value, super.obsTerminated, () {
      super.obsTerminated = value;
    });
  }

  final _$globalAudioSceneItemsAtom =
      Atom(name: '_DashboardStore.globalAudioSceneItems');

  @override
  ObservableList<SceneItem> get globalAudioSceneItems {
    _$globalAudioSceneItemsAtom.reportRead();
    return super.globalAudioSceneItems;
  }

  @override
  set globalAudioSceneItems(ObservableList<SceneItem> value) {
    _$globalAudioSceneItemsAtom.reportWrite(value, super.globalAudioSceneItems,
        () {
      super.globalAudioSceneItems = value;
    });
  }

  final _$sceneTransitionDurationMSAtom =
      Atom(name: '_DashboardStore.sceneTransitionDurationMS');

  @override
  int get sceneTransitionDurationMS {
    _$sceneTransitionDurationMSAtom.reportRead();
    return super.sceneTransitionDurationMS;
  }

  @override
  set sceneTransitionDurationMS(int value) {
    _$sceneTransitionDurationMSAtom
        .reportWrite(value, super.sceneTransitionDurationMS, () {
      super.sceneTransitionDurationMS = value;
    });
  }

  final _$_DashboardStoreActionController =
      ActionController(name: '_DashboardStore');

  @override
  dynamic _handleEvent(BaseEvent event) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
        name: '_DashboardStore._handleEvent');
    try {
      return super._handleEvent(event);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  dynamic _handleResponse(BaseResponse response) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
        name: '_DashboardStore._handleResponse');
    try {
      return super._handleResponse(response);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLive: ${isLive},
goneLiveInMS: ${goneLiveInMS},
streamStats: ${streamStats},
activeSceneName: ${activeSceneName},
scenes: ${scenes},
currentSceneItems: ${currentSceneItems},
obsTerminated: ${obsTerminated},
globalAudioSceneItems: ${globalAudioSceneItems},
sceneTransitionDurationMS: ${sceneTransitionDurationMS},
currentAudioSceneItems: ${currentAudioSceneItems}
    ''';
  }
}
