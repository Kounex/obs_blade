import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/connection.dart';

class Session {
  /// A plain obs-websocket channel; through the relay a
  /// [RemoteE2eChannel] (end-to-end encrypted)
  WebSocketChannel socket;
  Stream? socketStream;
  Connection connection;

  /// Reached through the remote relay (Pro) instead of the LAN
  final bool viaRemote;

  Session(this.socket, this.connection, {this.viaRemote = false});
}
