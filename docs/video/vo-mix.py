# Places Angad's voiceover lines on the cut and times the captions to them: python3 vo-mix.py
# One recording per line in assets/vo/, named by shot (1.m4a, 2a.m4a, ... 13.m4a); a second part of
# a line goes in <shot>-2.m4a and follows the first after a short pause. Each line starts 0.3 s into
# its shot, with leading and trailing silence trimmed and every line brought to the same level.
#   out/captions.json   each shot's caption phrases, timed to the pauses in the voice (draft.mjs reads it)
#   out/final/captions.srt
#   out/final/voice.wav, and out/final/DiabetesCare-CAC-2026.mp4 when out/final/film.mp4 exists
# No music by default (`--music` lays out/music.wav under the voice, ducked 8 dB).
import glob, json, os, re, subprocess, sys
import numpy as np
from scipy.io import wavfile

HERE = os.path.dirname(os.path.abspath(__file__))
SR = 48000
shots = json.loads(subprocess.check_output(["node", "-e", "import('./film.js').then(m=>console.log(JSON.stringify(m.timeline())))"], cwd=HERE))
length = shots[-1]["start"] + shots[-1]["dur"]
lines = {}
for l in open(os.path.join(HERE, "..", "demo-video.md")):
    if re.match(r"^\| [0-9]+[a-z]? \|", l):
        c = [x.strip() for x in l.strip().strip("|").split(" | ")]
        lines[c[0]] = c[-1].strip('"')


def load(path):
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"])
    return np.frombuffer(raw, dtype=np.float32).copy()


def envelope(x):
    return np.convolve(np.abs(x), np.ones(960) / 960, mode="same")


def trim(x):
    env = envelope(x)
    loud = np.where(env > np.max(env) * 0.06)[0]
    return x[max(0, loud[0] - 2880): loud[-1] + 2880] if len(loud) else x


def phrases(text):
    """Caption chunks: split at punctuation; a long piece breaks before a joining word (and, with,
    that…) near its middle, never inside a number; scraps merge with a neighbour."""
    parts = [p.strip() for p in re.findall(r"(?:[^.,:;?!]|[.,](?=\d))+[.,:;?!]?", text) if p.strip()]
    joins = (" and ", " or ", " with ", " that ", " unless ", " because ", " so ", " to ", " for ", " if ")
    out = []
    for p in parts:
        while len(p) > 52:
            mid = len(p) / 2
            cands = [i for j in joins for i in [m.start() for m in re.finditer(re.escape(j), p)] if 0.3 * len(p) < i < 0.75 * len(p)]
            if not cands: cands = [i for i, ch in enumerate(p) if ch == " " and not p[i + 1:i + 2].isdigit() and 0.3 * len(p) < i < 0.7 * len(p)]
            cut = min(cands, key=lambda i: abs(i - mid))
            out.append(p[:cut]); p = p[cut + 1:]
        if out and (len(p) < 12 or len(out[-1]) < 12) and len(out[-1]) + len(p) < 46: out[-1] += " " + p
        else: out.append(p)
    return out


def pauses(x):
    """Midpoints of quiet gaps (>120 ms) inside the speech, in seconds."""
    env = envelope(x); quiet = env < np.max(env) * 0.05
    gaps, i = [], 0
    while i < len(quiet):
        if quiet[i]:
            j = i
            while j < len(quiet) and quiet[j]: j += 1
            if (j - i) / SR > 0.12 and i > 0 and j < len(quiet): gaps.append((i + j) / 2 / SR)
            i = j
        else: i += 1
    return gaps


n = int(length * SR)
voice = np.zeros(n, dtype=np.float32)
captions, srt, missing = {}, [], []
for k, s in enumerate(shots):
    parts = []
    for suffix in ("", "-2"):
        f = [g for g in glob.glob(os.path.join(HERE, "assets", "vo", s["shot"] + suffix + ".*")) if g.rsplit(".", 1)[1].lower() in ("wav", "m4a", "mp3", "aiff", "caf")]
        if f: parts.append(trim(load(f[0])))
    if not parts: missing.append(s["shot"]); continue
    gap = np.zeros(int(0.35 * SR), dtype=np.float32)
    x = parts[0] if len(parts) == 1 else np.concatenate([parts[0], gap, parts[1]])
    x = x / (np.max(np.abs(x)) + 1e-9) * 10 ** (-3 / 20)
    at = s["start"] + 0.3
    end_of_shot = s["start"] + s["dur"] - (0.5 if k < len(shots) - 1 else 0)
    if at + len(x) / SR > end_of_shot + 0.05:
        print(f"  {s['shot']}: line runs {at + len(x) / SR - end_of_shot:.1f} s past its shot")
    a = int(at * SR); voice[a: a + len(x)] += x[: n - a]

    # Caption phrases: split the text by characters across the speech, then snap each boundary to
    # the nearest pause in the voice (within 0.6 s) so a phrase changes when Angad breathes.
    # Captions follow the first part; a second part (the slogan, 12b-2) is on the end card already, so
    # it only goes in the .srt.
    text = lines[s["shot"]]
    if len(parts) > 1:
        x1 = (len(parts[0]) + len(gap)) / len(x) * (len(x) / SR)
        srt.append((s["start"] + 0.3 + x1, s["start"] + 0.3 + len(x) / SR + 0.3, "Diabetes doesn't stop growing. DiabetesCare doesn't stop caring."))
        x_caption = parts[0]
    else:
        x_caption = x
    ph = phrases(text)
    dur = len(x_caption) / SR
    total = sum(len(p) for p in ph)
    gaps = pauses(x_caption)
    bounds, acc = [0.0], 0
    for p in ph[:-1]:
        acc += len(p)
        guess = 0.06 + (dur - 0.12) * acc / total
        near = min(gaps, key=lambda g: abs(g - guess), default=guess)
        bounds.append(near if abs(near - guess) < 0.6 and near > bounds[-1] + 0.4 else guess)
    bounds.append(dur)
    cues = [[round(0.3 + bounds[i], 2), round(0.3 + bounds[i + 1] + (0.25 if i == len(ph) - 1 else 0), 2), ph[i]] for i in range(len(ph))]
    captions[s["shot"]] = cues
    for c0, c1, txt in cues: srt.append((s["start"] + c0, s["start"] + c1, txt))

if missing: print("no recording yet for:", ", ".join(missing))
os.makedirs(os.path.join(HERE, "out", "final"), exist_ok=True)
json.dump(captions, open(os.path.join(HERE, "out", "captions.json"), "w"), indent=1)
ts = lambda x: f"{int(x // 3600):02d}:{int(x % 3600 // 60):02d}:{int(x % 60):02d},{int(round(x % 1 * 1000)) % 1000:03d}"
with open(os.path.join(HERE, "out", "final", "captions.srt"), "w") as f:
    for i, (a0, a1, txt) in enumerate(sorted(srt), 1): f.write(f"{i}\n{ts(a0)} --> {ts(a1)}\n{txt}\n\n")

mix = voice
if "--music" in sys.argv:
    music = load(os.path.join(HERE, "out", "music.wav"))[:n]
    active = (np.convolve(np.abs(voice), np.ones(4800) / 4800, mode="same") > 10 ** (-40 / 20)).astype(np.float32)
    ease = np.ones(int(0.3 * SR)) / int(0.3 * SR)
    duck = 1 - (1 - 10 ** (-8 / 20)) * np.clip(np.convolve(active, ease, mode="same"), 0, 1)
    mix = voice[: len(music)] + music * duck[: len(music)]
mix = mix / max(1.0, np.max(np.abs(mix)) / 0.95)
wav = os.path.join(HERE, "out", "final", "voice.wav")
wavfile.write(wav, SR, (np.stack([mix, mix], axis=1) * 32767).astype(np.int16))
print(f"wrote out/captions.json, out/final/captions.srt, {os.path.relpath(wav, HERE)}")
film = os.path.join(HERE, "out", "final", "film.mp4")
if os.path.exists(film):
    out = os.path.join(HERE, "out", "final", "DiabetesCare-CAC-2026.mp4")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", film, "-i", wav, "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
                    "-shortest", "-movflags", "+faststart", out], check=True)
    print("wrote", os.path.relpath(out, HERE))
