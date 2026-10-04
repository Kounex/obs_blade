# YouTube emoji harvest (maintainer tool)

Grows `lib/utils/youtube/youtube_standard_emojis.dart`, the bundled set of
YouTube's own live-chat emojis (`:yt:`, `:face-blue-smiling:`,
`:medal-yellow-first-red:`, ...). The Data API sends only the
`:shortcode:` text; the image URL exists only in YouTube's web chat data,
and there's no public list. The app learns missing ones at runtime from the
chat page (`YouTubeEmojiStore`); this bundle makes the picker useful from
the start.

```bash
python3 tool/youtube_emoji_harvest/harvest.py --chats=15 --minutes=3   # busiest live chats
python3 tool/youtube_emoji_harvest/harvest.py saved.html  # pages saved from a live chat
```

Fastest way to the full set: open any live chat on youtube.com **signed in**,
save the page (its data carries the whole emoji picker) and pass the file.
Re-run before a release; existing entries are kept.

How the sampling works: candidates come from YouTube's live hub and
several live searches, ranked by "watching"; each chat is followed in its
**Live chat** view (every message - the page opens on the filtered Top
chat) for the given minutes. Only YouTube's own emojis are kept; channel
member emojis are left to the app, which learns them per chat while it's
open. Busy chats reuse the same popular emojis - expect diminishing
returns (2026-10-05: 15 chats x 3 min added 6, total 39).
