# Event notice meta chip — design

**Date:** 2026-08-09 · **Status:** approved · **Process tier:** S

## Intent

Mimic Twitch notice headers: icon + **name · meta** on one line, body
underneath. Meta comes from typed EventSub blocks (not re-parsed
`system_message`).

## Layout

`🔥 Alice · 450` then body `Is currently on a 5-stream streak!`
(announcement still uses fixed `Announcement` title, no meta).

## Meta by notice (v1)

| Type | Meta |
|---|---|
| watch_streak | `channel_points_awarded` when > 0 |
| raid | `viewer_count` viewers |
| sub_gift / community_sub_gift | tier + count when known |
| bits_badge_tier | tier threshold |
| charity_donation | amount |
| modiversary | months |
| sub / resub | omit (body already carries months) |

Shared-chat variants use the same blocks under `shared_chat_*` keys —
normalize by reading either key.

## Out of scope

User-card full badge inventory; returning-chatter chrome.
