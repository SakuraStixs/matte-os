// Renders Matte OS's branding (logo icons, wallpapers, login background, Plymouth frames)
// into system_files/. Run from the repo root:
//
//     node branding/generate.mjs
//
// Needs Node with Playwright's Chromium, and Plus Jakarta Sans installed as a system font
// (the copy in system_files/usr/share/fonts/plus-jakarta-sans works: fc-cache after copying).
// The outputs are committed, so the image build never runs this.

import { chromium } from "playwright";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { execFileSync } from "node:child_process";
import { COLORS, apertureMarkup, logoSvg } from "./aperture.mjs";

const ROOT = new URL("..", import.meta.url).pathname;
const SYS = join(ROOT, "system_files");
const out = (p) => {
  const full = join(SYS, p);
  mkdirSync(dirname(full), { recursive: true });
  return full;
};

const browser = await chromium.launch();
const page = await browser.newPage({ deviceScaleFactor: 1 });

async function shoot(html, file, { width, height, transparent = true }) {
  await page.setViewportSize({ width, height });
  await page.setContent(
    `<!doctype html><html><head><meta charset="utf-8"><style>
      html,body{margin:0;padding:0;background:${transparent ? "transparent" : COLORS.ink}}
      #s{width:${width}px;height:${height}px;position:relative;overflow:hidden}
    </style></head><body><div id="s">${html}</div></body></html>`,
    { waitUntil: "load" }
  );
  await page.evaluate(() => document.fonts.ready);
  await page.locator("#s").screenshot({ path: file, omitBackground: transparent });
}

// ---------- 1. Logo: SVG + PNG icons ----------
writeFileSync(out("usr/share/icons/hicolor/scalable/apps/matte-os-logo.svg"), logoSvg(120) + "\n");
writeFileSync(out("usr/share/pixmaps/matte-os-logo.svg"), logoSvg(120) + "\n");
// Heavier lines for the 20-24 px launcher button in the shell's bar.
writeFileSync(out("usr/share/pixmaps/matte-os-logo-small.svg"), logoSvg(24) + "\n");
for (const px of [16, 22, 24, 32, 48, 64, 128, 256]) {
  await shoot(logoSvg(px), out(`usr/share/icons/hicolor/${px}x${px}/apps/matte-os-logo.png`), { width: px, height: px });
}
await shoot(logoSvg(256), out("usr/share/pixmaps/matte-os-logo.png"), { width: 256, height: 256 });

// ---------- 2. Wallpaper and login background ----------
// Near-black with one soft shape, as in the style guide. Rendered at 4K with a little grain
// so the dark gradient doesn't band, then saved as a high-quality JPEG.
const W = 3840, H = 2160;
const softShape = `
  <div style="position:absolute;inset:0;background:${COLORS.ink}"></div>
  <div style="position:absolute;left:${W * 0.52}px;top:${-H * 0.28}px;width:${W * 0.62}px;height:${H * 0.95}px;
       border-radius:50%;background:radial-gradient(closest-side, rgba(70,96,128,0.34), rgba(40,56,80,0.14) 55%, rgba(5,6,8,0) 100%);
       filter:blur(${H * 0.06}px);transform:rotate(-18deg)"></div>
  <div style="position:absolute;left:${W * 0.08}px;top:${H * 0.62}px;width:${W * 0.45}px;height:${H * 0.6}px;
       border-radius:50%;background:radial-gradient(closest-side, rgba(125,211,252,0.05), rgba(5,6,8,0) 100%);
       filter:blur(${H * 0.08}px)"></div>`;

async function wallpaper(extra, file) {
  const png = file.replace(/\.jpg$/, ".tmp.png");
  await shoot(softShape + extra, png, { width: W, height: H, transparent: false });
  // Grain + JPEG: keeps the gradient smooth on 8-bit screens and the file small.
  execFileSync("convert", [png, "-seed", "7", "-attenuate", "0.22", "+noise", "Gaussian", "-quality", "88", "-sampling-factor", "4:4:4", file]);
  execFileSync("rm", [png]);
}

await wallpaper("", out("usr/share/backgrounds/matte-os/matte-dark.jpg"));

// Login: the same backdrop with the small wordmark at the bottom centre (Login board on the canvas).
const S = 2; // 4K = 2x the 1080p mock-up
const wordmark = `
  <div style="position:absolute;left:0;right:0;bottom:${34 * S}px;display:flex;justify-content:center;align-items:center;gap:${8 * S}px;
       font-family:'Plus Jakarta Sans';font-size:${12 * S}px;color:${COLORS.muted}">
    ${logoSvg(18 * S, { disc: COLORS.muted, line: COLORS.ink }).replace(/width="\d+" height="\d+"/, `width="${18 * S}" height="${18 * S}"`)}
    <span>Matte OS</span>
  </div>`;
await wallpaper(wordmark, out("usr/share/backgrounds/matte-os/matte-login.jpg"));

// ---------- 3. Plymouth boot animation frames ----------
// Storyboard: the aperture fades in nearly closed, its blades open and a light appears inside;
// the light rises to the top and stretches into Iris. The script (matte.script) moves the
// sprites; these are the pieces it moves.
const PLY = "usr/share/plymouth/themes/matte";
const LOGO = 160;                // aperture size on screen
const ease = (t) => 1 - Math.pow(1 - t, 3);

// 3a. Aperture opening: 30 frames from nearly closed to fully open.
const OPEN_FRAMES = 30;
for (let i = 0; i < OPEN_FRAMES; i++) {
  const t = ease(i / (OPEN_FRAMES - 1));
  const r = 5 + (26 - 5) * t;
  const turn = -35 * (1 - t);
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${LOGO}" height="${LOGO}" viewBox="0 0 120 120">` +
    apertureMarkup({ r, turn, stroke: 4, line: COLORS.ink }) + `</svg>`;
  await shoot(svg, out(`${PLY}/aperture-${String(i).padStart(2, "0")}.png`), { width: LOGO, height: LOGO });
}

// 3b. The light: an accent pill with a soft glow, at 24 sizes from "inside the aperture"
// (28 x 10 in logo units) up to Iris's idle size (150 x 34 px).
const LIGHT_STEPS = 24;
const GLOW = 18;
const startW = (28 * LOGO) / 120, startH = (10 * LOGO) / 120;
const lights = [];
for (let i = 0; i < LIGHT_STEPS; i++) {
  const t = i / (LIGHT_STEPS - 1);
  const w = Math.round(startW + (150 - startW) * t);
  const h = Math.round(startH + (34 - startH) * t);
  lights.push({ w, h });
  const html = `<div style="position:absolute;left:${GLOW}px;top:${GLOW}px;width:${w}px;height:${h}px;border-radius:${h}px;
      background:${COLORS.accent};box-shadow:0 0 ${GLOW * 0.8}px ${GLOW * 0.15}px rgba(125,211,252,0.45)"></div>`;
  await shoot(html, out(`${PLY}/light-${String(i).padStart(2, "0")}.png`), { width: w + GLOW * 2, height: h + GLOW * 2 });
}

// 3c. Iris at rest: the dark glass pill with one blue dot (frame 5 of the storyboard).
await shoot(
  `<div style="position:absolute;left:0;top:0;width:150px;height:34px;box-sizing:border-box;border-radius:999px;
     background:#0E1016;border:1px solid rgba(255,255,255,0.14)"></div>`,
  out(`${PLY}/iris.png`), { width: 150, height: 34 });
await shoot(
  `<div style="position:absolute;left:7px;top:7px;width:6px;height:6px;border-radius:3px;background:${COLORS.accent};
     box-shadow:0 0 6px 1px rgba(125,211,252,0.6)"></div>`,
  out(`${PLY}/dot.png`), { width: 20, height: 20 });

// 3d. Password field for encrypted disks: a pill like the login screen's, and a bullet.
await shoot(
  `<div style="position:absolute;left:0;top:0;width:320px;height:46px;box-sizing:border-box;border-radius:999px;
     background:rgba(14,16,22,0.92);border:1px solid rgba(255,255,255,0.10)"></div>`,
  out(`${PLY}/entry.png`), { width: 320, height: 46 });
await shoot(
  `<div style="position:absolute;left:1px;top:1px;width:8px;height:8px;border-radius:4px;background:#E6E9EF"></div>`,
  out(`${PLY}/bullet.png`), { width: 10, height: 10 });

writeFileSync(join(ROOT, "branding", "light-sizes.json"), JSON.stringify({ glow: GLOW, logo: LOGO, lights }, null, 2) + "\n");

await browser.close();
console.log("Branding rendered into system_files/.");
