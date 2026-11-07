import 'dart:async';

import 'package:web_socket_channel/io.dart';

import '../../models/connection.dart';

class Session {
  IOWebSocketChannel socket;
  Stream? socketStream;
  Connection connection;

  /// Reached through the remote relay (Pro) instead of the LAN
  final bool viaRemote;

  Session(this.socket, this.connection, {this.viaRemote = false});
}
