// Fig 2: the grown-up passcode. A lockbox with a keypad, five try lamps, a lockout dial and a bolt.
// Matches ParentLock: 5 wrong tries → 30 s lockout; a right code unlocks for 5 minutes; only a salted hash is kept.
import { k, helpers, page } from "./shared.mjs";

export function build(theme) {
  const WIDTH = 600, HEIGHT = 340;
  const PLATE = { x: -128, y: -66, w: 256, d: 132, r: 12 };
  const BOX = { x: -78, y: -44, w: 116, d: 82, r: 9 }, BOX_H = 44;
  const KEY = { w: 12, d: 10, h: 3 }, KEYS_X = -50, KEYS_Y = -24, PITCH = [15, 13];
  const DIAL = [12, -4], DIAL_R = 17, DIAL_Z = BOX_H, DIAL_H = 5, DIAL_TOP = BOX_H + DIAL_H;
  const BOLT = { y: -3, d: 14, z: 14, h: 12, out: 32 };
  const KEEPER = { x: BOX.x + BOX.w + 22, y: -20, w: 14, d: 34, r: 2 }, KEEPER_H = 32;
  const LAMPS = [-56, -42, -28, -14, 0].map((x) => [x, BOX.y + BOX.d + 16]);
  const LAMP_R = 4.4;

  const P = k.fitProjection([...k.boxCorners(PLATE, -15, 0), [BOX.x, BOX.y, DIAL_TOP + 4]], WIDTH, HEIGHT, { pad: 32, azimuth: 36 });
  const { at, byDepth, S, L, D, plate, labelPlate } = helpers(P);

  function box() {
    const out = [`<path class="iso-halo" d="${k.haloOf(BOX, 0, BOX_H, P)}" style="filter:blur(6px)"/>`];
    out.push(S(k.slabOf({ ...k.insetPlan(BOX, -2), r: BOX.r + 2 }, 0, 4, P, 10, 0.6), { tone: "lo" }));
    out.push(S(k.slabOf(BOX, 4, BOX_H - 4, P, 10, 1.2), { tone: "mid", inner: L(k.sideSeam(BOX, BOX_H - 7, P, 10), { tone: "faint" }) }));
    out.push(L(k.planOutline(k.insetPlan(BOX, 4), BOX_H, P, 10), { tone: "faint" }));
    out.push(D(k.corners(BOX, 5).map(([x, y]) => at([x, y, BOX_H])), { size: 0.5 }));
    // Keypad bezel.
    const bezel = { x: KEYS_X - 9, y: KEYS_Y - 8, w: PITCH[0] * 2 + KEY.w + 18, d: PITCH[1] * 3 + KEY.d + 16, r: 4 };
    out.push(S(k.slabOf(bezel, BOX_H, 1, P, 4, 0.4), { tone: "lo", crease: "none" }));
    // The Keychain drawer on the front face: where the salted hash lives.
    const front = BOX.y + BOX.d;
    const drawer = { x: -66, y: front, w: 46, d: 2.4, r: 1 };
    out.push(S(k.slabOf(drawer, 10, 18, P, 2, 0.4), { tone: "hi", crease: "lo" }));
    out.push(S(k.slabOf({ x: -50, y: front + 2.4, w: 14, d: 2.4, r: 1 }, 17, 3.4, P, 2), { tone: "mid" }));
    return out.join("");
  }

  function keys() {
    const out = [];
    const list = [];
    for (let row = 0; row < 4; row++) for (let col = 0; col < 3; col++) list.push([KEYS_X + col * PITCH[0], KEYS_Y + row * PITCH[1], row * 3 + col]);
    list.sort((a, b) => k.depthOf([a[0], a[1], 0], P) - k.depthOf([b[0], b[1], 0], P));
    for (const [x, y, index] of list) {
      const plan = { x: x - KEY.w / 2, y: y - KEY.d / 2, w: KEY.w, d: KEY.d, r: 2.2 };
      const art = S(k.slabOf(plan, BOX_H + 1, KEY.h, P, 4, 0.5), { tone: "hi", crease: "lo" }) + D([at([x, y, BOX_H + 1 + KEY.h])], { size: 0.55, tone: "mid" });
      out.push(`<g data-key="${index}">${art}</g>`);
    }
    return out.join("");
  }

  function dial() {
    const [x, y] = DIAL;
    const out = [S(k.cylinder(x, y, DIAL_R, DIAL_Z, DIAL_H, P, 64, 0.8), { tone: "hi", crease: "lo" })];
    out.push(L(k.knurl(x, y, DIAL_R, DIAL_TOP - 2.6, DIAL_TOP, 72, P, 0.3), { tone: "lo" }));
    out.push(L(k.ring(x, y, DIAL_R - 2, DIAL_TOP, P, 64), { tone: "lo" }));
    const t = k.radialTicks(x, y, DIAL_R - 2.6, 30, 5, DIAL_TOP, [1.2, 2.6], P);
    out.push(L(t.minor, { tone: "lo" }), L(t.major, { tone: "mid" }));
    out.push(L(k.ring(x, y, 1.6, DIAL_TOP, P, 16), { tone: "mid" }));
    out.push(k.faceTextSvg(k.topMatrix([x, y + 7.5], DIAL_TOP, P, "x"), "30 s", { size: 2.6, tone: "lo", anchor: "middle" }));
    return out.join("");
  }

  const needleAt = (share) => {
    const a = share * Math.PI * 2;
    const [x, y] = DIAL;
    return k.lineOnTop([x - Math.sin(a) * 3, y + Math.cos(a) * 3], [x + Math.sin(a) * (DIAL_R - 4), y - Math.cos(a) * (DIAL_R - 4)], DIAL_TOP + 0.2, P);
  };

  // The bolt grows out of the box's side face; its length is rebuilt each frame.
  const boltPlan = (len) => ({ x: BOX.x + BOX.w, y: BOLT.y - BOLT.d / 2, w: Math.max(0.6, len), d: BOLT.d, r: Math.min(2, len / 2) });
  const bolt = (len) => S(k.slabOf(boltPlan(len), BOLT.z, BOLT.h, P, 3, 0.6), { tone: "hi", lit: true });

  function keeper() {
    const out = [S(k.slabOf(KEEPER, 0, KEEPER_H, P, 3, 0.8), { tone: "mid" })];
    out.push(D([at([KEEPER.x + 7, KEEPER.y + 5, KEEPER_H]), at([KEEPER.x + 7, KEEPER.y + KEEPER.d - 5, KEEPER_H])], { size: 0.5 }));
    out.push(L(k.planOutline(k.insetPlan(KEEPER, 2.4), KEEPER_H, P, 3), { tone: "faint" }));
    return out.join("");
  }

  function lamps() {
    return byDepth(LAMPS).map(([x, y], i) => {
      const art = S(k.cylinder(x, y, LAMP_R + 1.4, 0, 1.4, P, 28), { tone: "lo" }) + S(k.cylinder(x, y, LAMP_R, 1.4, 3, P, 28, 0.4), { tone: "hi", crease: "lo" });
      return `<g class="lamp" data-lamp="${LAMPS.findIndex((p) => p[0] === x)}">${art}</g>`;
    }).join("");
  }

  const ruler = { x: 14, y: PLATE.y + PLATE.d - 15, w: 100, d: 7, r: 1 };
  const svg = k.figureSvg({
    width: WIDTH, height: HEIGHT,
    label: "A lockbox on a base plate. A keypad on top, a 30-second dial beside it, five lamps in front for wrong tries and a bolt that slides into a keeper block. A small drawer on the front holds only a salted hash of the code.",
    body: [
      plate(PLATE, { ruler }),
      labelPlate({ x: PLATE.x + 10, y: PLATE.y + 10, w: 32, d: 16, r: 1.5 }, 0),
      box(),
      keys(),
      dial(),
      `<path data-part="needle" class="iso-line" data-tone="lit" data-free="start" d="${needleAt(0)}" style="stroke-width:1.1"/>`,
      `<g data-part="bolt">${bolt(BOLT.out)}</g>`,
      lamps(),
      keeper(),
    ],
  });

  const live = `
const P = ${JSON.stringify(P)};
const DIAL = ${JSON.stringify(DIAL)}, DIAL_R = ${DIAL_R}, DIAL_TOP = ${DIAL_TOP}, OUT = ${BOLT.out};
const BOX = ${JSON.stringify(BOX)}, BOLT = ${JSON.stringify(BOLT)};
const boltPlan = ${boltPlan.toString()};
const stage = document.querySelector(".iso-stage");
const keys = [...stage.querySelectorAll("[data-key]")].sort((a, b) => a.dataset.key - b.dataset.key);
const lamps = [...stage.querySelectorAll("[data-lamp]")].sort((a, b) => a.dataset.lamp - b.dataset.lamp);
const needle = stage.querySelector('[data-part="needle"]');
const bolt = stage.querySelector('[data-part="bolt"]');
const readout = document.querySelector("[data-readout]");
const still = matchMedia("(prefers-reduced-motion: reduce)");
const needleAt = ${needleAt.toString().replace("k.lineOnTop", "lineOnTop")};
// Script: five wrong codes, a 30 s lockout (shown at 6x), the right code, unlocked, then it locks again.
const SPEED = 6, LOCKOUT = 30;
const steps = [];
let t = 0.6;
const WRONG = [[1, 1, 1, 1], [4, 5, 6, 7], [0, 2, 4, 6], [9, 8, 7, 6], [3, 3, 8, 8]];
WRONG.forEach((code, n) => { code.forEach((key) => { steps.push({ t, key }); t += 0.28; }); steps.push({ t, wrong: n + 1 }); t += 0.5; });
steps.push({ t, lockout: true }); const lockFrom = t; t += LOCKOUT / SPEED;
steps.push({ t, reset: true }); t += 0.6;
[1, 2, 3, 4].forEach((key) => { steps.push({ t, key }); t += 0.28; });
steps.push({ t, open: true }); t += 3.2;
steps.push({ t, close: true }); t += 1.4;
const LOOP = t;
let clock = 0, last = 0, frame = 0, visible = false, boltAt = OUT, done = 0;
const state = { wrong: 0, open: false, locked: false, pressed: -1, pressedAt: -9 };
function reset() { state.wrong = 0; state.open = false; state.locked = false; done = 0; lamps.forEach((l) => l.classList.remove("on")); }
function apply(s) {
  if (s.key !== undefined) { state.pressed = s.key; state.pressedAt = clock; }
  if (s.wrong) { state.wrong = s.wrong; lamps[s.wrong - 1].classList.add("on"); }
  if (s.lockout) state.locked = true;
  if (s.reset) { state.locked = false; state.wrong = 0; lamps.forEach((l) => l.classList.remove("on")); }
  if (s.open) state.open = true;
  if (s.close) state.open = false;
}
function say() {
  if (state.locked) { const left = Math.max(0, Math.ceil(LOCKOUT - (clock - lockFrom) * SPEED)); return "5 wrong tries · locked " + left + " s"; }
  if (state.open) return "right code · open for 5 min";
  if (state.wrong) return "wrong · try " + state.wrong + " of 5";
  return "stored: salted hash only";
}
function tick(now) {
  const dt = last ? Math.min((now - last) / 1000, 1 / 30) : 1 / 60;
  last = now;
  clock += dt;
  if (clock >= LOOP) { clock = 0; reset(); }
  while (done < steps.length && steps[done].t <= clock) apply(steps[done++]);
  keys.forEach((el, i) => {
    const down = i === state.pressed && clock - state.pressedAt < 0.18;
    el.setAttribute("transform", down ? translateAlong(P, [0, 0, -1.6]) : "");
    const solid = el.querySelector(".iso-solid");
    if (down) solid.setAttribute("data-lit", ""); else solid.removeAttribute("data-lit");
  });
  const share = state.locked ? Math.min(1, (clock - lockFrom) * SPEED / LOCKOUT) : 0;
  needle.setAttribute("d", needleAt(share));
  const want = state.open ? 0 : OUT;
  const was = boltAt;
  boltAt = still.matches ? want : boltAt + (want - boltAt) * (1 - Math.exp(-dt / 0.2));
  if (Math.abs(boltAt - want) < 0.02) boltAt = want;
  if (boltAt !== was) bolt.innerHTML = boltAt < 0.3 ? "" : solidSvg(slabOf(boltPlan(boltAt), BOLT.z, BOLT.h, P, 3, 0.6), { tone: "hi", lit: true });
  const text = say();
  if (readout.textContent !== text) readout.textContent = text;
  frame = visible ? requestAnimationFrame(tick) : 0;
}
new IntersectionObserver((e) => { visible = e[e.length - 1].isIntersecting; if (visible && !frame) { last = 0; frame = requestAnimationFrame(tick); } }).observe(stage);
`;

  const css = `<style>
.lamp.on .iso-top{fill:#f4c7bc}.lamp.on .iso-shade{fill:#e3a596}.lamp.on .iso-edge{stroke:var(--anatomy-red)}
</style>`;

  const body = k.plateHtml({
    fig: "Fig 2",
    title: "Grown-up passcode",
    hint: "Watch five wrong tries",
    readout: "stored: salted hash only",
    keys: [
      { mark: "lit", label: "The bolt: out while locked, back in for 5 minutes after the right code" },
      { mark: "raised", label: "Five lamps: one per wrong try; the fifth starts the 30 s dial" },
      { mark: "flat", label: "The front drawer: the Keychain, holding only a salted hash" },
    ],
    caption: "The grown-up passcode on a kid's or teen's phone. The code itself is never saved: only a salted SHA-256 hash, in the Keychain, on that phone. Five wrong tries lock it for 30 seconds (the dial runs 6× fast here).",
    body: `${css}<div class="iso-stage" tabindex="0" aria-label="A passcode lockbox going through five wrong tries, a lockout and the right code">${svg}</div>`,
  });
  return page({ k, title: "Grown-up passcode", theme, body, live });
}
