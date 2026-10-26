# The music bed, made from scratch in code (no samples, no licensed music): python3 sound.py
# Writes out/music.wav, as long as the cut in film.js. One tempo and one key the whole way, so the
# parts can cross-fade without a bump; each act changes the instruments and the energy:
#   home    (1 to 2c)    soft piano and a pad, a little wistful
#   build   (2d, 3)      a pulse comes in under the numbers and lifts into the title
#   app     (4 to 10)    warm keys, a light shaker, bass: the app at work
#   proof   (11, 12a)    arpeggios and a soft kick for the tests and the feature wall
#   end     (12b, 13)    a full, warm pad and piano that resolve and fade out
# Quiet on purpose: peaks under -18 dBFS so a voiceover sits well above it.
import json, os, subprocess
import numpy as np
from scipy.signal import butter, sosfilt

HERE = os.path.dirname(os.path.abspath(__file__))
SR = 48000
BPM = 84
BEAT = 60 / BPM
BAR = 4 * BEAT
XFADE = 4.0  # seconds each act blends into the next

shots = json.loads(subprocess.check_output(["node", "-e", "import('./film.js').then(m=>console.log(JSON.stringify(m.timeline())))"], cwd=HERE))
start = {s["shot"]: s["start"] for s in shots}
LENGTH = shots[-1]["start"] + shots[-1]["dur"]
ACTS = [("home", 0), ("build", start["2d"]), ("app", start["4"]), ("proof", start["11"]), ("end", start["12b"])]

N = int(LENGTH * SR) + SR
t_all = np.arange(N) / SR

# C major / A minor. Chords as MIDI notes; two loops so acts can differ without leaving the key.
A_MIN, F_MAJ, C_MAJ, G_MAJ, E_MIN, D_MIN = [57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62], [52, 55, 59], [50, 53, 57]
WISTFUL = [A_MIN, F_MAJ, C_MAJ, G_MAJ]
BRIGHT = [C_MAJ, G_MAJ, A_MIN, F_MAJ]
LIFT = [F_MAJ, C_MAJ, G_MAJ, A_MIN]
HOME_END = [F_MAJ, G_MAJ, E_MIN, A_MIN, D_MIN, G_MAJ, C_MAJ, C_MAJ]

hz = lambda m: 440.0 * 2 ** ((m - 69) / 12)


def chord_at(prog, bar):
    return prog[int(bar) % len(prog)]


def add(buf, at, sig):
    i = int(at * SR)
    if i >= len(buf): return
    j = min(len(buf), i + len(sig))
    buf[i:j] += sig[: j - i]


def tone(f, dur, decay, harmonics=((1, 1.0), (2, 0.35), (3, 0.12)), attack=0.008):
    n = int(dur * SR); t = np.arange(n) / SR
    env = np.minimum(1, t / attack) * np.exp(-t / decay)
    return env * sum(a * np.sin(2 * np.pi * f * h * t) for h, a in harmonics)


def pad_layer(prog, lo, hi, bright=0.0, octave=0):
    """A soft chord pad: detuned sines per chord tone, each chord swelling in over half a bar."""
    out = np.zeros(N)
    bars = int(LENGTH / BAR) + 2
    for b in range(bars):
        t0 = b * BAR
        if t0 > hi + XFADE or t0 + BAR < lo - XFADE: continue
        n = int((BAR + 1.5) * SR); t = np.arange(n) / SR
        env = np.minimum(1, t / (BAR * 0.45)) * np.clip((BAR + 1.5 - t) / 1.5, 0, 1)
        sig = np.zeros(n)
        for m in chord_at(prog, b):
            for d in (-0.08, 0.0, 0.07):
                f = hz(m + 12 * octave) * 2 ** (d / 12)
                sig += np.sin(2 * np.pi * f * t + d * 40) + bright * 0.25 * np.sin(2 * np.pi * 2 * f * t)
        add(out, t0, env * sig / 9)
    return out


def piano(prog, lo, hi, pattern, vel=1.0, octave=12, decay=0.9):
    """Broken-chord piano: pattern = [(beat, chord index or 'top'), ...] per bar."""
    out = np.zeros(N)
    for b in range(int(LENGTH / BAR) + 2):
        t0 = b * BAR
        if t0 > hi + XFADE or t0 + BAR < lo - XFADE: continue
        ch = chord_at(prog, b)
        for beat, k in pattern:
            m = ch[k % 3] + octave + (12 if k >= 3 else 0)
            add(out, t0 + beat * BEAT, vel * tone(hz(m), 2.2, decay))
    return out


def bass(prog, lo, hi, beats=(0, 2), vel=1.0):
    out = np.zeros(N)
    for b in range(int(LENGTH / BAR) + 2):
        t0 = b * BAR
        if t0 > hi + XFADE or t0 + BAR < lo - XFADE: continue
        root = chord_at(prog, b)[0] - 12
        for beat in beats:
            add(out, t0 + beat * BEAT, vel * tone(hz(root), BEAT * 2, 0.6, ((1, 1.0), (2, 0.2)), attack=0.02))
    return out


def kick(lo, hi, beats=(0, 2), vel=1.0):
    out = np.zeros(N); n = int(0.35 * SR); t = np.arange(n) / SR
    k = np.sin(2 * np.pi * (48 * t + 60 * (1 - np.exp(-t * 30)) / 30)) * np.exp(-t * 14)
    for b in range(int(LENGTH / BAR) + 2):
        for beat in beats:
            at = b * BAR + beat * BEAT
            if lo - XFADE <= at <= hi + XFADE: add(out, at, vel * k)
    return out


def shaker(lo, hi, vel=1.0):
    out = np.zeros(N); n = int(0.09 * SR); t = np.arange(n) / SR
    rng = np.random.default_rng(7)
    sos = butter(4, 5000, "highpass", fs=SR, output="sos")
    for i in range(int(LENGTH / (BEAT / 2)) + 2):
        at = i * BEAT / 2
        if not (lo - XFADE <= at <= hi + XFADE): continue
        burst = sosfilt(sos, rng.standard_normal(n)) * np.exp(-t * 45) * (0.6 if i % 2 else 1.0)
        add(out, at, vel * burst)
    return out


def arp(prog, lo, hi, vel=1.0):
    out = np.zeros(N)
    order = [0, 1, 2, 3, 2, 1, 0, 1]
    for b in range(int(LENGTH / BAR) + 2):
        t0 = b * BAR
        if t0 > hi + XFADE or t0 + BAR < lo - XFADE: continue
        ch = chord_at(prog, b)
        for i, k in enumerate(order):
            m = ch[k % 3] + 24 + (12 if k == 3 else 0)
            add(out, t0 + i * BEAT / 2, vel * tone(hz(m), 0.8, 0.28, ((1, 1.0), (2, 0.15))))
    return out


def act(name, lo, hi):
    if name == "home":
        return pad_layer(WISTFUL, lo, hi) * 0.5 + piano(WISTFUL, lo, hi, [(0, 0), (1.5, 1), (2, 2), (3, 1)], 0.5)
    if name == "build":
        k = np.clip((t_all - lo) / max(1, hi - lo), 0, 1)  # energy rises toward the title
        return (pad_layer(WISTFUL, lo, hi, 0.4) * 0.5 + piano(WISTFUL, lo, hi, [(0, 0), (1, 1), (2, 2), (3, 3)], 0.45)
                + bass(WISTFUL, lo, hi, (0, 1, 2, 3), 0.5) * (0.4 + 0.6 * k) + kick(lo, hi, (0, 2), 0.35) * k)
    if name == "app":
        return (pad_layer(BRIGHT, lo, hi, 0.5) * 0.4 + piano(BRIGHT, lo, hi, [(0, 0), (0.5, 2), (1.5, 1), (2, 3), (3, 2), (3.5, 1)], 0.42, decay=0.6)
                + bass(BRIGHT, lo, hi, (0, 1.5, 2), 0.55) + shaker(lo, hi, 0.05) + kick(lo, hi, (0,), 0.25))
    if name == "proof":
        return (pad_layer(LIFT, lo, hi, 0.6) * 0.4 + arp(LIFT, lo, hi, 0.32) + bass(LIFT, lo, hi, (0, 1, 2, 3), 0.55)
                + kick(lo, hi, (0, 2), 0.42) + shaker(lo, hi, 0.06))
    if name == "end":
        return (pad_layer(HOME_END, lo, hi, 0.5, 0) * 0.55 + pad_layer(HOME_END, lo, hi, 0.0, -1) * 0.25
                + piano(HOME_END, lo, hi, [(0, 0), (1, 2), (2, 3), (3, 1)], 0.5, decay=1.2) + bass(HOME_END, lo, hi, (0,), 0.5))
    raise ValueError(name)


mix = np.zeros(N)
for i, (name, lo) in enumerate(ACTS):
    hi = ACTS[i + 1][1] if i + 1 < len(ACTS) else LENGTH
    layer = act(name, lo, hi)
    # Equal-power blend: in over XFADE before the act starts, out over XFADE after it ends.
    fin = np.clip((t_all - (lo - XFADE / 2)) / XFADE, 0, 1) if i else np.ones(N)
    fout = np.clip(((hi + XFADE / 2) - t_all) / XFADE, 0, 1) if i + 1 < len(ACTS) else np.ones(N)
    mix += layer * np.sin(fin * np.pi / 2) * np.cos((1 - fout) * np.pi / 2)

# Gentle top-end roll-off, fade in and out, then set the level: peaks at -18 dBFS.
mix = sosfilt(butter(2, 7000, "lowpass", fs=SR, output="sos"), mix)
mix *= np.clip(t_all / 1.5, 0, 1) * np.clip((LENGTH - t_all) / 3.0, 0, 1)
mix = mix[: int(LENGTH * SR)]
mix *= 10 ** (-18 / 20) / np.max(np.abs(mix))
stereo = np.stack([mix, np.roll(mix, int(0.012 * SR))], axis=1)  # a little width

os.makedirs(os.path.join(HERE, "out"), exist_ok=True)
from scipy.io import wavfile
wavfile.write(os.path.join(HERE, "out", "music.wav"), SR, (stereo * 32767).astype(np.int16))
w = int(2 * SR)
rms = [20 * np.log10(np.sqrt(np.mean(mix[i:i + w] ** 2)) + 1e-9) for i in range(0, len(mix) - w, w)]
print(f"out/music.wav  {LENGTH:.1f} s  peak -18.0 dBFS  RMS per 2 s: min {min(rms):.1f}, max {max(rms):.1f} dBFS")
for name, lo in ACTS:
    i = int((lo + 6) / 2)
    print(f"  {name:6} from {lo:6.1f} s  RMS {rms[min(i, len(rms) - 1)]:.1f} dBFS")
