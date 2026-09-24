# Combined chat icon

`CustomFlutterIcons.combined_chat` (U+E802 in `assets/fonts/CustomFlutterIcons.ttf`)
is drawn for the app, not a stock glyph: a solid speech bubble with a
knocked-out "merge" mark — three input nodes whose streams curve into one
output node (several platform chats flowing into one timeline). Single
color, so it tints per theme like every other font glyph.

- Source: [`combined-chat-icon.svg`](combined-chat-icon.svg) (preview of the
  exact outline).
- Generator: [`tool/icons/combined_chat_glyph.py`](../tool/icons/combined_chat_glyph.py)
  — builds the outline with skia-pathops boolean ops and adds/replaces the
  glyph in the font:

  ```bash
  python3 -m venv /tmp/iconvenv && /tmp/iconvenv/bin/pip install fonttools skia-pathops
  /tmp/iconvenv/bin/python tool/icons/combined_chat_glyph.py \
    assets/fonts/CustomFlutterIcons.ttf assets/fonts/CustomFlutterIcons.ttf /tmp/preview.svg
  ```

  Re-running is idempotent (the glyph is replaced in place); the other
  glyphs (Owncast, Kick) are untouched.
