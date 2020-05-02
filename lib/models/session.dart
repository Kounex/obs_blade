import 'dart:async';

import 'package:obs_station/models/connection.dart';
import 'package:web_socket_channel/io.dart';

class Session {
  IOWebSocketChannel socket;
  Stream socketStream;
  Connection connection;

  Session(this.socket, this.connection);
}
