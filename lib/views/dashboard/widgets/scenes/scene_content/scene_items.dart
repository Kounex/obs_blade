import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/scene_content/nested_list_manager.dart';
import 'package:provider/provider.dart';

import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../utils/network_helper.dart';

class SceneItems extends StatefulWidget {
  @override
  _SceneItemsState createState() => _SceneItemsState();
}

class _SceneItemsState extends State<SceneItems> {
  ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Observer(builder: (_) {
      dashboardStore.currentSceneItems
          ?.forEach((element) => print(element.type));
      return NestedScrollManager(
        child: Scrollbar(
          controller: _controller,
          isAlwaysShown: true,
          child: ListView(
            controller: _controller,
            physics: ClampingScrollPhysics(),
            padding: EdgeInsets.all(0.0),
            itemExtent: 50.0,
            children: [
              ...dashboardStore.currentSceneItems != null
                  ? dashboardStore.currentSceneItems.map(
                      (sceneItem) => ListTile(
                        leading: Icon(Icons.filter),
                        title: Text(
                          sceneItem.name,
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            sceneItem.render
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: sceneItem.render ? Colors.white : Colors.red,
                          ),
                          onPressed: () => NetworkHelper.makeRequest(
                              dashboardStore.activeSession.socket.sink,
                              RequestType.SetSceneItemProperties, {
                            'item': sceneItem.name,
                            'visible': !sceneItem.render
                          }),
                        ),
                      ),
                    )
                  : [Text('No Scene Items available')]
            ],
          ),
        ),
      );
    });
  }
}
