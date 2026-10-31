"""Pixel art for the apartment (map Byt): floors and furniture, the pilot of
the new look (PLAN.md, short-term plan part 1, step 8). One pixel = one
world unit, like the cat sprites, light from the top left, a dark outline.

    python tools/gen_apartment.py

Writes assets/sprites/apt_*.png. Floors tile seamlessly; furniture made of
fabric comes in one picture per rug colour (FloorChunk.RUG_COLORS), named
apt_<kind>_<i>.png, the rest apt_<kind>.png. Afterwards run the Godot import.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_sprites import OUT, OUTLINE, hexc, shade, write_png  # noqa: E402

# Same order as FloorChunk.RUG_COLORS.
FABRICS = ["8e3b46", "2f6f73", "c9a24a", "5b4a8a", "3f6b3a"]
WOOD = hexc("8a5a3b")
WOOD_DARK = hexc("6b4630")
CLEAR = (0, 0, 0, 0)


class Img:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [CLEAR] * (w * h)

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y * self.w + x]
        return CLEAR

    def set(self, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y * self.w + x] = c

    def rect(self, x, y, w, h, c):
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                self.set(xx, yy, c(xx, yy) if callable(c) else c)

    def circle(self, cx, cy, r, c, ry=None):
        ry = r if ry is None else ry
        for yy in range(int(cy - ry - 1), int(cy + ry + 2)):
            for xx in range(int(cx - r - 1), int(cx + r + 2)):
                dx, dy = (xx + 0.5 - cx) / r, (yy + 0.5 - cy) / ry
                if dx * dx + dy * dy <= 1.0:
                    self.set(xx, yy, c(xx, yy) if callable(c) else c)

    def poly(self, pts, c):
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
                    self.set(x, y, c(x, y) if callable(c) else c)

    def line(self, x1, y1, x2, y2, c):
        n = int(max(abs(x2 - x1), abs(y2 - y1))) + 1
        for i in range(n + 1):
            t = i / n
            self.set(round(x1 + (x2 - x1) * t), round(y1 + (y2 - y1) * t), c)

    def bevel(self, x, y, w, h, k=0.22):
        """Lit top/left edge, shaded bottom/right edge of a block."""
        for xx in range(int(x), int(x + w)):
            self._shade(xx, int(y), k)
            self._shade(xx, int(y + h - 1), -k)
        for yy in range(int(y) + 1, int(y + h) - 1):
            self._shade(int(x), yy, k * 0.6)
            self._shade(int(x + w - 1), yy, -k)

    def round_shade(self, cx, cy, r, k=0.25):
        """Light on the top-left of a round thing, shade at the bottom right."""
        for yy in range(int(cy - r - 1), int(cy + r + 2)):
            for xx in range(int(cx - r - 1), int(cx + r + 2)):
                dx, dy = (xx + 0.5 - cx) / r, (yy + 0.5 - cy) / r
                d = dx * dx + dy * dy
                if d <= 1.0:
                    self._shade(xx, yy, k * (-(dx + dy) * 0.7) * (0.4 + d))

    def _shade(self, x, y, k):
        c = self.get(x, y)
        if c[3]:
            self.set(x, y, shade(c, k))

    def outline(self):
        out = list(self.px)
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y * self.w + x][3]:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if self.get(x + dx, y + dy)[3] == 255:
                        out[y * self.w + x] = OUTLINE
                        break
        self.px = out

    def save(self, name):
        write_png(os.path.join(OUT, name), self.w, self.h, self.px)


def wood_fill(rng, base, horizontal=True):
    """Wood with grain streaks."""
    seeds = {}

    def f(x, y):
        key = y if horizontal else x
        if key not in seeds:
            seeds[key] = rng.uniform(-0.06, 0.06)
        n = seeds[key] + (0.05 if (x * 7 + y * 13) % 23 == 0 else 0.0)
        if (x + y * 3) % 17 == 0 and rng.random() < 0.5:
            n -= 0.08
        return shade(base, n)
    return f


def speckle(rng, base, amount=0.06, chance=0.25):
    def f(x, y):
        return shade(base, rng.uniform(-amount, amount)) if rng.random() < chance else base
    return f


# --- floors ------------------------------------------------------------------

def floor_planks():
    rng = random.Random(1)
    img = Img(192, 64)
    offsets = [0, 48, 24, 72]
    for row in range(4):
        y0 = row * 16
        for k in range(-1, 3):
            x0 = offsets[row] + k * 96
            tone = shade(WOOD, rng.uniform(-0.09, 0.05))
            grain = [rng.uniform(-0.05, 0.05) for _ in range(16)]
            for y in range(y0, y0 + 16):
                for x in range(x0, x0 + 96):
                    xx = x % 192
                    c = shade(tone, grain[y - y0] + (0.04 if ((x * 5 + y * 11) % 29) == 0 else 0.0))
                    if (x // 5 + y * 3) % 31 == 0:
                        c = shade(c, -0.06)
                    img.set(xx, y, c)
            # Seam at the plank's start, a lit top row, a dark bottom row.
            for y in range(y0, y0 + 16):
                img.set(x0 % 192, y, shade(tone, -0.45))
                img.set((x0 + 1) % 192, y, shade(tone, 0.12))
            for x in range(x0, x0 + 96):
                img.set(x % 192, y0, shade(tone, 0.14))
                img.set(x % 192, y0 + 15, shade(tone, -0.4))
            # A knot now and then.
            if rng.random() < 0.6:
                kx, ky = x0 + rng.randint(12, 80), y0 + rng.randint(5, 10)
                for dx in range(-3, 4):
                    for dy in range(-1, 2):
                        if abs(dx) / 3.5 + abs(dy) / 1.5 <= 1.0:
                            img.set((kx + dx) % 192, ky + dy, shade(tone, -0.25 if abs(dx) < 2 else -0.12))
    img.save("apt_floor_planks.png")


def floor_tiles():
    rng = random.Random(2)
    img = Img(64, 64)
    for ty in range(2):
        for tx in range(2):
            base = hexc("e9e2d0") if (tx + ty) % 2 == 0 else hexc("b7c4cc")
            x0, y0 = tx * 32, ty * 32
            img.rect(x0, y0, 32, 32, speckle(rng, base, 0.04, 0.2))
            img.bevel(x0 + 1, y0 + 1, 30, 30, 0.12)
            # Grout lines on the top and left of each tile.
            for i in range(32):
                img.set(x0 + i, y0, hexc("8f9a9e"))
                img.set(x0, y0 + i, hexc("8f9a9e"))
            # A soft glint in one corner.
            for i in range(4):
                img.set(x0 + 4 + i, y0 + 4, shade(base, 0.25))
            img.set(x0 + 4, y0 + 5, shade(base, 0.25))
    img.save("apt_floor_tiles.png")


def floor_carpet():
    rng = random.Random(3)
    base = hexc("6f5f86")
    img = Img(64, 64)
    img.rect(0, 0, 64, 64, speckle(rng, base, 0.07, 0.45))
    # A woven pattern of small diamonds.
    for y in range(0, 64, 8):
        for x in range(0, 64, 8):
            sx = x + (4 if (y // 8) % 2 else 0)
            for d in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                img.set((sx + d[0]) % 64, (y + 4 + d[1]) % 64, shade(base, 0.14))
            img.set(sx % 64, (y + 4) % 64, shade(base, 0.22))
    img.save("apt_floor_carpet.png")


# --- furniture ---------------------------------------------------------------

def framed(w, h):
    """An image with a 1 px margin for the outline."""
    return Img(w + 2, h + 2)


def sofa(fabric, n):
    img = framed(112, 44)
    o = 1
    dark, darker, light = shade(fabric, -0.18), shade(fabric, -0.32), shade(fabric, 0.18)
    img.rect(o, o, 112, 44, dark)
    img.rect(o, o, 112, 12, darker)
    img.bevel(o, o, 112, 12, 0.15)
    for x0 in (o, o + 102):
        img.rect(x0, o, 10, 44, darker)
        img.bevel(x0, o, 10, 44, 0.18)
    for i in range(3):
        x0 = o + 12 + i * 30
        img.rect(x0, o + 12, 28, 30, fabric)
        img.bevel(x0, o + 12, 28, 30, 0.2)
        # Stitching and a dimple in the middle of the cushion.
        for x in range(x0 + 3, x0 + 25, 2):
            img.set(x, o + 15, light)
        img.set(x0 + 14, o + 27, shade(fabric, -0.2))
        img.set(x0 + 13, o + 27, shade(fabric, -0.1))
    # A throw pillow in the corner.
    p = hexc("efe0b8")
    img.rect(o + 14, o + 7, 14, 10, p)
    img.bevel(o + 14, o + 7, 14, 10, 0.2)
    img.outline()
    img.save("apt_sofa_%d.png" % n)


def armchair(fabric, n):
    img = framed(44, 44)
    o = 1
    dark, darker = shade(fabric, -0.18), shade(fabric, -0.32)
    img.rect(o, o, 44, 44, dark)
    img.rect(o, o, 44, 11, darker)
    img.bevel(o, o, 44, 11, 0.15)
    for x0 in (o, o + 36):
        img.rect(x0, o, 8, 44, darker)
        img.bevel(x0, o, 8, 44, 0.18)
    img.rect(o + 8, o + 11, 28, 30, fabric)
    img.bevel(o + 8, o + 11, 28, 30, 0.2)
    for x in range(o + 11, o + 33, 2):
        img.set(x, o + 14, shade(fabric, 0.18))
    img.outline()
    img.save("apt_armchair_%d.png" % n)


def coffee_table(fabric, n):
    rng = random.Random(10 + n)
    img = framed(64, 36)
    o = 1
    img.rect(o, o, 64, 36, WOOD_DARK)
    img.rect(o + 3, o + 3, 58, 30, wood_fill(rng, WOOD))
    img.bevel(o, o, 64, 36, 0.2)
    img.bevel(o + 3, o + 3, 58, 30, 0.12)
    # A magazine and a mug of coffee.
    img.rect(o + 10, o + 10, 18, 14, shade(fabric, 0.2))
    img.rect(o + 12, o + 12, 14, 3, shade(fabric, 0.45))
    img.rect(o + 12, o + 17, 10, 1, shade(fabric, -0.1))
    img.circle(o + 46, o + 16, 5, hexc("efe6d0"))
    img.circle(o + 46, o + 16, 3, hexc("5a3a26"))
    img.set(o + 45, o + 15, hexc("8a5a3a"))
    img.outline()
    img.save("apt_coffee_table_%d.png" % n)


def bookshelf():
    rng = random.Random(4)
    img = framed(110, 22)
    o = 1
    img.rect(o, o, 110, 22, WOOD_DARK)
    img.bevel(o, o, 110, 22, 0.2)
    x = o + 3
    colors = [hexc(c) for c in FABRICS + ["e8dcc0", "4a6a9a", "a04a3a"]]
    while x < o + 106:
        w = rng.randint(3, 6)
        c = rng.choice(colors)
        top = o + 3 + rng.randint(0, 3)
        img.rect(x, top, w - 1, o + 19 - top, c)
        img.rect(x, top, w - 1, 1, shade(c, 0.3))
        img.rect(x + w - 2, top + 1, 1, o + 18 - top, shade(c, -0.25))
        if rng.random() < 0.4:
            img.rect(x, top + 4, w - 1, 1, hexc("f2c14e"))
        x += w + (1 if rng.random() < 0.2 else 0)
    img.outline()
    img.save("apt_bookshelf.png")


def tv():
    img = framed(90, 22)
    o = 1
    rng = random.Random(5)
    img.rect(o, o + 3, 90, 19, wood_fill(rng, WOOD_DARK))
    img.bevel(o, o + 3, 90, 19, 0.2)
    img.rect(o + 9, o, 72, 7, hexc("1d1d24"))
    img.rect(o + 10, o + 1, 70, 1, hexc("4a5a7a"))
    img.rect(o + 12, o + 2, 18, 1, hexc("6a7a9a"))
    img.circle(o + 75, o + 15, 3, hexc("2a2a30"))
    img.circle(o + 15, o + 15, 3, hexc("2a2a30"))
    img.rect(o + 36, o + 13, 18, 4, hexc("3a3a44"))
    img.set(o + 52, o + 14, hexc("d94848"))
    img.outline()
    img.save("apt_tv.png")


def floor_lamp():
    img = framed(26, 26)
    c = 14
    img.circle(c, c, 12, hexc("f3e3b8"))
    img.circle(c, c, 9, hexc("f7ecc8"))
    img.round_shade(c, c, 12, 0.18)
    img.circle(c, c, 5, hexc("fff6d8"))
    img.circle(c, c, 2.5, hexc("ffffff"))
    for i in range(8):
        a = i * math.tau / 8
        img.set(c + math.cos(a) * 10.5, c + math.sin(a) * 10.5, hexc("d8c49a"))
    img.outline()
    img.save("apt_floor_lamp.png")


def plant():
    rng = random.Random(6)
    img = framed(48, 48)
    c = 25
    greens = [hexc("4f8f3e"), hexc("5ea84a"), hexc("3f7a34")]
    for i in range(8):
        a = math.tau * i / 8 + rng.uniform(-0.15, 0.15)
        tip = (c + math.cos(a) * 22, c + math.sin(a) * 22)
        side = (math.cos(a + math.pi / 2) * 5, math.sin(a + math.pi / 2) * 5)
        mid = (c + math.cos(a) * 11, c + math.sin(a) * 11)
        g = greens[i % 3]
        img.poly([(c, c), (mid[0] + side[0], mid[1] + side[1]), tip, (mid[0] - side[0], mid[1] - side[1])], g)
        img.line(c, c, tip[0], tip[1], shade(g, 0.25))
    img.circle(c, c, 11, hexc("b5603a"))
    img.circle(c, c, 8, hexc("6b4630"))
    img.round_shade(c, c, 11, 0.2)
    for i in range(3):
        a = math.tau * i / 3 + 0.4
        img.line(c, c, c + math.cos(a) * 7, c + math.sin(a) * 7, greens[1])
    img.outline()
    img.save("apt_plant.png")


def cat_tree(fabric, n):
    img = framed(48, 48)
    o = 1
    base = hexc("d8c8a8")
    rng = random.Random(7)
    img.rect(o, o, 48, 48, speckle(rng, base, 0.06, 0.4))
    img.bevel(o, o, 48, 48, 0.18)
    for (px, py) in ((o + 10, o + 10), (o + 38, o + 38)):
        img.circle(px, py, 6, hexc("c9a26a"))
        for r in (2, 4):
            for i in range(16):
                a = i * math.tau / 16
                img.set(px + math.cos(a) * r, py + math.sin(a) * r, hexc("a8824a"))
    img.circle(o + 32, o + 16, 12, shade(fabric, 0.2))
    img.circle(o + 32, o + 16, 8, shade(fabric, 0.4))
    img.round_shade(o + 32, o + 16, 12, 0.2)
    img.line(o + 12, o + 34, o + 12, o + 44, hexc("e04646"))
    img.circle(o + 12, o + 45, 2.5, hexc("e04646"))
    img.outline()
    img.save("apt_cat_tree_%d.png" % n)


def dining_table():
    rng = random.Random(8)
    img = framed(92, 94)
    o = 1
    cy = o + 47
    for (cx, dy) in ((o + 24, -38), (o + 68, -38), (o + 24, 38), (o + 68, 38)):
        y = cy + dy
        img.rect(cx - 9, y - 9, 18, 18, wood_fill(rng, WOOD))
        img.bevel(cx - 9, y - 9, 18, 18, 0.22)
        img.rect(cx - 6, y - 6, 12, 12, hexc("c9a24a"))
        img.bevel(cx - 6, y - 6, 12, 12, 0.15)
    img.rect(o, cy - 28, 92, 56, WOOD_DARK)
    img.rect(o + 4, cy - 24, 84, 48, wood_fill(rng, WOOD))
    img.bevel(o, cy - 28, 92, 56, 0.2)
    for (px, py) in ((-22, -14), (22, -14), (-22, 14), (22, 14)):
        img.circle(o + 46 + px, cy + py, 7, hexc("f4f1ea"))
        img.circle(o + 46 + px, cy + py, 4, hexc("e2ddd0"))
        img.set(o + 44 + px, cy + py - 4, hexc("ffffff"))
    # A little vase with a flower in the middle.
    img.circle(o + 46, cy, 3, hexc("5b7fb0"))
    img.set(o + 46, cy - 1, hexc("e0628f"))
    img.outline()
    img.save("apt_dining_table.png")


def cat_bowls(fabric, n):
    rng = random.Random(9)
    img = framed(48, 24)
    o = 1
    mat = shade(fabric, 0.3)
    img.rect(o, o, 48, 24, mat)
    img.bevel(o, o, 48, 24, 0.15)
    for bx in (o + 13, o + 35):
        img.circle(bx, o + 12, 8, hexc("d9d9e0"))
        img.round_shade(bx, o + 12, 8, 0.3)
        img.circle(bx, o + 12, 5.5, hexc("b8b8c4"))
    img.circle(o + 35, o + 12, 5, hexc("6fb0e0"))
    img.set(o + 33, o + 10, hexc("c8e8ff"))
    for i in range(9):
        img.set(o + 10 + rng.randint(0, 6), o + 9 + rng.randint(0, 6), hexc("9a6a3a"))
    img.outline()
    img.save("apt_cat_bowls_%d.png" % n)


def trash_bin():
    img = framed(24, 24)
    c = 12.5
    img.circle(c, c, 10.5, hexc("8a9096"))
    img.round_shade(c, c, 10.5, 0.3)
    img.circle(c, c, 7, hexc("9aa0a6"))
    img.rect(c - 6, c - 1, 12, 2, hexc("5f6468"))
    img.outline()
    img.save("apt_trash_bin.png")


def counter():
    rng = random.Random(11)
    img = framed(112, 36)
    o = 1
    img.rect(o, o, 112, 36, speckle(rng, hexc("c9ced2"), 0.05, 0.35))
    img.bevel(o, o, 112, 36, 0.2)
    img.rect(o + 10, o + 7, 30, 22, hexc("9fb2bf"))
    img.bevel(o + 10, o + 7, 30, 22, -0.2)
    img.circle(o + 25, o + 18, 2, hexc("6a7a85"))
    img.rect(o + 23, o + 2, 4, 6, hexc("e0e4e8"))
    for (px, py) in ((70, 11), (90, 11), (70, 25), (90, 25)):
        img.circle(o + px, o + py, 6, hexc("2a2a30"))
        for i in range(12):
            a = i * math.tau / 12
            img.set(o + px + math.cos(a) * 4, o + py + math.sin(a) * 4, hexc("5a5a64"))
    img.outline()
    img.save("apt_counter.png")


def bed(fabric, n):
    rng = random.Random(12)
    img = framed(92, 124)
    o = 1
    img.rect(o, o, 92, 124, wood_fill(rng, WOOD_DARK, False))
    img.bevel(o, o, 92, 124, 0.2)
    img.rect(o + 4, o + 4, 84, 116, hexc("f1ece2"))
    for px in (o + 8, o + 50):
        img.rect(px, o + 8, 34, 20, hexc("ffffff"))
        img.bevel(px, o + 8, 34, 20, -0.12)
        img.set(px + 17, o + 18, hexc("e6e0d4"))
    img.rect(o + 4, o + 38, 84, 82, fabric)
    img.bevel(o + 4, o + 38, 84, 82, 0.15)
    # The blanket's fold and a checked pattern.
    img.rect(o + 4, o + 38, 84, 6, shade(fabric, 0.25))
    for y in range(o + 50, o + 118, 10):
        for x in range(o + 6, o + 86):
            img.set(x, y, shade(fabric, -0.12))
    for x in range(o + 14, o + 86, 12):
        for y in range(o + 46, o + 118):
            img.set(x, y, shade(fabric, -0.12))
    img.outline()
    img.save("apt_bed_%d.png" % n)


def nightstand():
    rng = random.Random(13)
    img = framed(28, 28)
    o = 1
    img.rect(o, o, 28, 28, wood_fill(rng, WOOD))
    img.bevel(o, o, 28, 28, 0.22)
    img.circle(o + 14, o + 14, 8, hexc("f3e3b8"))
    img.round_shade(o + 14, o + 14, 8, 0.15)
    img.circle(o + 14, o + 14, 3, hexc("fff6d8"))
    img.outline()
    img.save("apt_nightstand.png")


def wardrobe():
    rng = random.Random(14)
    img = framed(110, 32)
    o = 1
    img.rect(o, o, 110, 32, wood_fill(rng, WOOD_DARK))
    img.bevel(o, o, 110, 32, 0.22)
    for x0 in (o + 4, o + 57):
        img.rect(x0, o + 4, 49, 24, wood_fill(rng, shade(WOOD_DARK, 0.06)))
        img.bevel(x0, o + 4, 49, 24, -0.15)
    img.rect(o + 55, o, 1, 32, OUTLINE)
    img.rect(o + 50, o + 13, 2, 6, hexc("f2c14e"))
    img.rect(o + 59, o + 13, 2, 6, hexc("f2c14e"))
    img.outline()
    img.save("apt_wardrobe.png")


def cat_bed(fabric, n):
    img = framed(36, 36)
    c = 18.5
    img.circle(c, c, 17, fabric)
    img.round_shade(c, c, 17, 0.25)
    img.circle(c, c, 11, shade(fabric, 0.35))
    img.round_shade(c, c, 11, -0.15)
    # A paw print on the cushion.
    pad = shade(fabric, 0.15)
    img.circle(c, c + 2, 3, pad)
    for (dx, dy) in ((-3, -2), (-1, -4), (1, -4), (3, -2)):
        img.set(c + dx, c + dy, pad)
    img.outline()
    img.save("apt_cat_bed_%d.png" % n)


def rug_pattern(fabric, n):
    """The woven middle of a rug: tiles seamlessly (32 px)."""
    rng = random.Random(20 + n)
    img = Img(32, 32)
    img.rect(0, 0, 32, 32, speckle(rng, fabric, 0.05, 0.35))
    light, dark = shade(fabric, 0.22), shade(fabric, -0.18)
    for y in range(32):
        for x in range(32):
            # Diamonds on a lattice, with a darker weave line between them.
            d = abs((x % 16) - 8) + abs((y % 16) - 8)
            if d == 6:
                img.set(x, y, light)
            elif d == 7:
                img.set(x, y, dark)
            elif d < 2:
                img.set(x, y, shade(fabric, 0.35))
    img.save("apt_rug_%d.png" % n)


def mousetrap(sprung):
    img = framed(16, 10)
    o = 1
    rng = random.Random(30)
    img.rect(o, o, 16, 10, wood_fill(rng, hexc("c9a26a")))
    img.bevel(o, o, 16, 10, 0.2)
    img.rect(o + 7, o, 2, 10, hexc("9aa0a6"))
    if sprung:
        img.rect(o + 13, o + 1, 2, 8, hexc("c8ccd0"))
        img.rect(o + 14, o + 1, 1, 8, hexc("8a9096"))
    else:
        img.rect(o + 1, o + 1, 1, 8, hexc("c8ccd0"))
        # The cheese bait.
        img.rect(o + 11, o + 3, 4, 3, hexc("f2d14e"))
        img.set(o + 12, o + 4, hexc("d9a020"))
    img.outline()
    img.save("apt_trap_mousetrap_%s.png" % ("sprung" if sprung else "set"))


def stove():
    img = framed(52, 52)
    o = 1
    rng = random.Random(31)
    img.rect(o, o, 52, 52, speckle(rng, hexc("3a3a40"), 0.05, 0.3))
    img.bevel(o, o, 52, 52, 0.18)
    img.rect(o + 3, o + 3, 46, 46, hexc("2e2e34"))
    for i in range(46):
        img.set(o + 3 + i, o + 3, hexc("4a4a52"))
    # Knobs along the front edge.
    for kx in (o + 10, o + 20, o + 32, o + 42):
        img.circle(kx, o + 49, 1.6, hexc("c8c8d0"))
    img.outline()
    img.save("apt_trap_stove.png")


def main():
    os.makedirs(OUT, exist_ok=True)
    floor_planks()
    floor_tiles()
    floor_carpet()
    for n, hexcode in enumerate(FABRICS):
        fabric = hexc(hexcode)
        sofa(fabric, n)
        armchair(fabric, n)
        coffee_table(fabric, n)
        cat_tree(fabric, n)
        cat_bowls(fabric, n)
        bed(fabric, n)
        cat_bed(fabric, n)
        rug_pattern(fabric, n)
    bookshelf()
    tv()
    floor_lamp()
    plant()
    dining_table()
    trash_bin()
    counter()
    nightstand()
    wardrobe()
    mousetrap(False)
    mousetrap(True)
    stove()
    print("apartment art written to", OUT)


if __name__ == "__main__":
    main()
