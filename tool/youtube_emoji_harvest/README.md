# YouTube emoji harvest (maintainer tool)

Grows `lib/utils/youtube/youtube_standard_emojis.dart`, the bundled set of
YouTube's own live-chat emojis (`:yt:`, `:face-blue-smiling:`,
`:medal-yellow-first-red:`, ...). The Data API sends only the
`:shortcode:` text; the image URL exists only in YouTube's web chat data,
and there's no public list. The app learns missing ones at runtime from the
chat page (`YouTubeEmojiStore`); this bundle makes the picker useful from
the start.

```bash
python3 tool/youtube_emoji_harvest/harvest.py             # sample ~40 live chats (~5 min)
python3 tool/youtube_emoji_harvest/harvest.py saved.html  # pages saved from a live chat
```

Fastest way to the full set: open any live chat on youtube.com **signed in**,
save the page (its data carries the whole emoji picker) and pass the file.
Re-run before a release; existing entries are kept.
