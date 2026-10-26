// The film in order: one entry per shot in docs/demo-video.md. `dur` is the shot's length in the cut;
// when it's shorter than the scene's own `duration`, the scene plays faster to fit.
export const FILM = [
  { shot: "1", scene: "scrapKit", dur: 10 },
  { shot: "2a", scene: "kitchen", dur: 8 },
  { shot: "2b", scene: "lunch", dur: 8 },
  { shot: "2c", scene: "night", dur: 9 },
  { shot: "3", scene: "hypeTitle", dur: 6 },
  { shot: "4", scene: "appSetup", dur: 10 },
  { shot: "5", scene: "hypeHelp", dur: 14 },
  { shot: "6", scene: "appLock", dur: 10 },
  { shot: "7", scene: "scrapTools", dur: 12 },
  { shot: "8", scene: "appEarn", dur: 14 },
  { shot: "9a", scene: "scrapFamily", dur: 10 },
  { shot: "9b", scene: "codeSeal", dur: 6 },
  { shot: "10", scene: "appSees", dur: 14 },
  { shot: "11", scene: "hypeGate", dur: 15 },
  { shot: "12a", scene: "hypeMontage", dur: 12 },
  { shot: "12b", scene: "scrapEnd", dur: 12 },
];

// Where each shot starts in the cut, for sound and captions.
export const timeline = () => { let at = 0; return FILM.map((s) => { const e = { ...s, start: at }; at += s.dur; return e; }); };
