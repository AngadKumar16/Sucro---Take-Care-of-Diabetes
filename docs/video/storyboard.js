// Gate 2: the storyboard. One key frame per shot in docs/demo-video.md, rendered from the film code.
// Maya's shots are her real clips at a key time; recorded shots use the app's real screenshots.
import { C } from "./maya.js";
import { W, H, rr, text, caption, FONT } from "./scenes/common.js";
import { kitchen, lunch, night, title, cheer, proud } from "./scenes/maya-scenes.js";

export const SIZE = [2400, 2140];

const LINES = {
  1: "My mom has type 1 diabetes. I've watched her manage it every day, and I kept thinking about kids who get it young.",
  4: "First it asks who it's for: a kid, a teen, an adult, or a parent. The whole app changes with the answer.",
  5: "A kid gets a simpler screen. Feeling off? Get Help walks them through it, starts a 15-minute recheck, and calls Mom in one tap.",
  6: "Risky things need a grown-up's passcode. Safety help never does.",
  7: "Kids earn independence by learning. Each skill unlocks something, and when they're ready, a grown-up approves the move up.",
  8: "Mom doesn't have to text all day. She gets an alert when it matters, and fewer as Maya grows.",
  9: "Her health information is never shared outside her family. It's end-to-end encrypted, so not even Apple can read it.",
  10: "Every rule about who can do what lives in one function, so no screen has a back door.",
};

// Recorded footage gets a chip so it's clear what's filmed and what's animated.
function chip(ctx, s, color = C.pine) {
  ctx.font = FONT(900, 38);
  const w = ctx.measureText(s).width + 60;
  rr(ctx, 56, 52, w, 68, 34, color, null);
  text(ctx, s, 56 + w / 2, 87, { size: 38, weight: 900, color: "#ffffff" });
}

// Draws an image to fit inside a box, keeping its shape, with rounded corners.
function fit(ctx, img, x, y, w, h, r = 28) {
  const k = Math.min(w / img.width, h / img.height), iw = img.width * k, ih = img.height * k;
  const ix = x + (w - iw) / 2, iy = y + (h - ih) / 2;
  ctx.save(); ctx.beginPath(); ctx.roundRect(ix, iy, iw, ih, r); ctx.clip();
  ctx.drawImage(img, ix, iy, iw, ih); ctx.restore();
  ctx.beginPath(); ctx.roundRect(ix, iy, iw, ih, r); ctx.lineWidth = 4; ctx.strokeStyle = C.ink; ctx.stroke();
}

const bg = (ctx, c = C.sage) => { ctx.fillStyle = c; ctx.fillRect(0, 0, W, H); };

const FRAMES = [
  { shot: "1", time: "0:00–0:12", rubric: "Ideology", title: "Why I built it", action: "Angad on camera: his mom has type 1.", draw(ctx) {
    bg(ctx, "#f1f4e9");
    // A phone on a tripod, filming.
    ctx.lineWidth = 10; ctx.strokeStyle = C.ink; ctx.lineCap = "round";
    ctx.beginPath(); ctx.moveTo(960, 560); ctx.lineTo(860, 840); ctx.moveTo(960, 560); ctx.lineTo(1060, 840); ctx.moveTo(960, 560); ctx.lineTo(960, 850); ctx.stroke();
    rr(ctx, 860, 340, 200, 230, 30, C.cream, C.ink, 6);
    ctx.beginPath(); ctx.arc(960, 455, 46, 0, Math.PI * 2); ctx.fillStyle = C.mint; ctx.fill(); ctx.lineWidth = 6; ctx.stroke();
    ctx.beginPath(); ctx.arc(1010, 380, 10, 0, Math.PI * 2); ctx.fillStyle = C.berry; ctx.fill();
    chip(ctx, "Live action", C.berry);
    caption(ctx, LINES[1]);
  } },
  { shot: "2a", time: "0:12–0:21", rubric: "Ideology", title: "6:40 a.m.", action: "Maya, tired, logs numbers at the kitchen table.", draw: (ctx) => kitchen.render(ctx, 5.5) },
  { shot: "2b", time: "0:21–0:30", rubric: "Ideology", title: "Lunch", action: "Mom texts \"What's your number?\" four times.", draw: (ctx) => lunch.render(ctx, 6) },
  { shot: "2c", time: "0:30–0:40", rubric: "Ideology, Impact", title: "2 a.m.", action: "Alarm, pillow, then: \"I can do this. Just let me.\"", draw: (ctx) => night.render(ctx, 8.2) },
  { shot: "3", time: "0:40–0:48", rubric: "Structure", title: "Title", action: "The sprout grows and wipes to the name.", draw: (ctx) => title.render(ctx, 6.6) },
  { shot: "4", time: "0:48–1:00", rubric: "Impact, UI", title: "Who's it for?", action: "Setup screen, then Scene 1: Today updating.", draw(ctx, A) {
    bg(ctx); fit(ctx, A.kidToday, 140, 150, 480, 740); fit(ctx, A.scene1, 700, 170, 1100, 760);
    chip(ctx, "Simulator + Scene 1"); caption(ctx, LINES[4]);
  } },
  { shot: "5", time: "1:00–1:18", rubric: "Function, UI", title: "Feeling off?", action: "Kid's Get Help, then Scene 2: juice and the recheck.", draw(ctx, A) {
    bg(ctx); fit(ctx, A.kidHelp, 140, 150, 480, 740); fit(ctx, A.scene2, 700, 170, 1100, 760);
    chip(ctx, "Simulator + Scene 2"); caption(ctx, LINES[5]);
  } },
  { shot: "6", time: "1:18–1:26", rubric: "Function", title: "Grown-up passcode", action: "Log › Add Insulin asks for the passcode.", draw(ctx) {
    bg(ctx);
    rr(ctx, 720, 100, 480, 860, 70, C.cream, C.ink, 6);
    text(ctx, "Ask a grown-up", 960, 250, { size: 44, weight: 900 });
    for (let i = 0; i < 4; i++) { ctx.beginPath(); ctx.arc(870 + i * 60, 330, 14, 0, Math.PI * 2); ctx.fillStyle = i < 2 ? C.ink : "#ffffff"; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = C.ink; ctx.stroke(); }
    for (let r = 0; r < 4; r++) for (let c = 0; c < 3; c++) if (r < 3 || c === 1) rr(ctx, 790 + c * 120, 400 + r * 120, 100, 92, 30, C.sage, C.ink, 3);
    chip(ctx, "Simulator"); caption(ctx, LINES[6]);
  } },
  { shot: "7", time: "1:26–1:44", rubric: "Impact", title: "Earn it", action: "Quiz, skill unlocked, Maya cheers, move up to Teen.", draw(ctx, A) {
    bg(ctx); fit(ctx, A.quiz, 160, 150, 480, 740);
    const off = document.createElement("canvas"); off.width = W; off.height = H; cheer.render(off.getContext("2d"), 1.2);
    fit(ctx, off, 720, 190, 1080, 620);
    chip(ctx, "Simulator + Maya"); caption(ctx, LINES[7]);
  } },
  { shot: "8", time: "1:44–1:56", rubric: "Function", title: "Mom stops texting", action: "Scene 3: the sealed letter, then the parent's phone.", draw(ctx, A) {
    bg(ctx); fit(ctx, A.scene3, 120, 170, 1100, 760); fit(ctx, A.parentPhone, 1300, 150, 480, 740);
    chip(ctx, "Scene 3 + simulator"); caption(ctx, LINES[8]);
  } },
  { shot: "9", time: "1:56–2:12", rubric: "Impact", title: "Only your family", action: "Sealed letter, then See What Family Sees.", draw(ctx, A) {
    bg(ctx); fit(ctx, A.letter, 100, 200, 1180, 664); fit(ctx, A.familySees, 1360, 150, 460, 740);
    text(ctx, "Only your family. No one else.", 690, 160, { size: 54, weight: 900, color: C.pine });
    caption(ctx, LINES[9]);
  } },
  { shot: "10", time: "2:12–2:34", rubric: "Code", title: "The code", action: "Xcode: one rule function, encryption, tests.", draw(ctx) {
    bg(ctx, "#1d2a24");
    rr(ctx, 140, 130, 1640, 780, 28, "#24352d", "#3d5a4c", 4);
    const code = [
      ["func access(to feature: Feature, completed: Set<Skill>) -> FeatureAccess {", "#e9efe9"],
      ["    switch (self, feature) {", "#e9efe9"],
      ["    case (.adult, _):                     base = .open", "#9fd8b4"],
      ["    case (.kid, .quickBolus):             base = .hidden", "#f0a58f"],
      ["    case (.kid, .logInsulin), (.kid, .changeSite), ...:  base = .parent", "#f3cf8a"],
      ["    case (.teen, .logInsulin), (.teen, .changeSite), ...: base = .open", "#9fd8b4"],
      ["    case (_, .editThresholds), (_, .clearData), ...:    base = .parent", "#f3cf8a"],
      ["    }", "#e9efe9"],
      ["    // A kid's skills can open what the stage keeps behind the passcode.", "#7f9a8a"],
      ["    if base == .parent, skills ⊆ completed { return .open }", "#e9efe9"],
    ];
    code.forEach(([line, color], i) => { ctx.font = "500 34px ui-monospace, 'SF Mono', Menlo, monospace"; ctx.fillStyle = color; ctx.textAlign = "left"; ctx.textBaseline = "middle"; ctx.fillText(line, 190, 210 + i * 66); });
    chip(ctx, "Xcode recording"); caption(ctx, LINES[10]);
  } },
  { shot: "11", time: "2:34–2:50", rubric: "Structure", title: "She's got this", action: "Maya proud, then Angad closes on camera.", draw: (ctx) => proud.render(ctx, 2) },
];

export function render(ctx, t, ASSETS) {
  ctx.fillStyle = C.sage;
  ctx.fillRect(0, 0, ...SIZE);
  text(ctx, "Storyboard", 70, 92, { size: 80, weight: 900, color: C.pine, align: "left" });
  text(ctx, "DiabetesCare demo video · 13 key frames · 2:50 · animated by the film code, recorded shots marked", 520, 96, { size: 32, weight: 700, align: "left" });
  const off = document.createElement("canvas");
  off.width = W; off.height = H;
  const octx = off.getContext("2d");
  FRAMES.forEach((f, i) => {
    const col = i % 4, row = Math.floor(i / 4);
    const x = 60 + col * 580, y = 160 + row * 494, w = 540, h = 304;
    rr(ctx, x - 14, y - 14, w + 28, h + 172, 30, "#ffffff", null);
    octx.save(); octx.clearRect(0, 0, W, H); f.draw(octx, ASSETS); octx.restore();
    ctx.save(); ctx.beginPath(); ctx.roundRect(x, y, w, h, 18); ctx.clip(); ctx.drawImage(off, x, y, w, h); ctx.restore();
    ctx.beginPath(); ctx.roundRect(x, y, w, h, 18); ctx.lineWidth = 3; ctx.strokeStyle = C.ink; ctx.stroke();
    text(ctx, f.shot, x + 8, y + h + 40, { size: 30, weight: 900, color: C.berry, align: "left" });
    text(ctx, f.title, x + 58, y + h + 40, { size: 30, weight: 900, color: C.pine, align: "left" });
    text(ctx, f.action, x + 8, y + h + 84, { size: 22, weight: 700, align: "left" });
    text(ctx, `${f.time} · ${f.rubric}`, x + 8, y + h + 124, { size: 22, weight: 800, color: "#6f8277", align: "left" });
  });
}
