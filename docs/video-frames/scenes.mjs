// Animated desk scenes of the app for the demo video, built with the anatomy skill's kit.
// Phones lie flat on a soft desk mat; each screen is drawn in the plane of the glass (topMatrix)
// with the app's real screens: Today, Get Help (kid), and a parent's lock screen.
import { k, helpers, page } from "./shared.mjs";

const WIDTH = 640, HEIGHT = 380;
const PHONE = { w: 44, d: 90, r: 10 }, PHONE_H = 5;
const GLASS = 2.4; // bezel
const SW = PHONE.w - GLASS * 2, SH = PHONE.d - GLASS * 2;
const FONT = `<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@600;800;900&display=swap">`;
const SCREEN_CSS = `<style>
.ui text{font-family:Nunito,ui-rounded,"SF Pro Rounded",system-ui,sans-serif;fill:#23302a}
.ui .glass{fill:#fbf8f1}.ui .card{fill:#e6f1e8}.ui .soft{fill:#bfe0c9}.ui .green{fill:#1f6b4a}.ui .berry{fill:#e0644a}.ui .amber{fill:#d9933f}
.ui .muted{fill:#6f8277}.ui .white{fill:#fff}.ui .stroke{fill:none;stroke-linecap:round;stroke-linejoin:round}
.ui .banner{fill:#ffffff;stroke:#d5e1d8;stroke-width:.4}
.mat .iso-top{fill:#eef6ef}
.seal .iso-top{fill:#1f6b4a}.seal .iso-shade{fill:#17543a}.seal .iso-edge{stroke:#123f2c}
</style>`;

function scene(build) {
  return (theme) => {
    const s = build();
    const body = k.plateHtml({
      fig: s.fig, title: s.title, hint: s.hint, readout: s.readout, keys: s.keys, caption: s.caption,
      body: `${FONT}${SCREEN_CSS}<div class="iso-stage" tabindex="0" aria-label="${s.aria}">${s.svg}</div>`,
    });
    return page({ k, title: s.title, theme, body, live: s.live });
  };
}

// Shared parts --------------------------------------------------------------

function kitFor(P) {
  const h = helpers(P);
  const { at, S, L, D } = h;
  let clipCount = 0;

  // A soft desk mat on short feet: the ground every scene stands on.
  function mat(plan) {
    const out = [`<path class="iso-halo" d="${k.haloOf(plan, -8, 8, P)}"/>`];
    for (const [x, y] of h.byDepth(k.corners(plan, 18))) out.push(S(k.cylinder(x, y, 5, -8, 3, P, 24), { tone: "lo" }));
    out.push(`<g class="mat">${S(k.slabOf(plan, -5, 5, P, 12, 1.4), { tone: "mid" })}</g>`);
    out.push(L(k.planOutline(k.insetPlan(plan, 6), 0, P, 12), { tone: "faint" }));
    out.push(D(k.corners(plan, 11).map(([x, y]) => at([x, y, 0])), { size: 0.5 }));
    return out.join("");
  }

  // A phone lying face up. `screen` is SVG in screen units: u to the right (0..SW), v down (0..SH).
  function phone(cx, cy, screen, { id = "" } = {}) {
    const plan = { x: cx - PHONE.w / 2, y: cy - PHONE.d / 2, w: PHONE.w, d: PHONE.d, r: PHONE.r };
    const top = PHONE_H;
    const out = [`<path class="iso-halo" d="${k.haloOf(k.insetPlan(plan, 3), 0, 0.1, P)}" style="filter:blur(5px)"/>`];
    out.push(S(k.slabOf(plan, 0, PHONE_H, P, 12, 0.6), { tone: "hi", crease: "lo", inner: L(k.sideSeam(plan, PHONE_H / 2, P, 12), { tone: "faint" }) }));
    // Side buttons on the +x edge, and the action button on the far end of the -x edge.
    out.push(S(k.slabOf({ x: plan.x + plan.w, y: cy - 14, w: 0.8, d: 12, r: 0.4 }, 1.4, 2.2, P, 2), { tone: "mid" }));
    out.push(S(k.slabOf({ x: plan.x + plan.w, y: cy + 2, w: 0.8, d: 6, r: 0.4 }, 1.4, 2.2, P, 2), { tone: "mid" }));
    const id0 = `glass-${clipCount++}`;
    const g = { x: plan.x + GLASS, y: plan.y + GLASS };
    const shape = k.pathOf(k.roundedPlan({ x: 0, y: 0, w: SW, d: SH, r: PHONE.r - GLASS }, 10), true);
    const m = k.topMatrix([g.x, g.y], top + 0.02, P, "x");
    out.push(`<g class="ui" transform="${m}"><clipPath id="${id0}"><path d="${shape}"/></clipPath><path class="glass" d="${shape}"/><g clip-path="url(#${id0})"${id ? ` data-screen="${id}"` : ""}>${screen}</g>`);
    // Dynamic Island.
    out.push(`<rect x="${SW / 2 - 6}" y="2.2" width="12" height="3.4" rx="1.7" fill="#23302a"/>`);
    out.push(`<path class="iso-line" data-tone="lo" d="${shape}" vector-effect="non-scaling-stroke"/></g>`);
    return out.join("");
  }

  return { ...h, mat, phone };
}

const statusBar = (time) => `<text x="5" y="5.4" font-size="2.6" font-weight="800">${time}</text>
<rect x="${SW - 9}" y="3.2" width="5" height="2.4" rx="0.8" class="green"/>`;

// Scene 1: Today ---------------------------------------------------------------

export const today = scene(() => {
  const MAT = { x: -86, y: -56, w: 150, d: 112, r: 16 };
  const PH = [22, 0];
  const SENSOR = [-48, 6];
  const P = k.fitProjection([...k.boxCorners(MAT, -8, 0), [0, 0, 12]], WIDTH, HEIGHT, { pad: 22, azimuth: 68, elevation: 56 });
  const { S, L, D, at, mat, phone } = kitFor(P);

  // The day so far, mg/dL every 5 minutes. The last value is what the screen shows.
  const DAY = [148, 152, 149, 141, 136, 131, 128, 126, 122, 118, 116, 114, 113, 112];
  const sx = (i) => 6 + (i / (DAY.length - 1)) * (SW - 12);
  const sy = (v) => 64 - ((v - 70) / (180 - 70)) * 12;
  const spark = (n) => DAY.slice(0, n).map((v, i) => `${i ? "L" : "M"}${sx(i).toFixed(1)} ${sy(v).toFixed(1)}`).join("");

  const screen = `${statusBar("9:41")}
<text x="5" y="13.6" font-size="3.4" font-weight="900">Good morning, Maya</text>
<rect class="card" x="3" y="17" width="${SW - 6}" height="30" rx="5"/>
<circle data-part="halo" cx="14.6" cy="31" r="10" fill="none" stroke="#5fa77e" stroke-width="1.6" opacity=".55"/>
<text data-part="reading" x="14.6" y="35.4" font-size="11.5" font-weight="900" text-anchor="middle" class="green">${DAY[0]}</text>
<text x="14.6" y="43.4" font-size="2.4" font-weight="800" text-anchor="middle" class="muted">mg/dL</text>
<g data-part="arrow" transform="translate(30 27) rotate(45)"><path class="stroke" d="M-3.4 0H3.2M0.4 -2.8L3.2 0L0.4 2.8" stroke="#1f6b4a" stroke-width="1.4"/></g>
<rect class="soft" x="25" y="35.2" width="10.4" height="4.6" rx="2.3"/>
<text data-part="zone" x="30.2" y="38.6" font-size="2.4" font-weight="900" text-anchor="middle" class="green">In range</text>
<rect class="card" x="3" y="50" width="${SW - 6}" height="18" rx="5"/>
<rect x="6" y="${sy(180)}" width="${SW - 12}" height="${sy(70) - sy(180)}" fill="#d3ebd9" opacity=".7"/>
<path data-part="spark" class="stroke" d="${spark(1)}" stroke="#1f6b4a" stroke-width="1.1"/>
<circle data-part="dot" cx="${sx(0)}" cy="${sy(DAY[0])}" r="1.1" class="green"/>
<text x="6" y="54.4" font-size="2.2" font-weight="800" class="muted">Last 3 hours</text>
${[["Glucose", "#1f6b4a"], ["Carbs", "#d9933f"], ["Insulin", "#5fa77e"]].map(([label, c], i) => `<circle cx="${8.4 + i * 11.2}" cy="75" r="4.2" fill="${c}"/><path class="stroke" d="M${8.4 + i * 11.2 - 1.8} 75h3.6M${8.4 + i * 11.2} 73.2v3.6" stroke="#fff" stroke-width="1"/><text x="${8.4 + i * 11.2}" y="82" font-size="2" font-weight="800" text-anchor="middle">${label}</text>`).join("")}`;

  // A CGM sensor on its applicator pad: the source of the readings.
  function sensor() {
    const [x, y] = SENSOR;
    const pad = { x: x - 16, y: y - 16, w: 32, d: 32, r: 10 };
    const out = [S(k.slabOf(pad, 0, 0.8, P, 10), { tone: "lo", crease: "none" })];
    out.push(S(k.cylinder(x, y, 11, 0.8, 3.4, P, 56, 0.6), { tone: "hi", crease: "lo" }));
    out.push(L(k.ring(x, y, 8, 4.2, P, 48), { tone: "faint" }));
    out.push(S(k.cylinder(x, y, 3, 4.2, 0.8, P, 28), { tone: "mid" }));
    out.push(`<g data-part="ping">${L(k.ring(x, y, 13, 0.8, P, 56), { tone: "lit" })}</g>`);
    return out.join("");
  }

  const svg = k.figureSvg({
    width: WIDTH, height: HEIGHT,
    label: "A phone lies face up on a desk mat next to a glucose sensor. The phone shows DiabetesCare's Today screen: Good morning, Maya, a large reading in mg/dL with a trend arrow, a three-hour line and buttons to log glucose, carbs and insulin. Each new sensor reading rolls the number and extends the line.",
    body: [mat(MAT), sensor(), phone(PH[0], PH[1], screen, { id: "today" })],
  });

  const live = `
const DAY = ${JSON.stringify(DAY)};
const sx = ${sx.toString()}, sy = ${sy.toString()}, SW = ${SW};
const spark = ${spark.toString()};
const st = document.querySelector(".iso-stage");
const $ = (n) => st.querySelector('[data-part="' + n + '"]');
const reading = $("reading"), path = $("spark"), dot = $("dot"), arrow = $("arrow"), halo = $("halo"), ping = $("ping");
const readout = document.querySelector("[data-readout]");
const still = matchMedia("(prefers-reduced-motion: reduce)");
const STEP = 1.1; // one 5-minute reading per 1.1 s
let t = 0, last = 0, shown = DAY[0], frame = 0, visible = false;
function trendOf(i) { if (i < 1) return 0; const d = DAY[i] - DAY[Math.max(0, i - 2)]; return d <= -6 ? 45 : d >= 6 ? -45 : 0; }
function tick(now) {
  const dt = last ? Math.min((now - last) / 1000, 1 / 30) : 1 / 60; last = now;
  t = (t + dt) % (STEP * DAY.length + 2.4);
  const i = Math.min(DAY.length - 1, Math.floor(t / STEP));
  const target = DAY[i];
  shown = still.matches ? target : shown + (target - shown) * (1 - Math.exp(-dt / 0.25));
  reading.textContent = Math.round(shown);
  path.setAttribute("d", spark(i + 1));
  dot.setAttribute("cx", sx(i)); dot.setAttribute("cy", sy(target));
  arrow.setAttribute("transform", "translate(30 27) rotate(" + trendOf(i) + ")");
  const since = t - i * STEP;
  halo.setAttribute("r", (10 + Math.sin(now / 700) * 0.5).toFixed(2));
  ping.style.opacity = since < 0.5 && t < STEP * DAY.length ? String(1 - since / 0.5) : "0";
  const text = target + " mg/dL · " + (trendOf(i) > 0 ? "falling slowly" : trendOf(i) < 0 ? "rising" : "steady") + " · in range";
  if (readout.textContent !== text) readout.textContent = text;
  frame = visible ? requestAnimationFrame(tick) : 0;
}
new IntersectionObserver((e) => { visible = e[e.length - 1].isIntersecting; if (visible && !frame) { last = 0; frame = requestAnimationFrame(tick); } }).observe(st);
`;

  return {
    fig: "Scene 1", title: "Today", hint: "A new reading every 5 minutes", readout: `${DAY[0]} mg/dL · steady · in range`,
    keys: [
      { mark: "lit", label: "The sensor's ring flashes when a reading arrives (via Apple Health)" },
      { mark: "raised", label: "Today: the number rolls, the arrow turns, the line grows" },
    ],
    caption: "Maya's morning in DiabetesCare. Her sensor's readings come in through Apple Health; Today shows the latest one big, which way it's heading and the last three hours. Sample data; 5 minutes run in about a second here.",
    aria: "A phone showing the DiabetesCare Today screen updating as new glucose readings arrive",
    svg, live,
  };
});

// Scene 2: Feeling off? ---------------------------------------------------------

export const help = scene(() => {
  const MAT = { x: -98, y: -56, w: 186, d: 112, r: 16 };
  const PH = [0, 0];
  const JUICE = { x: -80, y: -34, w: 20, d: 14, r: 2.4 }, JUICE_H = 30;
  const WATCH = [56, 16];
  const P = k.fitProjection([...k.boxCorners(MAT, -8, 0), [JUICE.x, JUICE.y, JUICE_H + 14]], WIDTH, HEIGHT, { pad: 22, azimuth: 68, elevation: 56 });
  const { S, L, D, at, mat, phone } = kitFor(P);

  const R = 11, C = 2 * Math.PI * R;
  const screen = `${statusBar("3:12")}
<rect x="3" y="9" width="${SW - 6}" height="9" rx="4.5" class="berry" data-part="lowpill"/>
<text data-part="lowtext" x="${SW / 2}" y="15" font-size="3.4" font-weight="900" text-anchor="middle" class="white">Low · 62 mg/dL</text>
<text x="5" y="24.4" font-size="3.6" font-weight="900">Feeling off?</text>
<circle cx="${SW / 2}" cy="38" r="${R}" fill="none" stroke="#e6f1e8" stroke-width="2.6"/>
<circle data-part="ring" cx="${SW / 2}" cy="38" r="${R}" fill="none" stroke="#1f6b4a" stroke-width="2.6" stroke-linecap="round" stroke-dasharray="${C.toFixed(2)}" stroke-dashoffset="0" transform="rotate(-90 ${SW / 2} 38)"/>
<text data-part="clock" x="${SW / 2}" y="39.6" font-size="5" font-weight="900" text-anchor="middle">15:00</text>
<text x="${SW / 2}" y="43.6" font-size="2" font-weight="800" text-anchor="middle" class="muted">recheck</text>
${["Find a grown-up", "Have 15 g fast sugar", "Check again"].map((s, i) => `<circle data-step="${i}" cx="7" cy="${55 + i * 6}" r="1.8" fill="#e6f1e8" stroke="#1f6b4a" stroke-width=".5"/><text x="11" y="${56 + i * 6}" font-size="2.6" font-weight="800">${s}</text>`).join("")}
<rect x="3" y="73" width="${SW - 6}" height="8" rx="4" class="green"/>
<text x="${SW / 2}" y="78.2" font-size="3" font-weight="900" text-anchor="middle" class="white">Call Mom</text>`;

  function juice() {
    const out = [`<path class="iso-halo" d="${k.haloOf(JUICE, 0, JUICE_H, P)}" style="filter:blur(5px)"/>`];
    out.push(S(k.slabOf(JUICE, 0, JUICE_H, P, 3, 0.8), { tone: "hi", crease: "lo", inner: L(k.sideSeam(JUICE, 6, P, 3) + k.sideSeam(JUICE, 22, P, 3), { tone: "faint" }) }));
    // Label: an apple on the front face (+y), in the face plane.
    const front = JUICE.y + JUICE.d;
    out.push(`<g transform="${k.sideMatrix([JUICE.x, front], 0, P, "left")}"><circle cx="10" cy="-14" r="4.6" fill="#e0644a"/><path d="M10 -18.4c.4-1.8 1.6-2.6 2.8-2.8" fill="none" stroke="#1f6b4a" stroke-width=".8" stroke-linecap="round"/><text x="10" y="-6" font-size="2.6" font-weight="900" text-anchor="middle" style="font-family:Nunito,ui-rounded,system-ui;fill:#1f6b4a">15 g</text></g>`);
    out.push(S(k.cylinder(JUICE.x + 14, JUICE.y + 5, 1.6, JUICE_H, 0.6, P, 16), { tone: "mid" }));
    out.push(S(k.cylinder(JUICE.x + 14, JUICE.y + 5, 0.8, JUICE_H + 0.6, 12, P, 12), { tone: "hi", lit: true }));
    return out.join("");
  }

  function watch() {
    const [x, y] = WATCH;
    const body = { x: x - 10, y: y - 12, w: 20, d: 24, r: 6 };
    const out = [];
    for (const [y0, d] of [[y - 30, 18], [y + 12, 18]]) out.push(S(k.slabOf({ x: x - 8, y: y0, w: 16, d, r: 4 }, 0, 1.6, P, 6), { tone: "mid" }));
    out.push(S(k.slabOf(body, 0, 4.4, P, 8, 0.5), { tone: "hi", crease: "lo" }));
    out.push(S(k.cylinder(body.x + body.w + 0.6, y - 4, 1.6, 1.4, 2, P, 16), { tone: "mid" }));
    const m = k.topMatrix([body.x + 1.6, body.y + 1.6], 4.42, P, "x");
    const w = body.w - 3.2, d = body.d - 3.2;
    out.push(`<g class="ui" transform="${m}"><rect width="${w}" height="${d}" rx="4.6" fill="#16201b"/><circle cx="${w / 2}" cy="${d / 2}" r="6" fill="none" stroke="#2c3b33" stroke-width="1.6"/><circle data-part="wring" cx="${w / 2}" cy="${d / 2}" r="6" fill="none" stroke="#7fd1a1" stroke-width="1.6" stroke-linecap="round" stroke-dasharray="${(2 * Math.PI * 6).toFixed(2)}" transform="rotate(-90 ${w / 2} ${d / 2})"/><text data-part="wclock" x="${w / 2}" y="${d / 2 + 1.1}" font-size="3.1" font-weight="900" text-anchor="middle" style="fill:#fff">15:00</text></g>`);
    return out.join("");
  }

  const svg = k.figureSvg({
    width: WIDTH, height: HEIGHT,
    label: "A kid's phone on a desk mat next to a 15-gram juice box and an Apple Watch. The phone shows Get Help: a Low 62 banner, a 15-minute recheck ring counting down, three steps and a Call Mom button. The watch shows the same countdown. When it ends the next reading is back in range.",
    body: [mat(MAT), juice(), phone(PH[0], PH[1], screen), watch()],
  });

  const live = `
const C = ${C.toFixed(3)}, WC = ${(2 * Math.PI * 6).toFixed(3)};
const st = document.querySelector(".iso-stage");
const $ = (n) => st.querySelector('[data-part="' + n + '"]');
const ringEl = $("ring"), clock = $("clock"), wring = $("wring"), wclock = $("wclock"), pill = $("lowpill"), lowtext = $("lowtext");
const steps = [0, 1, 2].map((i) => st.querySelector('[data-step="' + i + '"]'));
const readout = document.querySelector("[data-readout]");
// 15 real minutes play in 9 s. Then the recheck reads 94, back in range, and the loop rests.
const RUN = 9, REST = 3.2, SCALE = 900 / RUN;
let t = 0, last = 0, frame = 0, visible = false;
const mmss = (s) => Math.floor(s / 60) + ":" + String(Math.floor(s % 60)).padStart(2, "0");
function tick(now) {
  const dt = last ? Math.min((now - last) / 1000, 1 / 30) : 1 / 60; last = now;
  t = (t + dt) % (RUN + REST);
  const left = Math.max(0, 900 - t * SCALE), share = left / 900;
  ringEl.setAttribute("stroke-dashoffset", (C * (1 - share)).toFixed(2));
  wring.setAttribute("stroke-dashoffset", (WC * (1 - share)).toFixed(2));
  clock.textContent = wclock.textContent = left > 0 ? mmss(left) : "0:00";
  const done = t >= RUN;
  steps.forEach((s, i) => s.setAttribute("fill", i < 2 || done ? "#1f6b4a" : "#e6f1e8"));
  pill.setAttribute("class", done ? "green" : "berry");
  lowtext.textContent = done ? "Back in range · 94 mg/dL" : "Low · 62 mg/dL";
  const text = done ? "recheck: 94 mg/dL · back in range" : "low 62 · had 15 g juice · recheck in " + mmss(left);
  if (readout.textContent !== text) readout.textContent = text;
  frame = visible ? requestAnimationFrame(tick) : 0;
}
new IntersectionObserver((e) => { visible = e[e.length - 1].isIntersecting; if (visible && !frame) { last = 0; frame = requestAnimationFrame(tick); } }).observe(st);
`;

  return {
    fig: "Scene 2", title: "Feeling off?", hint: "The 15-minute recheck", readout: "low 62 · had 15 g juice · recheck in 15:00",
    keys: [
      { mark: "lit", label: "The straw: 15 g of fast sugar, logged with one tap" },
      { mark: "raised", label: "Get Help on the phone and the same timer on the watch" },
    ],
    caption: "A kid's Get Help screen during a low: find a grown-up, have 15 g of fast sugar, check again in 15 minutes. The timer is also on the Lock Screen and the watch. Sample data; 15 minutes run in 9 seconds here.",
    aria: "A kid's phone and watch counting down a 15-minute recheck after a low",
    svg, live,
  };
});

// Scene 3: Family --------------------------------------------------------------

export const family = scene(() => {
  const MAT = { x: -106, y: -56, w: 212, d: 112, r: 16 };
  const KID = [-52, 0], MOM = [52, 0];
  const ENV = { w: 32, d: 22, h: 1.6 };
  const P = k.fitProjection([...k.boxCorners(MAT, -8, 0), [0, 0, 40]], WIDTH, HEIGHT, { pad: 22, azimuth: 68, elevation: 56 });
  const { S, L, D, at, mat, phone } = kitFor(P);

  const kidScreen = `${statusBar("3:12")}
<text x="5" y="13.6" font-size="3.4" font-weight="900">Hi Maya</text>
<rect class="card" x="3" y="17" width="${SW - 6}" height="24" rx="5"/>
<text x="${SW / 2}" y="32" font-size="10" font-weight="900" text-anchor="middle" class="berry">62</text>
<text x="${SW / 2}" y="37.4" font-size="2.4" font-weight="800" text-anchor="middle" class="muted">mg/dL · Low</text>
<rect x="3" y="45" width="${SW - 6}" height="8" rx="4" class="soft"/>
<text x="${SW / 2}" y="50.2" font-size="2.6" font-weight="900" text-anchor="middle" class="green">Shared with Mom · sealed</text>
<rect x="3" y="57" width="${SW - 6}" height="8" rx="4" class="green"/>
<text x="${SW / 2}" y="62.2" font-size="2.8" font-weight="900" text-anchor="middle" class="white">Tell My Grown-Up</text>`;

  const momScreen = `<rect width="${SW}" height="${SH}" fill="#24413a"/>
<text x="${SW / 2}" y="12" font-size="2.6" font-weight="800" text-anchor="middle" style="fill:#cfe5d6">Tuesday</text>
<text x="${SW / 2}" y="23" font-size="10" font-weight="900" text-anchor="middle" style="fill:#fff">3:12</text>
<g data-part="note1" transform="translate(0 -70)"><rect class="banner" x="2.4" y="29" width="${SW - 4.8}" height="13" rx="3.6"/>
<rect x="5" y="31.6" width="3.6" height="3.6" rx="1" class="green"/><text x="10.4" y="34.6" font-size="2.1" font-weight="800" class="muted">DiabetesCare · now</text>
<text x="5" y="39.4" font-size="2.7" font-weight="900">Maya: Low 62 · treating it</text></g>
<g data-part="note2" transform="translate(0 -90)"><rect class="banner" x="2.4" y="44" width="${SW - 4.8}" height="13" rx="3.6"/>
<rect x="5" y="46.6" width="3.6" height="3.6" rx="1" class="green"/><text x="10.4" y="49.6" font-size="2.1" font-weight="800" class="muted">DiabetesCare · now</text>
<text x="5" y="54.4" font-size="2.7" font-weight="900">Maya is back in range · 94</text></g>`;

  // The sealed letter: a flat envelope with a green wax seal and a sprout pressed into it.
  function envelope() {
    const plan = { x: -ENV.w / 2, y: -ENV.d / 2, w: ENV.w, d: ENV.d, r: 1.4 };
    const out = [S(k.slabOf(plan, 0, ENV.h, P, 3, 0.4), { tone: "hi", crease: "lo" })];
    out.push(L(k.onTop([[plan.x + 1.4, plan.y + 1.4], [0, 2], [plan.x + plan.w - 1.4, plan.y + 1.4]], ENV.h, P), { tone: "mid" }));
    out.push(`<g class="seal">${S(k.cylinder(0, 2, 5, ENV.h, 0.8, P, 32, 0.3), { tone: "hi" })}</g>`);
    out.push(`<g transform="${k.topMatrix([0, 2], ENV.h + 0.82, P, "x")}"><path d="M0 3V-1M0 1.2c-2.1-.4-2.8-2.1-2.5-3c1.6 0 2.4 1.5 2.5 3M0 .3c1.8-.6 2.5-2.1 2.2-3c-1.5.3-2.2 1.5-2.2 3" fill="none" stroke="#fff" stroke-width=".7" stroke-linecap="round"/></g>`);
    return out.join("");
  }
  // The key: only Mom's phone holds it. A small ring and bit lying beside her phone.
  function key() {
    const [x, y] = [MOM[0] + 36, MOM[1] + 32];
    return S(k.cylinder(x, y, 4.2, 0, 1.2, P, 28), { tone: "hi", crease: "lo" }) + L(k.ring(x, y, 1.6, 1.2, P, 16), { tone: "mid" })
      + S(k.slabOf({ x: x - 1, y: y - 16, w: 2, d: 12, r: 0.8 }, 0, 1.2, P, 2), { tone: "hi", crease: "lo" })
      + S(k.slabOf({ x: x + 1, y: y - 15, w: 3, d: 2, r: 0.5 }, 0, 1.2, P, 2), { tone: "hi", crease: "lo" })
      + S(k.slabOf({ x: x + 1, y: y - 11, w: 2.2, d: 2, r: 0.5 }, 0, 1.2, P, 2), { tone: "hi", crease: "lo" });
  }

  const svg = k.figureSvg({
    width: WIDTH, height: HEIGHT,
    label: "Two phones on a desk mat: Maya's on the left showing a low of 62 and Shared with Mom, sealed; Mom's on the right on its lock screen, with a key beside it. A sealed envelope with a green sprout seal flies in an arc from Maya's phone to Mom's, and a notification slides down: Maya: Low 62 · treating it Later a second one: Maya is back in range.",
    body: [mat(MAT), phone(KID[0], KID[1], kidScreen), key(), phone(MOM[0], MOM[1], momScreen), `<g data-part="env" style="opacity:0">${envelope()}</g>`],
  });

  const live = `
const P = ${JSON.stringify(P)}, KID = ${JSON.stringify(KID)}, MOM = ${JSON.stringify(MOM)};
const st = document.querySelector(".iso-stage");
const $ = (n) => st.querySelector('[data-part="' + n + '"]');
const env = $("env"), n1 = $("note1"), n2 = $("note2");
const readout = document.querySelector("[data-readout]");
const still = matchMedia("(prefers-reduced-motion: reduce)");
const FLY = 1.8, LOOP = 11;
let t = 0, last = 0, frame = 0, visible = false, d1 = -70, d2 = -90;
const ease = (s) => s < 0.5 ? 2 * s * s : 1 - Math.pow(-2 * s + 2, 2) / 2;
function letterAt(s) { const e = ease(s); return [KID[0] + (MOM[0] - KID[0]) * e, 0, 8 + Math.sin(Math.PI * e) * 28]; }
function tick(now) {
  const dt = last ? Math.min((now - last) / 1000, 1 / 30) : 1 / 60; last = now;
  t = (t + dt) % LOOP;
  // Two letters: the low at 0.6 s, back in range at 6 s.
  const legs = [0.6, 6];
  let flying = null;
  legs.forEach((at) => { if (t >= at && t < at + FLY) flying = (t - at) / FLY; });
  env.style.opacity = flying === null ? "0" : String(Math.min(1, flying * 6, (1 - flying) * 6));
  if (flying !== null) env.setAttribute("transform", translateAlong(P, letterAt(flying)));
  const want1 = t >= 0.6 + FLY ? 0 : -70, want2 = t >= 6 + FLY ? 0 : -90;
  const f = (v, w) => (still.matches ? w : v + (w - v) * (1 - Math.exp(-dt / 0.14)));
  d1 = f(d1, want1); d2 = f(d2, want2);
  n1.setAttribute("transform", "translate(0 " + d1.toFixed(2) + ")");
  n2.setAttribute("transform", "translate(0 " + d2.toFixed(2) + ")");
  const text = flying !== null ? "sealed · on the way to Mom · no stop in between" : t >= 6 + FLY ? "Mom sees: back in range · 94" : t >= 0.6 + FLY ? "Mom sees: Low 62 · only Mom can open it" : "Maya's phone · low 62";
  if (readout.textContent !== text) readout.textContent = text;
  frame = visible ? requestAnimationFrame(tick) : 0;
}
new IntersectionObserver((e) => { visible = e[e.length - 1].isIntersecting; if (visible && !frame) { last = 0; frame = requestAnimationFrame(tick); } }).observe(st);
`;

  return {
    fig: "Scene 3", title: "Only your family", hint: "Watch a low reach Mom", readout: "Maya's phone · low 62",
    keys: [
      { mark: "lit", label: "The wax seal: end-to-end encrypted the whole way" },
      { mark: "raised", label: "Maya's phone (left) and Mom's, with the only key (right)" },
    ],
    caption: "Family sharing in DiabetesCare. A low on Maya's phone goes to Mom sealed, straight from phone to phone, and opens only on hers: no server of ours, not even Apple can read it. Mom gets a notification, then another when Maya is back in range. Sample data.",
    aria: "A sealed envelope flying from a kid's phone to a parent's phone, followed by notifications",
    svg, live,
  };
});
