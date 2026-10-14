// Fig 1: data goes from your phone to your family's phone in a sealed capsule, with no stop in between.
import { k, helpers, page } from "./shared.mjs";

export function build(theme) {
  const WIDTH = 600, HEIGHT = 340;
  const PLATE = { x: -132, y: -56, w: 264, d: 112, r: 12 };
  const DOCK_A = -92, DOCK_B = 92;
  const CRADLE = { w: 48, d: 76, r: 7 }, CRADLE_H = 6;
  const PHONE = { w: 36, d: 64, r: 7 }, PHONE_H = 4;
  const RAIL = { from: -58, to: 58 };
  const CAR = { x: -18, y: -16, w: 36, d: 32, r: 3 }, CAR_Z = 3, CAR_TOP = 7;
  const BODY = { x: -14, y: -13, w: 28, d: 26, r: 7 }, BODY_TOP = 26;
  const LID = { x: -15, y: -14, w: 30, d: 28, r: 7.5 }, LID_H = 3.4, LID_OPEN = 12;
  const STOP = [-34, 34];

  const P = k.fitProjection(
    [...k.boxCorners(PLATE, -15, 0), [0, 0, BODY_TOP + LID_H + LID_OPEN + 6]],
    WIDTH, HEIGHT, { pad: 34, azimuth: 30 },
  );
  const { at, byDepth, S, L, D, plate } = helpers(P);

  const ruler = { x: -100, y: PLATE.y + PLATE.d - 15, w: 200, d: 7, r: 1 };
  const label = { x: 50, y: PLATE.y + PLATE.d - 15 - 22, w: 34, d: 16, r: 1.5 };

  function dock(cx, family) {
    const out = [];
    const cradle = { x: cx - CRADLE.w / 2, y: -CRADLE.d / 2, w: CRADLE.w, d: CRADLE.d, r: CRADLE.r };
    out.push(`<path class="iso-halo" d="${k.haloOf(cradle, 0, CRADLE_H, P)}" style="filter:blur(5px)"/>`);
    out.push(S(k.slabOf(cradle, 0, CRADLE_H, P, 8, 0.8), { tone: "mid" }));
    out.push(D(byDepth(k.corners(cradle, 4)).map(([x, y]) => at([x, y, CRADLE_H])), { size: 0.45 }));
    const phone = { x: cx - PHONE.w / 2, y: -PHONE.d / 2, w: PHONE.w, d: PHONE.d, r: PHONE.r };
    out.push(S(k.slabOf(phone, CRADLE_H, PHONE_H, P, 10, 0.6), { tone: "hi", crease: "lo" }));
    const top = CRADLE_H + PHONE_H;
    const screen = k.insetPlan(phone, 2.4);
    out.push(L(k.planOutline(screen, top, P, 10), { tone: "lo" }));
    out.push(L(k.lineOnTop([cx - 5, screen.y + 3], [cx + 5, screen.y + 3], top, P), { tone: "mid", free: true }));
    out.push(L(k.lineOnTop([cx - 6, screen.y + screen.d - 3], [cx + 6, screen.y + screen.d - 3], top, P), { tone: "lo", free: true }));
    // A glucose card on the screen: a ring for the reading and rule lines for the text.
    out.push(L(k.ring(cx, -12, 7, top, P, 40), { tone: family ? "lit" : "mid" }));
    out.push(L(k.ring(cx, -12, 4.6, top, P, 32), { tone: "faint" }));
    [[-1, 0.8], [4, 0.55], [9, 0.7], [14, 0.45]].forEach(([y, share]) => {
      out.push(L(k.lineOnTop([cx - 11, y], [cx - 11 + 22 * share, y], top, P), { tone: "lo", free: true }));
    });
    out.push(D([at([cx, screen.y + 1.2, top])], { size: 0.6, tone: "hi" }));
    return out.join("");
  }

  function rails() {
    const out = [];
    for (const y of [-13, 8]) {
      out.push(S(k.slabOf({ x: RAIL.from, y, w: RAIL.to - RAIL.from, d: 5, r: 1 }, 0, 3, P, 3, 0.4), { tone: "mid" }));
      out.push(D([RAIL.from + 5, 0, RAIL.to - 5].map((x) => at([x, y + 2.5, 3])), { size: 0.4 }));
    }
    for (const x of [RAIL.from - 5, RAIL.to]) {
      out.push(S(k.slabOf({ x, y: -16, w: 5, d: 32, r: 1.2 }, 0, 7, P, 3, 0.5), { tone: "mid" }));
      out.push(D([at([x + 2.5, -10, 7]), at([x + 2.5, 10, 7])], { size: 0.45 }));
    }
    // Midway: a blank cover plate where a server would sit on any other app's route. Nothing is mounted on it.
    const cover = { x: -10, y: 22, w: 20, d: 12, r: 2 };
    out.push(S(k.slabOf(cover, 0, 1, P, 3, 0.3), { tone: "lo" }));
    out.push(D(k.corners(cover, 2.2).map(([x, y]) => at([x, y, 1])), { size: 0.4 }));
    out.push(L(k.planOutline(k.insetPlan(cover, 4), 1, P, 3), { tone: "faint" }));
    return out.join("");
  }

  function carriage() {
    const out = [`<path class="iso-halo" d="${k.haloOf(k.insetPlan(CAR, 3), CAR_Z, 0.1, P)}" style="filter:blur(4px)"/>`];
    out.push(S(k.slabOf(CAR, CAR_Z, CAR_TOP - CAR_Z, P, 4, 0.6), { tone: "mid" }));
    out.push(D([-12, -4, 4, 12].map((x) => at([x, CAR.y + CAR.d - 2.2, CAR_TOP])), { size: 0.4, tone: "lo" }));
    out.push(S(k.slabOf(BODY, CAR_TOP, BODY_TOP - CAR_TOP, P, 10, 0.8), { tone: "hi", crease: "lo", inner: L(k.sideSeam(BODY, 14, P, 10), { tone: "faint" }) }));
    const well = k.insetPlan(BODY, 3.4);
    out.push(L(k.planOutline(well, BODY_TOP, P, 10), { tone: "lo" }));
    out.push(L(k.ring(0, -2, 5.4, BODY_TOP, P, 36), { tone: "lit" }));
    out.push(L(k.ring(0, -2, 3.2, BODY_TOP, P, 28), { tone: "faint" }));
    out.push(L(k.lineOnTop([-6, 6], [3, 6], BODY_TOP, P), { tone: "lo", free: true }));
    // Side latches: a small block on each visible side, where the lid locks down.
    out.push(S(k.slabOf({ x: BODY.x + BODY.w, y: -3, w: 1.6, d: 6, r: 0.6 }, BODY_TOP - 6, 5, P, 2), { tone: "mid" }));
    out.push(S(k.slabOf({ x: -3, y: BODY.y + BODY.d, w: 6, d: 1.6, r: 0.6 }, BODY_TOP - 6, 5, P, 2), { tone: "mid" }));
    return out.join("");
  }

  function lid() {
    const out = [S(k.slabOf(LID, BODY_TOP, LID_H, P, 10, 0.8), { tone: "hi", lit: true })];
    out.push(L(k.planOutline(k.insetPlan(LID, 3), BODY_TOP + LID_H, P, 10), { tone: "faint" }));
    // The lock: a hasp block and a keyed barrel on the lid.
    const hasp = { x: -5, y: -3.5, w: 10, d: 7, r: 1.6 };
    out.push(S(k.slabOf(hasp, BODY_TOP + LID_H, 2, P, 3, 0.4), { tone: "mid" }));
    out.push(S(k.cylinder(0, 0, 2.6, BODY_TOP + LID_H + 2, 2.6, P, 24), { tone: "hi", lit: true }));
    out.push(L(k.lineOnTop([0, -1.5], [0, 1.5], BODY_TOP + LID_H + 4.6, P), { tone: "lit" }));
    return out.join("");
  }

  const startX = STOP[0];
  const svg = k.figureSvg({
    width: WIDTH, height: HEIGHT,
    label: "Two phones on cradles at either end of a rail. A small sealed capsule rides the rail from the left phone to the right one. Its lid is locked the whole way and only opens on the family phone. Halfway along the rail is a blank plate with nothing mounted on it: there is no server on the route.",
    body: [
      plate(PLATE, { ruler, label }),
      dock(DOCK_A, false),
      rails(),
      `<g data-part="car" transform="${k.translateAlong(P, [startX, 0, 0])}">${carriage()}<g data-part="lid">${lid()}</g></g>`,
      dock(DOCK_B, true),
    ],
  });

  const live = `
const P = ${JSON.stringify(P)};
const STOP = ${JSON.stringify(STOP)}, LID_OPEN = ${LID_OPEN};
const stage = document.querySelector(".iso-stage");
const car = stage.querySelector('[data-part="car"]');
const lid = stage.querySelector('[data-part="lid"]');
const readout = document.querySelector("[data-readout]");
const still = matchMedia("(prefers-reduced-motion: reduce)");
// One trip: open at your phone, seal, ride, open at the family phone, seal, ride home.
const PLAN = [
  { t: 0.0, x: STOP[0], lid: 1, say: "your phone · open on your device" },
  { t: 1.6, x: STOP[0], lid: 0, say: "sealed · end-to-end encrypted" },
  { t: 2.4, x: STOP[1], lid: 0, say: "on the way · servers on the route: 0" },
  { t: 5.2, x: STOP[1], lid: 1, say: "family phone · only they can open it" },
  { t: 7.4, x: STOP[1], lid: 0, say: "sealed · end-to-end encrypted" },
  { t: 8.2, x: STOP[0], lid: 0, say: "on the way · servers on the route: 0" },
  { t: 11.0, x: STOP[0], lid: 1, say: "your phone · open on your device" },
];
const LOOP = 12.4;
let x = STOP[0], open = 1, clock = 0, last = 0, frame = 0, visible = false;
const goal = (t) => { let g = PLAN[0]; for (const p of PLAN) if (t >= p.t) g = p; return g; };
function draw() {
  car.setAttribute("transform", translateAlong(P, [x, 0, 0]));
  lid.setAttribute("transform", translateAlong(P, [0, 0, open * LID_OPEN]));
}
function tick(now) {
  const dt = last ? Math.min((now - last) / 1000, 1 / 30) : 1 / 60;
  last = now;
  clock = (clock + dt) % LOOP;
  const g = goal(clock);
  const calm = still.matches;
  x = calm ? g.x : x + (g.x - x) * (1 - Math.exp(-dt / 0.55));
  open = calm ? g.lid : open + (g.lid - open) * (1 - Math.exp(-dt / 0.22));
  if (readout.textContent !== g.say) readout.textContent = g.say;
  draw();
  frame = visible ? requestAnimationFrame(tick) : 0;
}
new IntersectionObserver((e) => { visible = e[e.length - 1].isIntersecting; if (visible && !frame) { last = 0; frame = requestAnimationFrame(tick); } }).observe(stage);
draw();
`;

  const body = k.plateHtml({
    fig: "Fig 1",
    title: "Only your family",
    hint: "Watch one trip",
    readout: "your phone · open on your device",
    keys: [
      { mark: "lit", label: "The capsule's lid and lock: sealed for the whole trip" },
      { mark: "raised", label: "Your phone (left) and a family member's phone (right)" },
      { mark: "flat", label: "The blank plate halfway: no server, nothing stops the data" },
    ],
    caption: "Family sharing in DiabetesCare. Readings leave your phone end-to-end encrypted, go straight to the people you invite, and open only on their phones. We never get a copy, and neither does Apple.",
    body: `<div class="iso-stage" tabindex="0" aria-label="A sealed capsule travelling from your phone to a family phone">${svg}</div>`,
  });
  return page({ k, title: "Only your family", theme, body, live });
}
