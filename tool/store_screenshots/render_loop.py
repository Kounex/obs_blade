#!/usr/bin/env python3
"""Renders a demo scene page's render(t) loop into a seamless looping mp4.

    render_loop.py <page.html> <out.mp4> [--w 1920 --h 1080 --fps 30]

The page (obs_scene/*.html opened with ?drive) exposes `render(t)`, a pure
function of t that is periodic in `kLoop` seconds. One headless Chrome is
driven over the DevTools protocol: for every frame n it evaluates
render(n / fps), takes a screenshot and pipes the PNG into ffmpeg, so the
result is deterministic and frame-exact (no screen recording, no dropped
frames). Frames run 0 .. kLoop*fps-1, so the last one runs straight into
the first: every moving part of the page completes a whole number of
cycles per kLoop. The seam check compares the last -> first step with an
ordinary step (PSNR of frames N-1/0 vs 0/1) on the encoded file.

Needs Google Chrome, ffmpeg and python3 with `websockets` (macOS).
Used by prepare_media.sh --video; see README.md.
"""
import argparse
import asyncio
import base64
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.request
from pathlib import Path

from websockets.asyncio.client import connect

CHROME = os.environ.get(
    'CHROME', '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')


class CDP:
    def __init__(self, ws):
        self.ws, self.n, self.pending, self.events = ws, 0, {}, asyncio.Queue()

    async def pump(self):
        async for raw in self.ws:
            msg = json.loads(raw)
            if 'id' in msg:
                self.pending.pop(msg['id']).set_result(msg)
            else:
                await self.events.put(msg)

    async def __call__(self, method, **params):
        self.n += 1
        fut = asyncio.get_running_loop().create_future()
        self.pending[self.n] = fut
        await self.ws.send(json.dumps({'id': self.n, 'method': method, 'params': params}))
        msg = await fut
        if 'error' in msg:
            raise RuntimeError(f'{method}: {msg["error"]}')
        return msg['result']

    async def wait_event(self, name):
        while True:
            ev = await self.events.get()
            if ev['method'] == name:
                return ev


async def render(a):
    profile = tempfile.mkdtemp(prefix='store-loop-chrome-')
    chrome = subprocess.Popen([
        CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--mute-audio',
        '--force-device-scale-factor=1', f'--window-size={a.w},{a.h}',
        '--allow-file-access-from-files', '--force-color-profile=srgb',
        '--font-render-hinting=none', '--run-all-compositor-stages-before-draw',
        '--no-first-run', '--no-default-browser-check', f'--user-data-dir={profile}',
        '--remote-debugging-port=0', 'about:blank'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    ffmpeg = None
    try:
        # port 0: Chrome picks a free port and writes it to the profile -
        # no clash with another Chrome driven over DevTools on this machine
        page = None
        for _ in range(100):
            try:
                port = Path(profile, 'DevToolsActivePort').read_text().split()[0]
                targets = json.load(urllib.request.urlopen(f'http://127.0.0.1:{port}/json/list'))
                page = next(t for t in targets if t['type'] == 'page')
                break
            except Exception:
                await asyncio.sleep(0.1)
        if page is None:
            sys.exit('render_loop: Chrome did not come up')
        async with connect(page['webSocketDebuggerUrl'], max_size=None) as ws:
            cdp = CDP(ws)
            pump = asyncio.create_task(cdp.pump())
            await cdp('Page.enable')
            await cdp('Emulation.setDeviceMetricsOverride', width=a.w, height=a.h,
                      deviceScaleFactor=1, mobile=False)
            await cdp('Page.navigate', url=Path(a.page).resolve().as_uri() + '?drive')
            await cdp.wait_event('Page.loadEventFired')
            await cdp('Runtime.evaluate', expression='__ready', awaitPromise=True)
            loop_s = (await cdp('Runtime.evaluate', expression='kLoop',
                                returnByValue=True))['result']['value']
            frames = round(loop_s * a.fps)

            async def shot(t):
                await cdp('Runtime.evaluate', expression=f'render({t})', awaitPromise=True)
                data = await cdp('Page.captureScreenshot', format='png', fromSurface=True)
                return base64.b64decode(data['data'])

            # H.264 for OBS's media source: BT.709 limited range, a keyframe
            # per second, CRF high enough that the scrolling grid stays crisp
            vf = ('scale=out_color_matrix=bt709:out_range=tv:flags=lanczos+accurate_rnd,'
                  'format=yuv420p,setparams=color_primaries=bt709:color_trc=bt709:'
                  'colorspace=bt709:range=tv')
            ffmpeg = subprocess.Popen([
                'ffmpeg', '-nostdin', '-hide_banner', '-loglevel', 'error', '-y',
                '-f', 'image2pipe', '-framerate', str(a.fps), '-c:v', 'png', '-i', '-',
                '-vf', vf, '-c:v', 'libx264', '-preset', 'slow', '-crf', str(a.crf),
                '-g', str(a.fps), '-r', str(a.fps), '-fps_mode', 'cfr', '-an',
                '-movflags', '+faststart', a.out], stdin=subprocess.PIPE)
            # the first frames after load come out incomplete (filters and
            # the clip path settle over a couple of paints) - warm up first
            for t in (0, loop_s / 2, 0):
                await shot(t)
            start = time.perf_counter()
            for n in range(frames):
                ffmpeg.stdin.write(await shot(n / a.fps))
            ffmpeg.stdin.close()
            if ffmpeg.wait() != 0:
                sys.exit('render_loop: ffmpeg failed')
            ffmpeg = None
            pump.cancel()
            took = time.perf_counter() - start
    finally:
        if ffmpeg is not None:
            ffmpeg.kill()
        chrome.terminate()
        chrome.wait(timeout=10)
        subprocess.run(['rm', '-rf', profile])

    seam, step = psnr(a.out, frames - 1, 0), psnr(a.out, 0, 1)
    print(f'[media] {Path(a.out).name}: {frames} frames, {loop_s}s loop @ {a.fps} fps, '
          f'{took:.0f}s; seam {seam:.1f} dB vs step {step:.1f} dB')
    if seam < step - 6:
        sys.exit('render_loop: the last -> first frame step is far larger than a normal one')


def psnr(video, n1, n2):
    """PSNR (dB) between frames n1 and n2 of [video]."""
    graph = (f"[0:v]select=eq(n\\,{n1}),setpts=0[a];"
             f"[1:v]select=eq(n\\,{n2}),setpts=0[b];[a][b]psnr")
    out = subprocess.run(['ffmpeg', '-nostdin', '-hide_banner', '-i', video, '-i', video,
                          '-lavfi', graph, '-f', 'null', '-'],
                         capture_output=True, text=True).stderr
    for token in out.split():
        if token.startswith('average:'):
            value = token.split(':', 1)[1]
            return 99.0 if value == 'inf' else float(value)
    sys.exit(f'render_loop: no PSNR for frames {n1}/{n2}')


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('page')
    ap.add_argument('out')
    ap.add_argument('--w', type=int, default=1920)
    ap.add_argument('--h', type=int, default=1080)
    ap.add_argument('--fps', type=int, default=30)
    ap.add_argument('--crf', type=int, default=16)
    asyncio.run(render(ap.parse_args()))


if __name__ == '__main__':
    main()
