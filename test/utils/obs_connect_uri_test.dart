import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/obs_connect_uri.dart';

void main() {
  group('connectionFromObsConnectUri', () {
    test('host, port and password', () {
      final c = connectionFromObsConnectUri(
        'obsws://192.168.1.20:4455/abc123',
      )!;
      expect(c.host, '192.168.1.20');
      expect(c.port, 4455);
      expect(c.pw, 'abc123');
      expect(c.isDomain, isFalse);
    });

    test('no password', () {
      final c = connectionFromObsConnectUri('obsws://192.168.1.20:4455')!;
      expect(c.pw, isNull);
    });

    test('percent-encoded password (OBS encodes it) is decoded', () {
      /// QUrl::toPercentEncoding('p@ss w#rd/!%') as OBS puts it in the QR
      final c = connectionFromObsConnectUri(
        'obsws://192.168.1.20:4455/p%40ss%20w%23rd%2F%21%25',
      )!;
      expect(c.pw, 'p@ss w#rd/!%');
    });

    test('missing port falls back to 4455', () {
      expect(connectionFromObsConnectUri('obsws://10.0.0.5/x')!.port, 4455);
    });

    test('obswss becomes a domain-mode wss connection', () {
      final c = connectionFromObsConnectUri('obswss://obs.example.com:443/x')!;
      expect(c.host, 'wss://obs.example.com');
      expect(c.isDomain, isTrue);
    });

    test('no host is rejected', () {
      expect(connectionFromObsConnectUri('obsws://'), isNull);
    });
  });

  test('isObsConnectUri', () {
    expect(isObsConnectUri('OBSWS://1.2.3.4:4455'), isTrue);
    expect(isObsConnectUri('https://example.com'), isFalse);
    expect(isObsConnectUri(null), isFalse);
  });
}
