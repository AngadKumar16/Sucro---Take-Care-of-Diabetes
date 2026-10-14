// Fig 3: one gate. A cabinet of five drawers (features) with lock pins on one camshaft, turned by one stage knob.
// Matches CareStage.access(to:completed:) before any skills: Kid locks insulin, site change, ranges and clear data;
// Teen locks ranges and clear data; Adult locks nothing; safety info is never locked.
import { k, helpers, page } from "./shared.mjs";

export function build(theme) {
  const WIDTH = 600, HEIGHT = 340;
  const PLATE = { x: -142, y: -48, w: 270, d: 104, r: 12 };
  const CAB = { x: -128, y: -28, w: 238, d: 50, r: 5 }, CAB_Z = 4, CAB_TOP = 44;
  const FRONT_Y = CAB.y + CAB.d;
  const DRAWER = { w: 36, gap: 5, z: CAB_Z + 6, h: 28 }, FIRST = -90;
  const DRAWERS = ["insulin", "site change", "ranges", "clear data", "safety"];
  const LOCKED = { Kid: [1, 1, 1, 1, 0], Teen: [0, 0, 1, 1, 0], Adult: [0, 0, 0, 0, 0] };
  const PIN_Y = FRONT_Y - 8, PIN_R = 2.6, PIN_UP = 9;
  const SHAFT_Y = FRONT_Y - 18;
  const KNOB = [-110, -3], KNOB_R = 9, KNOB_H = 6;
  const OPEN = 16;
  const xOf = (i) => FIRST + i * (DRAWER.w + DRAWER.gap);

  const P = k.fitProjection([...k.boxCorners(PLATE, -15, 0), [CAB.x, CAB.y, CAB_TOP + PIN_UP + 8]], WIDTH, HEIGHT, { pad: 30, azimuth: 60 });
  const { at, S, L, D, plate, labelPlate } = helpers(P);

  function cabinet() {
    const out = [`<path class="iso-halo" d="${k.haloOf(CAB, 0, CAB_TOP, P)}" style="filter:blur(6px)"/>`];
    out.push(S(k.slabOf(k.insetPlan(CAB, -2), 0, CAB_Z, P, 6, 0.5), { tone: "lo" }));
    out.push(S(k.slabOf(CAB, CAB_Z, CAB_TOP - CAB_Z, P, 6, 1.2), { tone: "mid", inner: L(k.sideSeam(CAB, CAB_TOP - 4, P, 6), { tone: "faint" }) }));
    out.push(L(k.planOutline(k.insetPlan(CAB, 3.5), CAB_TOP, P, 6), { tone: "faint" }));
    out.push(D(k.corners(CAB, 4).map(([x, y]) => at([x, y, CAB_TOP])), { size: 0.5 }));
    // Drawer openings: a recessed outline on the front face for each drawer.
    return out.join("");
  }

  // The camshaft: one rod from the knob along every pin. This is CareStage.access: one place for every rule.
  function shaft() {
    const out = [];
    out.push(S(k.slabOf({ x: KNOB[0] + 4, y: SHAFT_Y - 2, w: xOf(4) + DRAWER.w / 2 - KNOB[0] - 4, d: 4, r: 1.8 }, CAB_TOP, 3.4, P, 3, 0.4), { tone: "mid" }));
    for (let i = 0; i < 5; i++) {
      const x = xOf(i) + DRAWER.w / 2;
      // Bearing block on the shaft and a link plate forward to the pin.
      out.push(S(k.slabOf({ x: x - 3, y: SHAFT_Y - 3.4, w: 6, d: 6.8, r: 1 }, CAB_TOP, 5, P, 2, 0.4), { tone: "mid" }));
      out.push(D([at([x, SHAFT_Y, CAB_TOP + 5])], { size: 0.45 }));
    }
    return out.join("");
  }

  function knob() {
    const [x, y] = KNOB;
    const out = [S(k.cylinder(x, y, KNOB_R + 3, CAB_TOP, 2, P, 48), { tone: "lo" })];
    const t = k.radialTicks(x, y, KNOB_R + 2.6, 3, 1, CAB_TOP + 2, [2, 2], P, -Math.PI / 4, Math.PI / 2 * 1.5);
    out.push(L(t.major, { tone: "mid" }));
    out.push(S(k.cylinder(x, y, KNOB_R, CAB_TOP + 2, KNOB_H, P, 48, 0.6), { tone: "hi", crease: "lo" }));
    out.push(L(k.knurl(x, y, KNOB_R, CAB_TOP + 2, CAB_TOP + 2 + KNOB_H, 48, P), { tone: "lo" }));
    return out.join("");
  }
  const STAGE_ANGLE = { Kid: -Math.PI / 4, Teen: Math.PI / 8, Adult: Math.PI / 2 };
  const pointerAt = (a) => {
    const [x, y] = KNOB;
    return k.lineOnTop([x, y], [x + Math.sin(a) * (KNOB_R - 1.6), y - Math.cos(a) * (KNOB_R - 1.6)], CAB_TOP + 2 + KNOB_H, P);
  };

  // A pin's visible height above its collar, rebuilt per frame.
  const pinArt = (i, lift) => {
    const x = xOf(i) + DRAWER.w / 2;
    return S(k.cylinder(x, PIN_Y, PIN_R, CAB_TOP + 2, 1.2 + lift, P, 24, 0.3), { tone: "hi", lit: true });
  };
  function collars() {
    const out = [];
    for (let i = 0; i < 5; i++) {
      const x = xOf(i) + DRAWER.w / 2;
      if (i === 4) {
        // Safety has no pin at all: a blank cap where the hole would be.
        out.push(S(k.cylinder(x, PIN_Y, PIN_R + 1.6, CAB_TOP, 1.2, P, 28, 0.3), { tone: "lo" }));
        out.push(L(k.ring(x, PIN_Y, PIN_R, CAB_TOP + 1.2, P, 24), { tone: "green" }));
        continue;
      }
      out.push(S(k.cylinder(x, PIN_Y, PIN_R + 1.6, CAB_TOP, 2, P, 28, 0.3), { tone: "mid" }));
      // Link plate from the bearing block to the collar.
      out.push(S(k.slabOf({ x: x - 1.2, y: SHAFT_Y + 3.4, w: 2.4, d: PIN_Y - PIN_R - 1.6 - SHAFT_Y - 3.4, r: 0.6 }, CAB_TOP, 1.4, P, 2), { tone: "mid" }));
    }
    return out.join("");
  }

  // A drawer: the tray between the cabinet face and the front (rebuilt as it opens) and the front itself.
  const trayArt = (i, open) => open < 0.4 ? "" : S(k.slabOf({ x: xOf(i) + 2, y: FRONT_Y, w: DRAWER.w - 4, d: open, r: 0.6 }, DRAWER.z + 2, DRAWER.h - 6, P, 2), { tone: "mid" });
  function front(i) {
    const x = xOf(i);
    const plan = { x, y: FRONT_Y, w: DRAWER.w, d: 3, r: 1.4 };
    const out = [S(k.slabOf(plan, DRAWER.z, DRAWER.h, P, 3, 0.6), { tone: "hi", crease: "lo", className: i === 4 ? "safety" : "" })];
    // Label holder and pull on the face.
    const face = FRONT_Y + 3;
    out.push(L(k.segment([x + 9, face, DRAWER.z + DRAWER.h - 5], [x + DRAWER.w - 9, face, DRAWER.z + DRAWER.h - 5], P) + k.segment([x + DRAWER.w - 9, face, DRAWER.z + DRAWER.h - 5], [x + DRAWER.w - 9, face, DRAWER.z + DRAWER.h - 11], P) + k.segment([x + DRAWER.w - 9, face, DRAWER.z + DRAWER.h - 11], [x + 9, face, DRAWER.z + DRAWER.h - 11], P) + k.segment([x + 9, face, DRAWER.z + DRAWER.h - 11], [x + 9, face, DRAWER.z + DRAWER.h - 5], P), { tone: "lo" }));
    out.push(S(k.slabOf({ x: x + 11, y: face, w: DRAWER.w - 22, d: 2.6, r: 1 }, DRAWER.z + 7, 3.2, P, 2, 0.3), { tone: "mid" }));
    out.push(D([at([x + 3, face, DRAWER.z + DRAWER.h - 3]), at([x + DRAWER.w - 3, face, DRAWER.z + DRAWER.h - 3])], { size: 0.4 }));
    return out.join("");
  }

  const svg = k.figureSvg({
    width: WIDTH, height: HEIGHT,
    label: "A cabinet of five drawers: insulin, site change, ranges, clear data and safety. One knob on the left turns one shaft that runs along every drawer and sets its lock pin. Turned to Kid, four pins drop and lock their drawers; to Teen, two; to Adult, none. The safety drawer has no pin and is always open.",
    body: [
      plate(PLATE, {}),
      labelPlate({ x: PLATE.x + 12, y: PLATE.y + PLATE.d - 24, w: 34, d: 14, r: 1.5 }, 0),
      cabinet(),
      shaft(),
      collars(),
      ...[0, 1, 2, 3].map((i) => `<g data-pin="${i}">${pinArt(i, PIN_UP)}</g>`),
      knob(),
      `<path data-part="pointer" class="iso-line" data-tone="lit" data-free="end" d="${pointerAt(STAGE_ANGLE.Teen)}" style="stroke-width:1.2"/>`,
      ...[0, 1, 2, 3, 4].map((i) => `<g data-tray="${i}"></g><g data-front="${i}">${front(i)}</g>`),
    ],
  });

  const live = `
const P = ${JSON.stringify(P)};
const KNOB = ${JSON.stringify(KNOB)}, KNOB_R = ${KNOB_R}, KNOB_H = ${KNOB_H}, CAB_TOP = ${CAB_TOP};
const DRAWER = ${JSON.stringify(DRAWER)}, FIRST = ${FIRST}, FRONT_Y = ${FRONT_Y}, PIN_Y = ${PIN_Y}, PIN_R = ${PIN_R}, PIN_UP = ${PIN_UP}, OPEN = ${OPEN};
const LOCKED = ${JSON.stringify(LOCKED)}, STAGE_ANGLE = ${JSON.stringify(STAGE_ANGLE)};
const xOf = ${xOf.toString()};
const pointerAt = ${pointerAt.toString().replace("k.lineOnTop", "lineOnTop")};
const S = (paths, style) => solidSvg(paths, style);
const pinArt = ${pinArt.toString().replace(/k\./g, "")};
const trayArt = ${trayArt.toString().replace(/k\./g, "")};
const stage = document.querySelector(".iso-stage");
const pins = [0, 1, 2, 3].map((i) => stage.querySelector('[data-pin="' + i + '"]'));
const trays = [0, 1, 2, 3, 4].map((i) => stage.querySelector('[data-tray="' + i + '"]'));
const fronts = [0, 1, 2, 3, 4].map((i) => stage.querySelector('[data-front="' + i + '"]'));
const pointer = stage.querySelector('[data-part="pointer"]');
const readout = document.querySelector("[data-readout]");
const still = matchMedia("(prefers-reduced-motion: reduce)");
const ORDER = ["Kid", "Teen", "Adult"], HOLD = 3.6;
const NAMES = ["insulin", "site change", "ranges", "clear data"];
let clock = 0, last = 0, frame = 0, visible = false;
let angle = STAGE_ANGLE.Kid;
const lift = [0, 0, 0, 0].map(() => PIN_UP), open = [0, 0, 0, 0, OPEN].map((v) => v);
const drawn = { lift: [], open: [] };
function tick(now) {
  const dt = last ? Math.min((now - last) / 1000, 1 / 30) : 1 / 60;
  last = now;
  clock = (clock + dt) % (HOLD * ORDER.length);
  const name = ORDER[Math.floor(clock / HOLD)];
  const calm = still.matches;
  const ease = (v, want, s) => (calm ? want : v + (want - v) * (1 - Math.exp(-dt / s)));
  angle = ease(angle, STAGE_ANGLE[name], 0.3);
  pointer.setAttribute("d", pointerAt(angle));
  // The shaft turns first; pins and drawers follow a beat later, as the cam reaches them.
  const settled = Math.abs(angle - STAGE_ANGLE[name]) < 0.05;
  LOCKED[name].forEach((locked, i) => {
    if (i < 4) {
      if (settled) lift[i] = ease(lift[i], locked ? 0 : PIN_UP, 0.18 + i * 0.04);
      const l = Math.round(lift[i] * 10) / 10;
      if (drawn.lift[i] !== l) { pins[i].innerHTML = pinArt(i, l); drawn.lift[i] = l; }
    }
    const want = locked ? 0 : (i === 4 ? OPEN : OPEN * 0.6);
    if (settled || i === 4) open[i] = ease(open[i], want, 0.3 + i * 0.05);
    const o = Math.round(open[i] * 10) / 10;
    if (drawn.open[i] !== o) { trays[i].innerHTML = trayArt(i, o); fronts[i].setAttribute("transform", translateAlong(P, [0, o, 0])); drawn.open[i] = o; }
  });
  const locked = LOCKED[name].filter(Boolean).length;
  const text = name + " · " + (locked ? locked + " need a grown-up" : "all open") + " · safety always open";
  if (readout.textContent !== text) readout.textContent = text;
  frame = visible ? requestAnimationFrame(tick) : 0;
}
new IntersectionObserver((e) => { visible = e[e.length - 1].isIntersecting; if (visible && !frame) { last = 0; frame = requestAnimationFrame(tick); } }).observe(stage);
`;

  const css = `<style>
.safety>.iso-top{fill:#e3f3e8}.safety>.iso-shade{fill:#cfe8d8}.safety>.iso-edge{stroke:var(--anatomy-green)}
</style>`;

  const body = k.plateHtml({
    fig: "Fig 3",
    title: "One gate",
    hint: "Kid → Teen → Adult",
    readout: "Kid · 4 need a grown-up · safety always open",
    keys: [
      { mark: "lit", label: "Lock pins: down locks a drawer until a grown-up enters the passcode" },
      { mark: "raised", label: "Drawers, left to right: insulin, site change, ranges, clear data, safety" },
      { mark: "green", label: "Safety has no pin: it is never locked, at any stage" },
    ],
    caption: "Every rule about who can do what lives in one function, CareStage.access, like one knob turning one shaft past every drawer. No screen has its own back door. Shown before any skills are earned; a kid's skills can unlock insulin and site changes early.",
    body: `${css}<div class="iso-stage" tabindex="0" aria-label="A five-drawer cabinet whose lock pins change as one knob turns from Kid to Teen to Adult">${svg}</div>`,
  });
  return page({ k, title: "One gate", theme, body, live });
}
