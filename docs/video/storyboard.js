// Gate 2: the storyboard. One key frame per shot in docs/demo-video.md, rendered from the film code.
// The real app carries the solution (App); Paper (stop motion), Maya and Code frame it.
import { C } from "./maya.js";
import { W, H, rr, text } from "./scenes/common.js";
import { kitchen, lunch, night } from "./scenes/maya-scenes.js";
import { district } from "./scenes/district.js";
import { codeSeal } from "./scenes/code.js";
import { scrapKit, scrapTools, scrapFamily, scrapEnd, scrapSignOff } from "./scenes/scrap.js";
import { hypeTitle, hypeGate, hypeMontage } from "./scenes/hype.js";
import { appSetup, appHelp, appLock, appEarn, appSees, appApple } from "./scenes/app.js";
import { timeline } from "./film.js";

export const SIZE = [2400, 2630];

const LOOK = { App: C.pine, Scrapbook: C.amber, Hype: "#0f2219", Maya: C.berry, Code: "#3d5a4c" };
const mmss = (s) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, "0")}`;

// [shot, look, rubric, title, action, scene, key time]
const KEYS = [
  ["1", "Scrapbook", "Ideology", "Mom's every day", "Her kit stuck in as stickers, handwritten notes.", scrapKit, 7.6],
  ["2a", "Maya", "Ideology", "6:40 a.m.", "Tired Maya logs numbers at the kitchen table.", kitchen, 5.5],
  ["2b", "Maya", "Ideology", "Lunch", "Mom's four texts; Texas HB 1481 goes up.", lunch, 8.6],
  ["2c", "Maya", "Ideology, Impact", "2 a.m.", "She sits up slowly: \"I can do this.\"", night, 8.2],
  ["2d", "Hype", "Impact", "Our district", "TX-22, then the whole U.S.; sources on screen.", district, 10.5],
  ["3", "Hype", "Structure", "Title", "Sprout bursts up; the name slams in.", hypeTitle, 5.4],
  ["4", "App", "Impact, UI, Code", "Who's it for?", "Setup beside SetupView and CareStage.", appSetup, 5],
  ["5", "App", "Function, UI, Code", "Feeling off?", "Step tracker, real help flow, code per step.", appHelp, 5.8],
  ["6", "App", "Function, Code", "Grown-up passcode", "Keypad beside ParentLock's salted hash.", appLock, 6.5],
  ["7", "Scrapbook", "UI, Code", "Real-life tools", "Polaroids, with their code taped underneath.", scrapTools, 9],
  ["7b", "App", "Function, Code", "Built on Apple", "Apple Health import; Apple Intelligence, checked.", appApple, 8.5],
  ["8", "App", "Impact, Code", "Earn it", "Your Path beside SkillPathView.", appEarn, 7.2],
  ["9a", "Scrapbook", "Function", "Mom answers", "\"On my way!\"; the lunch texts scribbled out.", scrapFamily, 8.6],
  ["9b", "Code", "Code", "How it's sealed", "Maya's phone → encryptedValues → Mom's.", codeSeal, 4.2],
  ["10", "App", "Impact, Code", "Only your family", "What family sees, field by field; not Apple.", appSees, 7.6],
  ["11", "Hype", "Code, Function", "One set of rules", "CareStage.access; all 198 tests scroll past, green.", hypeGate, 9],
  ["12a", "Hype", "Function, UI", "Everything else", "13 features with their Swift types; Free.", hypeMontage, 15.6],
  ["12b", "Scrapbook", "Impact, Structure", "What's next", "Plans ticked off; the end card.", scrapEnd, 7],
  ["13", "Scrapbook", "Ideology", "Signed, Angad", "Photos of Angad and his mom; the app; his name.", scrapSignOff, 7.2],
];
const T = Object.fromEntries(timeline().map((s) => [s.shot, s]));
const FRAMES = KEYS.map(([shot, look, rubric, title, action, scene, at]) => ({ shot, look, rubric, title, action, time: `${mmss(T[shot].start)}–${mmss(T[shot].start + T[shot].dur)}`, draw: (c) => scene.render(c, at) }));
const TOTAL = mmss(timeline().at(-1).start + timeline().at(-1).dur);

export function render(ctx, t, ASSETS) {
  ctx.fillStyle = C.sage;
  ctx.fillRect(0, 0, ...SIZE);
  text(ctx, "Storyboard", 70, 92, { size: 80, weight: 900, color: C.pine, align: "left" });
  text(ctx, `DiabetesCare demo video · ${FRAMES.length} key frames · ${TOTAL}`, 520, 96, { size: 32, weight: 700, align: "left" });
  // Legend of the looks.
  let lx = 1300;
  for (const [name, color] of Object.entries(LOOK)) { rr(ctx, lx, 74, 30, 30, 15, color, null); text(ctx, name, lx + 40, 90, { size: 26, weight: 800, align: "left" }); lx += 190; }
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
    // Look tag in the frame's corner.
    ctx.font = "900 20px Nunito"; const tw = ctx.measureText(f.look).width + 28;
    rr(ctx, x + 12, y + 12, tw, 34, 17, LOOK[f.look], null);
    text(ctx, f.look, x + 12 + tw / 2, y + 30, { size: 20, weight: 900, color: "#ffffff" });
    text(ctx, f.shot, x + 8, y + h + 40, { size: 30, weight: 900, color: C.berry, align: "left" });
    text(ctx, f.title, x + 70, y + h + 40, { size: 30, weight: 900, color: C.pine, align: "left" });
    text(ctx, f.action, x + 8, y + h + 84, { size: 22, weight: 700, align: "left" });
    text(ctx, `${f.time} · ${f.rubric}`, x + 8, y + h + 124, { size: 22, weight: 800, color: "#6f8277", align: "left" });
  });
}
