#!/usr/bin/env python3
"""Video-mode watcher (record.sh): runs the store video test, records the
device per clip and normalizes the clips.

    record_watch.py --platform ios|android --device <id> --out <dir>
                    [--adb <path>] [--log <file>] [--pidfile <file>]
                    -- <test command ...>
    record_watch.py --analyze <dir>      # summary of existing clips only

Reads the test's output line by line (echoed to stdout and --log):

    REC_START: <clip>          start the recorder, wait until it really
                               records, then ack start:<clip>
    REC_STOP: <clip>           stop it (SIGINT), wait for the file to be
                               finalized (and pulled), then ack stop:<clip>
    CUE: <clip> <label> <ms>   <ms> since the start ack; logged as seconds
                               into that clip's file in <out>/cues.json

iOS records with `simctl io recordVideo --codec=h264` (<clip>.mov), Android
with `screenrecord` on the device (<clip>.raw.mp4, pulled) or, with
--android-recorder emulator, with the emulator's own host-side recorder
(<clip>.raw.webm). The first two write frames only when the screen
changes (variable frame rate), the emulator's constant 60 fps; after the test
every clip is re-encoded to constant 30 fps H.264 at native size
(<clip>.mp4), and <out>/clips.json summarizes each: duration, size, how
many frames per second the app really drew while something moved (from the
raw file's frame times - a smooth clip shows ~60 there, a janky one less),
and `lost_s`: how much shorter the file is than the test's own clock (a
stalled simulator drops that time from the recording - re-take the clip).

Acks go to the test's server on 127.0.0.1:8977 (adb forward on Android).

Interrupted (Ctrl-C, SIGTERM, SIGHUP, an error) it stops the running
recorder and the test command (its whole process group) before it exits,
and skips the normalizing. A terminal that went away (broken pipe) only
stops the echo - the log keeps every line and the run goes on. --pidfile
gets the test command's pid (= its process group) while it runs, so
record.sh can still stop it if this watcher itself was killed hard.
Stdlib only.
"""
import argparse
import json
import os
import re
import signal
import statistics
import subprocess
import sys
import threading
import time
import urllib.parse
import urllib.request
from pathlib import Path

ACK_URL = 'http://127.0.0.1:8977/ack?name='
MARKER = re.compile(r'(REC_START|REC_STOP): (\w+)')
CUE = re.compile(r'CUE: (\w+) (\w+) (\d+)')
FRAMES = re.compile(r'FRAMES: (\w+) (\d+) (\d+) (\d+) (\d+)')


_echo = True


def echo(text):
    """Writes to stdout; once the terminal is gone (ssh dropped: broken
    pipe / EIO) it only stops echoing - the run itself goes on."""
    global _echo
    if not _echo:
        return
    try:
        sys.stdout.write(text)
        sys.stdout.flush()
    except OSError:
        _echo = False
        try:  # no second error at exit when Python flushes stdout again
            os.dup2(os.open(os.devnull, os.O_WRONLY), sys.stdout.fileno())
        except OSError:
            pass


def log(message):
    echo(f'[record] {message}\n')


class Interrupted(Exception):
    pass


def _interrupt(signum, _frame):
    raise Interrupted(signal.Signals(signum).name)


def stop_child(child):
    """Terminates the test command's process group (flutter and what it
    spawned), killed after 15 s."""
    try:
        os.killpg(child.pid, signal.SIGTERM)
    except (ProcessLookupError, PermissionError):
        return
    try:
        child.wait(15)
    except subprocess.TimeoutExpired:
        log('test command did not stop - killing it')
        try:
            os.killpg(child.pid, signal.SIGKILL)
        except (ProcessLookupError, PermissionError):
            pass
        child.wait()


def ack(key):
    try:
        urllib.request.urlopen(ACK_URL + urllib.parse.quote(key), timeout=3).read()
    except Exception as e:  # the test times out on its own and says so
        log(f'ack {key} failed: {e}')


class Recorder:
    """One running screen recording; subclasses per platform."""

    ready_text = ''

    def __init__(self, args, clip):
        self.args, self.clip = args, clip
        self.started = threading.Event()
        self.proc = None
        self.t0 = None

    def command(self):
        raise NotImplementedError

    def start(self):
        self.proc = subprocess.Popen(self.command(), stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT, text=True, bufsize=1)
        threading.Thread(target=self._read, daemon=True).start()
        if not self.started.wait(15):
            log(f'{self.clip}: no "{self.ready_text}" from the recorder - going on')
        self.t0 = time.monotonic()

    def _read(self):
        for line in self.proc.stdout:
            if self.ready_text in line:
                self.started.set()
            elif line.strip():
                log(f'{self.clip}: {line.strip()}')

    def stop(self):
        raise NotImplementedError


class IosRecorder(Recorder):
    ready_text = 'Recording started'

    @property
    def raw(self):
        return self.args.out / f'{self.clip}.mov'

    def command(self):
        return ['xcrun', 'simctl', 'io', self.args.device, 'recordVideo',
                '--codec=h264', '--force', str(self.raw)]

    def stop(self):
        self.proc.send_signal(signal.SIGINT)
        try:
            self.proc.wait(60)  # returns once the movie is written
        except subprocess.TimeoutExpired:
            self.proc.kill()
            log(f'{self.clip}: recorder did not finish - killed')


class AndroidRecorder(Recorder):
    # screenrecord --verbose prints this once the virtual display and the
    # encoder are up, right before the first frame
    ready_text = 'Content area is'

    @property
    def raw(self):
        return self.args.out / f'{self.clip}.raw.mp4'

    @property
    def remote(self):
        return f'/sdcard/store_video_{self.clip}.mp4'

    def adb(self, *cmd, **kw):
        return subprocess.run([self.args.adb, '-s', self.args.device, *cmd],
                              capture_output=True, text=True, **kw)

    def command(self):
        return [self.args.adb, '-s', self.args.device, 'shell', 'screenrecord',
                '--verbose', '--bit-rate', '20000000', self.remote]

    def start(self):
        super().start()
        # the first frame lands a moment after the ready line (longer on a
        # busy emulator) - the clip's clock starts once the file has it
        for _ in range(100):
            size = self.adb('shell', 'stat', '-c', '%s', self.remote).stdout.strip()
            if size.isdigit() and int(size) > 0:
                break
            time.sleep(0.05)
        self.t0 = time.monotonic()

    def stop(self):
        # SIGINT to the local adb does not reach the device process
        self.adb('shell', 'pkill', '-INT', 'screenrecord')
        try:
            self.proc.wait(30)
        except subprocess.TimeoutExpired:
            self.proc.kill()
            log(f'{self.clip}: screenrecord did not finish - killed')
        time.sleep(0.5)
        pulled = self.adb('pull', self.remote, str(self.raw))
        if pulled.returncode != 0:
            log(f'{self.clip}: pull failed: {pulled.stderr.strip()}')
        self.adb('shell', 'rm', '-f', self.remote)


class EmulatorRecorder(Recorder):
    """The emulator's own recorder (`adb emu screenrecord`, Android
    emulators only): encodes the emulator's display on the host - VP9,
    constant 60 fps (<clip>.raw.webm) - so no guest virtual display and
    software encoder compete with the app for the emulator's GPU/CPU."""

    @property
    def raw(self):
        return self.args.out / f'{self.clip}.raw.webm'

    def emu(self, *cmd):
        return subprocess.run([self.args.adb, '-s', self.args.device, 'emu', 'screenrecord', *cmd],
                              capture_output=True, text=True)

    def _size(self):
        return self.raw.stat().st_size if self.raw.exists() else 0

    def start(self):
        self.raw.unlink(missing_ok=True)
        started = self.emu('start', '--fps', '60', '--bit-rate', '25M', str(self.raw))
        # it grabs frames from here on (the file only fills ~1 s later - the
        # encoder buffers), so the clip's clock starts now
        self.t0 = time.monotonic()
        if not started.stdout.startswith('OK'):
            log(f'{self.clip}: emulator recorder: {started.stdout.strip()} {started.stderr.strip()}')

    def stop(self):
        self.emu('stop')
        last, stable = -1, 0
        for _ in range(120):  # finalized: size unchanged for a second
            size = self._size()
            stable = stable + 1 if size == last else 0
            if stable >= 4:
                break
            last = size
            time.sleep(0.25)


def run_test(args):
    emulator = args.android_recorder == 'emulator' or (
        args.android_recorder == 'auto' and args.device.startswith('emulator-'))
    recorder_cls = (IosRecorder if args.platform == 'ios'
                    else EmulatorRecorder if emulator else AndroidRecorder)
    cues_file = args.out / 'cues.json'
    cues = json.loads(cues_file.read_text()) if cues_file.exists() else {}
    active = None
    ack_at = {}
    recorded = []
    logf = open(args.log, 'w') if args.log else None

    def stop_active():
        nonlocal active
        if active is None:
            return
        active.stop()
        log(f'{active.clip}: stopped -> {active.raw.name}')
        recorded.append(active.clip)
        active = None

    # its own process group: stop_child() reaches everything flutter
    # spawned, and a Ctrl-C in the terminal reaches this watcher, which
    # stops the recorder first
    child = subprocess.Popen(args.command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             stdin=subprocess.DEVNULL, start_new_session=True)
    if args.pidfile:
        Path(args.pidfile).write_text(f'{child.pid}\n')
    try:
        for raw_line in iter(child.stdout.readline, b''):
            line = raw_line.decode('utf-8', errors='replace')
            echo(line)
            if logf:
                logf.write(line)
                logf.flush()
            m = MARKER.search(line)
            if m and m[1] == 'REC_START':
                stop_active()
                active = recorder_cls(args, m[2])
                active.start()
                ack_at[m[2]] = time.monotonic()
                # t: seconds into the file; lead = where the start ack landed
                cues[m[2]] = {'file': f'{m[2]}.mp4', 'raw': active.raw.name,
                              'lead': round(ack_at[m[2]] - active.t0, 3), 'cues': []}
                log(f'{m[2]}: recording')
                ack(f'start:{m[2]}')
            elif m and m[1] == 'REC_STOP':
                if active is not None and active.clip == m[2]:
                    stop_active()
                ack(f'stop:{m[2]}')
            f = FRAMES.search(line)
            if f and f[1] in cues:
                # what the app drew itself (vs what the recorder kept)
                cues[f[1]]['app'] = {'frames': int(f[2]),
                                     'fps': round(int(f[2]) / max(int(f[3]), 1) * 1000, 1),
                                     'p90_build_ms': int(f[4]), 'p90_raster_ms': int(f[5])}
            c = CUE.search(line)
            if c and c[1] in cues and c[1] in ack_at:
                entry = cues[c[1]]
                entry['cues'].append({'label': c[2], 't': round(entry['lead'] + int(c[3]) / 1000, 3)})
                cues_file.write_text(json.dumps(cues, indent=1))
        code = child.wait()
    except BaseException as e:
        # nothing may cut this short: the recorder has to stop and the test
        # (which drives OBS) has to be gone before record.sh tears OBS down
        for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
            signal.signal(sig, signal.SIG_IGN)
        log(f'interrupted ({type(e).__name__} {e}) - stopping the recorder and the test')
        try:
            stop_active()
        except Exception as stop_error:
            log(f'stopping the recorder failed: {stop_error}')
        stop_child(child)
        raise
    finally:
        if args.pidfile:
            Path(args.pidfile).unlink(missing_ok=True)
        if logf:
            logf.close()
        cues_file.write_text(json.dumps(cues, indent=1))
    stop_active()

    for clip in recorded:
        normalize(args.out, clip, cues[clip]['raw'])
    analyze(args.out, recorded)
    return code


def normalize(out, clip, raw_name):
    """Variable -> constant 30 fps H.264, native size, high quality."""
    raw = out / raw_name
    if not raw.exists() or raw.stat().st_size == 0:
        log(f'{clip}: no raw file')
        return
    # simctl / screenrecord tag BT.709; the emulator's recorder leaves its
    # (BT.601) YUV untagged - convert that instead of just relabeling it
    space = probe(raw, 'stream=color_space').get('streams', [{}])[0].get('color_space', 'unknown')
    matrix = '' if space == 'bt709' else 'scale=in_color_matrix=bt601:out_color_matrix=bt709,'
    result = subprocess.run([
        'ffmpeg', '-nostdin', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(raw),
        '-vf', f'fps=30,{matrix}format=yuv420p,setparams=color_primaries=bt709:color_trc=bt709:'
               'colorspace=bt709:range=tv',
        '-c:v', 'libx264', '-preset', 'slow', '-crf', '13', '-profile:v', 'high',
        '-fps_mode', 'cfr', '-r', '30', '-an', '-movflags', '+faststart',
        str(out / f'{clip}.mp4')], capture_output=True, text=True)
    if result.returncode != 0:
        log(f'{clip}: normalize failed: {result.stderr.strip()[-400:]}')
    else:
        log(f'{clip}: -> {clip}.mp4')


def changed_frame_times(raw):
    """Times of the frames that differ from the one before. simctl and
    screenrecord only write changed frames, so those are the packets; the
    emulator's recorder repeats frames - those are dropped by comparing
    the decoded frames (framemd5; an unchanged frame decodes identical)."""
    if raw.suffix == '.webm':
        out = subprocess.run(['ffmpeg', '-nostdin', '-v', 'error', '-i', str(raw), '-an',
                              '-fps_mode', 'passthrough', '-f', 'framemd5', '-'],
                             capture_output=True, text=True).stdout
        tb = re.search(r'#tb 0: (\d+)/(\d+)', out)
        times, previous = [], None
        for row in (line.split(',') for line in out.splitlines() if line and line[0] != '#'):
            if row[5].strip() != previous:
                times.append(int(row[2]) * int(tb[1]) / int(tb[2]))
            previous = row[5].strip()
        return times
    return sorted(float(p['pts_time']) for p in probe(raw, 'packet=pts_time').get('packets', [])
                  if p.get('pts_time') not in (None, 'N/A'))


def probe(path, entries, stream='v:0'):
    out = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', stream, '-show_entries',
                          entries, '-of', 'json', str(path)], capture_output=True, text=True)
    return json.loads(out.stdout or '{}')


def analyze(out, clips=None):
    """Per clip: duration, size, and the frames per second the recorder got
    while the screen changed (raw frame times) - the smoothness check."""
    cues = json.loads((out / 'cues.json').read_text()) if (out / 'cues.json').exists() else {}
    clips = clips or list(cues)
    summary = {}
    for clip in clips:
        entry = cues.get(clip, {})
        mp4, raw = out / f'{clip}.mp4', out / entry.get('raw', f'{clip}.mov')
        if not mp4.exists() or not raw.exists():
            continue
        fmt = probe(mp4, 'stream=width,height,avg_frame_rate:format=duration')
        stream = fmt.get('streams', [{}])[0]
        times = changed_frame_times(raw)
        per_second = {}
        for t in times:
            per_second[int(t)] = per_second.get(int(t), 0) + 1
        # a second counts as "in motion" once the screen changed more than
        # a ticking clock would (the recorders skip unchanged frames)
        moving = [n for n in per_second.values() if n >= 5]
        duration = round(float(fmt.get('format', {}).get('duration', 0)), 2)
        # the test's clock vs the file's: a stalled simulator drops the
        # stalled time from the recording (the display clock stops too)
        end = next((c['t'] for c in entry.get('cues', []) if c['label'] == 'end'), None)
        summary[clip] = {
            'duration': duration,
            'lost_s': round(end - duration, 2) if end is not None else None,
            'size': f'{stream.get("width")}x{stream.get("height")}',
            'raw_frames': len(times),
            'motion_seconds': len(moving),
            'motion_fps_median': round(statistics.median(moving), 1) if moving else 0,
            'motion_fps_min': min(moving) if moving else 0,
            'fps_per_second': [per_second.get(s, 0) for s in range(int(times[-1]) + 1)] if times else [],
            'app': entry.get('app'),
            'cues': [f'{c["label"]}@{c["t"]}' for c in entry.get('cues', [])],
        }
        s = summary[clip]
        log(f'{clip}: {s["duration"]}s {s["size"]} raw {s["raw_frames"]} frames, '
            f'motion {s["motion_seconds"]}s @ median {s["motion_fps_median"]} fps '
            f'(min {s["motion_fps_min"]})'
            + (f'; app drew {s["app"]["fps"]} fps (p90 build {s["app"]["p90_build_ms"]} ms, '
               f'raster {s["app"]["p90_raster_ms"]} ms)' if s['app'] else ''))
        if (s['lost_s'] or 0) > 0.5:
            log(f'{clip}: WARNING the file is {s["lost_s"]}s shorter than the test '
                'ran it - the device stalled mid-clip; re-take it')
    existing = json.loads((out / 'clips.json').read_text()) if (out / 'clips.json').exists() else {}
    existing.update(summary)
    (out / 'clips.json').write_text(json.dumps(existing, indent=1))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--platform', choices=['ios', 'android'])
    ap.add_argument('--device')
    ap.add_argument('--out', type=Path)
    ap.add_argument('--adb', default='adb')
    ap.add_argument('--android-recorder', choices=['auto', 'device', 'emulator'], default='auto',
                    help='device: screenrecord on the device; emulator: the emulator\'s '
                         'host-side recorder (adb emu screenrecord); auto: emulator for '
                         'emulator-* serials')
    ap.add_argument('--log')
    ap.add_argument('--pidfile', help='gets the test command\'s pid while it runs')
    ap.add_argument('--analyze', type=Path, metavar='DIR')
    ap.add_argument('--normalize', action='store_true',
                    help='with --analyze: re-encode every clip\'s raw file first')
    ap.add_argument('command', nargs=argparse.REMAINDER)
    args = ap.parse_args()
    if args.analyze:
        if args.normalize:
            cues = json.loads((args.analyze / 'cues.json').read_text())
            for clip, entry in cues.items():
                normalize(args.analyze, clip, entry['raw'])
        analyze(args.analyze)
        return 0
    if args.command and args.command[0] == '--':
        args.command = args.command[1:]
    if not (args.platform and args.device and args.out and args.command):
        ap.error('--platform, --device, --out and the test command are required')
    args.out.mkdir(parents=True, exist_ok=True)
    # SIGINT too: record.sh runs this in the background, where the shell
    # starts it with SIGINT ignored - and the recorders it spawns would
    # inherit that (simctl stops its recording on SIGINT)
    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, _interrupt)
    try:
        return run_test(args)
    except Interrupted as e:
        log(f'stopped by {e}')
        return 130


if __name__ == '__main__':
    sys.exit(main())
