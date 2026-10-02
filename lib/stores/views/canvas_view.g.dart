// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_view.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CanvasViewStore on _CanvasViewStore, Store {
  Computed<bool>? _$hasMultipleCanvasesComputed;

  @override
  bool get hasMultipleCanvases =>
      (_$hasMultipleCanvasesComputed ??= Computed<bool>(
        () => super.hasMultipleCanvases,
        name: '_CanvasViewStore.hasMultipleCanvases',
      )).value;
  Computed<ObsCanvas?>? _$aitumCanvasComputed;

  @override
  ObsCanvas? get aitumCanvas => (_$aitumCanvasComputed ??= Computed<ObsCanvas?>(
    () => super.aitumCanvas,
    name: '_CanvasViewStore.aitumCanvas',
  )).value;
  Computed<ObsCanvas?>? _$viewedCanvasComputed;

  @override
  ObsCanvas? get viewedCanvas =>
      (_$viewedCanvasComputed ??= Computed<ObsCanvas?>(
        () => super.viewedCanvas,
        name: '_CanvasViewStore.viewedCanvas',
      )).value;
  Computed<bool>? _$isViewingOtherCanvasComputed;

  @override
  bool get isViewingOtherCanvas =>
      (_$isViewingOtherCanvasComputed ??= Computed<bool>(
        () => super.isViewingOtherCanvas,
        name: '_CanvasViewStore.isViewingOtherCanvas',
      )).value;
  Computed<bool>? _$aitumOnAirComputed;

  @override
  bool get aitumOnAir => (_$aitumOnAirComputed ??= Computed<bool>(
    () => super.aitumOnAir,
    name: '_CanvasViewStore.aitumOnAir',
  )).value;
  Computed<ObsCanvas?>? _$dualFormatCanvasComputed;

  @override
  ObsCanvas? get dualFormatCanvas =>
      (_$dualFormatCanvasComputed ??= Computed<ObsCanvas?>(
        () => super.dualFormatCanvas,
        name: '_CanvasViewStore.dualFormatCanvas',
      )).value;
  Computed<ExtraCanvasOnAir?>? _$extraCanvasOnAirComputed;

  @override
  ExtraCanvasOnAir? get extraCanvasOnAir =>
      (_$extraCanvasOnAirComputed ??= Computed<ExtraCanvasOnAir?>(
        () => super.extraCanvasOnAir,
        name: '_CanvasViewStore.extraCanvasOnAir',
      )).value;
  Computed<bool>? _$canControlViewedCanvasComputed;

  @override
  bool get canControlViewedCanvas =>
      (_$canControlViewedCanvasComputed ??= Computed<bool>(
        () => super.canControlViewedCanvas,
        name: '_CanvasViewStore.canControlViewedCanvas',
      )).value;
  Computed<String?>? _$liveControlBlockedReasonComputed;

  @override
  String? get liveControlBlockedReason =>
      (_$liveControlBlockedReasonComputed ??= Computed<String?>(
        () => super.liveControlBlockedReason,
        name: '_CanvasViewStore.liveControlBlockedReason',
      )).value;
  Computed<CanvasScene?>? _$selectedSceneComputed;

  @override
  CanvasScene? get selectedScene =>
      (_$selectedSceneComputed ??= Computed<CanvasScene?>(
        () => super.selectedScene,
        name: '_CanvasViewStore.selectedScene',
      )).value;

  late final _$canvasesAtom = Atom(
    name: '_CanvasViewStore.canvases',
    context: context,
  );

  @override
  ObservableList<ObsCanvas> get canvases {
    _$canvasesAtom.reportRead();
    return super.canvases;
  }

  @override
  set canvases(ObservableList<ObsCanvas> value) {
    _$canvasesAtom.reportWrite(value, super.canvases, () {
      super.canvases = value;
    });
  }

  late final _$viewedCanvasUuidAtom = Atom(
    name: '_CanvasViewStore.viewedCanvasUuid',
    context: context,
  );

  @override
  String? get viewedCanvasUuid {
    _$viewedCanvasUuidAtom.reportRead();
    return super.viewedCanvasUuid;
  }

  @override
  set viewedCanvasUuid(String? value) {
    _$viewedCanvasUuidAtom.reportWrite(value, super.viewedCanvasUuid, () {
      super.viewedCanvasUuid = value;
    });
  }

  late final _$scenesAtom = Atom(
    name: '_CanvasViewStore.scenes',
    context: context,
  );

  @override
  ObservableList<CanvasScene> get scenes {
    _$scenesAtom.reportRead();
    return super.scenes;
  }

  @override
  set scenes(ObservableList<CanvasScene> value) {
    _$scenesAtom.reportWrite(value, super.scenes, () {
      super.scenes = value;
    });
  }

  late final _$selectedSceneUuidAtom = Atom(
    name: '_CanvasViewStore.selectedSceneUuid',
    context: context,
  );

  @override
  String? get selectedSceneUuid {
    _$selectedSceneUuidAtom.reportRead();
    return super.selectedSceneUuid;
  }

  @override
  set selectedSceneUuid(String? value) {
    _$selectedSceneUuidAtom.reportWrite(value, super.selectedSceneUuid, () {
      super.selectedSceneUuid = value;
    });
  }

  late final _$sceneItemsAtom = Atom(
    name: '_CanvasViewStore.sceneItems',
    context: context,
  );

  @override
  ObservableList<SceneItem> get sceneItems {
    _$sceneItemsAtom.reportRead();
    return super.sceneItems;
  }

  @override
  set sceneItems(ObservableList<SceneItem> value) {
    _$sceneItemsAtom.reportWrite(value, super.sceneItems, () {
      super.sceneItems = value;
    });
  }

  late final _$expandedGroupsAtom = Atom(
    name: '_CanvasViewStore.expandedGroups',
    context: context,
  );

  @override
  ObservableSet<String> get expandedGroups {
    _$expandedGroupsAtom.reportRead();
    return super.expandedGroups;
  }

  @override
  set expandedGroups(ObservableSet<String> value) {
    _$expandedGroupsAtom.reportWrite(value, super.expandedGroups, () {
      super.expandedGroups = value;
    });
  }

  late final _$previewImageBytesAtom = Atom(
    name: '_CanvasViewStore.previewImageBytes',
    context: context,
  );

  @override
  Uint8List? get previewImageBytes {
    _$previewImageBytesAtom.reportRead();
    return super.previewImageBytes;
  }

  @override
  set previewImageBytes(Uint8List? value) {
    _$previewImageBytesAtom.reportWrite(value, super.previewImageBytes, () {
      super.previewImageBytes = value;
    });
  }

  late final _$loadingScenesAtom = Atom(
    name: '_CanvasViewStore.loadingScenes',
    context: context,
  );

  @override
  bool get loadingScenes {
    _$loadingScenesAtom.reportRead();
    return super.loadingScenes;
  }

  @override
  set loadingScenes(bool value) {
    _$loadingScenesAtom.reportWrite(value, super.loadingScenes, () {
      super.loadingScenes = value;
    });
  }

  late final _$aitumSupportAtom = Atom(
    name: '_CanvasViewStore.aitumSupport',
    context: context,
  );

  @override
  AitumSupport get aitumSupport {
    _$aitumSupportAtom.reportRead();
    return super.aitumSupport;
  }

  @override
  set aitumSupport(AitumSupport value) {
    _$aitumSupportAtom.reportWrite(value, super.aitumSupport, () {
      super.aitumSupport = value;
    });
  }

  late final _$aitumLiveSceneNameAtom = Atom(
    name: '_CanvasViewStore.aitumLiveSceneName',
    context: context,
  );

  @override
  String? get aitumLiveSceneName {
    _$aitumLiveSceneNameAtom.reportRead();
    return super.aitumLiveSceneName;
  }

  @override
  set aitumLiveSceneName(String? value) {
    _$aitumLiveSceneNameAtom.reportWrite(value, super.aitumLiveSceneName, () {
      super.aitumLiveSceneName = value;
    });
  }

  late final _$aitumStatusAtom = Atom(
    name: '_CanvasViewStore.aitumStatus',
    context: context,
  );

  @override
  AitumOutputStatus get aitumStatus {
    _$aitumStatusAtom.reportRead();
    return super.aitumStatus;
  }

  @override
  set aitumStatus(AitumOutputStatus value) {
    _$aitumStatusAtom.reportWrite(value, super.aitumStatus, () {
      super.aitumStatus = value;
    });
  }

  late final _$dualFormatCanvasUuidAtom = Atom(
    name: '_CanvasViewStore.dualFormatCanvasUuid',
    context: context,
  );

  @override
  String? get dualFormatCanvasUuid {
    _$dualFormatCanvasUuidAtom.reportRead();
    return super.dualFormatCanvasUuid;
  }

  @override
  set dualFormatCanvasUuid(String? value) {
    _$dualFormatCanvasUuidAtom.reportWrite(
      value,
      super.dualFormatCanvasUuid,
      () {
        super.dualFormatCanvasUuid = value;
      },
    );
  }

  late final _$_CanvasViewStoreActionController = ActionController(
    name: '_CanvasViewStore',
    context: context,
  );

  @override
  void _applyCanvases(List<ObsCanvas> canvases) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._applyCanvases',
    );
    try {
      return super._applyCanvases(canvases);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _clearCanvases() {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._clearCanvases',
    );
    try {
      return super._clearCanvases();
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void viewCanvas(String? canvasUuid) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore.viewCanvas',
    );
    try {
      return super.viewCanvas(canvasUuid);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectScene(String sceneUuid) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore.selectScene',
    );
    try {
      return super.selectScene(sceneUuid);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _applyScenes(ObsRequestAck? ack) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._applyScenes',
    );
    try {
      return super._applyScenes(ack);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _applyItems(List<SceneItem> items) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._applyItems',
    );
    try {
      return super._applyItems(items);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleGroup(SceneItem group) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore.toggleGroup',
    );
    try {
      return super.toggleGroup(group);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _patchItem(
    int sceneItemId, {
    String? group,
    bool? enabled,
    bool? locked,
  }) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._patchItem',
    );
    try {
      return super._patchItem(
        sceneItemId,
        group: group,
        enabled: enabled,
        locked: locked,
      );
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setDualFormat(String? canvasUuid) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._setDualFormat',
    );
    try {
      return super._setDualFormat(canvasUuid);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setAitumSupport(AitumSupport support) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._setAitumSupport',
    );
    try {
      return super._setAitumSupport(support);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _resetAitum() {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._resetAitum',
    );
    try {
      return super._resetAitum();
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _applyAitumState({String? scene, Map<String, dynamic>? status}) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._applyAitumState',
    );
    try {
      return super._applyAitumState(scene: scene, status: status);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _applyAitumEvent(String eventType, Map<String, dynamic> data) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._applyAitumEvent',
    );
    try {
      return super._applyAitumEvent(eventType, data);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setRecordingPaused(bool paused) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._setRecordingPaused',
    );
    try {
      return super._setRecordingPaused(paused);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setPreview(Uint8List bytes) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._setPreview',
    );
    try {
      return super._setPreview(bytes);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
canvases: ${canvases},
viewedCanvasUuid: ${viewedCanvasUuid},
scenes: ${scenes},
selectedSceneUuid: ${selectedSceneUuid},
sceneItems: ${sceneItems},
expandedGroups: ${expandedGroups},
previewImageBytes: ${previewImageBytes},
loadingScenes: ${loadingScenes},
aitumSupport: ${aitumSupport},
aitumLiveSceneName: ${aitumLiveSceneName},
aitumStatus: ${aitumStatus},
dualFormatCanvasUuid: ${dualFormatCanvasUuid},
hasMultipleCanvases: ${hasMultipleCanvases},
aitumCanvas: ${aitumCanvas},
viewedCanvas: ${viewedCanvas},
isViewingOtherCanvas: ${isViewingOtherCanvas},
aitumOnAir: ${aitumOnAir},
dualFormatCanvas: ${dualFormatCanvas},
extraCanvasOnAir: ${extraCanvasOnAir},
canControlViewedCanvas: ${canControlViewedCanvas},
liveControlBlockedReason: ${liveControlBlockedReason},
selectedScene: ${selectedScene}
    ''';
  }
}
