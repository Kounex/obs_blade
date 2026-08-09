import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_notice_chrome.dart';
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

  test('chatAnnouncementHighlight maps Helix colors to gradients', () {
    final purple = chatAnnouncementHighlight('purple');
    expect(purple.top, const Color(0xFF9147FF));
    expect(purple.bottom, const Color(0xFFE056FD));

    final blue = chatAnnouncementHighlight('blue');
    expect(blue.solid, const Color(0xFF1F69FF));

    final primary = chatAnnouncementHighlight('primary');
    expect(primary.bottom, const Color(0xFFE056FD));

    // IRC-style casing must not fall through to primary.
    expect(chatAnnouncementHighlight('ORANGE').solid, const Color(0xFFFF7A00));
  });
}

