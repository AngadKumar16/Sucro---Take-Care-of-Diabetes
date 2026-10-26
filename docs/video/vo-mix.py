# Places Angad's voiceover lines on the cut and mixes them over the music: python3 vo-mix.py
# Put one recording per line in assets/vo/, named by shot (1.m4a, 2a.m4a, ... 13.m4a; wav, m4a or mp3).
# Each line starts 0.3 s into its shot; leading and trailing silence is trimmed; the music dips
# under the voice. Warns when a line runs past its shot. Writes out/final/DiabetesCare-CAC-2026-vo.mp4.
import glob, json, os, subprocess
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
SR = 48000
shots = json.loads(subprocess.check_output(["node", "-e", "import('./film.js').then(m=>console.log(JSON.stringify(m.timeline())))"], cwd=HERE))
length = shots[-1]["start"] + shots[-1]["dur"]

def load(path):
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"])
    return np.frombuffer(raw, dtype=np.float32).copy()

music = load(os.path.join(HERE, "out", "music.wav"))
n = int(length * SR)
voice = np.zeros(n, dtype=np.float32)
missing = []
for i, s in enumerate(shots):
    files = [f for f in glob.glob(os.path.join(HERE, "assets", "vo", s["shot"] + ".*")) if f.rsplit(".", 1)[1].lower() in ("wav", "m4a", "mp3", "aiff", "caf")]
    if not files: missing.append(s["shot"]); continue
    x = load(files[0])
    # Trim silence (below -45 dBFS, smoothed over 20 ms) at both ends, keeping 60 ms of air.
    env = np.convolve(np.abs(x), np.ones(960) / 960, mode="same")
    loud = np.where(env > 10 ** (-45 / 20))[0]
    if len(loud): x = x[max(0, loud[0] - 2880): loud[-1] + 2880]
    x = x / (np.max(np.abs(x)) + 1e-9) * 10 ** (-3 / 20)  # each line to -3 dBFS peak, even levels
    at = s["start"] + 0.3
    end_of_shot = s["start"] + s["dur"] - (0.5 if i < len(shots) - 1 else 0)
    if at + len(x) / SR > end_of_shot:
        print(f"  {s['shot']}: line is {len(x) / SR:.1f} s, runs {at + len(x) / SR - end_of_shot:.1f} s past its shot (a faster take, or tell Claude to lengthen the shot)")
    a = int(at * SR); voice[a: a + len(x)] += x[: n - a]
if missing: print("no recording yet for:", ", ".join(missing))

# Duck: the music drops 8 dB under the voice, easing in and out over 0.3 s.
active = (np.convolve(np.abs(voice), np.ones(4800) / 4800, mode="same") > 10 ** (-40 / 20)).astype(np.float32)
ease = np.ones(int(0.3 * SR)) / int(0.3 * SR)
duck = 1 - (1 - 10 ** (-8 / 20)) * np.clip(np.convolve(active, ease, mode="same"), 0, 1)
mix = music[:n] * duck[: len(music[:n])] + voice[: len(music[:n])]
mix = mix / max(1.0, np.max(np.abs(mix)) / 0.95)

wav = os.path.join(HERE, "out", "final", "mix.wav")
from scipy.io import wavfile
wavfile.write(wav, SR, (np.stack([mix, mix], axis=1) * 32767).astype(np.int16))
out = os.path.join(HERE, "out", "final", "DiabetesCare-CAC-2026-vo.mp4")
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", os.path.join(HERE, "out", "final", "film.mp4"), "-i", wav, "-map", "0:v", "-map", "1:a",
                "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", out], check=True)
print("wrote", out)
