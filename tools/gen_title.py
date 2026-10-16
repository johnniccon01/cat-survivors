"""Draws the title screen picture (assets/title.png, 320x180 pixel art shown
at 4x): a night sky over the city, a big moon and cats on a rooftop.
Pure Python, no third-party assets. Run: python tools/gen_title.py"""
import math
import os
import random
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "title.png")
W, H = 320, 180
rnd = random.Random(7)


def hexc(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def mixc(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


img = [[(0, 0, 0)] * W for _ in range(H)]


def put(x, y, c):
    x, y = int(x), int(y)
    if 0 <= x < W and 0 <= y < H:
        img[y][x] = c


def blend(x, y, c, a):
    x, y = int(x), int(y)
    if 0 <= x < W and 0 <= y < H:
        img[y][x] = mixc(img[y][x], c, a)


def rect(x0, y0, w, h, c):
    for y in range(int(y0), int(y0 + h)):
        for x in range(int(x0), int(x0 + w)):
            put(x, y, c)


def disc(cx, cy, r, c):
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                put(x, y, c)


def ellipse(cx, cy, rx, ry, c):
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                put(x, y, c)


def tri(p, c):
    (x1, y1), (x2, y2), (x3, y3) = p
    for y in range(int(min(y1, y2, y3)), int(max(y1, y2, y3)) + 1):
        for x in range(int(min(x1, x2, x3)), int(max(x1, x2, x3)) + 1):
            px, py = x + 0.5, y + 0.5
            d1 = (px - x2) * (y1 - y2) - (x1 - x2) * (py - y2)
            d2 = (px - x3) * (y2 - y3) - (x2 - x3) * (py - y3)
            d3 = (px - x1) * (y3 - y1) - (x3 - x1) * (py - y1)
            if not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0)):
                put(x, y, c)


# --- sky ------------------------------------------------------------------------
top, horizon = hexc("0b0820"), hexc("3a2a5e")
for y in range(H):
    c = mixc(top, horizon, min(y / 130.0, 1.0) ** 1.4)
    for x in range(W):
        img[y][x] = c
for i in range(140):
    x, y = rnd.randrange(W), rnd.randrange(105)
    b = rnd.random()
    put(x, y, mixc(img[y][x], (255, 245, 220), 0.35 + 0.6 * b))
    if b > 0.93:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            blend(x + dx, y + dy, (255, 245, 220), 0.35)

# --- moon -------------------------------------------------------------------------
MX, MY, MR = 236, 50, 24
for r in range(60, MR, -1):
    a = 0.10 * (1.0 - (r - MR) / (60 - MR)) ** 2
    for k in range(int(r * 7)):
        ang = k / (r * 7) * math.tau
        blend(MX + math.cos(ang) * r, MY + math.sin(ang) * r, (255, 236, 180), a)
disc(MX, MY, MR, hexc("f6e7b4"))
for cx, cy, r in ((-8, -6, 5), (7, 4, 4), (-2, 10, 3), (10, -10, 2.5)):
    disc(MX + cx, MY + cy, r, hexc("e2cf95"))
for y in range(int(MY - MR), int(MY + MR + 1)):
    for x in range(int(MX - MR), int(MX + MR + 1)):
        if (x - MX) ** 2 + (y - MY) ** 2 <= MR * MR and (x - MX + 7) ** 2 + (y - MY - 5) ** 2 > (MR + 3) ** 2:
            blend(x, y, hexc("fff6d6"), 0.5)

# --- city skyline (far, then near) ------------------------------------------------
def skyline(base_y, color, window, seed, min_h, max_h, lit):
    r = random.Random(seed)
    x = -4
    while x < W:
        w = r.randint(14, 30)
        h = r.randint(min_h, max_h)
        rect(x, base_y - h, w, h + 80, color)
        if r.random() < 0.35:
            rect(x + w // 2 - 1, base_y - h - r.randint(4, 9), 2, 9, color)
        for wy in range(base_y - h + 4, base_y, 6):
            for wx in range(x + 3, x + w - 3, 5):
                if r.random() < lit:
                    rect(wx, wy, 2, 3, window)
        x += w + r.randint(-2, 3)


skyline(128, hexc("1d1638"), hexc("8a6a3a"), 3, 20, 60, 0.18)
skyline(140, hexc("150f2a"), hexc("f2c14e"), 11, 10, 38, 0.22)

# --- the rooftop in front -----------------------------------------------------------
ROOF = hexc("0d0919")
EDGE = hexc("2a2148")
rect(0, 138, W, 50, ROOF)
for x in range(0, W, 2):
    put(x, 138, EDGE)
# chimney, antenna, water tank
rect(20, 116, 16, 22, ROOF)
rect(18, 114, 20, 3, ROOF)
for x in range(18, 38):
    put(x, 114, EDGE)
for k in range(5):
    blend(28 + k * 0.6, 108 - k * 3, (200, 200, 220), 0.25)
rect(282, 100, 2, 38, ROOF)
for i, w in enumerate((16, 12, 8)):
    rect(283 - w // 2, 104 + i * 6, w, 1, ROOF)
disc(283, 99, 1.5, hexc("e04646"))
ellipse(258, 126, 12, 6, ROOF)
rect(246, 120, 24, 18, ROOF)


# --- cats ---------------------------------------------------------------------------
def cat_mask(cx, by, s, tail_dir=1):
    """Pixels of a sitting cat facing the viewer; (cx, by) = bottom centre."""
    pts = set()

    def e(x0, y0, rx, ry):
        for y in range(int(y0 - ry - 1), int(y0 + ry + 2)):
            for x in range(int(x0 - rx - 1), int(x0 + rx + 2)):
                if ((x + 0.5 - x0) / rx) ** 2 + ((y + 0.5 - y0) / ry) ** 2 <= 1.0:
                    pts.add((x, y))

    def t(p):
        (x1, y1), (x2, y2), (x3, y3) = p
        for y in range(int(min(y1, y2, y3)), int(max(y1, y2, y3)) + 1):
            for x in range(int(min(x1, x2, x3)), int(max(x1, x2, x3)) + 1):
                px, py = x + 0.5, y + 0.5
                d1 = (px - x2) * (y1 - y2) - (x1 - x2) * (py - y2)
                d2 = (px - x3) * (y2 - y3) - (x2 - x3) * (py - y3)
                d3 = (px - x1) * (y3 - y1) - (x3 - x1) * (py - y1)
                if not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0)):
                    pts.add((x, y))

    e(cx, by - 7 * s, 6 * s, 7.5 * s)
    e(cx, by - 1.5 * s, 7 * s, 2.5 * s)
    hx, hy = cx, by - 16 * s
    e(hx, hy, 4.6 * s, 4.4 * s)
    t([(hx - 4.4 * s, hy - 1 * s), (hx - 4.0 * s, hy - 7.5 * s), (hx - 0.6 * s, hy - 3.8 * s)])
    t([(hx + 4.4 * s, hy - 1 * s), (hx + 4.0 * s, hy - 7.5 * s), (hx + 0.6 * s, hy - 3.8 * s)])
    for k in range(30):
        q = k / 29
        e(cx + tail_dir * (6.5 * s + 3.5 * s * math.sin(q * 3.0)), by - 1 * s - 11 * s * q, 1.2 * s, 1.2 * s)
    return pts, (hx, hy)


def draw_cat(cx, by, s, eyes, tail_dir=1, rim=None):
    pts, (hx, hy) = cat_mask(cx, by, s, tail_dir)
    if rim is not None:
        for (x, y) in pts:
            for dx, dy in ((1, 0), (-1, 0), (0, -1), (1, -1), (-1, -1)):
                if (x + dx, y + dy) not in pts:
                    put(x + dx, y + dy, rim)
    for (x, y) in pts:
        put(x, y, hexc("07050f"))
    for ex in (-1.8 * s, 1.8 * s):
        for dy in (0, 1):
            put(hx + ex, hy + dy, eyes)
        blend(hx + ex + 1, hy, eyes, 0.5)


# The big cat sits on a chimney right in front of the moon.
rect(MX - 9, 92, 18, 46, ROOF)
rect(MX - 11, 90, 22, 3, ROOF)
for x in range(MX - 11, MX + 11):
    put(x, 90, EDGE)
draw_cat(MX, 90, 1.7, hexc("f2d14e"))
# Two more on the roof, outlined so they stand out from the city.
draw_cat(70, 138, 1.2, hexc("9ad04a"), -1, hexc("3d2f6a"))
draw_cat(100, 138, 1.0, hexc("8fd3ff"), 1, hexc("3d2f6a"))

# a few fireflies / dust motes in the air
for i in range(14):
    x, y = rnd.randrange(60, 300), rnd.randrange(100, 160)
    put(x, y, hexc("f2e6a0"))
    blend(x + 1, y, hexc("f2e6a0"), 0.4)

# --- write PNG ------------------------------------------------------------------------
raw = bytearray()
for row in img:
    raw.append(0)
    for c in row:
        raw.extend(bytes(c))


def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "wb") as f:
    f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))
print("written", OUT)
