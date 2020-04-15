class Connection {
  String ip;
  int port;
  String pw;
  String challenge;
  String salt;

  Connection(this.ip, this.port, [this.pw]);
}
