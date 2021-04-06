import 'dart:async';

import 'package:web_socket_channel/io.dart';

import '../../models/connection.dart';

class Session {
  IOWebSocketChannel socket;
  Stream? socketStream;
  Connection connection;

  Session(this.socket, this.connection);
}
