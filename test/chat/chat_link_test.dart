import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_link.dart';

void main() {
  test('kChatUrlPattern finds http(s) URLs in a message', () {
    const text = 'see https://example.com/path and http://foo.bar/x.';
    final matches =
        kChatUrlPattern.allMatches(text).map((m) => m.group(0)).toList();
    expect(matches, [
      'https://example.com/path',
      'http://foo.bar/x.',
    ]);
  });

  test('kChatUrlPattern ignores bare hostnames', () {
    expect(kChatUrlPattern.hasMatch('go to example.com please'), isFalse);
  });
}
