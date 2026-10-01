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
  void _applyItems(Map<String, dynamic>? data) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._applyItems',
    );
    try {
      return super._applyItems(data);
    } finally {
      _$_CanvasViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _patchItem(int sceneItemId, {bool? enabled, bool? locked}) {
    final _$actionInfo = _$_CanvasViewStoreActionController.startAction(
      name: '_CanvasViewStore._patchItem',
    );
    try {
      return super._patchItem(sceneItemId, enabled: enabled, locked: locked);
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
previewImageBytes: ${previewImageBytes},
loadingScenes: ${loadingScenes},
hasMultipleCanvases: ${hasMultipleCanvases},
viewedCanvas: ${viewedCanvas},
isViewingOtherCanvas: ${isViewingOtherCanvas},
selectedScene: ${selectedScene}
    ''';
  }
}
