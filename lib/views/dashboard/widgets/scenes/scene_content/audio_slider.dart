import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../stores/shared/network.dart';
import '../../../../../types/classes/api/scene_item.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../utils/network_helper.dart';

class AudioSlider extends StatelessWidget {
  final SceneItem audioSceneItem;

  AudioSlider({@required this.audioSceneItem});

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = Provider.of<NetworkStore>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          this.audioSceneItem.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                this.audioSceneItem.muted ? Icons.volume_off : Icons.volume_up,
                color: this.audioSceneItem.muted ? Colors.red : null,
              ),
              padding: EdgeInsets.all(0.0),
              onPressed: () => NetworkHelper.makeRequest(
                  networkStore.activeSession.socket.sink, RequestType.SetMute, {
                'source': this.audioSceneItem.name,
                'mute': !this.audioSceneItem.muted
              }),
            ),
            Expanded(
              child: Slider(
                min: 0.0,
                max: 1.0,
                value: this.audioSceneItem.volume,
                onChanged: (volume) => NetworkHelper.makeRequest(
                    networkStore.activeSession.socket.sink,
                    RequestType.SetVolume,
                    {'source': this.audioSceneItem.name, 'volume': volume}),
              ),
            ),
            Container(
              width: 48.0,
              padding: EdgeInsets.only(right: 12.0),
              alignment: Alignment.center,
              child: Text((((this.audioSceneItem.volume * 100).toInt()) / 100)
                  .toString()
                  .padRight(4, '0')),
            ),
          ],
        ),
        // Stack(
        //   children: [
        //     Transform(
        //       transform: Matrix4.identity()..translate(-12.0),
        //       child: IconButton(
        //         icon: Icon(
        //           this.audioSceneItem.muted
        //               ? Icons.volume_off
        //               : Icons.volume_up,
        //           color: this.audioSceneItem.muted ? Colors.red : null,
        //         ),
        //         padding: EdgeInsets.all(0.0),
        //         onPressed: () => NetworkHelper.makeRequest(
        //             networkStore.activeSession.socket.sink,
        //             RequestType.SetMute, {
        //           'source': this.audioSceneItem.name,
        //           'mute': !this.audioSceneItem.muted
        //         }),
        //       ),
        //     ),
        //     Padding(
        //       padding: EdgeInsets.only(left: 20.0),
        //       child: Slider(
        //         min: 0.0,
        //         max: 1.0,
        //         value: this.audioSceneItem.volume,
        //         onChanged: (volume) => NetworkHelper.makeRequest(
        //             networkStore.activeSession.socket.sink,
        //             RequestType.SetVolume,
        //             {'source': this.audioSceneItem.name, 'volume': volume}),
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }
}
