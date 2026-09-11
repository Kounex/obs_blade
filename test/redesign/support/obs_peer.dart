import 'dart:convert';
import 'dart:io';

import 'package:obs_blade/models/connection.dart';

/// Real loopback WebSocket transport and production handshake; synthetic OBS.
/// No installed OBS process, production account or Hive box is touched.
class ObsPeer {
  ObsPeer(this.server, {this.identify = true, this.rejectAuth = false}) {
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      socket.add(
        jsonEncode({
          'op': 0,
          'd': {'rpcVersion': 1},
        }),
      );
      socket.listen((raw) {
        final packet = jsonDecode(raw as String) as Map<String, dynamic>;
        if (packet['op'] == 1) {
          if (rejectAuth) {
            socket.close(4009, 'Synthetic auth rejection');
          } else if (identify) {
            socket.add(
              jsonEncode({
                'op': 2,
                'd': {'negotiatedRpcVersion': 1},
              }),
            );
          }
        } else if (packet['op'] == 6) {
          final data = packet['d'] as Map<String, dynamic>;
          requests.add(data);
          final type = data['requestType'];
          final fields = data['requestData'] as Map<String, dynamic>;
          if (type == 'SetCurrentPreviewScene') {
            preview = fields['sceneName'] as String;
            event(socket, 'CurrentPreviewSceneChanged', {'sceneName': preview});
          } else if (type == 'TriggerStudioModeTransition') {
            final previous = program;
            program = preview;
            preview = previous;
            event(socket, 'CurrentProgramSceneChanged', {'sceneName': program});
            event(socket, 'CurrentPreviewSceneChanged', {'sceneName': preview});
          }
          socket.add(
            jsonEncode({
              'op': 7,
              'd': {
                'requestType': type,
                'requestId': data['requestId'],
                'requestStatus': {'result': true, 'code': 100},
                'responseData': switch (type) {
                  'GetSceneList' => {
                    'scenes': [
                      {'sceneName': 'Camera', 'sceneIndex': 2},
                      {'sceneName': 'Break', 'sceneIndex': 1},
                      {'sceneName': 'Desktop', 'sceneIndex': 0},
                    ],
                    'currentProgramSceneName': program,
                    'currentPreviewSceneName': preview,
                  },
                  'GetStudioModeEnabled' => {'studioModeEnabled': true},
                  _ => <String, dynamic>{},
                },
              },
            }),
          );
        }
      });
    });
  }

  final HttpServer server;
  final bool identify;
  final bool rejectAuth;
  final sockets = <WebSocket>[];
  final requests = <Map<String, dynamic>>[];
  String program = 'Camera';
  String preview = 'Break';

  Connection get connection => Connection('localhost', server.port);
  static Future<ObsPeer> start({
    bool identify = true,
    bool rejectAuth = false,
  }) async => ObsPeer(
    await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    identify: identify,
    rejectAuth: rejectAuth,
  );

  void event(WebSocket socket, String type, Map<String, dynamic> data) {
    socket.add(
      jsonEncode({
        'op': 5,
        'd': {'eventType': type, 'eventIntent': 4, 'eventData': data},
      }),
    );
  }

  Future<void> close() async {
    for (final socket in sockets) {
      await socket.close();
    }
    await server.close(force: true);
  }
}
