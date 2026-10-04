#!/usr/bin/env python3
"""Grow the bundled YouTube standard emoji set (maintainer tool).

YouTube's own live-chat emojis (`:yt:`, `:face-blue-smiling:`, ...) belong
to the channel UCkszU2WH9gy1mb0dV-11UJg. The Data API only sends their
`:shortcode:` text; the image URL exists only in the web chat's data. No
public list exists and the anonymous chat page only carries the emojis of
its recent messages, so this script samples live chats (quota-free page
reads + a few `get_live_chat` continuations - maintainer side only, the app
never calls innertube) and merges what it finds into
`lib/utils/youtube/youtube_standard_emojis.dart`.

    python3 tool/youtube_emoji_harvest/harvest.py              # busiest live chats
    python3 tool/youtube_emoji_harvest/harvest.py --chats=15 --minutes=3
    python3 tool/youtube_emoji_harvest/harvest.py page.html ...  # saved pages

A page saved from a live chat while signed in carries the full emoji picker
(every standard emoji) - the quickest way to complete the set.
Stdlib only. Existing entries are kept; new ones are added.
"""
import json, re, sys, time, urllib.request
from pathlib import Path

OWNER = 'UCkszU2WH9gy1mb0dV-11UJg'
UA = ('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0 Safari/537.36')
HEADERS = {'User-Agent': UA, 'Cookie': 'SOCS=CAI; CONSENT=YES+1',
           'Accept-Language': 'en-US'}
OUT = Path(__file__).resolve().parents[2] / 'lib/utils/youtube/youtube_standard_emojis.dart'
LIVE_HUB = 'https://www.youtube.com/channel/UC4R8DWoMoI7CAwX8_LjQHig'


def get(url, data=None):
    headers = dict(HEADERS)
    if data is not None:
        headers['Content-Type'] = 'application/json'
    req = urllib.request.Request(url, data=data, headers=headers)
    return urllib.request.urlopen(req, timeout=20).read().decode('utf-8', 'replace')


def base_url(url):
    """Image URL without its size suffix (`=w48-h48-c-k-nd`)."""
    return url.split('=')[0]


def collect(node, found):
    if isinstance(node, dict):
        if node.get('isCustomEmoji') and str(node.get('emojiId', '')).startswith(OWNER + '/'):
            shortcuts = node.get('shortcuts') or []
            thumbs = (node.get('image') or {}).get('thumbnails') or []
            if shortcuts and thumbs:
                found[shortcuts[0]] = {'id': node['emojiId'][len(OWNER) + 1:],
                                       'codes': shortcuts,
                                       'url': base_url(thumbs[-1]['url'])}
        for value in node.values():
            collect(value, found)
    elif isinstance(node, list):
        for value in node:
            collect(value, found)


def initial_data(html):
    m = (re.search(r'ytInitialData"\]\s*=\s*(\{.*?\});\s*</script>', html, re.S)
         or re.search(r'ytInitialData\s*=\s*(\{.*?\});\s*</script>', html, re.S))
    return json.loads(m.group(1)) if m else None


LIVE_QUERIES = ['live', 'gaming live', 'just chatting live', 'music live',
                'news live', 'minecraft live', 'fortnite live', 'vtuber live',
                'sports live', 'football live']


def _viewers(text):
    """'1,234 watching' / '12K watching' -> number (0 when unknown)."""
    m = re.search(r'([\d.,]+)\s*([KkMm])?\s*watching', text)
    if not m:
        return 0
    value = float(m.group(1).replace(',', ''))
    unit = (m.group(2) or '').upper()
    return int(value * (1000 if unit == 'K' else 1000000 if unit == 'M' else 1))


def busiest_live(limit):
    """Live video ids with the most viewers, from live searches + the hub."""
    viewers = {}
    pages = [LIVE_HUB] + [
        'https://www.youtube.com/results?search_query='
        + urllib.request.quote(q) + '&sp=EgJAAQ%253D%253D' for q in LIVE_QUERIES]
    for url in pages:
        try:
            data = initial_data(get(url))
        except Exception:
            continue

        def walk(node):
            if isinstance(node, dict):
                for key in ('videoRenderer', 'gridVideoRenderer'):
                    video = node.get(key)
                    if isinstance(video, dict) and video.get('videoId'):
                        label = video.get('viewCountText') or {}
                        text = label.get('simpleText') or ''.join(
                            run.get('text', '') for run in label.get('runs', []))
                        count = _viewers(text)
                        vid = video['videoId']
                        viewers[vid] = max(viewers.get(vid, 0), count)
                for value in node.values():
                    walk(value)
            elif isinstance(node, list):
                for value in node:
                    walk(value)
        if data:
            walk(data)
        time.sleep(1)
    ranked = sorted(viewers.items(), key=lambda item: -item[1])
    return [(vid, count) for vid, count in ranked if count > 0][:limit]


def live_chat_token(data):
    """The 'Live chat' (every message) view's token - the page opens on
    'Top chat', a filtered sample."""
    found = []

    def walk(node):
        if isinstance(node, dict):
            for item in node.get('subMenuItems') or []:
                if item.get('title') == 'Live chat':
                    token = ((item.get('continuation') or {})
                             .get('reloadContinuationData') or {}).get('continuation')
                    if token:
                        found.append(token)
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)
    walk(data)
    if found:
        return found[0]
    cont = re.search(r'"continuation":"([^"]+)"', json.dumps(data))
    return cont.group(1) if cont else None


def sample_live(found, chats=15, minutes=3.0):
    """Follow the busiest live chats for [minutes] each (a request every
    5 s) - only YouTube's own emojis are kept (see [collect])."""
    for vid, count in busiest_live(chats):
        try:
            html = get(f'https://www.youtube.com/live_chat?v={vid}&is_popout=1')
        except Exception:
            continue
        data = initial_data(html)
        key = re.search(r'"INNERTUBE_API_KEY":"([^"]+)"', html)
        version = re.search(r'"INNERTUBE_CLIENT_VERSION":"([^"]+)"', html)
        if not data or not key:
            continue
        before = len(found)
        collect(data, found)
        token = live_chat_token(data)
        deadline = time.time() + minutes * 60
        messages = 0
        while token and time.time() < deadline:
            body = json.dumps({'context': {'client': {
                'clientName': 'WEB',
                'clientVersion': version.group(1) if version else '2.20260101'}},
                'continuation': token}).encode()
            try:
                answer = json.loads(get(
                    'https://www.youtube.com/youtubei/v1/live_chat/get_live_chat'
                    f'?key={key.group(1)}', body))
            except Exception:
                break
            chat = (answer.get('continuationContents') or {}).get('liveChatContinuation') or {}
            messages += len(chat.get('actions') or [])
            collect(chat, found)
            nxt = next(iter(((chat.get('continuations') or [{}])[0]).values()), {})
            token = nxt.get('continuation')
            time.sleep(max(2.0, (nxt.get('timeoutMs') or 5000) / 1000))
        print(f'{vid} ({count} watching, {messages} chat actions): '
              f'+{len(found) - before} -> {len(found)}', flush=True)


def existing():
    if not OUT.exists():
        return {}
    found = {}
    for m in re.finditer(r"YouTubeStandardEmoji\(\s*id: '([^']+)',\s*codes: \[([^\]]*)\],\s*url: '([^']+)'", OUT.read_text()):
        codes = re.findall(r"'([^']+)'", m.group(2))
        found[codes[0]] = {'id': m.group(1), 'codes': codes, 'url': m.group(3)}
    return found


def write(found):
    lines = [
        '// GENERATED by tool/youtube_emoji_harvest/harvest.py - do not edit by hand.',
        '//',
        "// YouTube's standard live-chat emojis (owner channel $OWNER): the",
        '// Data API only sends their `:shortcode:`, the image exists only in the',
        '// web chat data. The app learns more at runtime (`YouTubeEmojiStore`).',
        '',
        "import 'youtube_emoji.dart';",
        '',
        'const List<YouTubeStandardEmoji> kYouTubeStandardEmojis = [',
    ]
    for code in sorted(found, key=str.lower):
        e = found[code]
        codes = ', '.join("'" + c.replace("'", "\\'") + "'" for c in e['codes'])
        lines.append(f"  YouTubeStandardEmoji(\n    id: '{e['id']}',\n    codes: [{codes}],\n    url: '{e['url']}',\n  ),")
    lines.append('];')
    OUT.write_text('\n'.join(lines).replace('$OWNER', OWNER) + '\n')


def main():
    found = existing()
    before = len(found)
    files = [a for a in sys.argv[1:] if not a.startswith('--')]
    if files:
        for path in files:
            html = Path(path).read_text(errors='replace')
            data = initial_data(html)
            if data:
                collect(data, found)
            for blob in re.findall(r'\{"emojiId".*?"isCustomEmoji":true\}', html):
                try:
                    collect(json.loads(blob), found)
                except Exception:
                    pass
    else:
        chats = int(next((a.split('=')[1] for a in sys.argv if a.startswith('--chats=')), 15))
        minutes = float(next((a.split('=')[1] for a in sys.argv if a.startswith('--minutes=')), 3))
        sample_live(found, chats, minutes)
    write(found)
    print(f'{before} -> {len(found)} standard emojis in {OUT}')


if __name__ == '__main__':
    main()
