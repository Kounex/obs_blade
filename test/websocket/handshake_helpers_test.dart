import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/types/classes/connection_attempt_result.dart';
import 'package:obs_blade/types/enums/web_socket_codes/event_subscription.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/authentication_helper.dart';
import 'package:obs_blade/utils/network_helper.dart';

void main() {
  group('AuthenticationHelper.createAuthenticationString', () {
    test('matches SHA256+Base64 protocol algorithm (known vector)', () {
      // Same steps as protocol.md; result verified against independent Python.
      const password = 'supersecretpassword';
      const salt = 'lM1GncleQOaCu9lT1yeUZhFYnqhsLLP1G5lAGo3ixaI=';
      const challenge = '+IxH4CnCiqpX1rM9scsNynZzbOe4KhDeYcTNS3PDaeY=';

      final auth = AuthenticationHelper.createAuthenticationString(
        password,
        salt,
        challenge,
      );

      expect(auth, '1Ct943GAT+6YQUUX47Ia/ncufilbe6+oD6lY+5kaCu4=');
    });
  });

  group('EventSubscription', () {
    test('appDefault includes All categories and InputVolumeMeters', () {
      expect(EventSubscription.appDefault & EventSubscription.canvases,
          EventSubscription.canvases);
      expect(EventSubscription.appDefault & EventSubscription.inputVolumeMeters,
          EventSubscription.inputVolumeMeters);
      expect(EventSubscription.all, 0xfff);
    });
  });

  group('NetworkHelper.websocketUri', () {
    test('LAN IP uses ws and default port 4455', () {
      final uri = NetworkHelper.websocketUri(Connection('192.168.1.50', null));
      expect(uri.scheme, 'ws');
      expect(uri.host, '192.168.1.50');
      expect(uri.port, 4455);
    });

    test('LAN IP respects explicit port', () {
      final uri = NetworkHelper.websocketUri(Connection('10.0.0.2', 4456));
      expect(uri.toString(), 'ws://10.0.0.2:4456');
    });

    test('domain host with baked-in wss scheme keeps scheme and applies port',
        () {
      final uri = NetworkHelper.websocketUri(
        Connection('wss://stream.example.com', 443, null, true),
      );
      expect(uri.scheme, 'wss');
      expect(uri.host, 'stream.example.com');
      expect(uri.port, 443);
    });

    test('domain host with baked-in ws scheme', () {
      final uri = NetworkHelper.websocketUri(
        Connection('ws://obs.local', 4455, null, true),
      );
      expect(uri.scheme, 'ws');
      expect(uri.host, 'obs.local');
      expect(uri.port, 4455);
    });
  });

  group('ConnectionAttemptResult.userMessage', () {
    test('auth failure', () {
      const result = ConnectionAttemptResult(
        closeCode: WebSocketCloseCode.AuthenticationFailed,
        stage: ConnectionStage.waitingIdentified,
      );
      expect(result.userMessage, 'Wrong password');
      expect(result.isAuthenticationFailure, isTrue);
    });

    test('timeout while connecting', () {
      const result = ConnectionAttemptResult(
        closeCode: WebSocketCloseCode.HandshakeTimeout,
        stage: ConnectionStage.connecting,
      );
      expect(result.userMessage, contains('firewall'));
    });

    test('timeout waiting Hello', () {
      const result = ConnectionAttemptResult(
        closeCode: WebSocketCloseCode.HandshakeTimeout,
        stage: ConnectionStage.waitingHello,
      );
      expect(result.userMessage, contains('WebSocket enabled'));
      expect(result.userMessage, contains('did not greet'));
    });

    test('timeout waiting Identify', () {
      const result = ConnectionAttemptResult(
        closeCode: WebSocketCloseCode.HandshakeTimeout,
        stage: ConnectionStage.waitingIdentified,
      );
      expect(result.userMessage, contains('Identify'));
    });
  });

  group('WebSocketCloseCode.fromIdentifier', () {
    test('maps known OBS codes', () {
      expect(WebSocketCloseCode.fromIdentifier(4009),
          WebSocketCloseCode.AuthenticationFailed);
      expect(WebSocketCloseCode.fromIdentifier(4010),
          WebSocketCloseCode.UnsupportedRpcVersion);
    });

    test('unknown falls back', () {
      expect(WebSocketCloseCode.fromIdentifier(12345),
          WebSocketCloseCode.UnknownReason);
      expect(WebSocketCloseCode.fromIdentifier(null),
          WebSocketCloseCode.UnknownReason);
    });
  });
}
