// Matte OS logo geometry: a camera aperture drawn as a hexagon whose edges run out to the rim.
// Everything is in a 120 x 120 box, centred on (60, 60), the same box as the design canvas.

export const COLORS = {
  ink: "#050608",      // near-black background
  blade: "#E6E9EF",    // light disc
  line: "#0B0D12",     // blade lines and opening
  muted: "#8B93A3",    // secondary text
  accent: "#7DD3FC",   // sky-blue light
};

const C = 60;          // centre
const RIM = 46;        // disc radius

// Hexagon corners for an opening of radius r, turned by `turn` degrees.
function corners(r, turn) {
  const pts = [];
  for (let k = 0; k < 6; k++) {
    const a = ((60 * k + turn) * Math.PI) / 180;
    pts.push([C + r * Math.cos(a), C + r * Math.sin(a)]);
  }
  return pts;
}

const f = (n) => Number(n.toFixed(2));

// One aperture mark as SVG markup (no <svg> wrapper).
//   r       opening radius: 18 is the logo, 26 is fully open, ~5 is nearly closed
//   turn    rotation of the blades in degrees
//   stroke  blade line width (thicker for small sizes)
//   disc / line   colours of the disc and of the lines + opening
export function apertureMarkup({ r = 18, turn = 0, stroke = 4, disc = COLORS.blade, line = COLORS.line, clipId = "rim" } = {}) {
  const p = corners(r, turn);
  const lines = p
    .map((a, k) => {
      const b = p[(k + 1) % 6];
      const dx = b[0] - a[0];
      const dy = b[1] - a[1];
      const len = Math.hypot(dx, dy);
      // Run each edge on from its start corner, well past the rim; the clip trims it.
      const ex = a[0] + (dx / len) * 120;
      const ey = a[1] + (dy / len) * 120;
      return `M${f(a[0])} ${f(a[1])}L${f(ex)} ${f(ey)}`;
    })
    .join("");
  const hex = p.map(([x, y]) => `${f(x)},${f(y)}`).join(" ");
  return (
    `<defs><clipPath id="${clipId}"><circle cx="${C}" cy="${C}" r="${RIM}"/></clipPath></defs>` +
    `<circle cx="${C}" cy="${C}" r="${RIM}" fill="${disc}"/>` +
    `<g clip-path="url(#${clipId})"><path d="${lines}" stroke="${line}" stroke-width="${stroke}" fill="none"/></g>` +
    `<polygon points="${hex}" fill="${line}"/>`
  );
}

// The chosen logo (direction A, "Blades"): solid blades and a small blue light in the centre.
// Stroke and dot grow a little at small sizes so the mark stays readable.
export function logoSvg(px = 120, { light = true, disc = COLORS.blade, line = COLORS.line } = {}) {
  const stroke = px >= 96 ? 4 : px >= 40 ? 6 : px >= 28 ? 8 : 10;
  const dot = px >= 96 ? 5 : px >= 40 ? 6 : 7;
  const showDot = light && px > 22;
  return (
    `<svg xmlns="http://www.w3.org/2000/svg" width="${px}" height="${px}" viewBox="0 0 120 120">` +
    apertureMarkup({ r: 18, stroke, disc, line }) +
    (showDot ? `<circle cx="60" cy="60" r="${dot}" fill="${COLORS.accent}"/>` : "") +
    `</svg>`
  );
}
