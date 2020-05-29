import 'dart:convert';

import 'package:mobx/mobx.dart';

import '../../types/classes/api/scene.dart';
import '../../types/classes/api/stream_stats.dart';
import '../../types/classes/session.dart';
import '../../types/classes/stream/base_event.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../types/classes/stream/responses/get_scene_list.dart';
import '../../types/enums/event_type.dart';
import '../../types/enums/request_type.dart';
import '../../types/mixins/short_provider.dart';
import '../../utils/network_helper.dart';

part 'dashboard.g.dart';

class DashboardStore = _DashboardStore with _$DashboardStore, ShortProvider;

abstract class _DashboardStore with Store {
  @observable
  bool isLive = false;
  @observable
  int goneLiveInMS;
  @observable
  StreamStats streamStats;

  @observable
  String activeSceneName;
  @observable
  ObservableList<Scene> scenes;

  Session activeSession;

  @action
  updateActiveScene(String name) => this.activeSceneName = name;

  @action
  setScenes(Iterable<Scene> scenes) => this.scenes = scenes;

  setNetworkStore(Session activeSession) {
    this.activeSession = activeSession;
    this.handleStream();
  }

  handleStream() {
    this.activeSession.socketStream.listen((event) {
      Map<String, dynamic> fullJSON = json.decode(event);
      if (fullJSON['update-type'] != null) {
        _handleEvent(BaseEvent(fullJSON));
      } else {
        _handleResponse(BaseResponse(fullJSON));
      }
    });
  }

  @action
  _handleEvent(BaseEvent event) {
    switch (event.updateType) {
      case EventType.StreamStarted:
        this.isLive = true;
        this.goneLiveInMS = DateTime.now().millisecondsSinceEpoch;
        break;
      case EventType.StreamStopping:
        this.isLive = false;
        break;
      case EventType.StreamStatus:
        this.streamStats = StreamStats.fromJSON(event.json);
        if (this.goneLiveInMS == null) {
          this.isLive = true;
          this.goneLiveInMS = DateTime.now().millisecondsSinceEpoch -
              (this.streamStats.totalStreamTime * 1000);
        }
        break;
      case EventType.ScenesChanged:
        NetworkHelper.makeRequest(
            this.activeSession.socket.sink, RequestType.GetSceneList);
        break;
      case EventType.SwitchScenes:
        this.activeSceneName = event.json['scene-name'];
        break;
      default:
        break;
    }
  }

  @action
  _handleResponse(BaseResponse response) {
    switch (RequestType.values[response.messageID]) {
      case RequestType.GetSceneList:
        GetSceneListResponse getSceneListResponse =
            GetSceneListResponse(response.json);
        this.activeSceneName = getSceneListResponse.currentScene;
        this.scenes = ObservableList.of(getSceneListResponse.scenes);
        break;
      default:
        break;
    }
  }
}
