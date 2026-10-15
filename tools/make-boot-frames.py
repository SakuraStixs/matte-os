#!/usr/bin/env python3
"""Matte OS boot animation v2 (50 fps, motion blur, soft glow).

The Iris aperture draws itself, its six blades unfold, the centre ignites, and the blades fly out as
tapered streaks while a small solar system fades in. intro-NNN.png plays once, loop-NNN.png repeats.

Usage: make-boot-frames.py OUTDIR [intro|loop|all]
"""
import math, os, random, sys
import numpy as np
from multiprocessing import Pool
from PIL import Image, ImageChops, ImageDraw, ImageFilter

SIZE = 720
OUT = 512                        # shipped size: Plymouth keeps every frame decoded in RAM (4 bytes/pixel)
SS = 2
S = SIZE * SS
C = S / 2
INTRO, LOOP = 120, 200           # frames at 50 fps: 2.4 s intro, 4 s loop
BG, WHITE = 10, 242
R = 120 * SS                     # aperture ring radius
BLADE_OUT, BLADE_IN, TWIST = 116 * SS, 43 * SS, math.radians(115)
SUBFRAMES, SHUTTER = 5, 0.5      # intro motion blur

def clamp(x, a=0.0, b=1.0): return max(a, min(b, x))
def seg(t, a, b): return clamp((t - a) / (b - a))
def e_out(t): return 1 - (1 - t) ** 3
def e_in(t): return t ** 2.2
def e_io(t): return 0.5 - 0.5 * math.cos(math.pi * clamp(t))
def e_back(t, s=1.55):
    t = clamp(t); c = s + 1
    return 1 + c * (t - 1) ** 3 + s * (t - 1) ** 2
def lv(a): return int(BG + (WHITE - BG) * clamp(a))
def pt(r, a): return (C + r * math.cos(a), C + r * math.sin(a))

random.seed(11)
STARS = []
for _ in range(110):
    STARS.append((random.uniform(0, 2 * math.pi), (random.random() ** 0.75) * 345 * SS,
                  random.uniform(0.7, 1.8) * SS, random.uniform(0, 2 * math.pi), random.randint(1, 3)))
def edge_fade(rad): return clamp((345 * SS - rad) / (120 * SS))

A = dict(r=190 * SS, lap=1, start=math.radians(-35), delta=math.radians(150))
B = dict(r=268 * SS, lap=-1, start=math.radians(150), delta=math.radians(-120))

def line(d, p, q, a, w):
    if a > 0.01: d.line([p, q], fill=lv(a), width=max(1, int(round(w * SS))))

def planet(img, x, y, r, banded, ring, alpha):
    if r < 0.6 or alpha <= 0.02: return
    pad = int(r * 3) + 6
    W = pad * 2
    col, msk = Image.new("L", (W, W), 0), Image.new("L", (W, W), 0)
    cd, md = ImageDraw.Draw(col), ImageDraw.Draw(msk)
    box = [pad - r, pad - r, pad + r, pad + r]
    md.ellipse(box, fill=255); cd.ellipse(box, fill=WHITE)
    if banded:
        for k in (-0.5, -0.12, 0.28):
            cd.line([(pad - r, pad + k * r + 0.14 * r), (pad + r, pad + k * r - 0.14 * r)], fill=40, width=max(1, int(0.17 * r)))
    if ring:
        rc, rm = Image.new("L", (W, W), 0), Image.new("L", (W, W), 0)
        rx, ry = r * 2.15, r * 0.56
        for im in (rc, rm):
            ImageDraw.Draw(im).ellipse([pad - rx, pad - ry, pad + rx, pad + ry], outline=255 if im is rm else WHITE, width=max(1, int(1.4 * SS)))
        rc, rm = rc.rotate(16, resample=Image.BICUBIC), rm.rotate(16, resample=Image.BICUBIC)
        col, msk = ImageChops.lighter(col, rc), ImageChops.lighter(msk, rm)
    msk = msk.point(lambda v: int(v * clamp(alpha)))
    img.paste(col, (int(x - pad), int(y - pad)), msk)

def draw_scene(ft):
    """One sharp, supersampled frame at (fractional) frame number ft. ft < INTRO is the intro, ft >= INTRO the loop."""
    img = Image.new("L", (S, S), BG)
    d = ImageDraw.Draw(img)
    intro = ft < INTRO
    t = ft / INTRO if intro else 1.0
    lf = ft - INTRO                                   # loop clock (negative during the intro, 0 at hand-off)
    cyc = 2 * math.pi * lf / LOOP
    pulse01 = 0.5 + 0.5 * math.sin(cyc)

    # stars (drift-free twinkle; phases are whole cycles per loop so it repeats)
    sf = seg(t, 0.0, 0.16) if intro else 1.0
    for ang, rad, r, ph, spd in STARS:
        a = sf * (0.55 + 0.45 * math.sin(cyc * spd + ph)) * edge_fade(rad) * 0.9
        if a > 0.03:
            x, y = pt(rad, ang)
            d.ellipse([x - r, y - r, x + r, y + r], fill=lv(a))

    # aperture ring: sweeps in with a bright head, then breathes
    amp = seg(t, 0.52, 0.72) if intro else 1.0
    ring_r = R * (1 + 0.010 * math.sin(cyc) * amp)
    ring_a = 0.78 + 0.16 * pulse01
    sweep = 360 * e_io(seg(t, 0.04, 0.40)) if intro else 360
    if sweep > 0.5:
        box = [C - ring_r, C - ring_r, C + ring_r, C + ring_r]
        if sweep >= 359.5: d.ellipse(box, outline=lv(ring_a), width=2 * SS)
        else: d.arc(box, -90, -90 + sweep, fill=lv(ring_a), width=2 * SS)
        if intro and sweep < 359:
            hx, hy = pt(ring_r, math.radians(-90 + sweep))
            hr = 3.2 * SS
            d.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=WHITE)

    # blades: unfold (twist + grow with a little overshoot), hold, then fly out
    star_flash = 0.0
    for k in range(6):
        base = math.radians(k * 60 - 90)
        if intro:
            g = seg(t, 0.20 + k * 0.022, 0.50 + k * 0.022)
            twist = (1 - e_back(g)) * math.radians(-42)
            grow = e_out(g)
            s = seg(t, 0.63 + k * 0.012, 0.97)
        else:
            continue
        ang = base + twist
        outer, inner = pt(BLADE_OUT, ang), pt(BLADE_IN, ang + TWIST)
        ux, uy = outer[0] - inner[0], outer[1] - inner[1]
        L = math.hypot(ux, uy); ux, uy = ux / L, uy / L
        travel = e_in(s) * 240 * SS
        head = (outer[0] + ux * travel, outer[1] + uy * travel)
        tail_len = grow * L * (1 + 1.7 * s)
        tail = (head[0] - ux * tail_len, head[1] - uy * tail_len)
        fade = 1 - seg(s, 0.68, 1.0)
        n = 22
        for i in range(n):
            a0, a1 = i / n, (i + 1) / n
            p0 = (tail[0] + (head[0] - tail[0]) * a0, tail[1] + (head[1] - tail[1]) * a0)
            p1 = (tail[0] + (head[0] - tail[0]) * a1, tail[1] + (head[1] - tail[1]) * a1)
            rad = math.hypot(p1[0] - C, p1[1] - C)
            al = (0.2 + 0.8 * a1 ** 1.4) * fade * edge_fade(rad)
            line(d, p0, p1, al, 0.7 + 1.9 * a1 * (0.55 + 0.45 * s))

    # centre star ignites (overshoot) and then pulses
    grow_star = e_back(seg(t, 0.625, 0.76)) if intro else 1.0
    star_r = (9 + 2.5 * pulse01) * SS * max(0.0, grow_star)
    if intro and t > 0.625:
        flash = (1 - seg(t, 0.64, 0.84)) ** 2
        if flash > 0.01:
            hr = star_r + 26 * SS * flash
            d.ellipse([C - hr, C - hr, C + hr, C + hr], fill=lv(0.16 * flash))
    if star_r > 0.3:
        d.ellipse([C - star_r, C - star_r, C + star_r, C + star_r], fill=WHITE)

    # shockwave from the opening
    if intro:
        w = seg(t, 0.625, 0.88)
        if 0 < w < 1:
            rr = R + (340 * SS - R) * e_out(w)
            d.ellipse([C - rr, C - rr, C + rr, C + rr], outline=lv(0.5 * (1 - w) ** 1.6 * edge_fade(rr)), width=int(1.5 * SS))

    # orbits and planets
    orb = seg(t, 0.74, 0.96) if intro else 1.0
    rot = math.radians(8) * lf / LOOP
    for cfg, sign, a_orbit in ((A, 1, 0.14), (B, -1, 0.10)):
        n = 90
        for i in range(0, n, 2):
            ang = 2 * math.pi * i / n
            if ang / (2 * math.pi) > e_io(orb): break
            a0, a1 = ang + sign * rot, ang + 2 * math.pi / n + sign * rot
            d.line([pt(cfg["r"], a0), pt(cfg["r"], a1)], fill=lv(a_orbit * min(1, orb * 3)), width=max(1, SS))
    u = seg(t, 0.80, 1.0) if intro else 1.0
    for cfg, r_px, banded, ring in ((A, 11 * SS, True, True), (B, 6 * SS, False, False)):
        theta = cfg["start"] + cfg["lap"] * cyc - cfg["delta"] * (1 - u) ** 3
        x, y = pt(cfg["r"], theta)
        sc = e_back(seg(t, 0.80, 0.93)) if intro else 1.0
        planet(img, x, y, r_px * sc, banded, ring, seg(t, 0.80, 0.88) if intro else 1.0)
    return img

def finish(arr):
    """Average of subframes (numpy float) -> RGB image with a soft glow and no hard square edge."""
    img = Image.fromarray(np.clip(arr, 0, 255).astype("uint8"), "L").resize((SIZE, SIZE), Image.LANCZOS)
    a = np.asarray(img, dtype=np.float32)
    bright = np.clip(a - BG, 0, None)
    b1 = np.asarray(Image.fromarray(np.clip(bright, 0, 255).astype("uint8")).filter(ImageFilter.GaussianBlur(3.5)), dtype=np.float32)
    b2 = np.asarray(Image.fromarray(np.clip(bright, 0, 255).astype("uint8")).filter(ImageFilter.GaussianBlur(13)), dtype=np.float32)
    out = a + 0.55 * b1 + 0.9 * b2
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    rr = np.hypot(xx - SIZE / 2 + 0.5, yy - SIZE / 2 + 0.5)
    mask = np.clip((358 - rr) / 40, 0, 1)
    out = BG + (out - BG) * mask
    g = np.clip(out, 0, 255).astype("uint8")
    return Image.fromarray(np.stack([g, g, g], axis=-1), "RGB")

def render_frame(ft_index):
    ft = float(ft_index)
    if ft < INTRO:
        acc = None
        for s in range(SUBFRAMES):
            off = (s / (SUBFRAMES - 1) - 0.5) * SHUTTER if SUBFRAMES > 1 else 0
            f = min(max(ft + off, 0), INTRO - 1e-3) if ft + off < INTRO else INTRO - 1e-3
            a = np.asarray(draw_scene(f), dtype=np.float32)
            acc = a if acc is None else acc + a
        arr = acc / SUBFRAMES
    else:
        arr = np.asarray(draw_scene(ft), dtype=np.float32)
    return finish(arr)

def job(args):
    name, idx, out = args
    render_frame(idx).resize((OUT, OUT), Image.LANCZOS).save(os.path.join(out, name), optimize=True)
    return name

if __name__ == "__main__":
    out = sys.argv[1]
    which = sys.argv[2] if len(sys.argv) > 2 else "all"
    os.makedirs(out, exist_ok=True)
    jobs = []
    if which in ("intro", "all"): jobs += [("intro-%03d.png" % i, i, out) for i in range(INTRO)]
    if which in ("loop", "all"): jobs += [("loop-%03d.png" % i, INTRO + i, out) for i in range(LOOP)]
    with Pool(os.cpu_count()) as p:
        for n, _ in enumerate(p.imap_unordered(job, jobs, chunksize=4)):
            pass
    print("wrote", len(jobs), "frames to", out)
