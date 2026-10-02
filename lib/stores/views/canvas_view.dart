import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import '../../types/classes/api/aitum_vertical.dart';
import '../../types/classes/api/obs_canvas.dart';
import '../../types/classes/api/scene_item.dart';
import '../../types/classes/obs_request_ack.dart';
import '../../types/classes/session.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/enums/event_type.dart';
import '../../types/enums/request_type.dart';
import '../../utils/general_helper.dart';
import '../../utils/network_helper.dart';
import '../shared/network.dart';
import 'dashboard.dart';

part 'canvas_view.g.dart';

/// How often the scenes / items of a viewed non-main canvas are re-read -
/// OBS sends no scene / scene item created/removed events for them
const Duration kCanvasRefreshInterval = Duration(seconds: 10);

/// View-only switch between OBS canvases (obs-websocket 5.7+ / OBS 32.1+).
///
/// The main canvas stays [DashboardStore]'s business - this store only
/// holds what the dashboard shows while a non-main canvas (e.g. Aitum
/// Vertical) is selected: its scenes, the scene picked for viewing, that
/// scene's items and a preview. Nothing here changes what OBS outputs:
/// core OBS has no live scene for non-main canvases, so picking a scene only
/// selects what the app shows.
///
/// With Aitum Vertical installed its obs-websocket vendor adds what core OBS
/// lacks for its canvas: a live scene (tap = switch it, the shown scene
/// follows it) and the canvas' own stream / record / backtrack outputs.
/// Detected per connection ([aitumSupport]) - without it the canvas stays
/// view-only and the UI explains what the plugin would add.
///
/// Every read goes through [NetworkHelper.makeScopedRequest] so
/// [DashboardStore] never applies these responses to the program state, and
/// everything is keyed by UUID - scene names can repeat across canvases.
class CanvasViewStore = _CanvasViewStore with _$CanvasViewStore;

abstract class _CanvasViewStore with Store {
  /// Canvases OBS reports - empty when unsupported (OBS < 32.1)
  @observable
  ObservableList<ObsCanvas> canvases = ObservableList();

  /// The non-main canvas being viewed - null = main canvas (regular
  /// dashboard)
  @observable
  String? viewedCanvasUuid;

  @observable
  ObservableList<CanvasScene> scenes = ObservableList();

  /// Scene picked for viewing (not a live switch)
  @observable
  String? selectedSceneUuid;

  /// Items of [selectedSceneUuid], top of the OBS list first - a group's
  /// children follow it directly (with [SceneItem.parentGroupName] set)
  @observable
  ObservableList<SceneItem> sceneItems = ObservableList();

  /// Groups (by source name) whose children are shown - kept across
  /// re-reads and scene switches, group names are unique in OBS
  @observable
  ObservableSet<String> expandedGroups = ObservableSet();

  /// Latest screenshot of [selectedSceneUuid] while the preview runs
  @observable
  Uint8List? previewImageBytes;

  /// First scene read for the viewed canvas is in flight
  @observable
  bool loadingScenes = false;

  /// Whether Aitum Vertical's vendor answers on this connection
  @observable
  AitumSupport aitumSupport = AitumSupport.unknown;

  /// Live scene of the Aitum Vertical canvas (by name - that's all the
  /// vendor speaks), null until read
  @observable
  String? aitumLiveSceneName;

  /// Stream / record / backtrack state of the Aitum Vertical canvas
  @observable
  AitumOutputStatus aitumStatus = const AitumOutputStatus();

  /// The "only shown in the app" hint for scene taps on a canvas without
  /// live control was shown once already (per dashboard session)
  bool viewOnlyHintShown = false;

  @computed
  bool get hasMultipleCanvases => this.canvases.length > 1;

  /// The Aitum Vertical canvas, null when OBS has none
  @computed
  ObsCanvas? get aitumCanvas {
    for (final canvas in this.canvases) {
      if (isAitumCanvas(canvas)) return canvas;
    }
    return null;
  }

  /// The viewed canvas while it's a non-main one, null otherwise
  @computed
  ObsCanvas? get viewedCanvas {
    for (final canvas in this.canvases) {
      if (canvas.uuid == this.viewedCanvasUuid && !canvas.isMain) {
        return canvas;
      }
    }
    return null;
  }

  @computed
  bool get isViewingOtherCanvas => this.viewedCanvas != null;

  /// Aitum Vertical's own stream or recording runs - the dashboard app bar
  /// then shows it next to the main LIVE / REC pills
  @computed
  bool get aitumOnAir =>
      this.aitumSupport == AitumSupport.available &&
      this.aitumCanvas != null &&
      (this.aitumStatus.streaming || this.aitumStatus.recording);

  /// The viewed canvas is Aitum's and its vendor answers: scene taps switch
  /// its live scene, its outputs can be started / stopped
  @computed
  bool get canControlViewedCanvas =>
      this.aitumSupport == AitumSupport.available &&
      isAitumCanvas(this.viewedCanvas);

  /// Why live control is off for the viewed canvas - null when it works
  /// (or no other canvas is viewed)
  @computed
  String? get liveControlBlockedReason =>
      !this.isViewingOtherCanvas || this.canControlViewedCanvas
      ? null
      : aitumBlockedReason(this.aitumSupport, this.viewedCanvas);

  @computed
  CanvasScene? get selectedScene {
    for (final scene in this.scenes) {
      if (scene.uuid == this.selectedSceneUuid) return scene;
    }
    return null;
  }

  StreamSubscription<dynamic>? _streamSubscription;
  final List<ReactionDisposer> _disposers = [];
  Timer? _refreshTimer;
  Timer? _previewRetry;
  bool _previewInFlight = false;

  /// Bumped whenever the viewed canvas / scene changes - answers to reads
  /// sent before that are dropped
  int _viewGeneration = 0;

  DashboardStore get _dashboardStore => GetIt.instance<DashboardStore>();

  /// Wires the store to the current dashboard session: (re)loads the canvas
  /// list whenever GetVersion reports `GetCanvasList` (initial connect and
  /// every reconnect), and runs this canvas' preview loop instead of the
  /// program one while a non-main canvas is viewed with the preview open.
  ///
  /// The reaction tracks the session identity, not just canvas support:
  /// [DashboardStore.availableRequests] is never cleared, so across a
  /// reconnect the support bool stays true and would never re-fire - the
  /// event subscription would keep listening on the dead socket's stream
  /// and the canvas list would go stale until the view is re-entered.
  void init() {
    _disposers.add(
      reaction<(bool, Session?)>(
        (_) => (
          _dashboardStore.availableRequests.contains(
            RequestType.GetCanvasList.name,
          ),
          GetIt.instance<NetworkStore>().activeSession,
        ),
        (state) {
          if (state.$1 && state.$2 != null) {
            /// New session (reconnect): the old stream ended with the old
            /// socket - re-listen and re-read
            _listen();
            this.loadCanvases();
          } else if (!state.$1) {
            _clearCanvases();
          }
        },
        fireImmediately: true,
      ),
    );
    _disposers.add(
      reaction<(bool, bool)>(
        (_) => (
          this.isViewingOtherCanvas,
          _dashboardStore.shouldRequestPreviewImage,
        ),
        (state) {
          _dashboardStore.setPreviewSuspended(state.$1);
          if (state.$1 && state.$2) {
            _requestPreview();
          }
        },
        fireImmediately: true,
      ),
    );
  }

  void dispose() {
    for (final dispose in _disposers) {
      dispose();
    }
    _disposers.clear();
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _refreshTimer?.cancel();
    _previewRetry?.cancel();
  }

  /// A new socket (reconnect) means a new stream - the old one ended with
  /// the old socket
  void _listen() {
    _streamSubscription?.cancel();
    _streamSubscription = GetIt.instance<NetworkStore>()
        .watchOBSStream()
        .listen((message) {
          if (message is BaseEvent) _handleEvent(message);
        });
  }

  Future<ObsRequestAck?> _request(
    RequestType type, [
    Map<String, dynamic>? fields,
  ]) async {
    final session = GetIt.instance<NetworkStore>().activeSession;
    if (session == null) return null;
    return NetworkHelper.makeScopedRequest(session.socket, type, fields);
  }

  Future<void> loadCanvases() async {
    final ack = await _request(RequestType.GetCanvasList);
    if (ack == null || !ack.success) return;
    _applyCanvases(
      (ack.responseData?['canvases'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ObsCanvas.fromJson)
          .toList(),
    );
    if (this.canvases.any((canvas) => !canvas.isMain)) {
      _checkAitum();
    } else {
      _resetAitum();
    }
  }

  @action
  void _applyCanvases(List<ObsCanvas> canvases) {
    this.canvases = ObservableList.of(canvases);
    if (this.viewedCanvasUuid == null) return;
    if (this.viewedCanvas == null) {
      this.viewCanvas(null);
    } else {
      _loadScenes();
    }
  }

  @action
  void _clearCanvases() {
    this.canvases = ObservableList();
    this.viewCanvas(null);
    _resetAitum();
  }

  /// Show [canvasUuid] in the dashboard - null (or the main canvas) goes
  /// back to the regular program view
  @action
  void viewCanvas(String? canvasUuid) {
    final bool isMain = this.canvases.any(
      (canvas) => canvas.uuid == canvasUuid && canvas.isMain,
    );
    final String? target = isMain ? null : canvasUuid;
    if (target == this.viewedCanvasUuid && target != null) return;

    _viewGeneration++;
    this.viewedCanvasUuid = target;
    this.scenes = ObservableList();
    this.selectedSceneUuid = null;
    this.sceneItems = ObservableList();
    this.previewImageBytes = null;
    _previewInFlight = false;
    _previewRetry?.cancel();
    _refreshTimer?.cancel();

    if (target == null) return;
    this.loadingScenes = true;
    _loadScenes();
    _refreshTimer = Timer.periodic(kCanvasRefreshInterval, (_) {
      _loadScenes();
      if (this.canControlViewedCanvas) _loadAitumState();
    });
    if (this.canControlViewedCanvas) _loadAitumState();
  }

  /// Pick a scene of the viewed canvas to look at (no live switch)
  @action
  void selectScene(String sceneUuid) {
    if (sceneUuid == this.selectedSceneUuid) return;
    _viewGeneration++;
    this.selectedSceneUuid = sceneUuid;
    this.sceneItems = ObservableList();
    this.previewImageBytes = null;
    _loadItems();
    _previewInFlight = false;
    _requestPreview();
  }

  Future<void> _loadScenes() async {
    final canvasUuid = this.viewedCanvasUuid;
    if (canvasUuid == null) return;
    final generation = _viewGeneration;
    final ack = await _request(RequestType.GetSceneList, {
      'canvasUuid': canvasUuid,
    });
    if (generation != _viewGeneration) return;
    _applyScenes(ack);
  }

  @action
  void _applyScenes(ObsRequestAck? ack) {
    this.loadingScenes = false;
    if (ack == null || !ack.success) return;
    final raw = (ack.responseData?['scenes'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .toList();

    /// Same order as the main scene buttons (OBS lists bottom-up)
    raw.sort(
      (a, b) => ((b['sceneIndex'] as num?) ?? 0).compareTo(
        (a['sceneIndex'] as num?) ?? 0,
      ),
    );
    this.scenes = ObservableList.of(raw.map(CanvasScene.fromJson));

    if (this.canControlViewedCanvas && _liveScene != null) {
      _followLiveScene();
      if (_liveScene?.uuid == this.selectedSceneUuid) _loadItems();
    } else if (this.selectedScene == null) {
      if (this.scenes.isNotEmpty) {
        this.selectScene(this.scenes.first.uuid);
      } else {
        this.selectedSceneUuid = null;
        this.sceneItems = ObservableList();
        this.previewImageBytes = null;
      }
    } else {
      /// Periodic refresh - items can change without events
      _loadItems();
    }
  }

  /// The scene's items plus every group's children (groups are sources,
  /// their names are unique across OBS - so the group's own scene is
  /// addressed by name, whatever canvas it sits in)
  Future<void> _loadItems() async {
    final sceneUuid = this.selectedSceneUuid;
    if (sceneUuid == null) return;
    final generation = _viewGeneration;
    final ack = await _request(RequestType.GetSceneItemList, {
      'sceneUuid': sceneUuid,
    });
    if (generation != _viewGeneration || ack == null || !ack.success) return;
    final items = _parseItems(ack.responseData);

    final groups = items
        .where((item) => item.isGroup == true && item.sourceName != null)
        .map((item) => item.sourceName!)
        .toList();
    final childAcks = await Future.wait(
      groups.map(
        (group) =>
            _request(RequestType.GetGroupSceneItemList, {'sceneName': group}),
      ),
    );
    if (generation != _viewGeneration) return;

    final Map<String, List<SceneItem>> children = {
      for (final (index, group) in groups.indexed)
        if (childAcks[index]?.success == true)
          group: _parseItems(
            childAcks[index]!.responseData,
          ).map((child) => child.copyWith(parentGroupName: group)).toList(),
    };
    _applyItems([
      for (final item in items) ...[item, ...?children[item.sourceName]],
    ]);
  }

  /// Top of the OBS list first, like the main scene items
  List<SceneItem> _parseItems(Map<String, dynamic>? data) =>
      (data?['sceneItems'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SceneItem.fromJson)
          .toList()
        ..sort(
          (a, b) => (b.sceneItemIndex ?? 0).compareTo(a.sceneItemIndex ?? 0),
        );

  @action
  void _applyItems(List<SceneItem> items) =>
      this.sceneItems = ObservableList.of(items);

  /// Show / hide a group's children in the list
  @action
  void toggleGroup(SceneItem group) {
    final name = group.sourceName;
    if (name == null) return;
    if (!this.expandedGroups.remove(name)) this.expandedGroups.add(name);
  }

  /// Item ids are only unique within a scene - [group] tells a group's
  /// child apart from a top-level item with the same id
  @action
  void _patchItem(
    int sceneItemId, {
    String? group,
    bool? enabled,
    bool? locked,
  }) {
    this.sceneItems = ObservableList.of(
      this.sceneItems.map(
        (item) =>
            item.sceneItemId == sceneItemId && item.parentGroupName == group
            ? item.copyWith(
                sceneItemEnabled: enabled ?? item.sceneItemEnabled,
                sceneItemLocked: locked ?? item.sceneItemLocked,
              )
            : item,
      ),
    );
  }

  /// Where an item lives for Set* requests: a group child in its group's
  /// scene (by name), anything else in the viewed scene (by UUID)
  Map<String, dynamic> _itemScene(SceneItem item, String sceneUuid) =>
      item.parentGroupName != null
      ? {'sceneName': item.parentGroupName}
      : {'sceneUuid': sceneUuid};

  /// Where a scene-item event lands: `(group: null)` for the viewed scene
  /// itself, `(group: name)` for one of its groups, null for anything else
  ({String? group})? _eventTarget(BaseEvent event) {
    if (!this.isViewingOtherCanvas) return null;
    if (event.json['sceneUuid'] == this.selectedSceneUuid) {
      return (group: null);
    }
    final sceneName = event.json['sceneName'];
    final isOwnGroup = this.sceneItems.any(
      (item) => item.isGroup == true && item.sourceName == sceneName,
    );
    return isOwnGroup ? (group: sceneName as String) : null;
  }

  /// Show / hide an item of the viewed scene - optimistic, re-read on
  /// failure
  Future<void> setItemEnabled(SceneItem item, bool enabled) async {
    final sceneUuid = this.selectedSceneUuid;
    final id = item.sceneItemId;
    if (sceneUuid == null || id == null) return;
    _patchItem(id, group: item.parentGroupName, enabled: enabled);
    final ack = await _request(RequestType.SetSceneItemEnabled, {
      ..._itemScene(item, sceneUuid),
      'sceneItemId': id,
      'sceneItemEnabled': enabled,
    });
    if (ack == null || !ack.success) _loadItems();
  }

  /// Lock / unlock an item of the viewed scene - optimistic, re-read on
  /// failure
  Future<void> setItemLocked(SceneItem item, bool locked) async {
    final sceneUuid = this.selectedSceneUuid;
    final id = item.sceneItemId;
    if (sceneUuid == null || id == null) return;
    _patchItem(id, group: item.parentGroupName, locked: locked);
    final ack = await _request(RequestType.SetSceneItemLocked, {
      ..._itemScene(item, sceneUuid),
      'sceneItemId': id,
      'sceneItemLocked': locked,
    });
    if (ack == null || !ack.success) _loadItems();
  }

  void _handleEvent(BaseEvent event) {
    switch (event.eventType) {
      case EventType.CanvasCreated:
      case EventType.CanvasRemoved:
      case EventType.CanvasNameChanged:
        this.loadCanvases();
        break;
      case EventType.VendorEvent:
        if (event.json['vendorName'] == kAitumVendorName) {
          _handleAitumEvent(
            event.json['eventType'] as String?,
            event.json['eventData'] as Map<String, dynamic>? ?? const {},
          );
        }
        break;

      /// Enable / lock events are not limited to the main canvas (created /
      /// removed ones are) - the viewed scene by UUID, its groups by name
      case EventType.SceneItemEnableStateChanged:
        final target = _eventTarget(event);
        if (target != null) {
          _patchItem(
            (event.json['sceneItemId'] as num).toInt(),
            group: target.group,
            enabled: event.json['sceneItemEnabled'] as bool?,
          );
        }
        break;
      case EventType.SceneItemLockStateChanged:
        final target = _eventTarget(event);
        if (target != null) {
          _patchItem(
            (event.json['sceneItemId'] as num).toInt(),
            group: target.group,
            locked: event.json['sceneItemLocked'] as bool?,
          );
        }
        break;
      default:
        break;
    }
  }

  /// Aitum Vertical vendor request - the plugin's own payload (inside the
  /// `CallVendorRequest` response) on success, null when OBS rejected the
  /// call (e.g. no such vendor) or the plugin didn't answer `success: true`
  /// (every one of its handlers sets it)
  Future<(ObsRequestAck?, Map<String, dynamic>?)> _vendorRequest(
    String requestType, [
    Map<String, dynamic>? data,
  ]) async {
    final ack = await _request(RequestType.CallVendorRequest, {
      'vendorName': kAitumVendorName,
      'requestType': requestType,
      'requestData': data ?? const <String, dynamic>{},
    });
    if (ack == null || !ack.success) return (ack, null);
    final response =
        ack.responseData?['responseData'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return (ack, response['success'] == true ? response : null);
  }

  /// Asks Aitum Vertical's vendor for its version - only a rejection (no
  /// such vendor) or a failed answer counts as missing, a timeout / lost
  /// connection keeps the previous verdict
  Future<void> _checkAitum() async {
    final (ack, data) = await _vendorRequest('version');
    if (ack == null) return;
    if (ack.success || ack.failureKind == ObsRequestFailureKind.rejected) {
      _setAitumSupport(
        data != null ? AitumSupport.available : AitumSupport.missing,
      );
    }
    if (this.aitumSupport == AitumSupport.available) _loadAitumState();
  }

  @action
  void _setAitumSupport(AitumSupport support) {
    this.aitumSupport = support;
    if (support != AitumSupport.available) {
      this.aitumLiveSceneName = null;
      this.aitumStatus = const AitumOutputStatus();
    }
  }

  @action
  void _resetAitum() => _setAitumSupport(AitumSupport.unknown);

  /// Live scene + outputs of the Aitum canvas
  Future<void> _loadAitumState() async {
    final canvas = this.aitumCanvas;
    if (canvas == null || this.aitumSupport != AitumSupport.available) return;
    final target = aitumCanvasTarget(canvas);
    final results = await Future.wait([
      _vendorRequest('current_scene', target),
      _vendorRequest('status', target),
    ]);
    _applyAitumState(
      scene: results[0].$2?['scene'] as String?,
      status: results[1].$2,
    );
  }

  @action
  void _applyAitumState({String? scene, Map<String, dynamic>? status}) {
    if (this.aitumSupport != AitumSupport.available) return;
    if (status != null) {
      this.aitumStatus = AitumOutputStatus.fromJson(
        status,
        recordingPaused: this.aitumStatus.recordingPaused,
      );
    }
    if (scene != null) {
      this.aitumLiveSceneName = scene.isEmpty ? null : scene;
      _followLiveScene();
    }
  }

  CanvasScene? get _liveScene {
    for (final scene in this.scenes) {
      if (scene.name == this.aitumLiveSceneName) return scene;
    }
    return null;
  }

  /// With live control the shown scene is the live one (like the program
  /// scene buttons)
  void _followLiveScene() {
    final live = _liveScene;
    if (this.canControlViewedCanvas && live != null) {
      this.selectScene(live.uuid);
    }
  }

  void _handleAitumEvent(String? eventType, Map<String, dynamic> data) {
    final canvas = this.aitumCanvas;
    if (eventType == null || canvas == null) return;

    /// Aitum tags its events with the canvas resolution
    final width = (data['width'] as num?)?.toInt();
    final height = (data['height'] as num?)?.toInt();
    if ((width != null &&
            canvas.baseWidth != null &&
            width != canvas.baseWidth) ||
        (height != null &&
            canvas.baseHeight != null &&
            height != canvas.baseHeight)) {
      return;
    }
    _applyAitumEvent(eventType, data);
  }

  @action
  void _applyAitumEvent(String eventType, Map<String, dynamic> data) {
    /// An event proves the vendor is there (e.g. it registered after the
    /// first check)
    if (this.aitumSupport != AitumSupport.available) {
      this.aitumSupport = AitumSupport.available;
      _loadAitumState();
    }
    switch (eventType) {
      case 'switch_scene':
        _applyAitumState(scene: data['new_scene'] as String? ?? '');
      case 'streaming_started':
        this.aitumStatus = this.aitumStatus.copyWith(streaming: true);
      case 'streaming_stopped':
        this.aitumStatus = this.aitumStatus.copyWith(streaming: false);
      case 'recording_started':
        this.aitumStatus = this.aitumStatus.copyWith(
          recording: true,
          recordingPaused: false,
        );
      case 'recording_stopped':
        this.aitumStatus = this.aitumStatus.copyWith(
          recording: false,
          recordingPaused: false,
        );
      case 'virtual_camera_started':
        this.aitumStatus = this.aitumStatus.copyWith(virtualCamera: true);
      case 'virtual_camera_stopped':
        this.aitumStatus = this.aitumStatus.copyWith(virtualCamera: false);
      case 'backtrack_started':
        this.aitumStatus = this.aitumStatus.copyWith(backtrack: true);
      case 'backtrack_stopped':
        this.aitumStatus = this.aitumStatus.copyWith(backtrack: false);
    }
  }

  /// Switch the Aitum canvas' live scene - optimistic (the shown scene
  /// follows), re-read on failure
  Future<void> switchLiveScene(CanvasScene scene) async {
    if (!this.canControlViewedCanvas) return;
    _applyAitumState(scene: scene.name);
    final (ack, data) = await _vendorRequest('switch_scene', {
      'scene': scene.name,
      ...aitumCanvasTarget(this.viewedCanvas),
    });
    if (data == null) {
      _reportFailure(ack, 'Scene switch');
      _loadAitumState();
    }
  }

  /// Explicit start / stop instead of Aitum's toggles - see
  /// [RecordStreamService]: a confirmed direction must never flip into the
  /// opposite when the state changed on the PC meanwhile
  Future<void> setAitumStreaming(bool start) => _aitumOutput(
    start ? 'start_streaming' : 'stop_streaming',
    start ? 'Start vertical stream' : 'Stop vertical stream',
  );

  Future<void> setAitumRecording(bool start) => _aitumOutput(
    start ? 'start_recording' : 'stop_recording',
    start ? 'Start vertical recording' : 'Stop vertical recording',
  );

  Future<void> setAitumBacktrack(bool start) => _aitumOutput(
    start ? 'start_backtrack' : 'stop_backtrack',
    start ? 'Start backtrack' : 'Stop backtrack',
  );

  Future<bool> saveAitumBacktrack() =>
      _aitumOutput('save_backtrack', 'Save backtrack');

  Future<void> setAitumVirtualCamera(bool start) => _aitumOutput(
    start ? 'start_virtual_camera' : 'stop_virtual_camera',
    start ? 'Start vertical virtual camera' : 'Stop vertical virtual camera',
  );

  /// Chapter marker in the running vertical recording - OBS only writes
  /// them into Hybrid MP4 recordings, the plugin answers `success: false`
  /// otherwise
  Future<bool> addAitumChapter() =>
      _aitumOutput('add_chapter', 'Chapter marker (Hybrid MP4 only)');

  /// Pause / resume the vertical recording. Aitum neither reports nor
  /// announces a pause, so the answers are the source of truth: it refuses
  /// a pause of a paused recording (and a resume of a running one) - with
  /// the recording running, that refusal tells the real state, which is
  /// applied silently instead of a failure toast (e.g. paused from the
  /// plugin's dock in OBS)
  Future<void> setAitumRecordingPaused(bool pause) async {
    if (!this.canControlViewedCanvas) return;
    final (ack, data) = await _vendorRequest(
      pause ? 'pause_recording' : 'unpause_recording',
      aitumCanvasTarget(this.viewedCanvas),
    );

    /// Applied, or refused because it already is that way - either way the
    /// recording now is what was asked for
    if (data != null ||
        (ack != null && ack.success && this.aitumStatus.recording)) {
      _setRecordingPaused(pause);
    } else {
      _reportFailure(
        ack,
        pause ? 'Pause vertical recording' : 'Resume vertical recording',
      );
      _loadAitumState();
    }
  }

  @action
  void _setRecordingPaused(bool paused) => this.aitumStatus = this.aitumStatus
      .copyWith(recordingPaused: this.aitumStatus.recording && paused);

  /// The output state itself arrives through Aitum's events once the
  /// output really started / stopped - true when the plugin applied it
  Future<bool> _aitumOutput(String requestType, String label) async {
    if (!this.canControlViewedCanvas) return false;
    final (ack, data) = await _vendorRequest(
      requestType,
      aitumCanvasTarget(this.viewedCanvas),
    );
    if (data == null) {
      _reportFailure(ack, label);
      _loadAitumState();
    }
    return data != null;
  }

  /// Same toast as failed program commands - an answer with
  /// `success: false` from the plugin counts as a rejection
  void _reportFailure(ObsRequestAck? ack, String label) {
    if (ack == null) return;
    _dashboardStore.reportCommandFailure(
      ack.success
          ? const ObsRequestAck.rejected(
              RequestType.CallVendorRequest,
              0,
              'Aitum Vertical did not apply the command',
            )
          : ack,
      label: label,
    );
  }

  bool get _previewActive =>
      this.isViewingOtherCanvas && _dashboardStore.shouldRequestPreviewImage;

  /// Response-driven like the program preview: one screenshot in flight,
  /// the next one is requested when it answers
  Future<void> _requestPreview() async {
    final sceneUuid = this.selectedSceneUuid;
    if (_previewInFlight || !_previewActive || sceneUuid == null) return;
    _previewInFlight = true;
    final generation = _viewGeneration;
    final ack = await _request(RequestType.GetSourceScreenshot, {
      'sourceUuid': sceneUuid,
      'imageFormat': _dashboardStore.previewFileFormat,
      'imageWidth': _previewImageWidth,
      'imageCompressionQuality': -1,
    });
    if (generation != _viewGeneration) return;
    _previewInFlight = false;
    if (ack == null) return;

    final imageData = ack.responseData?['imageData'] as String?;
    if (ack.success && imageData != null && imageData.contains(',')) {
      try {
        _setPreview(base64Decode(imageData.split(',')[1]));
      } catch (e) {
        GeneralHelper.advLog('Canvas preview decode failed: $e');
      }
      _requestPreview();
    } else {
      _previewRetry?.cancel();
      _previewRetry = Timer(const Duration(seconds: 1), _requestPreview);
    }
  }

  @action
  void _setPreview(Uint8List bytes) => this.previewImageBytes = bytes;

  /// Screen-sized frames, narrower for portrait canvases (they render in a
  /// narrower frame) and never above the canvas' own width
  int get _previewImageWidth {
    final view = PlatformDispatcher.instance.implicitView;
    double width = view != null
        ? view.physicalSize.shortestSide.clamp(320, 1920).toDouble()
        : 1280;
    final aspect = this.viewedCanvas?.aspectRatio;
    if (aspect != null && aspect < 1) width *= aspect;
    final baseWidth = this.viewedCanvas?.baseWidth;
    if (baseWidth != null && baseWidth < width) width = baseWidth.toDouble();
    return width.round().clamp(160, 1920);
  }
}

/// The canvas switch for widgets that also render outside a dashboard
/// session (widget tests, customisation mocks) - null when not registered
CanvasViewStore? canvasViewStoreOrNull() =>
    GetIt.instance.isRegistered<CanvasViewStore>()
    ? GetIt.instance<CanvasViewStore>()
    : null;
