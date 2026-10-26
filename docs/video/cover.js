// The CAC cover photo (3:4): node render.mjs cover out/final/cover.png, then a 600×800 JPEG.
// A scrapbook page: the app icon, the name, the slogan, and two real screens as taped photos.
export const SIZE = [1200, 1600];

export function render(ctx, t, A) {
  const img = (k) => (window.ASSETS ? window.ASSETS[k] : null);
  ctx.fillStyle = "#c8a274"; ctx.fillRect(0, 0, 1200, 1600);
  ctx.save(); ctx.shadowColor = "rgba(60,40,20,.35)"; ctx.shadowBlur = 24; ctx.shadowOffsetY = 8;
  ctx.fillStyle = "#fbf6ea"; ctx.beginPath(); ctx.roundRect(40, 40, 1120, 1520, 14); ctx.fill(); ctx.restore();
  ctx.fillStyle = "rgba(47,74,59,.12)";
  for (let y = 80; y < 1540; y += 40) for (let x = 80; x < 1140; x += 40) ctx.fillRect(x, y, 3, 3);
  // Icon and name.
  const icon = img("appIcon");
  ctx.save(); ctx.shadowColor = "rgba(30,45,36,.3)"; ctx.shadowBlur = 20; ctx.shadowOffsetY = 10;
  ctx.fillStyle = "#fff"; ctx.beginPath(); ctx.roundRect(470, 110, 260, 260, 62); ctx.fill(); ctx.restore();
  if (icon) { ctx.save(); ctx.beginPath(); ctx.roundRect(482, 122, 236, 236, 54); ctx.clip(); ctx.drawImage(icon, 482, 122, 236, 236); ctx.restore(); }
  text(ctx, "DiabetesCare", 600, 470, { size: 110, weight: 900, color: C.pine });
  ctx.font = '700 54px Caveat, cursive'; ctx.fillStyle = C.ink; ctx.textAlign = "center";
  ctx.fillText("grows with kids who have type 1 diabetes", 600, 555);
  // Two real screens, taped in like photos.
  const shot = (name, x, y, rot) => {
    const s = img(name); if (!s) return;
    const w = 380, h = (w * s.height) / s.width;
    ctx.save(); ctx.translate(x, y); ctx.rotate(rot);
    ctx.shadowColor = "rgba(30,45,36,.3)"; ctx.shadowBlur = 18; ctx.shadowOffsetY = 10;
    ctx.fillStyle = "#fff"; ctx.fillRect(-w / 2 - 16, -330, w + 32, 700);
    ctx.shadowColor = "transparent"; ctx.beginPath(); ctx.rect(-w / 2, -314, w, 668); ctx.clip(); ctx.drawImage(s, -w / 2, -314, w, h);
    ctx.restore();
    ctx.save(); ctx.translate(x, y - 330); ctx.rotate(rot - 0.2); ctx.globalAlpha = 0.85; ctx.fillStyle = "#bfe0c9"; ctx.fillRect(-80, -22, 160, 44); ctx.restore();
  };
  shot("kidToday", 380, 1000, -0.06);
  shot("pathKid", 820, 1020, 0.05);
  // The slogan on a strip.
  ctx.save(); ctx.translate(600, 1440); ctx.rotate(-0.015);
  ctx.shadowColor = "rgba(60,40,20,.25)"; ctx.shadowBlur = 12; ctx.shadowOffsetY = 6;
  ctx.fillStyle = "#fff"; ctx.fillRect(-500, -70, 1000, 140); ctx.shadowColor = "transparent";
  text(ctx, "Diabetes doesn't stop growing.", 0, -24, { size: 46, weight: 900, color: C.ink });
  text(ctx, "DiabetesCare doesn't stop caring.", 0, 32, { size: 46, weight: 900, color: C.pine });
  ctx.restore();
}
