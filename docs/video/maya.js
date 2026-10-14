// Maya, the demo video's character. Original, drawn from simple shapes with an Ink outline.
// drawMaya(ctx, { x, y, scale, facing, expression, pose, t }) draws her with her feet at (x, y).
// Local units: 450 tall at scale 1, y up is negative. Head is 1/4.5 of her height.

export const C = {
  ink: "#2f4a3b", pine: "#1f6b4a", leaf: "#5fa77e", mint: "#bfe0c9", sage: "#e2eee3", cream: "#fbf8f1",
  amber: "#d9933f", berry: "#e0644a", berryDark: "#c4533c", skin: "#d9a27c", skinShade: "#c48a66",
  hair: "#3b2b26", hairHi: "#5a443b", denim: "#557587", denimDark: "#46636f", blush: "rgba(224,100,74,.28)",
};
const LINE = 4;

// Joint angles in degrees: 0 points straight down, positive swings forward (toward the way she faces).
export const POSES = {
  stand: { hip: [0, -192], lean: 0, head: 0, armB: [-6, -12], armF: [8, 14], legB: [-3, 0], legF: [3, 0] },
  sit: { hip: [0, -100], lean: -4, head: 4, armB: [12, 70], armF: [16, 74], legB: [86, 2], legF: [92, 0] },
  slump: { hip: [0, -100], lean: 26, head: 22, armB: [64, 96], armF: [58, 92], legB: [86, 2], legF: [92, 0] },
  phone: { hip: [0, -192], lean: 2, head: 20, armB: [14, 150], armF: [20, 158], legB: [-3, 0], legF: [4, 0], prop: "phone" },
  pillow: { hip: [0, -192], lean: 0, head: 0, armB: [168, 196], armF: [160, 190], legB: [-10, 14], legF: [8, 20], lying: true, prop: "pillow" },
  sitPhone: { hip: [0, -100], lean: 0, head: 22, armB: [16, 160], armF: [22, 166], legB: [86, 2], legF: [92, 0], prop: "phone" },
  cheer: { hip: [0, -192], lean: -3, head: -10, armB: [20, 70], armF: [168, 178], legB: [-6, 0], legF: [12, -4], armOver: true },
};

const rad = (a) => (a * Math.PI) / 180;
const down = (a, len) => [Math.sin(rad(a)) * len, Math.cos(rad(a)) * len];
const add = (p, d) => [p[0] + d[0], p[1] + d[1]];

function outlined(ctx, fill, build, width = LINE) {
  ctx.beginPath();
  build();
  ctx.fillStyle = fill;
  ctx.fill();
  ctx.lineWidth = width;
  ctx.strokeStyle = C.ink;
  ctx.lineJoin = "round";
  ctx.stroke();
}

// A limb: a thick round stroke with an Ink outline.
function limb(ctx, points, width, color) {
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  for (const [w, c] of [[width + LINE * 2, C.ink], [width, color]]) {
    ctx.beginPath();
    ctx.moveTo(...points[0]);
    for (const p of points.slice(1)) ctx.lineTo(...p);
    ctx.lineWidth = w;
    ctx.strokeStyle = c;
    ctx.stroke();
  }
}

function dot(ctx, x, y, r, fill, stroke = C.ink) {
  ctx.beginPath();
  ctx.arc(x, y, r, 0, Math.PI * 2);
  ctx.fillStyle = fill;
  ctx.fill();
  if (stroke) { ctx.lineWidth = LINE * 0.75; ctx.strokeStyle = stroke; ctx.stroke(); }
}

// CGM sensor: a small white disc with a ring, worn on the back of her left upper arm.
function sensor(ctx, x, y, r = 9) {
  dot(ctx, x, y, r, "#ffffff");
  ctx.beginPath();
  ctx.arc(x, y, r * 0.5, 0, Math.PI * 2);
  ctx.lineWidth = 2;
  ctx.strokeStyle = C.mint;
  ctx.stroke();
}

// ---- Arms and legs (side and three-quarter views) ------------------------------------------

function arm(ctx, shoulder, [upper, fore], { near, sensorOn, sx = 1 }) {
  const elbow = add(shoulder, down(upper, 70));
  const wrist = add(elbow, down(fore, 62));
  const shade = near ? 1 : 0.92;
  limb(ctx, [elbow, wrist], 19, near ? C.skin : C.skinShade);
  dot(ctx, wrist[0], wrist[1], 11, near ? C.skin : C.skinShade);
  limb(ctx, [shoulder, elbow], 27, near ? C.berry : C.berryDark);
  // Pushed-up sleeve: a soft cuff at the elbow.
  ctx.save();
  ctx.translate(...elbow);
  ctx.rotate(-rad(upper));
  outlined(ctx, near ? C.berry : C.berryDark, () => ctx.ellipse(0, -6, 17, 9, 0, 0, Math.PI * 2), LINE * 0.75);
  ctx.restore();
  if (sensorOn) {
    // Back of the upper arm: offset toward her back (screen left when she faces right).
    const mid = add(shoulder, down(upper, 30));
    const back = [-Math.cos(rad(upper)) * 15 * sx, Math.sin(rad(upper)) * 15 * sx];
    sensor(ctx, mid[0] + back[0], mid[1] + back[1]);
  }
  void shade;
  return { elbow, wrist };
}

function leg(ctx, hip, [thigh, shin], near) {
  const knee = add(hip, down(thigh, 92));
  const ankle = add(knee, down(shin, 82));
  limb(ctx, [hip, knee, ankle], 30, near ? C.denim : C.denimDark);
  // Sneaker: cream with a pine sole, pointing forward.
  ctx.save();
  ctx.translate(...ankle);
  ctx.rotate(-rad(shin));
  outlined(ctx, C.cream, () => ctx.roundRect(-14, -6, 44, 20, 9));
  ctx.beginPath();
  ctx.moveTo(-12, 10);
  ctx.lineTo(28, 10);
  ctx.lineWidth = 3;
  ctx.strokeStyle = C.pine;
  ctx.stroke();
  ctx.restore();
}

// ---- Torso -----------------------------------------------------------------------------------

function torsoSide(ctx, hip, lean, view) {
  const top = add(hip, [Math.sin(rad(lean)) * 125, -Math.cos(rad(lean)) * 125]);
  const n = [Math.cos(rad(lean)), Math.sin(rad(lean))]; // forward, perpendicular to the spine
  const back = view === "side" ? 22 : 34, front = view === "side" ? 26 : 36;
  const p = (base, k) => [base[0] + n[0] * k, base[1] + n[1] * k];
  // Hood resting behind the neck.
  outlined(ctx, C.berryDark, () => ctx.ellipse(top[0] - n[0] * 14, top[1] - 4, 26, 16, rad(lean), 0, Math.PI * 2));
  outlined(ctx, C.berry, () => {
    const a = p(top, -back), b = p(top, front), c = p(hip, front - 2), d = p(hip, -back + 2);
    ctx.moveTo(a[0], a[1] + 8);
    ctx.quadraticCurveTo(a[0], a[1] - 4, a[0] + 14 * n[0], a[1] - 6);
    ctx.lineTo(b[0] - 10 * n[0], b[1] - 6);
    ctx.quadraticCurveTo(b[0], b[1] - 4, b[0], b[1] + 10);
    ctx.lineTo(c[0], c[1] + 6);
    ctx.lineTo(d[0], d[1] + 6);
    ctx.closePath();
  });
  // The open front: the cream T-shirt showing between the hoodie's edges.
  const w = view === "side" ? 7 : 16;
  outlined(ctx, C.cream, () => {
    const a = p(top, front - w - 4), b = p(top, front - 1), c = p(hip, front - 3), d = p(hip, front - w - 6);
    ctx.moveTo(a[0], a[1]);
    ctx.lineTo(b[0], b[1]);
    ctx.lineTo(c[0], c[1] + 4);
    ctx.lineTo(d[0], d[1] + 4);
    ctx.closePath();
  }, LINE * 0.75);
  // A drawstring.
  const s0 = p(top, front - w - 2), s1 = add(s0, [Math.sin(rad(lean)) * -44, Math.cos(rad(lean)) * 44]);
  ctx.beginPath();
  ctx.moveTo(...s0);
  ctx.lineTo(...s1);
  ctx.lineWidth = 3;
  ctx.strokeStyle = C.cream;
  ctx.stroke();
  dot(ctx, s1[0], s1[1], 3.4, C.cream);
  return { top, shoulderF: p(top, 2), shoulderB: p(top, view === "side" ? -2 : -16) };
}

// ---- Head and face ----------------------------------------------------------------------------

const FACES = {
  // brows: [inner y, outer y] offsets; mouth: kind
  neutral: { brow: [-2, -2], mouth: "smile", lid: false, blush: 0.6 },
  tired: { brow: [-3, 4], mouth: "flat", lid: true, blush: 0.3 },
  annoyed: { brow: [5, -4], mouth: "frown", lid: false, blush: 0.4 },
  embarrassed: { brow: [-7, 0], mouth: "wobble", lid: false, blush: 1.4 },
  proud: { brow: [-6, -5], mouth: "grin", lid: false, blush: 0.8 },
};
export const EXPRESSIONS = Object.keys(FACES);

function face(ctx, expression, { eyes, mouth, mouthW }) {
  const f = FACES[expression] ?? FACES.neutral;
  for (const e of eyes) {
    // Blush under each eye.
    ctx.beginPath();
    ctx.ellipse(e.x + (e.cheek ?? 0), e.y + 15, 9 * e.s, 5 * e.s, 0, 0, Math.PI * 2);
    ctx.fillStyle = f.blush > 1 ? "rgba(224,100,74,.5)" : `rgba(224,100,74,${0.28 * f.blush})`;
    ctx.fill();
    dot(ctx, e.x, e.y, 5.4 * e.s, C.ink, null);
    dot(ctx, e.x + 1.6 * e.s, e.y - 1.8 * e.s, 1.5 * e.s, "#ffffff", null);
    if (f.lid) {
      ctx.beginPath();
      ctx.moveTo(e.x - 7 * e.s, e.y - 1);
      ctx.quadraticCurveTo(e.x, e.y - 4, e.x + 7 * e.s, e.y - 1);
      ctx.lineWidth = 3;
      ctx.strokeStyle = C.ink;
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(e.x - 6 * e.s, e.y - 2.4);
      ctx.lineTo(e.x + 6 * e.s, e.y - 2.4);
      ctx.lineTo(e.x + 6 * e.s, e.y - 8);
      ctx.lineTo(e.x - 6 * e.s, e.y - 8);
      ctx.fillStyle = C.skin;
      ctx.fill();
    }
    // Brow: inner end toward the face centre.
    const inner = e.side * -1;
    ctx.beginPath();
    ctx.moveTo(e.x + inner * 7 * e.s, e.y - 13 + f.brow[0]);
    ctx.lineTo(e.x - inner * 7 * e.s, e.y - 13 + f.brow[1]);
    ctx.lineWidth = 3.6;
    ctx.lineCap = "round";
    ctx.strokeStyle = C.hair;
    ctx.stroke();
  }
  const [mx, my] = mouth, w = mouthW;
  ctx.beginPath();
  ctx.lineWidth = 3.4;
  ctx.strokeStyle = C.ink;
  ctx.lineCap = "round";
  if (f.mouth === "smile") { ctx.moveTo(mx - w, my - 1); ctx.quadraticCurveTo(mx, my + 6, mx + w, my - 1); ctx.stroke(); }
  if (f.mouth === "flat") { ctx.moveTo(mx - w * 0.8, my + 1); ctx.lineTo(mx + w * 0.8, my + 2); ctx.stroke(); }
  if (f.mouth === "frown") { ctx.moveTo(mx - w * 0.9, my + 3); ctx.quadraticCurveTo(mx, my - 2, mx + w * 0.9, my + 3); ctx.stroke(); }
  if (f.mouth === "wobble") { ctx.moveTo(mx - w * 0.8, my + 1); ctx.bezierCurveTo(mx - w * 0.3, my - 3, mx + w * 0.3, my + 5, mx + w * 0.8, my + 1); ctx.stroke(); }
  if (f.mouth === "grin") {
    outlined(ctx, "#8c3a2c", () => { ctx.moveTo(mx - w * 1.2, my - 3); ctx.quadraticCurveTo(mx, my + 16, mx + w * 1.2, my - 3); ctx.closePath(); }, 3);
    ctx.beginPath();
    ctx.moveTo(mx - w * 0.9, my - 1.5);
    ctx.lineTo(mx + w * 0.9, my - 1.5);
    ctx.lineWidth = 3;
    ctx.strokeStyle = "#ffffff";
    ctx.stroke();
  }
}

// The Leaf hair clip, on her right side.
function clip(ctx, x, y, angle = -0.5) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(angle);
  outlined(ctx, C.leaf, () => ctx.roundRect(-11, -4.5, 22, 9, 4.5), 3);
  ctx.restore();
}

// Draws the head centred at (0, 0), radius about 46. facing: front | three-quarter | side | back.
export function drawHead(ctx, facing = "front", expression = "neutral") {
  const R = 46;
  if (facing === "back") {
    outlined(ctx, C.hair, () => { ctx.moveTo(-R - 6, 26); ctx.bezierCurveTo(-R - 10, -64, R + 10, -64, R + 6, 26); ctx.quadraticCurveTo(0, 40, -R - 6, 26); });
    ctx.beginPath();
    ctx.moveTo(-8, -40); ctx.quadraticCurveTo(-4, 0, -12, 26);
    ctx.moveTo(14, -36); ctx.quadraticCurveTo(18, 0, 12, 28);
    ctx.lineWidth = 3; ctx.strokeStyle = C.hairHi; ctx.stroke();
    clip(ctx, R - 6, -18, 0.6);
    return;
  }
  const shift = facing === "front" ? 0 : facing === "three-quarter" ? 12 : 22;
  // Back of the bob, behind the face.
  outlined(ctx, C.hair, () => {
    ctx.moveTo(-R - 6 + shift * 0.2, 30);
    ctx.bezierCurveTo(-R - 12, -64, R + 10, -66, R + 6 - shift * 0.4, 26);
    ctx.lineTo(R - 2, 32);
    ctx.quadraticCurveTo(0, 44, -R - 6 + shift * 0.2, 30);
  });
  // Face.
  outlined(ctx, C.skin, () => {
    if (facing === "side") {
      ctx.moveTo(-14, -42);
      ctx.bezierCurveTo(30, -50, 46, -20, 46, -4);
      ctx.lineTo(52, 8);
      ctx.lineTo(45, 12);
      ctx.quadraticCurveTo(44, 34, 20, 40);
      ctx.quadraticCurveTo(-8, 42, -14, 24);
      ctx.closePath();
    } else ctx.ellipse(shift * 0.6, 2, R - 4 - shift * 0.25, R, 0, 0, Math.PI * 2);
  });
  // Ears.
  if (facing === "side") outlined(ctx, C.skin, () => ctx.ellipse(-6, 6, 8, 11, 0, 0, Math.PI * 2), 3);
  if (facing === "three-quarter") outlined(ctx, C.skin, () => ctx.ellipse(-30, 8, 7, 10, 0, 0, Math.PI * 2), 3);
  // Bangs over the forehead.
  outlined(ctx, C.hair, () => {
    ctx.moveTo(-R + shift * 0.2, -4);
    ctx.bezierCurveTo(-R - 2, -60, R + 4 - shift * 0.3, -62, R - shift * 0.35, -6);
    ctx.quadraticCurveTo(R * 0.45 + shift * 0.3, -22, shift * 0.8 + 4, -20);
    ctx.quadraticCurveTo(-R * 0.4 + shift * 0.6, -26, -R + shift * 0.2, -4);
  });
  // Side lock of the bob in front of the near cheek (front and three-quarter).
  if (facing !== "side") {
    outlined(ctx, C.hair, () => { ctx.moveTo(-R + shift * 0.2, -6); ctx.quadraticCurveTo(-R - 6 + shift * 0.2, 20, -R + 2 + shift * 0.2, 32); ctx.lineTo(-R + 12 + shift * 0.2, 30); ctx.quadraticCurveTo(-R + 8 + shift * 0.2, 10, -R + 10 + shift * 0.3, -10); ctx.closePath(); }, 3);
  }
  if (facing === "front") {
    outlined(ctx, C.hair, () => { ctx.moveTo(R, -6); ctx.quadraticCurveTo(R + 6, 20, R - 2, 32); ctx.lineTo(R - 12, 30); ctx.quadraticCurveTo(R - 8, 10, R - 10, -10); ctx.closePath(); }, 3);
    clip(ctx, -R + 10, -20, -0.55);
    face(ctx, expression, { eyes: [{ x: -17, y: 4, s: 1, side: -1 }, { x: 17, y: 4, s: 1, side: 1 }], mouth: [0, 24], mouthW: 9 });
  } else if (facing === "three-quarter") {
    face(ctx, expression, { eyes: [{ x: 2, y: 4, s: 0.9, side: -1, cheek: -2 }, { x: 30, y: 4, s: 1, side: 1 }], mouth: [20, 24], mouthW: 8 });
    ctx.beginPath(); ctx.moveTo(24, 10); ctx.quadraticCurveTo(28, 15, 23, 16); ctx.lineWidth = 2.6; ctx.strokeStyle = C.skinShade; ctx.stroke();
  } else {
    face(ctx, expression, { eyes: [{ x: 28, y: 2, s: 1, side: 1 }], mouth: [36, 24], mouthW: 7 });
  }
}

// ---- Whole figure -----------------------------------------------------------------------------

function neckAndHead(ctx, top, lean, headTilt, facing, expression) {
  const neckTop = add(top, [Math.sin(rad(lean)) * 20, -Math.cos(rad(lean)) * 20]);
  limb(ctx, [top, neckTop], 18, C.skin);
  const tilt = lean + headTilt;
  const centre = add(neckTop, [Math.sin(rad(tilt)) * 44, -Math.cos(rad(tilt)) * 44]);
  ctx.save();
  ctx.translate(...centre);
  ctx.rotate(rad(tilt) * 0.8);
  drawHead(ctx, facing, expression);
  ctx.restore();
  return centre;
}

function phoneProp(ctx, at, angle) {
  ctx.save();
  ctx.translate(...at);
  ctx.rotate(angle);
  outlined(ctx, C.ink, () => ctx.roundRect(-11, -20, 22, 40, 6), 3);
  ctx.fillStyle = C.mint;
  ctx.beginPath(); ctx.roundRect(-8, -16, 16, 32, 4); ctx.fill();
  ctx.restore();
}

function sideFigure(ctx, facing, expression, pose) {
  const P = POSES[pose] ?? POSES.stand;
  const hip = P.hip;
  const view = facing === "side" ? "side" : "three-quarter";
  const top = add(hip, [Math.sin(rad(P.lean)) * 125, -Math.cos(rad(P.lean)) * 125]);
  const n = [Math.cos(rad(P.lean)), Math.sin(rad(P.lean))];
  const shoulderB = add(top, [n[0] * (view === "side" ? -2 : -18), n[1] * (view === "side" ? -2 : -18) + 10]);
  const shoulderF = add(top, [n[0] * (view === "side" ? 2 : 14), n[1] * (view === "side" ? 2 : 14) + 10]);
  const hipB = add(hip, [view === "side" ? 0 : -10, 0]);
  const hipF = add(hip, [view === "side" ? 4 : 12, 4]);
  const back = arm(ctx, shoulderB, P.armB, { near: false });
  leg(ctx, hipB, P.legB, false);
  leg(ctx, hipF, P.legF, true);
  torsoSide(ctx, hip, P.lean, view);
  let head;
  if (!P.armOver) head = neckAndHead(ctx, top, P.lean, P.head, facing, expression);
  const front = arm(ctx, shoulderF, P.armF, { near: true, sensorOn: true });
  if (P.armOver) head = neckAndHead(ctx, top, P.lean, P.head, facing, expression);
  if (P.prop === "phone") phoneProp(ctx, add(front.wrist, [4, -10]), 0.25);
  return { head, top, hands: [back.wrist, front.wrist] };
}

function frontFigure(ctx, facing, expression, pose) {
  const P = POSES[pose] ?? POSES.stand;
  const hipY = P.hip[1];
  const topY = hipY - 125;
  const isBack = facing === "back";
  // Arms swing out to the sides; "forward" angle is used as a raise.
  const armAngles = (a, side) => [side * (6 + Math.max(0, a[0]) * 0.1) + (a[0] > 90 ? side * 0 : 0), side * (4 + Math.max(0, a[1]) * 0.08)];
  const shoulders = [[-46, topY + 12, -1], [46, topY + 12, 1]];
  // Hood behind the neck.
  outlined(ctx, C.berryDark, () => ctx.ellipse(0, topY + 2, 40, 16, 0, 0, Math.PI * 2));
  for (const [hx, side] of [[-20, -1], [20, 1]]) leg(ctx, [hx, hipY], [side * 2, 0], true);
  // Arms behind the torso edges.
  const wrists = [];
  for (const [sx, sy, side] of shoulders) {
    const raise = (pose === "cheer" && side === (isBack ? -1 : 1));
    const upper = raise ? side * 160 : side * 12, fore = raise ? side * 170 : side * 6;
    const elbow = add([sx, sy], down(upper, 70));
    const wrist = add(elbow, down(fore, 62));
    wrists.push(wrist);
    limb(ctx, [elbow, wrist], 19, C.skin);
    dot(ctx, wrist[0], wrist[1], 11, C.skin);
    limb(ctx, [[sx, sy], elbow], 27, C.berry);
    ctx.save(); ctx.translate(...elbow); ctx.rotate(-rad(upper));
    outlined(ctx, C.berry, () => ctx.ellipse(0, -6, 17, 9, 0, 0, Math.PI * 2), LINE * 0.75);
    ctx.restore();
    // Her left arm is screen-right from the front, screen-left from the back; the sensor is on its back,
    // so it shows only from behind.
    if (isBack && side === -1) wrists.sensorAt = add([sx, sy], down(upper, 30));
  }
  void armAngles;
  // Torso.
  outlined(ctx, C.berry, () => {
    ctx.moveTo(-50, topY + 14);
    ctx.quadraticCurveTo(-48, topY - 2, -30, topY - 2);
    ctx.lineTo(30, topY - 2);
    ctx.quadraticCurveTo(48, topY - 2, 50, topY + 14);
    ctx.lineTo(42, hipY + 8);
    ctx.lineTo(-42, hipY + 8);
    ctx.closePath();
  });
  if (isBack) {
    // The hood hanging down her back.
    outlined(ctx, C.berryDark, () => { ctx.moveTo(-30, topY + 2); ctx.quadraticCurveTo(-34, topY + 56, 0, topY + 62); ctx.quadraticCurveTo(34, topY + 56, 30, topY + 2); ctx.closePath(); });
  } else {
    outlined(ctx, C.cream, () => { ctx.moveTo(-18, topY - 2); ctx.lineTo(18, topY - 2); ctx.lineTo(14, hipY + 8); ctx.lineTo(-14, hipY + 8); ctx.closePath(); }, LINE * 0.75);
    for (const x of [-12, 12]) {
      ctx.beginPath(); ctx.moveTo(x * 1.25, topY + 4); ctx.lineTo(x * 1.25, topY + 50);
      ctx.lineWidth = 3; ctx.strokeStyle = C.berryDark; ctx.stroke();
      dot(ctx, x * 1.25, topY + 52, 3.4, C.cream);
    }
  }
  // Upper arms over the torso edge, so the sleeve and (from behind) the sensor read clearly.
  shoulders.forEach(([sx, sy, side]) => {
    const raise = pose === "cheer" && side === (isBack ? -1 : 1);
    const elbow = add([sx, sy], down(raise ? side * 160 : side * 12, 70));
    limb(ctx, [[sx, sy], elbow], 27, C.berry);
  });
  if (wrists.sensorAt) sensor(ctx, wrists.sensorAt[0] - 4, wrists.sensorAt[1]);
  limb(ctx, [[0, topY], [0, topY - 20]], 18, C.skin);
  ctx.save();
  ctx.translate(0, topY - 64);
  drawHead(ctx, facing, expression);
  ctx.restore();
  return { head: [0, topY - 64], top: [0, topY], hands: wrists };
}

export function drawMaya(ctx, { x = 0, y = 0, scale = 1, facing = "front", expression = "neutral", pose = "stand", flip = false, t = 0 } = {}) {
  ctx.save();
  ctx.translate(x, y);
  ctx.scale(flip ? -scale : scale, scale);
  // A breath: 2 px over 3.6 s, so she never looks frozen.
  const breathe = Math.sin((t / 3.6) * Math.PI * 2) * 1.2;
  const P = POSES[pose] ?? POSES.stand;
  let out;
  if (P.lying) {
    ctx.translate(-180, -40);
    ctx.rotate(-Math.PI / 2);
    ctx.translate(0, 230);
    out = sideFigure(ctx, "side", expression, pose);
    // The pillow, held over her head.
    ctx.save();
    ctx.translate(out.head[0] + 6, out.head[1] - 10);
    outlined(ctx, C.cream, () => ctx.roundRect(-58, -66, 116, 132, 40));
    ctx.beginPath(); ctx.moveTo(-36, -44); ctx.quadraticCurveTo(-20, 0, -36, 44); ctx.lineWidth = 3; ctx.strokeStyle = C.mint; ctx.stroke();
    ctx.restore();
    for (const w of out.hands) dot(ctx, w[0], w[1], 11, C.skin);
  } else {
    ctx.translate(0, breathe);
    out = facing === "front" || facing === "back" ? frontFigure(ctx, facing, expression, pose) : sideFigure(ctx, facing, expression, pose);
  }
  ctx.restore();
  return out;
}

// A thought bubble with an Ink outline and a tail of two dots toward (tx, ty).
export function thought(ctx, x, y, text, { tx, ty, size = 44, font = "Nunito" } = {}) {
  ctx.save();
  ctx.font = `800 ${size}px ${font}, ui-rounded, system-ui, sans-serif`;
  const w = ctx.measureText(text).width + size * 1.4, h = size * 2;
  outlined(ctx, "#ffffff", () => ctx.roundRect(x - w / 2, y - h / 2, w, h, h / 2));
  if (tx !== undefined) {
    dot(ctx, x + (tx - x) * 0.55, y + h / 2 + (ty - y - h / 2) * 0.45, size * 0.22, "#ffffff");
    dot(ctx, x + (tx - x) * 0.8, y + h / 2 + (ty - y - h / 2) * 0.8, size * 0.13, "#ffffff");
  }
  ctx.fillStyle = C.ink;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(text, x, y + 2);
  ctx.restore();
}
