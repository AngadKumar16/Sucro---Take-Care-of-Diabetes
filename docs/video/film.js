// The film in order: one entry per shot in docs/demo-video.md. `dur` is the shot's length in the cut;
// when it's shorter than the scene's own `duration`, the scene plays faster to fit. Each shot flows
// into the next with its `in` transition (an ffmpeg xfade), overlapping by XF seconds.
export const XF = 0.5;
export const FILM = [
  { shot: "1", scene: "scrapKit", dur: 8.5 },
  { shot: "2a", scene: "kitchen", dur: 6, in: "fade" },
  { shot: "2b", scene: "lunch", dur: 9.5, in: "smoothleft" },
  { shot: "2c", scene: "night", dur: 7.5, in: "fade" },
  { shot: "2d", scene: "district", dur: 13, in: "fadeblack" },
  { shot: "3", scene: "hypeTitle", dur: 10.5, in: "circleopen" },
  { shot: "4", scene: "appSetup", dur: 8, in: "fade" },
  { shot: "5", scene: "appHelp", dur: 10.5, in: "smoothleft" },
  { shot: "6", scene: "appLock", dur: 10, in: "smoothleft" },
  { shot: "7", scene: "scrapTools", dur: 9, in: "fade" },
  { shot: "7b", scene: "appApple", dur: 11, in: "fade" },
  { shot: "8", scene: "appEarn", dur: 9.5, in: "smoothleft" },
  { shot: "9a", scene: "scrapFamily", dur: 8.5, in: "fade" },
  { shot: "9b", scene: "codeSeal", dur: 6, in: "smoothleft" },
  { shot: "10", scene: "appSees", dur: 9.5, in: "smoothleft" },
  { shot: "11", scene: "hypeGate", dur: 12, in: "fade" },
  { shot: "12a", scene: "hypeMontage", dur: 16.5, in: "fade" },
  { shot: "12b", scene: "scrapEnd", dur: 12, in: "circleopen" },
  { shot: "13", scene: "scrapSignOff", dur: 7, in: "slideleft" },
];

// Where each shot starts in the cut (after the overlaps), for sound and captions.
export const timeline = () => { let at = 0; return FILM.map((s, i) => { const e = { ...s, start: at }; at += s.dur - (i < FILM.length - 1 ? XF : 0); return e; }); };
