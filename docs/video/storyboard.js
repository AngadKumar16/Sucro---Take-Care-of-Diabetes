// Gate 2: the storyboard. One key frame per shot in docs/demo-video.md, rendered from the film code.
// The real app carries the solution (App); Paper (stop motion), Maya and Code frame it.
import { C } from "./maya.js";
import { W, H, rr, text } from "./scenes/common.js";
import { kitchen, lunch, night } from "./scenes/maya-scenes.js";
import { paperKit, paperTitle, paperDeal, paperEnd } from "./scenes/paper.js";
import { codeSeal, codeGate } from "./scenes/code.js";
import { appSetup, appHelp, appLock, appTools, appEarn, appFamily, appSees, appMontage } from "./scenes/app.js";

export const SIZE = [2400, 2140];

const LOOK = { App: C.pine, Paper: C.amber, Maya: C.berry, Code: "#3d5a4c" };

const FRAMES = [
  { shot: "1", look: "Paper", time: "0:00–0:10", rubric: "Ideology", title: "Mom's kit", action: "Her meter, pen, sensor, juice land on the table.", draw: (c) => paperKit.render(c, 7.6) },
  { shot: "2a", look: "Maya", time: "0:10–0:18", rubric: "Ideology", title: "6:40 a.m.", action: "Tired Maya logs numbers at the kitchen table.", draw: (c) => kitchen.render(c, 5.5) },
  { shot: "2b", look: "Maya", time: "0:18–0:26", rubric: "Ideology", title: "Lunch", action: "Mom texts \"What's your number?\" four times.", draw: (c) => lunch.render(c, 6) },
  { shot: "2c", look: "Maya", time: "0:26–0:35", rubric: "Ideology, Impact", title: "2 a.m.", action: "Alarm, pillow, then \"I can do this.\"", draw: (c) => night.render(c, 8.2) },
  { shot: "3", look: "Paper", time: "0:35–0:41", rubric: "Structure", title: "Title", action: "Paper sprout blooms; the name is laid tile by tile.", draw: (c) => paperTitle.render(c, 5.4) },
  { shot: "4", look: "App", time: "0:41–0:51", rubric: "Impact, UI", title: "Who's it for?", action: "Setup → Kid → passcode → the meter ruler.", draw: (c) => appSetup.render(c, 8.4) },
  { shot: "5", look: "App", time: "0:51–1:07", rubric: "Function, UI", title: "Feeling off?", action: "Get Help, 15 g, recheck in the Dynamic Island.", draw: (c) => appHelp.render(c, 13.2) },
  { shot: "6", look: "Code", time: "1:07–1:17", rubric: "Function, Code", title: "Grown-up passcode", action: "Real keypad, ruler ranges, then the salted hash.", draw: (c) => appLock.render(c, 7.6) },
  { shot: "7", look: "App", time: "1:17–1:29", rubric: "UI", title: "Real-life tools", action: "Kitchen scale, insulin pen, body map, test tubes.", draw: (c) => appTools.render(c, 1.6) },
  { shot: "8", look: "App", time: "1:29–1:43", rubric: "Impact", title: "Earn it", action: "Plant, Skill Learned, Move Up to Teen.", draw: (c) => appEarn.render(c, 11.4) },
  { shot: "9a", look: "App", time: "1:43–1:53", rubric: "Function", title: "Mom answers", action: "Maya asked for help; \"On my way!\" in one tap.", draw: (c) => appFamily.render(c, 3.6) },
  { shot: "9b", look: "Code", time: "1:53–1:59", rubric: "Code", title: "How it's sealed", action: "encryptedValues typed; the letter flies over it.", draw: (c) => codeSeal.render(c, 4.6) },
  { shot: "10", look: "App", time: "1:59–2:13", rubric: "Impact", title: "Only your family", action: "Real See What Family Sees; not us, not Apple.", draw: (c) => appSees.render(c, 10.8) },
  { shot: "11", look: "Code", time: "2:13–2:33", rubric: "Code, Function", title: "One set of rules", action: "CareStage.access, 207 tests, the app running.", draw: (c) => codeGate.render(c, 21) },
  { shot: "12a", look: "App", time: "2:33–2:40", rubric: "Structure", title: "The real app", action: "Plant, scale, recap, sick day, Teen: like photos.", draw: (c) => appMontage.render(c, 4.2) },
  { shot: "12b", look: "Paper", time: "2:40–2:47", rubric: "Structure", title: "End card", action: "Plant in bloom; free, honest status, next steps.", draw: (c) => paperEnd.render(c, 5) },
];

export function render(ctx, t, ASSETS) {
  ctx.fillStyle = C.sage;
  ctx.fillRect(0, 0, ...SIZE);
  text(ctx, "Storyboard", 70, 92, { size: 80, weight: 900, color: C.pine, align: "left" });
  text(ctx, "DiabetesCare demo video · 16 key frames · 2:47 · real app footage in 9 of them", 520, 96, { size: 32, weight: 700, align: "left" });
  // Legend of the looks.
  let lx = 1720;
  for (const [name, color] of Object.entries(LOOK)) { rr(ctx, lx, 74, 30, 30, 15, color, null); text(ctx, name, lx + 40, 90, { size: 26, weight: 800, align: "left" }); lx += 160; }
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
