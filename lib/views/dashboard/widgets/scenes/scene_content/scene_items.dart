import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../utils/network_helper.dart';
import 'nested_list_manager.dart';

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
              ...dashboardStore.currentSceneItems != null &&
                      dashboardStore.currentSceneItems.length > 0
                  ? dashboardStore.currentSceneItems.map(
                      (sceneItem) => ListTile(
                        dense: true,
                        leading: Icon(Icons.filter),
                        title: Text(
                          sceneItem.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            sceneItem.render
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: sceneItem.render ? Colors.white : Colors.red,
                          ),
                          onPressed: () => NetworkHelper.makeRequest(
                              context
                                  .read<NetworkStore>()
                                  .activeSession
                                  .socket
                                  .sink,
                              RequestType.SetSceneItemProperties,
                              {
                                'item': sceneItem.name,
                                'visible': !sceneItem.render
                              }),
                        ),
                      ),
                    )
                  : [
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Center(
                          child: Text('No Scene Items available'),
                        ),
                      )
                    ]
            ],
          ),
        ),
      );
    });
  }
}
