// The film in order: one entry per shot in docs/demo-video.md. `dur` is the shot's length in the cut,
// fitted to Angad's recorded line; when it's shorter than the scene's own `duration`, the scene plays
// faster to fit. Each shot flows into the next with its `in` transition (an ffmpeg xfade), overlapping
// by XF seconds. `cap` is how its caption is drawn: "card" (the bottom card), "float" (big words, a
// phrase at a time, at x/y) or "paper" (a phrase at a time on a taped strip).
export const XF = 0.5;
export const FILM = [
  { shot: "1", scene: "scrapKit", dur: 8, cap: { mode: "paper", x: 960, y: 960 } },
  { shot: "2a", scene: "kitchen", dur: 6, in: "fade", cap: { mode: "float", x: 1450, y: 470, w: 760 } },
  { shot: "2b", scene: "lunch", dur: 9.5, in: "smoothleft", cap: { mode: "float", x: 330, y: 560, w: 560 } },
  { shot: "2c", scene: "night", dur: 7, in: "fade", cap: { mode: "float", x: 1450, y: 300, w: 760 } },
  { shot: "2d", scene: "district", dur: 12.5, in: "fadeblack", cap: { mode: "float", x: 560, y: 930, w: 1000 } },
  { shot: "3", scene: "hypeTitle", dur: 10.5, in: "circleopen", cap: { mode: "float", x: 960, y: 900, w: 1500 } },
  { shot: "4", scene: "appSetup", dur: 9, in: "fade" },
  { shot: "5", scene: "appHelp", dur: 9.5, in: "smoothleft" },
  { shot: "6", scene: "appLock", dur: 9.5, in: "smoothleft" },
  { shot: "7", scene: "scrapTools", dur: 8.5, in: "fade", cap: { mode: "paper", x: 960, y: 965 } },
  { shot: "7b", scene: "appApple", dur: 10.5, in: "fade" },
  { shot: "8", scene: "appEarn", dur: 8.5, in: "smoothleft" },
  { shot: "9a", scene: "scrapFamily", dur: 8.5, in: "fade", cap: { mode: "paper", x: 960, y: 965 } },
  { shot: "9b", scene: "codeSeal", dur: 10.5, in: "smoothleft" },
  { shot: "10", scene: "appSees", dur: 8.5, in: "smoothleft" },
  { shot: "11", scene: "hypeGate", dur: 11.5, in: "fade" },
  { shot: "12a", scene: "hypeMontage", dur: 15.5, in: "fade" },
  { shot: "12b", scene: "scrapEnd", dur: 14.5, in: "circleopen", cap: { mode: "paper", x: 1240, y: 965 } },
  { shot: "13", scene: "scrapSignOff", dur: 6.5, in: "slideleft", cap: { mode: "paper", x: 1240, y: 900 } },
];

// Where each shot starts in the cut (after the overlaps), for sound and captions.
export const timeline = () => { let at = 0; return FILM.map((s, i) => { const e = { ...s, start: at }; at += s.dur - (i < FILM.length - 1 ? XF : 0); return e; }); };
