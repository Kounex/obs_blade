# IRC first-msg sidecar — plan

**Date:** 2026-08-09 · Spec: `2026-08-09-irc-first-msg-sidecar-design.md`

## Files

| File | Role |
|---|---|
| `lib/utils/twitch/twitch_irc_sidecar.dart` | WS IRC client + tag parse |
| `lib/types/.../channel_chat_message.dart` | `isFirstMessage` (not from JSON) |
| `lib/stores/views/twitch_chat.dart` | Connect/switch/merge |
| `lib/views/.../twitch_chat_message_row.dart` | Chrome on `isFirstMessage` |
| `test/chat/twitch_irc_sidecar_test.dart` | Parser + merge unit tests |

## Tasks

1. Parser tests for PRIVMSG tags (`id`, `first-msg`)
2. Sidecar connect / PING / JOIN / callback
3. Freezed field + codegen
4. Store wiring + channel switch
5. Row chrome
6. Gates: `flutter test test/chat/twitch_irc_sidecar_test.dart` + related
