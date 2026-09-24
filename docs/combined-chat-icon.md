# Combined chat icon

The combined chat mark is a speech bubble holding three chat lines in the
platforms' accent colors (Twitch purple `#B58CF0`, Kick green `#5FC27E`,
YouTube red `#F07F78`) — several chats in one. Source:
[`combined-chat-icon.svg`](combined-chat-icon.svg) (24×24 viewBox,
provided by the maintainer).

It's multi-color, so it can't be an icon-font glyph. `CombinedChatIcon`
(`lib/views/dashboard/widgets/obs_widgets/stream_chat/combined_chat_icon.dart`)
paints the same paths with a `CustomPainter` (no SVG package needed). The
lines keep their fixed colors; the bubble follows the theme (`#3A3A44` on
light surfaces, a lifted `#55555F` on dark ones so it doesn't sink into the
dark control fill).

Used by the chat-type dropdown, the chat empty-state header and the combo
card's placeholder tile (`chatTypeIcon(...)` picks it for
`ChatType.Combined`). `ChatType.Combined.icon` is only a monochrome
fallback (`JamIcons.messages`).
