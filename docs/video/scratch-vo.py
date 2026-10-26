# Scratch voiceover for reviewing drafts: macOS `say` reads each shot's line at its start (+0.5 s),
# so the timing can be judged before Angad records the real one. Writes out/draft/scratch-vo.wav.
import json, re, subprocess, tempfile, os

here = os.path.dirname(os.path.abspath(__file__))
film = open(os.path.join(here, "film.js")).read()
shots = re.findall(r'shot: "(\w+)", scene: "\w+", dur: (\d+)', film)
lines = {}
for l in open(os.path.join(here, "..", "demo-video.md")):
    if l.startswith("| ") and l[2].isdigit():
        c = [x.strip() for x in l.strip().strip("|").split("|")]
        lines[c[0]] = c[-1].strip('"')
tmp = tempfile.mkdtemp()
inputs, delays, at = [], [], 0.0
for i, (shot, dur) in enumerate(shots):
    aiff = os.path.join(tmp, f"{i}.aiff")
    subprocess.run(["say", "-r", "160", "-o", aiff, lines[shot]], check=True)
    inputs += ["-i", aiff]
    delays.append(f"[{i}]adelay={int((at + 0.5) * 1000)}:all=1[a{i}]")
    at += int(dur)
mix = ";".join(delays) + ";" + "".join(f"[a{i}]" for i in range(len(shots))) + f"amix=inputs={len(shots)}:normalize=0,apad=whole_dur={at}"
out = os.path.join(here, "out", "draft", "scratch-vo.wav")
subprocess.run(["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", mix, "-ar", "48000", out], check=True)
print("wrote", out, at, "s")
