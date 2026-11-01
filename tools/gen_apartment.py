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


def fabric_fill(rng, base, y0, h, tex=0.05, light=0.14):
    """Upholstery: lit at the top, shaded at the bottom, a fine weave."""
    def f(x, y):
        t = (y - y0) / max(h - 1, 1)
        k = light - 2 * light * t + rng.uniform(-tex, tex)
        if (x + y) % 4 == 0:
            k -= 0.03
        return shade(base, k)
    return f


def sofa(fabric, n):
    rng = random.Random(30 + n)
    img = framed(116, 48)
    o = 1
    dark, darker = shade(fabric, -0.2), shade(fabric, -0.34)
    # Back rest with tufted buttons.
    img.rect(o, o, 116, 14, fabric_fill(rng, darker, o, 14))
    img.bevel(o, o, 116, 14, 0.16)
    for x in range(o + 18, o + 100, 14):
        img.set(x, o + 6, shade(darker, -0.35))
        img.set(x + 1, o + 6, shade(darker, 0.15))
        img.line(x - 4, o + 3, x, o + 6, shade(darker, -0.15))
        img.line(x + 4, o + 3, x, o + 6, shade(darker, -0.15))
    # Arms, rolled: a light ridge along the top.
    for x0 in (o, o + 105):
        img.rect(x0, o + 2, 11, 46, fabric_fill(rng, darker, o + 2, 46))
        img.bevel(x0, o + 2, 11, 46, 0.2)
        img.rect(x0 + 4, o + 4, 2, 42, shade(darker, 0.22))
    # Seat cushions with piping and a sag in the middle.
    for i in range(3):
        x0 = o + 12 + i * 31
        img.rect(x0, o + 14, 30, 32, fabric_fill(rng, fabric, o + 14, 32))
        img.bevel(x0, o + 14, 30, 32, 0.18)
        for x in range(x0 + 2, x0 + 28):
            img.set(x, o + 44, shade(fabric, 0.3))
        img.circle(x0 + 15, o + 30, 6, lambda x, y: shade(img.get(x, y), -0.06), 4)
        img.rect(x0 + 29, o + 14, 1, 32, shade(fabric, -0.4))
    # Two throw pillows, a cream striped one and a contrasting one.
    cream = hexc("efe0b8")
    img.poly([(o + 15, o + 8), (o + 31, o + 5), (o + 34, o + 19), (o + 18, o + 22)], cream)
    for k in range(3):
        img.line(o + 17 + k * 5, o + 8 - k, o + 20 + k * 5, o + 21 - k, shade(cream, -0.18))
    img.bevel(o + 15, o + 6, 18, 15, 0.12)
    other = hexc(FABRICS[(n + 2) % len(FABRICS)])
    img.poly([(o + 84, o + 6), (o + 99, o + 8), (o + 97, o + 22), (o + 82, o + 20)], other)
    img.round_shade(o + 90, o + 14, 8, 0.25)
    img.set(o + 90, o + 14, shade(other, -0.3))
    # A knitted throw hanging over the right arm.
    throw = hexc("e8dcc0")
    img.rect(o + 101, o + 16, 15, 24, throw)
    for y in range(o + 17, o + 40, 3):
        img.rect(o + 101, y, 15, 1, shade(throw, -0.1))
    img.rect(o + 101, o + 24, 15, 2, shade(fabric, 0.1))
    for x in range(o + 102, o + 116, 2):
        img.set(x, o + 40, shade(throw, -0.2))
    img.outline()
    img.save("apt_sofa_%d.png" % n)


def armchair(fabric, n):
    rng = random.Random(40 + n)
    img = framed(46, 46)
    o = 1
    darker = shade(fabric, -0.34)
    img.rect(o, o, 46, 13, fabric_fill(rng, darker, o, 13))
    img.bevel(o, o, 46, 13, 0.16)
    img.set(o + 23, o + 6, shade(darker, -0.35))
    for x0 in (o, o + 37):
        img.rect(x0, o + 2, 9, 44, fabric_fill(rng, darker, o + 2, 44))
        img.bevel(x0, o + 2, 9, 44, 0.2)
        img.rect(x0 + 3, o + 4, 2, 40, shade(darker, 0.22))
    img.rect(o + 9, o + 13, 28, 31, fabric_fill(rng, fabric, o + 13, 31))
    img.bevel(o + 9, o + 13, 28, 31, 0.18)
    for x in range(o + 11, o + 35):
        img.set(x, o + 42, shade(fabric, 0.3))
    img.circle(o + 23, o + 28, 6, lambda x, y: shade(img.get(x, y), -0.06), 4)
    cream = hexc("efe0b8")
    img.poly([(o + 13, o + 7), (o + 27, o + 5), (o + 29, o + 17), (o + 15, o + 19)], cream)
    img.bevel(o + 13, o + 5, 16, 14, 0.12)
    img.set(o + 21, o + 12, shade(cream, -0.25))
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
    img = framed(112, 26)
    o = 1
    img.rect(o, o, 112, 26, wood_fill(rng, WOOD_DARK))
    img.bevel(o, o, 112, 26, 0.22)
    img.rect(o + 2, o + 2, 108, 22, shade(WOOD_DARK, -0.35))
    x = o + 3
    colors = [hexc(c) for c in FABRICS + ["e8dcc0", "4a6a9a", "a04a3a", "d07a3a"]]
    while x < o + 107:
        roll = rng.random()
        if roll < 0.07 and x < o + 95:
            # A little potted plant between the books.
            img.circle(x + 5, o + 13, 4, hexc("b5603a"))
            img.circle(x + 5, o + 10, 5, hexc("5ea84a"))
            img.set(x + 4, o + 8, hexc("8fd06a"))
            x += 11
            continue
        if roll < 0.12 and x < o + 95:
            # A framed photo.
            img.rect(x, o + 5, 10, 14, hexc("c9a24a"))
            img.rect(x + 2, o + 7, 6, 10, hexc("8ab0d0"))
            img.rect(x + 3, o + 12, 4, 5, hexc("e0a060"))
            x += 12
            continue
        w = rng.randint(3, 6)
        c = rng.choice(colors)
        top = o + 3 + rng.randint(0, 5)
        img.rect(x, top, w - 1, o + 23 - top, c)
        img.rect(x, top, w - 1, 1, shade(c, 0.35))
        img.rect(x + w - 2, top + 1, 1, o + 22 - top, shade(c, -0.3))
        if rng.random() < 0.45:
            img.rect(x, top + 4, w - 1, 1, hexc("f2c14e"))
        if rng.random() < 0.25:
            img.rect(x, o + 18, w - 1, 1, shade(c, 0.25))
        x += w + (1 if rng.random() < 0.15 else 0)
    img.outline()
    img.save("apt_bookshelf.png")


def tv():
    img = framed(94, 26)
    o = 1
    rng = random.Random(5)
    img.rect(o, o + 4, 94, 22, wood_fill(rng, WOOD_DARK))
    img.bevel(o, o + 4, 94, 22, 0.2)
    # Drawer fronts with small handles.
    for x0 in (o + 4, o + 50):
        img.rect(x0, o + 15, 40, 9, shade(WOOD_DARK, 0.05))
        img.bevel(x0, o + 15, 40, 9, -0.15)
        img.rect(x0 + 18, o + 19, 4, 1, hexc("f2c14e"))
    # The screen from above: thin, with a cool glint, on a stand.
    img.rect(o + 38, o + 7, 18, 4, hexc("3a3a44"))
    img.rect(o + 8, o, 78, 8, hexc("1d1d24"))
    img.rect(o + 9, o + 1, 76, 1, hexc("4a5a7a"))
    img.rect(o + 12, o + 2, 22, 1, hexc("8aa0c8"))
    img.rect(o + 9, o + 6, 76, 1, hexc("2a3a5a"))
    # A game console with a green light and a remote.
    img.rect(o + 62, o + 9, 16, 5, hexc("e8e8ee"))
    img.bevel(o + 62, o + 9, 16, 5, 0.15)
    img.set(o + 75, o + 11, hexc("4ad86a"))
    img.rect(o + 16, o + 9, 3, 6, hexc("2a2a30"))
    img.set(o + 17, o + 10, hexc("d94848"))
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
    img = framed(116, 40)
    o = 1
    top = hexc("d4d8dc")
    img.rect(o, o, 116, 40, speckle(rng, top, 0.06, 0.45))
    # Marble veins.
    for _ in range(4):
        x, y = rng.randint(o, o + 110), rng.randint(o, o + 36)
        for k in range(rng.randint(8, 18)):
            x += rng.choice((1, 1, 2))
            y += rng.choice((-1, 0, 1))
            img._shade(x, y, -0.1)
    img.bevel(o, o, 116, 40, 0.2)
    img.rect(o, o + 36, 116, 4, shade(top, -0.2))
    # Sink with a faucet, water drop and a glint.
    img.rect(o + 8, o + 7, 32, 24, hexc("aebcc6"))
    img.bevel(o + 8, o + 7, 32, 24, -0.25)
    img.rect(o + 11, o + 10, 26, 18, hexc("9fb0bc"))
    img.circle(o + 24, o + 20, 2, hexc("5a6a75"))
    img.rect(o + 22, o + 2, 4, 9, hexc("e8ecf0"))
    img.rect(o + 22, o + 2, 1, 9, hexc("ffffff"))
    img.set(o + 24, o + 13, hexc("8ac8f0"))
    img.rect(o + 14, o + 12, 6, 1, hexc("d4e0e8"))
    # Cutting board with carrot slices.
    board = hexc("c9a26a")
    img.rect(o + 46, o + 9, 20, 15, wood_fill(rng, board))
    img.bevel(o + 46, o + 9, 20, 15, 0.15)
    for cx, cy in ((51, 14), (55, 17), (59, 13)):
        img.circle(o + cx, o + cy, 2, hexc("e8822a"))
        img.set(o + cx, o + cy, hexc("f4b060"))
    # Hob: four rings, a pot with a lid on one.
    for (px, py) in ((80, 12), (100, 12), (80, 28), (100, 28)):
        img.circle(o + px, o + py, 7, hexc("2a2a30"))
        for i in range(14):
            a = i * math.tau / 14
            img.set(o + px + math.cos(a) * 5, o + py + math.sin(a) * 5, hexc("6a5a64"))
    img.circle(o + 100, o + 12, 8, hexc("b8bcc4"))
    img.round_shade(o + 100, o + 12, 8, 0.3)
    img.circle(o + 100, o + 12, 2, hexc("2a2a30"))
    img.rect(o + 107, o + 11, 5, 2, hexc("2a2a30"))
    img.outline()
    img.save("apt_counter.png")


def bed(fabric, n):
    rng = random.Random(12 + n)
    img = framed(96, 128)
    o = 1
    img.rect(o, o, 96, 128, wood_fill(rng, WOOD_DARK, False))
    img.bevel(o, o, 96, 128, 0.2)
    # Headboard.
    img.rect(o, o, 96, 8, wood_fill(rng, shade(WOOD_DARK, 0.08)))
    img.bevel(o, o, 96, 8, 0.22)
    sheet = hexc("f1ece2")
    img.rect(o + 4, o + 8, 88, 116, sheet)
    # Pillows with a crease and a soft dent.
    for px in (o + 8, o + 52):
        img.rect(px, o + 12, 36, 22, hexc("fbf8f2"))
        img.bevel(px, o + 12, 36, 22, -0.12)
        img.line(px + 4, o + 23, px + 31, o + 22, hexc("e6e0d4"))
        img.circle(px + 18, o + 22, 6, lambda x, y: shade(img.get(x, y), -0.05), 4)
    # The duvet: turned-down sheet, soft folds, a quilted pattern.
    img.rect(o + 4, o + 40, 88, 84, fabric_fill(rng, fabric, o + 40, 84, 0.03, 0.1))
    for y in range(o + 46, o + 124):
        wave = math.sin((y - o) * 0.18) * 0.06
        for x in range(o + 4, o + 92):
            if ((x - o) // 11 + (y - o) // 11) % 2 == 0:
                img.set(x, y, shade(img.get(x, y), wave - 0.04))
            else:
                img.set(x, y, shade(img.get(x, y), wave))
    img.rect(o + 4, o + 40, 88, 7, sheet)
    img.rect(o + 4, o + 46, 88, 1, shade(sheet, -0.2))
    img.bevel(o + 4, o + 40, 88, 84, 0.12)
    # A book left open on the blanket.
    img.poly([(o + 58, o + 78), (o + 72, o + 74), (o + 76, o + 88), (o + 62, o + 92)], hexc("f4efe4"))
    img.line(o + 67, o + 76, o + 69, o + 90, hexc("9a8a7a"))
    img.outline()
    img.save("apt_bed_%d.png" % n)


def nightstand():
    rng = random.Random(13)
    img = framed(30, 30)
    o = 1
    img.rect(o, o, 30, 30, wood_fill(rng, WOOD))
    img.bevel(o, o, 30, 30, 0.22)
    img.rect(o, o + 25, 30, 5, shade(WOOD, -0.2))
    img.rect(o + 12, o + 27, 6, 1, hexc("f2c14e"))
    # A lamp with a pleated shade, a little book and glasses.
    img.circle(o + 11, o + 11, 8, hexc("f3e3b8"))
    for i in range(10):
        a = i * math.tau / 10
        img.line(o + 11, o + 11, o + 11 + math.cos(a) * 8, o + 11 + math.sin(a) * 8, hexc("e6d2a4"))
    img.round_shade(o + 11, o + 11, 8, 0.15)
    img.circle(o + 11, o + 11, 3, hexc("fff6d8"))
    img.rect(o + 20, o + 14, 8, 10, hexc("5b4a8a"))
    img.rect(o + 20, o + 22, 8, 1, hexc("efe6d0"))
    img.circle(o + 22, o + 7, 2, hexc("3a3a44"))
    img.circle(o + 27, o + 7, 2, hexc("3a3a44"))
    img.set(o + 22, o + 7, hexc("bfe0ff"))
    img.set(o + 27, o + 7, hexc("bfe0ff"))
    img.outline()
    img.save("apt_nightstand.png")


def wardrobe():
    rng = random.Random(14)
    img = framed(112, 34)
    o = 1
    img.rect(o, o, 112, 34, wood_fill(rng, WOOD_DARK))
    img.bevel(o, o, 112, 34, 0.22)
    # The top seen from above: a crown moulding and things stored up there.
    img.rect(o + 2, o + 2, 108, 2, shade(WOOD_DARK, 0.2))
    for x0 in (o + 4, o + 58):
        img.rect(x0, o + 6, 50, 24, wood_fill(rng, shade(WOOD_DARK, 0.08)))
        img.bevel(x0, o + 6, 50, 24, -0.15)
        img.rect(x0 + 4, o + 9, 42, 18, wood_fill(rng, shade(WOOD_DARK, 0.03)))
        img.bevel(x0 + 4, o + 9, 42, 18, 0.1)
    img.rect(o + 56, o + 2, 1, 32, OUTLINE)
    img.rect(o + 51, o + 15, 2, 6, hexc("f2c14e"))
    img.rect(o + 60, o + 15, 2, 6, hexc("f2c14e"))
    img.set(o + 51, o + 15, hexc("fff0b0"))
    img.set(o + 60, o + 15, hexc("fff0b0"))
    # A hat box and a folded jumper on top.
    img.circle(o + 22, o + 17, 8, hexc("d98aa0"))
    img.round_shade(o + 22, o + 17, 8, 0.25)
    img.rect(o + 14, o + 16, 16, 1, hexc("f4efe4"))
    img.rect(o + 78, o + 12, 20, 12, hexc(FABRICS[1]))
    img.rect(o + 78, o + 15, 20, 1, shade(hexc(FABRICS[1]), 0.3))
    img.bevel(o + 78, o + 12, 20, 12, 0.15)
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


# --- things left on the floor --------------------------------------------------
# Small, drawn at 1 px = 1 world unit like the rest; the ones made of fabric
# come per rug colour (apt_item_<kind>_<i>.png).

def item_sock(fabric, n):
    img = framed(14, 18)
    o = 1
    stripe = shade(fabric, 0.45)
    # Leg (top) bending into the foot (bottom right).
    img.rect(o + 1, o, 7, 11, fabric)
    img.poly([(o + 1, o + 10), (o + 8, o + 10), (o + 13, o + 13), (o + 13, o + 17), (o + 5, o + 17), (o + 1, o + 14)], fabric)
    for y in (o + 1, o + 4, o + 7):
        img.rect(o + 1, y, 7, 1, stripe)
    img.rect(o + 1, o, 7, 1, shade(fabric, 0.6))
    img.circle(o + 11, o + 15, 2, shade(fabric, -0.2))
    img.bevel(o + 1, o, 7, 11, 0.15)
    img.outline()
    img.save("apt_item_sock_%d.png" % n)


def item_yarn(fabric, n):
    img = framed(22, 14)
    o = 1
    c = (o + 6, o + 6)
    img.circle(c[0], c[1], 6, fabric)
    img.round_shade(c[0], c[1], 6, 0.3)
    for i in range(4):
        a = 0.6 + i * 0.7
        img.line(c[0] - math.cos(a) * 5, c[1] - math.sin(a) * 5, c[0] + math.cos(a) * 5, c[1] + math.sin(a) * 5, shade(fabric, 0.3))
    img.outline()
    # A loose thread wandering off to the right (no outline).
    for x in range(o + 12, o + 22):
        img.set(x, o + 7 + round(math.sin((x - o) * 0.9) * 2), shade(fabric, 0.15))
    img.save("apt_item_yarn_%d.png" % n)


def item_paper_ball():
    rng = random.Random(21)
    img = framed(10, 10)
    o = 1
    img.circle(o + 5, o + 5, 5, hexc("ecebe4"))
    for _ in range(9):
        x, y = o + rng.randint(1, 8), o + rng.randint(1, 8)
        img._shade(x, y, -0.18)
        img._shade(x + 1, y, -0.1)
    img.round_shade(o + 5, o + 5, 5, 0.25)
    img.outline()
    img.save("apt_item_paper_ball.png")


def item_toy_mouse():
    img = framed(16, 9)
    o = 1
    body = hexc("9a9aa2")
    img.circle(o + 7, o + 4.5, 5.5, body, 3.5)
    img.round_shade(o + 7, o + 4.5, 5, 0.3)
    img.circle(o + 4, o + 1.5, 1.6, hexc("e0a8b0"))
    img.circle(o + 4, o + 7.5, 1.6, hexc("e0a8b0"))
    img.set(o + 2, o + 4, OUTLINE)
    img.set(o + 1, o + 4, hexc("e07080"))
    img.outline()
    for x in range(o + 12, o + 16):
        img.set(x, o + 4 + (1 if x % 3 == 0 else 0), hexc("d9a0a8"))
    img.save("apt_item_toy_mouse.png")


def item_slipper(fabric, n):
    img = framed(12, 22)
    o = 1
    sole = hexc("e8dcc0")
    img.circle(o + 6, o + 11, 6, sole, 11)
    img.circle(o + 6, o + 8, 5, fabric, 6)
    img.round_shade(o + 6, o + 8, 5, 0.3)
    img.circle(o + 6, o + 4, 2, hexc("f4f1ea"))
    img.outline()
    img.save("apt_item_slipper_%d.png" % n)


def item_newspaper():
    rng = random.Random(22)
    img = framed(24, 17)
    o = 1
    paper = hexc("e4e0d4")
    img.poly([(o, o + 2), (o + 22, o), (o + 24, o + 15), (o + 2, o + 17)], paper)
    img.rect(o + 3, o + 3, 8, 6, hexc("9aa0a6"))
    for y in range(o + 4, o + 15, 2):
        for x in range(o + 13 if y < o + 10 else o + 3, o + 21):
            if rng.random() < 0.8:
                img.set(x, y, hexc("8a8a90"))
    img.line(o + 12, o + 1, o + 13, o + 16, shade(paper, -0.15))
    img.outline()
    img.save("apt_item_newspaper.png")


def item_kibble():
    rng = random.Random(23)
    img = Img(14, 10)
    for _ in range(7):
        x, y = rng.randint(1, 11), rng.randint(1, 7)
        img.rect(x, y, 2, 2, hexc("9a6a3a"))
        img.set(x, y, hexc("c08a4a"))
        img.set(x + 1, y + 1, hexc("6b4630"))
    img.save("apt_item_kibble.png")


def item_hair():
    rng = random.Random(24)
    img = Img(12, 9)
    for _ in range(14):
        x, y = rng.uniform(2, 9), rng.uniform(2, 6)
        a = rng.uniform(0, math.pi)
        img.line(x, y, x + math.cos(a) * 3, y + math.sin(a) * 2, (232, 224, 210, 200))
    img.save("apt_item_hair.png")


def item_book(fabric, n):
    img = framed(16, 12)
    o = 1
    img.rect(o, o, 16, 12, fabric)
    img.rect(o + 1, o + 9, 15, 2, hexc("efe6d0"))
    img.rect(o, o, 2, 12, shade(fabric, -0.25))
    img.rect(o + 6, o + 3, 6, 1, shade(fabric, 0.45))
    img.bevel(o, o, 16, 12, 0.18)
    img.outline()
    img.save("apt_item_book_%d.png" % n)


def doormat(fabric, n):
    rng = random.Random(25 + n)
    img = framed(42, 26)
    o = 1
    coir = hexc("a8824a")
    img.rect(o, o, 42, 26, shade(fabric, -0.1))
    img.rect(o + 3, o + 3, 36, 20, speckle(rng, coir, 0.12, 0.7))
    for x in range(o + 3, o + 39, 3):
        for y in range(o + 3, o + 23):
            img._shade(x, y, -0.08)
    # A paw print in the middle.
    img.circle(o + 21, o + 15, 3.5, shade(fabric, 0.1))
    for dx, dy in ((-4, -4), (0, -6), (4, -4)):
        img.circle(o + 21 + dx, o + 14 + dy, 1.6, shade(fabric, 0.1))
    img.bevel(o, o, 42, 26, 0.15)
    img.outline()
    img.save("apt_doormat_%d.png" % n)


def main():
    os.makedirs(OUT, exist_ok=True)
    for n, hexcode in enumerate(FABRICS):
        fabric = hexc(hexcode)
        item_sock(fabric, n)
        item_yarn(fabric, n)
        item_slipper(fabric, n)
        item_book(fabric, n)
        doormat(fabric, n)
    item_paper_ball()
    item_toy_mouse()
    item_newspaper()
    item_kibble()
    item_hair()
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
