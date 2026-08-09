# IRC first-msg sidecar — design

**Date:** 2026-08-09 · **Status:** approved · **Process tier:** M

## Intent

Native Twitch chat styles “FIRST MESSAGE” chrome the way 7TV / Twitch’s
internal `isFirstMsg` does. EventSub does not expose IRC `first-msg`;
`message_type: user_intro` is a different, rarer signal. Add a read-only
IRC sidecar that only supplies that tag.

## Decisions

| Topic | Choice |
|---|---|
| Source of truth for message bodies | EventSub (unchanged) |
| First-message signal | IRC PRIVMSG `first-msg=1` matched by `id` ↔ EventSub `message_id` |
| Also treat as first | `message_type == user_intro` |
| Returning chatter | Out of scope v1 |
| Auth | Same OAuth token + login (`PASS oauth:…` / `NICK`) |
| Scope | Selected channel only; reconnect on channel switch |
| Failure mode | Best-effort — IRC down never fails EventSub chat |

## Merge

- IRC arrives first → stash `messageId` in a short pending set; apply when
  EventSub appends.
- EventSub arrives first → look up pending (or `user_intro`) and set
  `ChatMessageEvent.isFirstMessage`.
- Late IRC after row exists → `copyWith(isFirstMessage: true)` in place.

## UI

Existing magenta chrome + `FIRST MESSAGE` label when
`isFirstMessage && isChatFirstMessageVisible(settings)`.
