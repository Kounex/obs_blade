import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:obs_station/stores/shared/network.dart';
import 'package:obs_station/types/classes/base_event.dart';
import 'package:obs_station/types/classes/responses/base.dart';
import 'package:obs_station/types/classes/responses/get_scene_list.dart';
import 'package:obs_station/types/classes/scene.dart';
import 'package:obs_station/types/enums/event_type.dart';
import 'package:obs_station/types/enums/request_type.dart';
import 'package:obs_station/types/mixins/short_provider.dart';

// Include generated file
part 'dashboard.g.dart';

class DashboardStore = _DashboardStore with _$DashboardStore, ShortProvider;

abstract class _DashboardStore with Store {
  @observable
  bool isLive = false;

  @observable
  String activeSceneName;
  @observable
  ObservableList<Scene> scenes;

  NetworkStore networkStore;

  @action
  updateActiveScene(String name) => this.activeSceneName = name;

  @action
  setScenes(Iterable<Scene> scenes) => this.scenes = scenes;

  setNetworkStore(NetworkStore networkStore) {
    this.networkStore = networkStore;
    this.handleStream();
  }

  handleStream() {
    this.networkStore.activeSession.socketStream.listen((event) {
      Map<String, dynamic> fullJSON = json.decode(event);
      if (fullJSON['update-type'] != null) {
        this.handleEvent(BaseEvent(fullJSON));
      } else {
        this.handleResponse(BaseResponse(fullJSON));
      }
    });
  }

  @action
  handleEvent(BaseEvent event) {
    switch (event.updateType) {
      case EventType.ScenesChanged:
        this.networkStore.makeRequest(RequestType.GetSceneList);
        break;
      default:
        break;
    }
    print(event.json['update-type']);
  }

  @action
  handleResponse(BaseResponse response) {
    switch (RequestType.values[response.messageID]) {
      case RequestType.GetSceneList:
        GetSceneListResponse getSceneListResponse =
            GetSceneListResponse(response.json);
        this.scenes = ObservableList.of(getSceneListResponse.scenes);
        break;
      default:
        break;
    }
  }
}
