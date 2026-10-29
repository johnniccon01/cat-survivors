"""Generates the pixel-art sprite sheets for cats, enemies and props.

    python tools/gen_sprites.py

Sprites are built from simple shapes on a pixel grid, each pixel tagged with
a *material* (fur, belly, eye...). A finishing pass then turns materials into
colours with automatic shading (light from the top, shadow underneath) and a
1-pixel outline, which gives a consistent hand-made pixel-art look.

Looks come from data/cats.json, data/enemies.json and data/props.json, so a
new cat or recoloured enemy only needs a data change and a re-run.

Writes assets/sprites/*.png and assets/sprites/sprites.json (cell sizes and
anchor points used by the game).
"""
import json
import math
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites")
OUTLINE = (43, 29, 20, 255)


# --- tiny PNG writer -----------------------------------------------------------------

def write_png(path, w, h, pixels):
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            raw.extend(pixels[y * w + x])
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


def shade(c, k):
    """k < 0 darkens, k > 0 lightens."""
    r, g, b, a = c
    if k < 0:
        return (int(r * (1 + k)), int(g * (1 + k)), int(b * (1 + k)), a)
    return (int(r + (255 - r) * k), int(g + (255 - g) * k), int(b + (255 - b) * k), a)


# --- material canvas -----------------------------------------------------------------

class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.m = [None] * (w * h)
        # Which body part each pixel belongs to (cats only); `cur` is the
        # part being drawn now. Markings painted with `only=` keep the part.
        self.p = [None] * (w * h)
        self.cur = None

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.m[y * self.w + x]
        return None

    def set(self, x, y, mat, keep_part=False):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.m[y * self.w + x] = mat
            if not keep_part:
                self.p[y * self.w + x] = self.cur

    def ellipse(self, cx, cy, rx, ry, mat, only=None, jag=0.0):
        for y in range(int(cy - ry - 2), int(cy + ry + 3)):
            for x in range(int(cx - rx - 2), int(cx + rx + 3)):
                dx, dy = (x + 0.5 - cx) / max(rx, 0.1), (y + 0.5 - cy) / max(ry, 0.1)
                r = 1.0
                if jag:
                    a = math.atan2(dy, dx)
                    r += jag * (0.5 + 0.5 * math.sin(a * 9.0))
                if dx * dx + dy * dy <= r * r:
                    if only is None or self.get(x, y) in only:
                        self.set(x, y, mat, only is not None)

    def rect(self, x0, y0, w, h, mat, only=None):
        for y in range(int(y0), int(y0 + h)):
            for x in range(int(x0), int(x0 + w)):
                if only is None or self.get(x, y) in only:
                    self.set(x, y, mat, only is not None)

    def poly(self, pts, mat, only=None):
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)) - 1, int(max(ys)) + 2):
            yc = y + 0.5
            xs = []
            for i in range(len(pts)):
                (x1, y1), (x2, y2) = pts[i], pts[(i + 1) % len(pts)]
                if (y1 <= yc < y2) or (y2 <= yc < y1):
                    xs.append(x1 + (yc - y1) * (x2 - x1) / (y2 - y1))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(math.ceil(xs[i] - 0.5)), int(math.floor(xs[i + 1] - 0.5)) + 1):
                    if only is None or self.get(x, y) in only:
                        self.set(x, y, mat, only is not None)

    def thick_line(self, pts, radius, mat):
        for i in range(len(pts) - 1):
            (x1, y1), (x2, y2) = pts[i], pts[i + 1]
            steps = int(max(abs(x2 - x1), abs(y2 - y1)) * 2) + 1
            for s in range(steps + 1):
                t = s / steps
                self.ellipse(x1 + (x2 - x1) * t, y1 + (y2 - y1) * t, radius, radius, mat)

    def render_parts(self, palette, flash=False):
        """Cats: light from the top left on every body part separately, so the
        head, body, legs and tail look round; a part tucked behind another
        (body under the head) gets its shadow; outlines take the colour of
        what they wrap and are lighter on the lit side."""
        w, h = self.w, self.h
        flat = ("eye", "pupil", "glint", "nose", "ink", "tear", "eyelow", "blush")
        rank = {"tail": 0, "leg_far": 1, "body": 2, "leg": 3, "head": 4}
        def part(x, y):
            if 0 <= x < w and 0 <= y < h and self.m[y * w + x] is not None:
                return self.p[y * w + x]
            return "none"
        px = [(0, 0, 0, 0)] * (w * h)
        for y in range(h):
            for x in range(w):
                mat = self.m[y * w + x]
                if mat is None:
                    continue
                if flash:
                    px[y * w + x] = (255, 255, 255, 255)
                    continue
                c = palette[mat]
                me = self.p[y * w + x]
                if mat not in flat and me in rank:
                    # Count this part's pixels straight above and below: the
                    # top rows catch the light, the bottom rows sit in shade.
                    up = 0
                    while up < 3 and part(x, y - up - 1) == me:
                        up += 1
                    down = 0
                    while down < 3 and part(x, y + down + 1) == me:
                        down += 1
                    k = 0.0
                    if up == 0:
                        k = 0.3
                    elif up == 1:
                        k = 0.13
                    if down == 0:
                        k = -0.34
                    elif down == 1 and up > 1:
                        k = -0.17
                    if part(x - 1, y) != me and up > 0 and down > 0:
                        k += 0.08
                    if part(x + 1, y) != me and up > 0 and down > 0:
                        k -= 0.12
                    above = part(x, y - 1)
                    if above not in ("none", me) and rank.get(above, 0) > rank[me]:
                        k = -0.38
                    elif part(x, y - 2) not in ("none", me) and rank.get(part(x, y - 2), 0) > rank[me]:
                        k = min(k, -0.18)
                    if k:
                        c = shade(c, k)
                px[y * w + x] = c
        out = list(px)
        for y in range(h):
            for x in range(w):
                if px[y * w + x][3] != 0:
                    continue
                for dx, dy in ((0, 1), (1, 0), (-1, 0), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < w and 0 <= yy < h and px[yy * w + xx][3] != 0:
                        if flash:
                            out[y * w + x] = (255, 255, 255, 255)
                            break
                        n = px[yy * w + xx]
                        dark = shade(n, -0.7)
                        if dy == 1 or dx == 1:
                            # Lit side (the shape is below or right of us):
                            # a dark shade of the fur, not plain black.
                            out[y * w + x] = tuple((a * 2 + b) // 3 for a, b in zip(dark, OUTLINE))[:3] + (255,)
                        else:
                            out[y * w + x] = tuple((a + b * 2) // 3 for a, b in zip(dark, OUTLINE))[:3] + (255,)
                        break
        return out

    def render(self, palette, outline=True, flash=False, translucent=()):
        """Materials -> RGBA with shading and outline."""
        w, h = self.w, self.h
        px = [(0, 0, 0, 0)] * (w * h)
        for y in range(h):
            for x in range(w):
                mat = self.m[y * w + x]
                if mat is None:
                    continue
                if flash:
                    px[y * w + x] = (255, 255, 255, 255)
                    continue
                c = palette[mat]
                if mat not in ("eye", "pupil", "glint", "nose", "ink", "tear", "outline"):
                    below = self.get(x, y + 1)
                    above = self.get(x, y - 1)
                    left = self.get(x - 1, y)
                    if below is None or below in ("outline",):
                        c = shade(c, -0.25)
                    elif above is None or (left is None and self.get(x - 1, y - 1) is None):
                        c = shade(c, 0.18)
                    elif self.get(x, y + 2) is None:
                        c = shade(c, -0.1)
                if mat in translucent:
                    c = (c[0], c[1], c[2], 150)
                px[y * w + x] = c
        if outline:
            out = list(px)
            for y in range(h):
                for x in range(w):
                    if px[y * w + x][3] != 0:
                        continue
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        xx, yy = x + dx, y + dy
                        if 0 <= xx < w and 0 <= yy < h and px[yy * w + xx][3] != 0 and self.m[yy * w + xx] not in translucent:
                            out[y * w + x] = (255, 255, 255, 255) if flash else OUTLINE
                            break
            px = out
        return px


def sheet(cells, cw, ch):
    """cells: rows of rendered frames -> one RGBA image."""
    rows, cols = len(cells), max(len(r) for r in cells)
    w, h = cw * cols, ch * rows
    img = [(0, 0, 0, 0)] * (w * h)
    for r, row in enumerate(cells):
        for c, frame in enumerate(row):
            for y in range(ch):
                for x in range(cw):
                    img[(r * ch + y) * w + c * cw + x] = frame[y * cw + x]
    return w, h, img


def rotate_cw(px, w, h):
    out = [(0, 0, 0, 0)] * (w * h)
    # rotate around the centre, keeping the canvas size (content fits).
    cx, cy = w / 2.0, h / 2.0
    for y in range(h):
        for x in range(w):
            sx = cx + (y + 0.5 - cy) - 0.5
            sy = cy - (x + 0.5 - cx) - 0.5
            sx, sy = int(round(sx)), int(round(sy))
            if 0 <= sx < w and 0 <= sy < h:
                out[y * w + x] = px[sy * w + sx]
    return out


# --- cats ----------------------------------------------------------------------------

CAT_W, CAT_H = 36, 30


def cat_frame(look, frame, mood="normal", dead=False, scale=1.0):
    """One cat frame facing right. frame 0-3 = walk cycle."""
    s = scale
    W, H = int(math.ceil(CAT_W * s)), int(math.ceil(CAT_H * s))
    c = Canvas(W, H)
    ox, oy = (W - CAT_W * s) / 2, H - CAT_H * s
    P = lambda x, y: (ox + x * s, oy + y * s)
    fluffy = look.get("fluffy", False)
    points = look.get("points", False)
    bob = 1 if frame in (1, 3) else 0

    # Tail (sways with the walk)
    c.cur = "tail"
    sway = [0, 1, 0, -1][frame]
    tail = [P(9, 19 - bob), P(5, 16 - bob), P(4 + sway, 10), P(6 + sway, 6), P(8 + sway, 5)]
    c.thick_line(tail, (2.0 if fluffy else 1.4) * s, "tailtip" if points else "fur")

    # Legs: diagonal pairs move together.
    lifts = [(0, 2), (1, 1), (2, 0), (1, 1)][frame]
    swing = [(-1, 1), (0, 0), (1, -1), (0, 0)][frame]
    for i, (lx, pair) in enumerate([(10, 0), (13, 1), (21, 1), (24, 0)]):
        # Far-side legs sit behind the body, near-side ones in front.
        c.cur = "leg_far" if lx in (13, 24) else "leg"
        lift = lifts[pair]
        dx = swing[pair]
        x, y = P(lx + dx, 21 - lift)
        c.rect(x, y, 2.5 * s, (6 - lift) * s, "leg" if points else "fur")
        c.ellipse(x + 1.3 * s, y + (5.6 - lift) * s, 1.7 * s, 1.0 * s + 0.4, "paw")

    # Body
    c.cur = "body"
    bx, by = P(16, 18 - bob)
    c.ellipse(bx, by, 9.5 * s, 5.2 * s, "fur", jag=0.08 if fluffy else 0.0)
    c.ellipse(bx + 1 * s, by + 2.6 * s, 6 * s, 2.2 * s, "belly", only=("fur",))
    # Chest fluff
    cx_, cy_ = P(23, 17 - bob)
    c.ellipse(cx_, cy_, 3.4 * s, 3.6 * s, "belly", jag=0.1 if fluffy else 0.0)

    # Head (a touch bigger than the old one: cuter, and room for the eyes)
    c.cur = "head"
    hx, hy = P(25, 11 - bob)
    hr = 6.9 * s
    # Ears (behind the head outline)
    ear_l = [P(19.5, 8 - bob), P(20.5, 1.5 - bob), P(24, 6 - bob)]
    ear_r = [P(25.5, 6 - bob), P(29.5, 1.5 - bob), P(30.5, 8.5 - bob)]
    sad = mood == "sad"
    if sad:  # flattened ears
        ear_l = [P(19.5, 8 - bob), P(17.5, 4 - bob), P(23, 6 - bob)]
        ear_r = [P(27, 6 - bob), P(32, 5 - bob), P(30.5, 9 - bob)]
    for ear in (ear_l, ear_r):
        c.poly(ear, "ear" if points else "fur")
    c.ellipse(hx, hy, hr, hr * 0.95, "fur", jag=0.06 if fluffy else 0.0)
    # Inner ears
    inner_l = [P(20.5, 7 - bob), P(21, 3.5 - bob), P(23, 6.5 - bob)]
    inner_r = [P(26.5, 6.5 - bob), P(29, 3.5 - bob), P(29.5, 7.5 - bob)]
    if not sad:
        c.poly(inner_l, "inner")
        c.poly(inner_r, "inner")
    # Muzzle and cheeks
    mx, my = P(27, 14 - bob)
    if points:
        c.ellipse(mx, my - 0.5 * s, 4.2 * s, 3.4 * s, "mask", only=("fur",))
    c.ellipse(mx, my + 0.4 * s, 2.6 * s, 1.7 * s, "muzzle")

    # Pattern
    if look.get("stripes"):
        for y in range(H):
            for x in range(W):
                # Bands across the back and tail only; the head keeps its "M".
                part = c.p[y * W + x]
                if c.get(x, y) == "fur" and part in ("body", "tail") and y < by + 1 and int(x + y * 0.6) % 5 < 2:
                    c.set(x, y, "dark", True)
        # Forehead "M"
        for dx in (-1.5, 0.5, 2.5):
            fx, fy = P(25 + dx, 6.5 - bob)
            c.set(fx, fy, "dark", True)
            c.set(fx, fy + 1, "dark", True)
    if look.get("patches"):
        c.ellipse(*P(13, 15 - bob), 3.2 * s, 2.6 * s, "dark", only=("fur",))
        c.ellipse(*P(19, 14 - bob), 2.2 * s, 2 * s, "patch2", only=("fur",))
        c.ellipse(*P(23, 8 - bob), 2.4 * s, 2 * s, "dark", only=("fur",))

    # Eyes (3/4 view: two eyes on the right side of the head). Placed from
    # the unbobbed spot and then moved by whole pixels, so they bob together
    # with the head instead of sliding on it (rounding used to make them
    # jump on some cat sizes).
    for ex in (23, 27.5):
        x, y = P(ex, 10.5)
        x, y = int(math.floor(x + 0.5)), int(math.floor(y + 0.5)) - bob
        if dead:
            c.set(x, y, "ink"); c.set(x + 1, y + 1, "ink"); c.set(x + 1, y, "ink"); c.set(x, y + 1, "ink")
            continue
        if mood == "angry":
            c.set(x, y, "eye"); c.set(x + 1, y, "pupil")
            c.set(x - 1 if ex < 25 else x + 2, y - 1, "ink")
            c.set(x if ex < 25 else x + 1, y - 1, "ink")
            continue
        if mood == "blink":
            # Closed eyes: a happy curved lid line.
            c.set(x, y + 1, "ink"); c.set(x + 1, y + 1, "ink"); c.set(x - 1 if ex < 25 else x + 2, y, "ink")
            c.set(x - 1 if ex < 25 else x + 2, y + 3, "blush")
            continue
        # Tall eyes: a glint on top, the pupil to the front, darker iris below.
        c.set(x, y, "glint"); c.set(x + 1, y, "eye")
        c.set(x, y + 1, "eye"); c.set(x + 1, y + 1, "pupil")
        c.set(x, y + 2, "eyelow"); c.set(x + 1, y + 2, "pupil")
        if s > 1.1:
            c.set(x + 1, y - 1, "eye"); c.set(x, y - 1, "eye")
        # A rosy cheek under each eye.
        c.set(x - 1 if ex < 25 else x + 2, y + 3, "blush")
        if sad and ex > 25:
            c.set(x + 1, y + 3, "tear")
    # Nose and mouth
    nx, ny = P(29.2, 12.6 - bob)
    c.set(nx, ny, "nose")
    c.set(nx + 1, ny, "nose")
    c.set(nx, ny + 1.4, "ink")
    return c


def cat_palette(look):
    fur = hexc(look["fur"])
    dark = hexc(look["dark"])
    return {
        "fur": fur, "dark": dark, "belly": hexc(look["belly"]),
        "muzzle": shade(hexc(look["belly"]), 0.15), "mask": dark,
        "ear": dark, "tailtip": dark, "leg": dark,
        "paw": shade(hexc(look["belly"]), 0.1) if not look.get("points") else shade(dark, -0.2),
        "inner": hexc("#f3a9b8"), "eye": hexc(look["eyes"]), "pupil": hexc("#1a1210"),
        "eyelow": shade(hexc(look["eyes"]), -0.35),
        "blush": tuple((a * 3 + b * 2) // 5 for a, b in zip(hexc(look["belly"])[:3], (240, 120, 140))) + (255,),
        "glint": (255, 255, 255, 255), "nose": hexc("#f08aa0"), "ink": OUTLINE,
        "tear": hexc("#8fd3ff"), "patch2": hexc("#3a2a22"),
    }


def build_cat(cat_id, data):
    look = data
    scale = float(data.get("size", 1.0))
    pal = cat_palette(look)
    rows = []
    for mood in ("normal", "angry", "sad"):
        rows.append([cat_frame(look, f, mood, scale=scale).render_parts(pal) for f in range(4)])
    dead_canvas = cat_frame(look, 0, "normal", dead=True, scale=scale)
    dw, dh = dead_canvas.w, dead_canvas.h
    dead = rotate_cw(dead_canvas.render_parts(pal), dw, dh)
    rows[0].append(dead)
    rows.append([cat_frame(look, f, "normal", scale=scale).render_parts(pal, flash=True) for f in range(4)])
    # Row 4: eyes closed, for blinking.
    rows.append([cat_frame(look, f, "blink", scale=scale).render_parts(pal) for f in range(4)])
    cw, ch = dead_canvas.w, dead_canvas.h
    w, h, img = sheet(rows, cw, ch)
    write_png(os.path.join(OUT, "cat_%s.png" % cat_id.lower()), w, h, img)
    # Anchor: where the cat's body centre sits in the cell (matches the old
    # vector art, whose origin was the body centre).
    return {"cell": [cw, ch], "anchor": [cw / 2.0 - 2.0 * scale, ch - 12.0 * scale], "frames": 4}


# --- enemies & props ---------------------------------------------------------------

def enemy_canvas(shape, frame, data):
    c = Canvas(28, 28)
    wob = [0, 1][frame]
    if shape == "sock":
        c.poly([(9, 3), (17, 3), (17, 16), (23, 17), (24, 21), (22, 24), (9, 24), (7, 20)], "body")
        c.rect(9, 3, 8, 3, "accent")
        if data.get("stripes"):
            c.rect(9, 9, 8, 2, "accent", only=("body",))
            c.rect(9, 14, 8, 2, "accent", only=("body",))
        c.ellipse(21, 21, 2.2, 2.2, "accent", only=("body",))
        c.ellipse(11, 22, 2.0, 1.6, "accent", only=("body",))
        for x in (11, 15):
            c.set(x, 8 + wob, "pupil"); c.set(x, 9 + wob, "pupil")
        c.set(10, 6 + wob, "ink"); c.set(11, 7 + wob, "ink"); c.set(16, 6 + wob, "ink"); c.set(15, 7 + wob, "ink")
        c.set(12, 11 + wob, "ink"); c.set(13, 11 + wob, "ink"); c.set(14, 11 + wob, "ink")
    elif shape == "dust":
        c.ellipse(14, 15 + wob * 0.5, 7, 6.5, "body", jag=0.22)
        c.ellipse(14, 15, 4, 3, "accent", only=("body",), jag=0.3)
        for x in (11, 16):
            c.ellipse(x, 13, 1.8, 1.8, "white")
            c.set(x + (1 if frame else 0), 13, "pupil")
    elif shape == "bubble":
        c.ellipse(14, 14, 6.5 + wob * 0.4, 6.5 - wob * 0.4, "bubble")
        c.set(11, 10, "glint"); c.set(12, 10, "glint"); c.set(11, 11, "glint")
        c.set(12, 14, "pupil"); c.set(16, 14, "pupil")
    elif shape == "roomba":
        c.ellipse(14, 15, 10, 9, "body")
        c.ellipse(14, 14, 8.5, 7.5, "top", only=("body",))
        c.rect(6, 19, 16, 2, "accent", only=("body", "top"))
        c.set(18, 11, "led"); c.set(19, 11, "led"); c.set(18, 14, "led"); c.set(19, 14, "led")
        c.set(17, 10, "ink"); c.set(20, 10, "ink")
        c.ellipse(10, 13, 1.6, 1.6, "led" if frame else "accent")
    elif shape == "slipper":
        c.ellipse(13, 18, 11, 6, "accent")
        c.poly([(9, 10), (20, 10), (22, 19), (8, 19)], "body")
        c.ellipse(21, 10, 3.2, 3.2, "white", jag=0.3)
        for x in (12, 16):
            c.set(x, 14 + wob, "pupil"); c.set(x, 15 + wob, "pupil")
        c.set(11, 13 + wob, "ink"); c.set(17, 13 + wob, "ink")
    elif shape == "rat":
        sway = [0, 1][frame]
        c.thick_line([(5, 17), (2, 15 + sway), (1, 11 + sway)], 0.7, "tail")
        c.ellipse(13, 17, 8, 5, "body")
        c.poly([(18, 13), (26, 17), (18, 21)], "body")
        c.ellipse(17, 12, 2.6, 2.6, "body")
        c.ellipse(17, 12, 1.4, 1.4, "accent")
        c.set(21, 15, "eye"); c.set(26, 17, "accent")
        c.ellipse(13, 19, 5, 2, "belly", only=("body",))
        for x in ((9, 12) if frame else (11, 14)):
            c.rect(x, 21, 2, 2, "accent")
    elif shape == "spider":
        step = [1, -1][frame]
        for side in (-1, 1):
            for i in range(4):
                root = (11 + i * 2, 15)
                knee = (8 + i * 4, 15 + side * 6 + (step if i % 2 == 0 else -step))
                foot = (6 + i * 5, 15 + side * 9)
                c.thick_line([root, knee, foot], 0.5, "leg")
        c.ellipse(11, 15, 5, 4.5, "body")
        c.ellipse(18, 15, 3.4, 3.2, "body")
        c.rect(9, 14, 3, 2, "accent")
        for p in ((19, 14), (19, 16), (20, 15), (21, 14)):
            c.set(*p, "eye")
    elif shape == "moth":
        flap = 2 if frame else 0
        for side in (-1, 1):
            c.ellipse(14, 14 + side * (4 + flap * 0.5), 6, 3.5 - flap * 0.6, "body")
            c.ellipse(14, 14 + side * (4 + flap * 0.5), 2.2, 1.4, "accent", only=("body",))
        c.rect(9, 13, 11, 2, "ink")
        c.set(20, 12, "ink"); c.set(21, 11, "ink"); c.set(20, 16, "ink"); c.set(21, 17, "ink")
    elif shape == "vacuum":
        c.rect(12, 1, 3, 12, "accent")
        c.rect(9, 1, 9, 2, "ink")
        c.poly([(7, 8), (19, 8), (21, 21), (5, 21)], "body")
        c.rect(3, 21, 22, 4, "accent")
        c.ellipse(6, 25, 2, 2, "ink"); c.ellipse(22, 25, 2, 2, "ink")
        for x in (10, 15):
            c.set(x, 12 + wob, "pupil"); c.set(x, 13 + wob, "pupil")
        c.set(9, 10 + wob, "ink"); c.set(16, 10 + wob, "ink")
        for x in range(11, 15):
            c.set(x, 17, "ink")
    elif shape == "bee":
        flap = frame
        c.ellipse(11 - flap, 10, 4, 3 - flap, "wing")
        c.ellipse(16 + flap, 10, 4, 3 - flap, "wing")
        c.ellipse(13, 16, 7, 5, "body")
        for x in (10, 14):
            c.rect(x, 11, 2, 10, "accent", only=("body",))
        c.poly([(5, 15), (2, 16), (5, 17)], "ink")
        c.ellipse(20, 15, 3.4, 3.4, "accent")
        c.set(21, 14, "white"); c.set(22, 14, "pupil")
        c.set(21, 11, "ink"); c.set(22, 10, "ink"); c.set(19, 11, "ink"); c.set(19, 10, "ink")
    elif shape == "snail":
        stretch = frame
        c.poly([(3, 22), (23 + stretch, 22), (25 + stretch, 19), (21 + stretch, 17), (6, 18)], "belly")
        c.ellipse(12, 14, 7.5, 7.5, "accent")
        c.ellipse(12, 14, 5, 5, "top", only=("accent",))
        c.ellipse(12, 14, 2.4, 2.4, "accent", only=("top",))
        c.thick_line([(21 + stretch, 18), (22 + stretch, 12)], 0.6, "belly")
        c.thick_line([(23 + stretch, 18), (25 + stretch, 13)], 0.6, "belly")
        c.set(22 + stretch, 11, "pupil"); c.set(25 + stretch, 12, "pupil")
    elif shape == "mole":
        c.ellipse(13, 17, 8, 6.5, "body")
        c.ellipse(20, 17, 3.5, 3, "body")
        c.ellipse(24, 17, 2, 1.8, "accent")
        c.ellipse(13, 20, 6, 2.5, "belly", only=("body",))
        c.set(20, 15, "pupil")
        dig = [0, 1][frame]
        for x in (16 + dig, 9 - dig):
            c.ellipse(x, 23, 2.4, 1.4, "accent")
    elif shape == "crow":
        flap = frame
        c.poly([(3, 16), (8, 13), (8, 19)], "body")
        c.ellipse(13, 16, 7, 5, "body")
        c.ellipse(19, 12, 3.6, 3.4, "body")
        c.poly([(22, 11), (27, 13), (22, 14)], "accent")
        c.poly([(9, 14), (17, 13 - flap * 3), (16, 18 - flap)], "top", only=None)
        c.set(20, 11, "white"); c.set(20, 12, "eye")
        for x in (12, 15):
            c.rect(x, 21, 1, 3, "accent")
    elif shape == "gnome":
        bob = frame
        c.poly([(14, 1 + bob), (20, 11 + bob), (8, 11 + bob)], "accent")
        c.ellipse(14, 13 + bob, 5, 3, "skin")
        c.ellipse(14, 17 + bob, 5.5, 4.5, "beard")
        c.rect(8, 18 + bob, 12, 6, "body")
        c.ellipse(14, 17 + bob, 5.5, 4.5, "beard", only=("body",))
        c.ellipse(17, 13 + bob, 1.6, 1.4, "nose")
        c.set(12, 12 + bob, "pupil"); c.set(16, 12 + bob, "pupil")
        c.rect(9, 24, 4, 2, "ink"); c.rect(15, 24, 4, 2, "ink")
    elif shape == "mower":
        c.rect(2, 4, 3, 12, "ink")
        c.rect(2, 3, 10, 2, "ink")
        c.rect(5, 9, 20, 12, "body")
        c.rect(5, 9, 20, 3, "top", only=("body",))
        c.ellipse(15, 15, 4, 3, "top")
        c.rect(5, 19, 20, 2, "accent")
        for x in (7, 22):
            c.ellipse(x, 22, 3, 3, "ink")
            c.set(x + frame, 22, "white")
        c.set(20, 13, "eye"); c.set(23, 13, "eye")
        for i in range(4):
            c.set(25 + (i + frame) % 3, 17 + i, "grass")
    elif shape == "pigeon":
        bob = frame
        c.poly([(3, 15), (8, 13), (8, 18)], "accent")
        c.ellipse(13, 16, 7, 5.5, "body")
        c.ellipse(18, 11 + bob, 3.4, 3.4, "body")
        c.ellipse(16, 14 + bob * 0.5, 3, 2.4, "accent", only=("body",))
        c.ellipse(11, 16, 4.5, 3, "top", only=("body",))
        c.rect(11, 15, 5, 1, "ink", only=("top",))
        c.poly([(21, 11 + bob), (24, 12 + bob), (21, 13 + bob)], "beak")
        c.set(19, 10 + bob, "eye")
        for x in ((11, 15) if frame else (12, 14)):
            c.rect(x, 21, 1, 3, "beak")
    elif shape == "bat":
        up = frame
        for side in (-1, 1):
            tip = 14 + side * 12
            c.poly([(14, 13), (tip, 8 if up else 18), (14 + side * 9, 16 if up else 20), (14 + side * 5, 15)], "wing_dark")
        c.ellipse(14, 14, 4, 4.5, "body")
        c.poly([(11, 11), (12, 6), (13, 10)], "body")
        c.poly([(15, 10), (16, 6), (17, 11)], "body")
        c.set(12, 13, "eye"); c.set(16, 13, "eye")
        c.set(13, 16, "white"); c.set(15, 16, "white")
    elif shape == "gull":
        flap = frame
        c.poly([(3, 15), (8, 13), (8, 18)], "top")
        c.ellipse(13, 16, 7.5, 5, "body")
        c.ellipse(19, 12, 3.6, 3.4, "body")
        c.poly([(8, 14), (18, 13 - flap * 3), (17, 17)], "top")
        c.poly([(22, 12), (27, 13), (22, 14)], "accent")
        c.set(26, 13, "eye")
        c.set(20, 11, "pupil")
        for x in (12, 15):
            c.rect(x, 21, 1, 3, "accent")
    elif shape == "raccoon":
        sway = frame
        for i in range(5):
            c.ellipse(5 - i * 0.6, 17 - i * 1.6 + sway * (i % 2), 2.6, 2.2, "accent" if i % 2 else "body")
        c.ellipse(13, 17, 8, 6, "body")
        c.ellipse(13, 19, 5, 3, "belly", only=("body",))
        c.ellipse(20, 12, 5, 4.5, "body")
        c.poly([(17, 9), (17, 5), (20, 8)], "body")
        c.poly([(21, 8), (23, 5), (24, 9)], "body")
        c.rect(16, 11, 9, 2, "accent", only=("body",))
        c.set(18, 11, "white"); c.set(22, 11, "white")
        c.ellipse(24, 14, 1.4, 1.2, "nose")
        for x in ((10, 15) if frame else (11, 16)):
            c.rect(x, 22, 2, 2, "accent")
    elif shape == "frog":
        hop = frame
        for x in (7, 19):
            c.ellipse(x, 22 - hop, 3.5, 2.2, "body")
        c.ellipse(13, 17 - hop, 8, 6, "body")
        c.ellipse(13, 19 - hop, 5.5, 3, "accent", only=("body",))
        for x in (9, 17):
            c.ellipse(x, 11 - hop, 2.8, 2.8, "body")
            c.set(x, 11 - hop, "white"); c.set(x + 1, 11 - hop, "pupil")
        for x in range(10, 17):
            c.set(x, 15 - hop, "ink")
        c.ellipse(13, 13 - hop, 1.2, 0.8, "top", only=("body",))
    elif shape == "iron":
        c.poly([(4, 20), (22, 20), (25, 15), (8, 12)], "body")
        c.rect(4, 20, 21, 3, "accent")
        c.thick_line([(9, 12), (11, 6), (20, 6), (22, 12)], 1.2, "ink")
        c.set(13, 16, "pupil"); c.set(18, 16, "pupil")
        c.set(12, 15, "ink"); c.set(19, 15, "ink")
        if frame:
            c.ellipse(3, 13, 2, 2, "white"); c.ellipse(1, 9, 1.5, 1.5, "white")
    elif shape == "boiler":
        c.ellipse(14, 15, 9, 10, "body")
        c.ellipse(14, 9, 6, 2.5, "top", only=("body",))
        c.ellipse(14, 19, 4, 3, "accent" if frame else "ink")
        c.ellipse(19, 11, 2.2, 2.2, "white")
        c.set(19, 11, "pupil"); c.set(20, 10, "pupil")
        c.set(10, 13, "pupil"); c.set(13, 13, "pupil")
        c.rect(11, 2, 3, 5, "top")
    elif shape == "scarecrow":
        sway = frame
        c.thick_line([(14, 10), (14, 26)], 1.0, "accent")
        c.thick_line([(3, 13 + sway), (25, 13 - sway)], 1.0, "accent")
        c.rect(9, 12, 10, 9, "top")
        c.ellipse(14, 8, 4.5, 4.5, "belly")
        c.poly([(7, 5), (21, 5), (14, -1)], "body")
        c.rect(6, 5, 16, 2, "body")
        c.set(12, 8, "ink"); c.set(16, 8, "ink")
        for x in range(11, 18):
            c.set(x, 10, "ink")
        for x in (3, 25):
            c.set(x, 14 + sway, "grass"); c.set(x, 12 - sway, "grass")
    elif shape == "cloud":
        bob = frame
        for cx, cy, r in ((9, 14, 6), (15, 11, 7), (20, 15, 5.5), (14, 17, 7)):
            c.ellipse(cx, cy + bob, r, r * 0.8, "body")
        c.ellipse(15, 10 + bob, 4, 2.5, "top", only=("body",))
        c.set(11, 14 + bob, "eye"); c.set(17, 14 + bob, "eye")
        c.set(10, 13 + bob, "ink"); c.set(18, 13 + bob, "ink")
        c.thick_line([(14, 22 + bob), (12, 25), (15, 25), (13, 28)], 0.6, "accent")
    elif shape == "banana":
        bob = frame
        c.thick_line([(6, 18 - bob), (9, 12 - bob), (15, 9 - bob), (21, 10 - bob)], 2.6, "body")
        c.thick_line([(6, 18 - bob), (9, 13 - bob), (15, 10 - bob)], 1.2, "top")
        c.rect(21, 8 - bob, 3, 3, "accent")
        c.set(11, 13 - bob, "pupil"); c.set(15, 12 - bob, "pupil")
        c.set(12, 15 - bob, "ink"); c.set(13, 15 - bob, "ink")
    elif shape == "cart":
        roll = frame
        c.poly([(4, 8), (24, 8), (21, 18), (7, 18)], "body")
        for x in range(6, 23, 3):
            c.rect(x, 9, 1, 8, "ink", only=("body",))
        c.rect(4, 8, 21, 2, "top")
        c.thick_line([(24, 8), (26, 4)], 0.8, "accent")
        for x in (9, 19):
            c.ellipse(x + roll * 0.5, 21, 2.2, 2.2, "ink")
        c.set(11, 13, "eye"); c.set(17, 13, "eye")
    elif shape == "chicken":
        c.ellipse(14, 16, 9, 7, "body")
        c.ellipse(14, 13, 6, 3, "top", only=("body",))
        for x in (6, 22):
            c.thick_line([(x, 18), (x + (-3 if x < 14 else 3), 22 + frame)], 1.4, "belly")
            c.ellipse(x + (-3 if x < 14 else 3), 23 + frame, 1.8, 1.4, "white")
        c.set(10, 12, "accent"); c.set(18, 14, "accent"); c.set(14, 18, "accent")
        c.set(11, 15, "pupil"); c.set(16, 15, "pupil")
    elif shape == "spray":
        c.rect(9, 10, 10, 14, "body")
        c.rect(9, 18, 10, 4, "accent", only=("body",))
        c.rect(11, 5, 6, 5, "white")
        c.rect(17, 5, 5, 2, "white")
        c.rect(15, 9, 2, 4, "ink")
        if frame:
            c.ellipse(24, 6, 2, 1.5, "bubble"); c.ellipse(26, 9, 1.4, 1.2, "bubble")
        c.set(12, 14, "pupil"); c.set(16, 14, "pupil")
    elif shape == "register":
        c.rect(4, 12, 20, 12, "body")
        c.rect(4, 12, 20, 3, "top", only=("body",))
        c.rect(7, 4, 14, 8, "accent")
        c.rect(9, 6, 10, 4, "ink")
        c.set(11, 8, "eye"); c.set(16, 8, "eye")
        c.rect(6, 22, 16, 2, "white" if frame else "accent")
        for x in range(7, 21, 4):
            c.rect(x, 17, 2, 2, "white")
    elif shape == "dog":
        sway = frame
        c.thick_line([(4, 12), (2, 7 + sway)], 1.2, "body")
        c.ellipse(12, 15, 8, 6, "body")
        c.ellipse(12, 18, 5, 2.5, "belly", only=("body",))
        c.ellipse(20, 10, 5, 4.5, "body")
        c.ellipse(24, 12, 3, 2.4, "belly")
        c.set(26, 11, "ink"); c.set(27, 11, "ink")
        c.poly([(17, 7), (15, 2), (19, 5)], "accent")
        c.poly([(22, 6), (23, 1), (25, 6)], "accent")
        c.set(20, 9, "eye"); c.set(23, 9, "eye")
        c.rect(14, 12, 8, 1, "accent", only=("body",))
        for x in ((7, 16) if frame else (9, 14)):
            c.rect(x, 20, 2, 4, "body")
        c.set(24, 14, "white")
    elif shape == "crab":
        step = frame
        for side in (-1, 1):
            for i in range(3):
                c.thick_line([(14 + side * 5, 16 + i * 2), (14 + side * (9 + i), 20 + i * 2 + (step if i % 2 else -step))], 0.6, "accent")
            c.ellipse(14 + side * 10, 9, 3, 2.6, "body")
            c.set(14 + side * 11, 8, "ink")
        c.ellipse(14, 15, 7, 5, "body")
        c.ellipse(14, 13, 5, 2, "top", only=("body",))
        c.thick_line([(12, 11), (12, 8)], 0.4, "ink"); c.thick_line([(16, 11), (16, 8)], 0.4, "ink")
        c.set(12, 7, "white"); c.set(16, 7, "white")
    elif shape == "jelly":
        pulse = frame
        c.ellipse(14, 11, 8 - pulse * 0.5, 6 + pulse * 0.5, "bubble")
        c.ellipse(14, 9, 4, 2, "glint", only=("bubble",))
        for x in (9, 12, 16, 19):
            c.thick_line([(x, 16), (x + (1 if (x + pulse) % 2 else -1), 21), (x, 25)], 0.5, "accent")
        c.set(12, 12, "pupil"); c.set(16, 12, "pupil")
    elif shape == "eel":
        wave = [0, 1][frame]
        pts = [(3 + i * 3, 15 + (2 if (i + wave) % 2 else -2)) for i in range(7)]
        c.thick_line(pts, 2.2, "body")
        c.thick_line(pts[:-1], 0.8, "accent")
        c.ellipse(24, 15, 3.2, 2.6, "body")
        c.set(25, 14, "eye"); c.set(27, 16, "ink")
    elif shape == "octopus":
        wave = frame
        c.ellipse(14, 10, 8, 7, "body")
        c.ellipse(12, 7, 3, 2, "top", only=("body",))
        for i in range(5):
            x = 7 + i * 3.5
            c.thick_line([(x, 15), (x + (1 if (i + wave) % 2 else -1) * 2, 20), (x, 25)], 1.0, "body")
            c.set(x, 21, "accent")
        c.ellipse(11, 11, 1.8, 1.8, "white"); c.ellipse(17, 11, 1.8, 1.8, "white")
        c.set(11, 11, "pupil"); c.set(17, 11, "pupil")
    elif shape == "anchor":
        swing = frame
        c.thick_line([(14, 4), (14 + swing, 22)], 1.6, "body")
        c.ellipse(14, 4, 3, 3, "body"); c.ellipse(14, 4, 1.4, 1.4, "pupil")
        c.thick_line([(9, 9), (19, 9)], 1.2, "body")
        c.thick_line([(5, 17), (8 + swing, 23), (14 + swing, 24), (20 + swing, 23), (23, 17)], 1.5, "body")
        c.poly([(3, 16), (7, 15), (6, 19)], "body"); c.poly([(25, 16), (21, 15), (22, 19)], "body")
        c.thick_line([(14, 4), (20, 1), (25, 3)], 0.6, "accent")
        c.set(12, 13, "eye"); c.set(16, 13, "eye")
    elif shape == "nut":
        step = frame
        for side in (-1, 1):
            for i in range(2):
                c.thick_line([(14 + side * 5, 15 + i * 4), (14 + side * 9, 18 + i * 4 + (step if i else -step))], 0.6, "ink")
        c.poly([(14, 7), (21, 11), (21, 19), (14, 23), (7, 19), (7, 11)], "body")
        c.ellipse(14, 15, 3, 3, "ink", only=("body",))
        c.rect(8, 11, 12, 2, "top", only=("body",))
        c.set(11, 10, "eye"); c.set(17, 10, "eye")
    elif shape == "spring":
        squash = frame
        for i in range(4):
            y = 22 - i * (4 - squash)
            c.ellipse(14, y, 6, 1.6, "accent")
        c.ellipse(14, 9 + squash * 2, 7, 5, "body")
        c.ellipse(14, 7 + squash * 2, 4, 2, "top", only=("body",))
        c.set(11, 9 + squash * 2, "eye"); c.set(17, 9 + squash * 2, "eye")
    elif shape == "drone":
        spin = frame
        for dx, dy in ((-8, -6), (8, -6), (-8, 6), (8, 6)):
            c.thick_line([(14, 14), (14 + dx, 14 + dy)], 0.7, "ink")
            if spin:
                c.ellipse(14 + dx, 14 + dy, 4, 1.2, "wing")
            else:
                c.ellipse(14 + dx, 14 + dy, 1.2, 3.5, "wing")
        c.ellipse(14, 14, 5, 4, "body")
        c.ellipse(14, 13, 3, 1.5, "top", only=("body",))
        c.set(14, 15, "eye")
    elif shape == "welder":
        c.rect(8, 10, 12, 13, "body")
        c.rect(8, 10, 12, 3, "top", only=("body",))
        c.rect(10, 4, 8, 6, "accent")
        c.rect(11, 6, 6, 2, "ink")
        c.set(12, 6, "eye"); c.set(15, 6, "eye")
        c.thick_line([(20, 14), (25, 11)], 1.0, "accent")
        if frame:
            c.ellipse(26, 10, 2, 2, "glint")
        for x in (10, 17):
            c.rect(x, 23, 2, 3, "ink")
    elif shape == "crusher":
        bob = frame
        c.rect(4, 8 + bob, 20, 15, "body")
        c.rect(4, 8 + bob, 20, 4, "top", only=("body",))
        for x in range(6, 23, 4):
            c.rect(x, 21 + bob, 2, 3, "accent")
        c.rect(8, 13 + bob, 12, 3, "ink")
        c.set(10, 14 + bob, "eye"); c.set(17, 14 + bob, "eye")
        c.rect(2, 12, 3, 8, "accent"); c.rect(23, 12, 3, 8, "accent")
    elif shape == "arm":
        swing = frame
        c.ellipse(14, 22, 9, 4, "accent")
        c.thick_line([(14, 21), (11, 12)], 2.0, "body")
        c.thick_line([(11, 12), (19 + swing * 2, 6)], 1.6, "body")
        c.ellipse(11, 12, 2.4, 2.4, "ink")
        c.thick_line([(19 + swing * 2, 6), (23 + swing * 2, 3)], 0.6, "accent")
        c.thick_line([(19 + swing * 2, 6), (24 + swing * 2, 8)], 0.6, "accent")
        c.set(14, 19, "eye")
    elif shape == "press":
        drop = frame * 3
        c.rect(3, 3, 22, 5, "accent")
        c.rect(6, 8, 2, 12, "ink"); c.rect(20, 8, 2, 12, "ink")
        c.rect(7, 8 + drop, 14, 8, "body")
        c.rect(7, 8 + drop, 14, 2, "top", only=("body",))
        c.set(11, 12 + drop, "eye"); c.set(16, 12 + drop, "eye")
        c.rect(3, 22, 22, 3, "accent")
    elif shape == "sack":
        c.poly([(8, 9), (20, 9), (23, 24), (5, 24)], "body")
        c.rect(10, 6, 8, 4, "body")
        c.rect(9, 9, 10, 1, "ink")
        c.ellipse(14, 17, 3.5, 3.5, "accent", only=("body",))
        c.set(14, 15, "top"); c.set(13, 17, "top")
    elif shape == "box":
        c.rect(5, 7, 18, 16, "body")
        c.rect(5, 7, 18, 4, "top", only=("body",))
        c.rect(13, 7, 3, 16, "accent")
    elif shape == "plant":
        for a in range(5):
            ang = -math.pi * 0.5 + (a - 2) * 0.5
            tip = (14 + math.cos(ang) * 10, 13 + math.sin(ang) * 10)
            c.thick_line([(14, 14), tip], 1.8, "accent")
        c.poly([(8, 13), (20, 13), (18, 25), (10, 25)], "body")
        c.rect(7, 12, 14, 3, "top")
    elif shape == "paint_can":
        c.rect(8, 9, 12, 14, "body")
        c.rect(8, 13, 12, 5, "accent")
        c.ellipse(14, 9, 6, 2, "top")
    return c


def enemy_palette(data):
    body = hexc(data.get("color", "#ffffff"))
    accent = hexc(data.get("accent", "#888888"))
    return {
        "body": body, "accent": accent, "top": shade(body, 0.12), "belly": shade(body, 0.3),
        "white": (250, 250, 250, 255), "pupil": hexc("#1a1210"), "ink": OUTLINE,
        "eye": hexc("#e04646"), "led": accent, "glint": (255, 255, 255, 255),
        "bubble": body, "leg": shade(body, -0.2), "tail": accent,
        "wing": (225, 240, 250, 255), "wing_dark": shade(body, -0.25), "skin": hexc("#f0c8a0"),
        "beard": (245, 245, 240, 255), "nose": hexc("#e8907a"), "beak": hexc("#e8a040"), "grass": hexc("#5ea84a"),
    }


def build_enemy(key, data):
    shape = data.get("shape", "sock")
    if shape == "cat":
        return None
    pal = enemy_palette(data)
    translucent = ("bubble", "wing")
    frames = [enemy_canvas(shape, f, data) for f in range(2)]
    rows = [[fr.render(pal, translucent=translucent) for fr in frames],
            [fr.render(pal, flash=True, translucent=translucent) for fr in frames]]
    w, h, img = sheet(rows, 28, 28)
    write_png(os.path.join(OUT, "enemy_%s.png" % key.lower()), w, h, img)
    return {"cell": [28, 28], "anchor": [14.0, 15.0], "frames": 2}


def main():
    os.makedirs(OUT, exist_ok=True)
    manifest = {"cats": {}, "enemies": {}}
    cats = json.load(open(os.path.join(ROOT, "data", "cats.json"), encoding="utf8"))
    for cid, data in cats.items():
        manifest["cats"][cid] = build_cat(cid, data)
    enemies = json.load(open(os.path.join(ROOT, "data", "enemies.json"), encoding="utf8"))
    props = json.load(open(os.path.join(ROOT, "data", "props.json"), encoding="utf8"))["props"]
    for key, data in list(enemies.items()) + list(props.items()):
        info = build_enemy(key, data)
        if info:
            manifest["enemies"][key] = info
    with open(os.path.join(OUT, "sprites.json"), "w", encoding="utf8", newline="\n") as f:
        json.dump(manifest, f, indent=2)
    print("written to", OUT, len(manifest["cats"]), "cats,", len(manifest["enemies"]), "enemies/props")


if __name__ == "__main__":
    main()
