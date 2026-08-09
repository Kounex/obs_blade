import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_notification_row.dart';

void main() {
  test('strips leading chatter name and capitalizes the body', () {
    expect(
      chatNoticeBodyText(
        systemMessage: 'viewer32 subscribed for 3 months!',
        chatterUserName: 'viewer32',
      ),
      'Subscribed for 3 months!',
    );
  });

  test('capitalizes when the name is not a prefix', () {
    expect(
      chatNoticeBodyText(
        systemMessage: 'a raid of 12 from OtherChan',
        chatterUserName: 'viewer32',
      ),
      'A raid of 12 from OtherChan',
    );
  });

  test('empty remainder after the name stays empty', () {
    expect(
      chatNoticeBodyText(
        systemMessage: 'viewer32',
        chatterUserName: 'viewer32',
      ),
      '',
    );
  });

  test('announcement notices use a fixed banner label', () {
    expect(chatNoticeBannerLabel('announcement'), 'Announcement');
    expect(chatNoticeBannerLabel('shared_chat_announcement'), 'Announcement');
    expect(chatNoticeBannerLabel('sub'), isNull);
  });
}
