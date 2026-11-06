"""Pixel art for the maps after the basement (Garden, Rooftop, Supermarket,
Harbor, Factory, Park, Cemetery, Station, Island), in the style of the
apartment (tools/gen_apartment.py): one pixel = one world unit, light from
the top left, a dark outline.

    python tools/gen_outdoor.py

Writes assets/sprites/apt_*.png (the floor loader's prefix): floors
apt_floor_<zone>.png, furniture apt_<kind>.png (fabric ones apt_<kind>_<n>),
floor clutter apt_item_<kind>.png. Afterwards run the Godot import.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_apartment import FABRICS, Img, WOOD, WOOD_DARK, framed, speckle, wood_fill  # noqa: E402
from gen_sprites import OUT, hexc, shade  # noqa: E402

METAL = hexc("8a9096")
STEEL_DARK = hexc("4a4e54")
STONE = hexc("a8a49c")
GRASS = hexc("5e9e4a")
LEAF_GREENS = [hexc("3f7a34"), hexc("4f8f3e"), hexc("5ea84a"), hexc("6fb85a")]


class Tile(Img):
    """A floor texture: drawing wraps around, so it tiles without seams."""

    def set(self, x, y, c):
        self.px[(int(y) % self.h) * self.w + int(x) % self.w] = c

    def get(self, x, y):
        return self.px[(int(y) % self.h) * self.w + int(x) % self.w]


def blob(img, rng, cx, cy, r, k):
    """A soft irregular patch, lighter (k > 0) or darker."""
    for yy in range(int(cy - r), int(cy + r) + 1):
        for xx in range(int(cx - r), int(cx + r) + 1):
            d = ((xx - cx) ** 2 + (yy - cy) ** 2) ** 0.5 / r
            if d < 1.0 and rng.random() < 1.1 - d:
                img.set(xx, yy, shade(img.get(xx, yy), k))


# --- ground --------------------------------------------------------------------

def grass(name, base, seed, flowers=(), size=192, dry=0.0):
    rng = random.Random(seed)
    img = Tile(size, size)
    img.rect(0, 0, size, size, speckle(rng, base, 0.06, 0.5))
    for _ in range(10):
        blob(img, rng, rng.randrange(size), rng.randrange(size), rng.randint(10, 26), rng.choice((-0.07, 0.06)))
    if dry:
        for _ in range(6):
            blob(img, rng, rng.randrange(size), rng.randrange(size), rng.randint(6, 14), dry)
    # Blades: short strokes, light at the tip.
    for _ in range(size * size // 22):
        x, y = rng.randrange(size), rng.randrange(size)
        k = rng.choice((-0.18, -0.12, 0.1, 0.16))
        img.set(x, y, shade(img.get(x, y), k))
        img.set(x, y - 1, shade(img.get(x, y - 1), k * 0.6))
        if k > 0:
            img.set(x, y - 2, shade(img.get(x, y - 2), k * 0.4))
    for colour, n in flowers:
        for _ in range(n):
            x, y = rng.randrange(size), rng.randrange(size)
            img.set(x, y, colour)
            img.set(x + 1, y, shade(colour, -0.2))
            img.set(x, y + 1, shade(colour, -0.3))
    img.save("apt_floor_%s.png" % name)


def gravel(name, base, seed, stones=True, size=204):
    rng = random.Random(seed)
    img = Tile(size, size)
    img.rect(0, 0, size, size, speckle(rng, base, 0.08, 0.7))
    for _ in range(size * size // 9):
        x, y = rng.randrange(size), rng.randrange(size)
        k = rng.uniform(-0.25, 0.2)
        img.set(x, y, shade(base, k))
        if rng.random() < 0.4:
            img.set(x + 1, y, shade(base, k - 0.08))
            img.set(x, y + 1, shade(base, k - 0.15))
    if stones:
        # Irregular flagstones, roughly in rows, with gravel in the gaps.
        slab = hexc("c8c0ae")
        for gy in range(0, size, 34):
            gx = rng.randint(0, 20)
            while gx < size:
                rx, ry = rng.uniform(9, 16), rng.uniform(8, 13)
                cx, cy = gx + rx, gy + 17 + rng.uniform(-4, 4)
                gx += rx * 2 + rng.randint(4, 12)
                if rng.random() < 0.4:
                    continue
                n = rng.randint(6, 8)
                pts = [(cx + math.cos(i * math.tau / n) * rx * rng.uniform(0.8, 1.05),
                        cy + math.sin(i * math.tau / n) * ry * rng.uniform(0.8, 1.05)) for i in range(n)]
                tone = shade(slab, rng.uniform(-0.16, 0.0))
                shadow = [(x + 1, y + 1) for (x, y) in pts]
                img.poly(shadow, shade(base, -0.4))
                img.poly(pts, tone)
                for yy in range(int(cy - ry - 1), int(cy + ry + 2)):
                    for xx in range(int(cx - rx - 1), int(cx + rx + 2)):
                        if img.get(xx, yy) == tone:
                            k = -((xx - cx) / rx + (yy - cy) / ry) * 0.08 + (rng.uniform(-0.04, 0.04) if rng.random() < 0.4 else 0)
                            img.set(xx, yy, shade(tone, k))
    img.save("apt_floor_%s.png" % name)


def soil_rows():
    """Flower bed: dark soil with tilled rows and tufts of grass at the edges."""
    rng = random.Random(201)
    size = 128
    img = Tile(size, size)
    soil = hexc("5a3e2a")
    img.rect(0, 0, size, size, speckle(rng, soil, 0.08, 0.6))
    for y in range(0, size, 16):
        for x in range(size):
            img.set(x, y + 6, shade(soil, 0.14 + rng.uniform(-0.04, 0.04)))
            img.set(x, y + 7, shade(soil, 0.08))
            img.set(x, y + 12, shade(soil, -0.25))
    for _ in range(300):
        x, y = rng.randrange(size), rng.randrange(size)
        img.set(x, y, shade(soil, rng.choice((-0.3, 0.2))))
    for _ in range(40):
        x, y = rng.randrange(size), rng.randrange(size)
        for k in range(3):
            img.set(x + k - 1, y - (1 if k == 1 else 0), LEAF_GREENS[rng.randrange(4)])
    img.save("apt_floor_flowerbed.png")


def sand(name, base, seed, ripples=True, shells=0):
    rng = random.Random(seed)
    size = 160
    img = Tile(size, size)
    img.rect(0, 0, size, size, speckle(rng, base, 0.05, 0.6))
    for _ in range(8):
        blob(img, rng, rng.randrange(size), rng.randrange(size), rng.randint(12, 26), rng.choice((-0.05, 0.05)))
    if ripples:
        for y in range(0, size, 9):
            phase = rng.uniform(0, 6)
            for x in range(size):
                yy = y + round(math.sin(x * 0.08 + phase) * 2)
                img.set(x, yy, shade(img.get(x, yy), 0.1))
                img.set(x, yy + 1, shade(img.get(x, yy + 1), -0.08))
    for _ in range(size * 3):
        x, y = rng.randrange(size), rng.randrange(size)
        img.set(x, y, shade(base, rng.choice((-0.2, 0.15))))
    for _ in range(shells):
        x, y = rng.randrange(size), rng.randrange(size)
        img.set(x, y, hexc("f4ecdc"))
        img.set(x + 1, y, hexc("e8c8b0"))
    img.save("apt_floor_%s.png" % name)


def planks_floor(name, base, seed, w=96, h=16, rows=4, gap=0, nails=True):
    """Boards with seams, nail heads and grain; `gap` dark rows between rows."""
    rng = random.Random(seed)
    W, H = w * 2, (h + gap) * rows
    img = Tile(W, H)
    offsets = [0, w // 2, w // 4, w * 3 // 4]
    for row in range(rows):
        y0 = row * (h + gap)
        for k in range(-1, 3):
            x0 = offsets[row % 4] + k * w
            tone = shade(base, rng.uniform(-0.1, 0.05))
            grain = [rng.uniform(-0.05, 0.05) for _ in range(h)]
            for y in range(y0, y0 + h):
                for x in range(x0, x0 + w):
                    c = shade(tone, grain[y - y0] + (0.05 if (x * 5 + y * 11) % 29 == 0 else 0.0))
                    img.set(x, y, c)
            for y in range(y0, y0 + h):
                img.set(x0, y, shade(tone, -0.45))
                img.set(x0 + 1, y, shade(tone, 0.1))
            for x in range(x0, x0 + w):
                img.set(x, y0, shade(tone, 0.14))
                img.set(x, y0 + h - 1, shade(tone, -0.4))
            if nails:
                for nx in (x0 + 4, x0 + w - 5):
                    img.set(nx, y0 + 3, hexc("3a3a3a"))
                    img.set(nx, y0 + h - 4, hexc("3a3a3a"))
            if rng.random() < 0.5:
                kx, ky = x0 + rng.randint(12, w - 14), y0 + h // 2
                for dx in range(-2, 3):
                    img.set(kx + dx, ky, shade(tone, -0.22))
            for gy in range(gap):
                for x in range(x0, x0 + w):
                    img.set(x, y0 + h + gy, hexc("1e1a1c") if gy else hexc("2e2622"))
    img.save("apt_floor_%s.png" % name)


def tiles_floor(name, a, b, seed, t=32, grout="8f9a9e", n=4, glint=True):
    rng = random.Random(seed)
    img = Tile(t * n, t * n)
    for ty in range(n):
        for tx in range(n):
            base = a if (tx + ty) % 2 == 0 else b
            base = shade(base, rng.uniform(-0.03, 0.03))
            x0, y0 = tx * t, ty * t
            img.rect(x0, y0, t, t, speckle(rng, base, 0.035, 0.25))
            img.bevel(x0 + 1, y0 + 1, t - 2, t - 2, 0.1)
            for i in range(t):
                img.set(x0 + i, y0, hexc(grout))
                img.set(x0, y0 + i, hexc(grout))
            if glint:
                for i in range(4):
                    img.set(x0 + 4 + i, y0 + 4, shade(base, 0.25))
    return img


def floor_tar():
    rng = random.Random(211)
    size = 160
    img = Tile(size, size)
    tar = hexc("3c3c44")
    img.rect(0, 0, size, size, speckle(rng, tar, 0.1, 0.6))
    # Roofing felt in wide strips with a lapped seam, then roof gravel.
    for y in range(0, size, 40):
        for x in range(size):
            img.set(x, y, shade(tar, 0.22))
            img.set(x, y + 1, shade(tar, -0.3))
    for _ in range(size * 6):
        x, y = rng.randrange(size), rng.randrange(size)
        img.set(x, y, shade(hexc("8a8480"), rng.uniform(-0.25, 0.15)))
    for _ in range(4):
        blob(img, rng, rng.randrange(size), rng.randrange(size), rng.randint(8, 16), -0.1)
    img.save("apt_floor_tar.png")


def floor_roof_tiles():
    rng = random.Random(212)
    W, H = 128, 96
    img = Tile(W, H)
    clay = hexc("a8503a")
    for row in range(H // 12):
        y0 = row * 12
        off = 8 if row % 2 else 0
        for k in range(W // 16):
            x0 = off + k * 16
            tone = shade(clay, rng.uniform(-0.1, 0.06))
            for y in range(12):
                for x in range(16):
                    # Rounded bottom edge of each tile, lit on the left.
                    edge = abs(x - 7.5) / 8.0
                    k2 = 0.12 - x * 0.014 - (0.25 if y >= 10 - edge * 3 else 0.0)
                    img.set(x0 + x, y0 + y, shade(tone, k2 + rng.uniform(-0.03, 0.03)))
            for y in range(12):
                img.set(x0, y0 + y, shade(tone, -0.4))
            if rng.random() < 0.12:
                for _ in range(6):
                    img.set(x0 + rng.randint(2, 13), y0 + rng.randint(2, 8), shade(hexc("6a8a4a"), rng.uniform(-0.1, 0.1)))
    img.save("apt_floor_tiles.png".replace("tiles", "roof_tiles"))


def floor_store(name, a, b, seed, grout="b8bcc0"):
    img = tiles_floor(name, a, b, seed, t=40, grout=grout, n=4)
    rng = random.Random(seed + 1)
    # Scuffs from cart wheels.
    for _ in range(5):
        x, y = rng.randrange(160), rng.randrange(160)
        for i in range(rng.randint(8, 18)):
            img.set(x + i, y + (i // 6), shade(img.get(x + i, y + (i // 6)), -0.12))
    img.save("apt_floor_%s.png" % name)


def floor_concrete_plain(name, base, seed, slab=80, stripes=False, plates=False):
    rng = random.Random(seed)
    size = 160
    img = Tile(size, size)
    img.rect(0, 0, size, size, speckle(rng, base, 0.07, 0.6))
    for _ in range(6):
        blob(img, rng, rng.randrange(size), rng.randrange(size), rng.randint(10, 22), rng.choice((-0.06, 0.05)))
    for i in range(size):
        for s in range(0, size, slab):
            img.set(i, s, shade(base, -0.25))
            img.set(s, i, shade(base, -0.25))
            img.set(i, s + 1, shade(base, 0.08))
    if plates:
        # Steel tread plates with diamond studs.
        for py in range(0, size, slab):
            for px in range(0, size, slab):
                if (px + py) // slab % 2:
                    continue
                img.rect(px + 4, py + 4, slab - 8, slab - 8, hexc("7a8088"))
                img.bevel(px + 4, py + 4, slab - 8, slab - 8, 0.2)
                for y in range(py + 8, py + slab - 8, 6):
                    for x in range(px + 8 + (3 if (y // 6) % 2 else 0), px + slab - 8, 6):
                        img.set(x, y, hexc("a0a6ae"))
                        img.set(x + 1, y + 1, hexc("5a5e64"))
                for (rx, ry) in ((6, 6), (slab - 7, 6), (6, slab - 7), (slab - 7, slab - 7)):
                    img.set(px + rx, py + ry, hexc("c8ccd0"))
    if stripes:
        # Yellow and black hazard band along the top.
        for x in range(size):
            for y in range(6):
                img.set(x, y + 20, hexc("e8c02a") if ((x + y) // 6) % 2 == 0 else hexc("2a2a2a"))
    for _ in range(3):
        x, y = rng.randrange(size), rng.randrange(size)
        for _ in range(rng.randint(8, 18)):
            img.set(x, y, shade(base, -0.3))
            x += rng.choice((-1, 0, 1, 1))
            y += rng.choice((0, 1, 1))
    for _ in range(2):
        cx, cy = rng.randrange(size), rng.randrange(size)
        for k in range(3):
            blob(img, rng, cx, cy, 10 - k * 3, -0.1)
    img.save("apt_floor_%s.png" % name)


def floor_tracks():
    """Ballast, sleepers and two rails, in rows 128 apart (as the vector
    version: rails at 30 and 58, sleepers 20..67, every 24 px)."""
    rng = random.Random(231)
    W, H = 96, 128
    img = Tile(W, H)
    ballast = hexc("7a7268")
    img.rect(0, 0, W, H, speckle(rng, ballast, 0.1, 0.7))
    for _ in range(W * H // 5):
        x, y = rng.randrange(W), rng.randrange(H)
        k = rng.uniform(-0.25, 0.2)
        img.set(x, y, shade(ballast, k))
        img.set(x + 1, y + 1, shade(ballast, k - 0.15))
    for x0 in range(0, W, 24):
        tone = shade(hexc("5a3a24"), rng.uniform(-0.1, 0.05))
        img.rect(x0, 20, 10, 48, wood_fill(rng, tone, horizontal=False))
        img.bevel(x0, 20, 10, 48, 0.2)
        for y in range(20, 68):
            img.set(x0 + 10, y, shade(ballast, -0.35))
    for ry in (30, 58):
        for x in range(W):
            img.set(x, ry - 1, hexc("3a3a40"))
            img.set(x, ry, hexc("e0e0e8"))
            img.set(x, ry + 1, hexc("a8a8b0"))
            img.set(x, ry + 2, hexc("6a6a72"))
            img.set(x, ry + 3, hexc("4a4a52"))
            img.set(x, ry + 4, shade(ballast, -0.4))
        for x0 in range(0, W, 24):
            for dx in (2, 7):
                img.set(x0 + dx, ry + 2, hexc("2a2a30"))
    img.save("apt_floor_tracks.png")


def floor_platform():
    rng = random.Random(232)
    img = Tile(128, 128)
    base = hexc("a8a49c")
    img.rect(0, 0, 128, 128, speckle(rng, base, 0.05, 0.5))
    for i in range(128):
        for s in (0, 64):
            img.set(i, s, shade(base, -0.2))
            img.set(s, i, shade(base, -0.2))
            img.set(i, s + 1, shade(base, 0.1))
            img.set(s + 1, i, shade(base, 0.06))
    for _ in range(8):
        # Old chewing gum.
        x, y = rng.randrange(128), rng.randrange(128)
        img.set(x, y, hexc("5a5654"))
        img.set(x + 1, y, hexc("6a6664"))
    img.save("apt_floor_platform.png")


def floor_rocks():
    rng = random.Random(241)
    size = 160
    img = Tile(size, size)
    base = hexc("8a8480")
    img.rect(0, 0, size, size, speckle(rng, hexc("c9b48a"), 0.06, 0.6))
    for _ in range(22):
        cx, cy, r = rng.randrange(size), rng.randrange(size), rng.randint(6, 15)
        ry = r * 0.75
        tone = shade(base, rng.uniform(-0.12, 0.08))
        for yy in range(int(cy - ry) - 2, int(cy + ry) + 3):
            for xx in range(int(cx - r) - 2, int(cx + r) + 3):
                dx, dy = (xx - cx) / r, (yy - cy) / ry
                d = dx * dx + dy * dy
                if d <= 1.0:
                    k = -(dx + dy) * 0.22 + (0.18 if d < 0.25 and dx + dy < -0.3 else 0) + rng.uniform(-0.03, 0.03)
                    img.set(xx, yy, shade(tone, k))
                elif d <= 1.35 and dx + dy > 0:
                    img.set(xx, yy, shade(img.get(xx, yy), -0.25))
    for _ in range(40):
        x, y = rng.randrange(size), rng.randrange(size)
        img.set(x, y, hexc("4f8f3e"))
    img.save("apt_floor_rocks.png")


def floor_dock():
    """Harbour quay: big concrete slabs with a row of iron mooring rings."""
    rng = random.Random(251)
    size = 160
    img = Tile(size, size)
    base = hexc("8e8a84")
    img.rect(0, 0, size, size, speckle(rng, base, 0.07, 0.6))
    for i in range(size):
        for s in (0, 80):
            img.set(i, s, shade(base, -0.3))
            img.set(s, i, shade(base, -0.3))
            img.set(i, s + 1, shade(base, 0.1))
    for _ in range(3):
        blob(img, rng, rng.randrange(size), rng.randrange(size), rng.randint(14, 24), -0.04)
    # A few salt stains.
    for _ in range(2):
        blob(img, rng, rng.randrange(size), rng.randrange(size), rng.randint(6, 10), 0.06)
    for _ in range(40):
        x, y = rng.randrange(size), rng.randrange(size)
        img.set(x, y, hexc("4f6a5a"))
    img.save("apt_floor_dock.png")


def floors():
    grass("lawn", GRASS, 200, flowers=((hexc("f4f1ea"), 30), (hexc("f2d14e"), 18)))
    soil_rows()
    gravel("path", hexc("b8ab92"), 202)
    grass("meadow", hexc("6aa850"), 203, flowers=((hexc("f4f1ea"), 40), (hexc("e88aa8"), 20), (hexc("f2d14e"), 20), (hexc("9a8ad8"), 12)))
    gravel("park_path", hexc("c9b88e"), 204)
    grass("grave_lawn", hexc("4a7a3e"), 205, dry=-0.1)
    grass("graves", hexc("44703a"), 206, dry=-0.12)
    gravel("gravel", hexc("9a948a"), 207, stones=False)
    grass("palm_grove", hexc("78a848"), 208, dry=0.1)
    floor_tar()
    floor_roof_tiles()
    planks_floor("deck", hexc("9a7048"), 213, w=80, h=12, rows=4, gap=2)
    floor_store("aisle", hexc("eceae4"), hexc("dedad2"), 221)
    floor_store("produce", hexc("d8c8a8"), hexc("c8b494"), 222, grout="a89878")
    floor_store("freezer", hexc("e4eef4"), hexc("c8dce8"), 223, grout="9ab0c0")
    sand("beach", hexc("e2cc94"), 251, shells=30)
    floor_dock()
    planks_floor("pier", hexc("8a6a4a"), 252, w=64, h=14, rows=4, gap=3)
    floor_concrete_plain("storage_bay", hexc("8a8680"), 261, slab=80, stripes=True)
    floor_concrete_plain("assembly", hexc("7a7e84"), 262, slab=80, plates=True)
    floor_concrete_plain("conveyor", hexc("6e7076"), 263, slab=40)
    img = tiles_floor("hall", hexc("e2dccb"), hexc("9a8e7a"), 271, t=32)
    img.save("apt_floor_hall.png")
    floor_platform()
    floor_tracks()
    sand("sand", hexc("ecd8a0"), 281, shells=40)
    floor_rocks()


# --- shared pieces --------------------------------------------------------------

def canopy(img, rng, cx, cy, r, greens=LEAF_GREENS, lumps=9):
    """A round crown of leaves seen from above, lit at the top left."""
    for i in range(lumps):
        a = math.tau * i / lumps + rng.uniform(-0.2, 0.2)
        d = r * 0.55
        img.circle(cx + math.cos(a) * d, cy + math.sin(a) * d, r * 0.5, greens[1])
    img.circle(cx, cy, r * 0.62, greens[1])
    for yy in range(int(cy - r - 2), int(cy + r + 3)):
        for xx in range(int(cx - r - 2), int(cx + r + 3)):
            c = img.get(xx, yy)
            if not c[3]:
                continue
            dx, dy = (xx - cx) / r, (yy - cy) / r
            light = -(dx + dy) * 0.5
            n = rng.random()
            if n < 0.18:
                c = greens[0]
            elif n < 0.3:
                c = greens[2]
            elif light > 0.3 and n < 0.55:
                c = greens[3]
            img.set(xx, yy, shade(c, light * 0.18))
    # Leaf clusters: small light arcs.
    for _ in range(int(r * 1.6)):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0, r * 0.9)
        x, y = cx + math.cos(a) * d, cy + math.sin(a) * d
        if img.get(int(x), int(y))[3]:
            img.set(x, y, shade(greens[3], 0.15))
            img.set(x + 1, y + 1, greens[0])


def lamp_head(name, body, glass="fff3c8", size=18, square=False):
    img = framed(size, size)
    c = size / 2 + 1
    if square:
        img.rect(2, 2, size - 2, size - 2, body)
        img.bevel(2, 2, size - 2, size - 2, 0.25)
    else:
        img.circle(c, c, size / 2 - 0.5, body)
        img.round_shade(c, c, size / 2 - 0.5, 0.3)
    img.circle(c, c, size / 2 - 4, hexc(glass))
    img.circle(c - 1, c - 1, size / 2 - 6.5, hexc("ffffff"))
    img.outline()
    img.save("apt_%s.png" % name)


def box_crate(img, rng, x, y, w, h, tone):
    img.rect(x, y, w, h, wood_fill(rng, tone))
    img.bevel(x, y, w, h, 0.22)
    for i in range(w):
        img.set(x + i, y + 2, shade(tone, -0.2))
        img.set(x + i, y + h - 3, shade(tone, -0.2))
    img.line(x + 2, y + 3, x + w - 3, y + h - 4, shade(tone, -0.3))


# --- garden --------------------------------------------------------------------

def tree():
    rng = random.Random(301)
    img = framed(86, 86)
    canopy(img, rng, 44, 44, 40)
    img.outline()
    img.save("apt_tree.png")


TREE_SIZES = (30, 42, 56)


def terrain_trees():
    """The big trees and bushes of the tree terrain (terrain.gd picks the
    nearest size and tint): apt_terrain_tree_<R>_<t>, apt_terrain_bush_<R>_<t>."""
    tints = [
        [hexc("1f4a24"), hexc("2f6b34"), hexc("3a7a3c"), hexc("5a9a4a")],
        [hexc("2a5a22"), hexc("3f7d2c"), hexc("4f8f34"), hexc("78b04a")],
    ]
    bush_tints = [
        [hexc("3a6a2a"), hexc("4f8a3a"), hexc("5e9a44"), hexc("7ab858")],
        [hexc("4a6a1f"), hexc("6b9a2f"), hexc("7aa83a"), hexc("98c45a")],
    ]
    for R in TREE_SIZES:
        for t, greens in enumerate(tints):
            rng = random.Random(R * 10 + t)
            img = framed(R * 2 + 6, R * 2 + 6)
            c = R + 4
            # A darker rim under the crown, then the crown itself.
            img.circle(c, c, R, greens[0])
            canopy(img, rng, c, c, R - 3, greens, lumps=10 + R // 8)
            img.outline()
            img.save("apt_terrain_tree_%d_%d.png" % (R, t))
        for t, greens in enumerate(bush_tints):
            rng = random.Random(R * 20 + t)
            img = framed(R * 2 + 6, R * 2 + 6)
            c = R + 4
            for i in range(5):
                a = math.tau * i / 5 + t * 3.0
                img.circle(c + math.cos(a) * R * 0.42, c + math.sin(a) * R * 0.42, R * 0.58, greens[1])
            canopy(img, rng, c, c, R * 0.75, greens, lumps=6)
            for _ in range(3 + R // 10):
                a, d = rng.uniform(0, math.tau), rng.uniform(0, R * 0.8)
                x, y = c + math.cos(a) * d, c + math.sin(a) * d
                col = hexc("e85a7a") if t else hexc("f2e15c")
                img.circle(x, y, 2.2, col)
                img.set(x - 1, y - 1, shade(col, 0.4))
            img.outline()
            img.save("apt_terrain_bush_%d_%d.png" % (R, t))


def bush():
    rng = random.Random(302)
    img = framed(48, 40)
    for (x, y, r) in ((15, 22, 13), (33, 23, 13), (25, 13, 12)):
        img.circle(x, y, r, LEAF_GREENS[1])
    for yy in range(42):
        for xx in range(50):
            c = img.get(xx, yy)
            if c[3]:
                k = -((xx - 20) + (yy - 15)) / 60.0
                n = rng.random()
                img.set(xx, yy, shade(LEAF_GREENS[0] if n < 0.2 else LEAF_GREENS[3] if n > 0.85 else c, k * 0.4))
    for _ in range(5):
        img.set(rng.randint(8, 40), rng.randint(6, 32), hexc("d9534f"))
    img.outline()
    img.save("apt_bush.png")


def bench():
    rng = random.Random(303)
    img = framed(82, 26)
    o = 1
    for i in range(5):
        y = o + i * 5
        img.rect(o + 2, y, 78, 4, wood_fill(rng, shade(WOOD, 0.08)))
        img.bevel(o + 2, y, 78, 4, 0.25)
    for x in (o, o + 76):
        img.rect(x, o, 5, 25, hexc("3a3a40"))
        img.bevel(x, o, 5, 25, 0.25)
    img.outline()
    img.save("apt_bench.png")


def birdbath():
    img = framed(36, 36)
    c = 18.5
    img.circle(c, c, 17, STONE)
    img.round_shade(c, c, 17, 0.3)
    img.circle(c, c, 12.5, shade(STONE, -0.2))
    img.circle(c, c, 11.5, hexc("6fb0e0"))
    img.circle(c - 3, c - 3, 5, hexc("8fc8f0"))
    img.set(c - 5, c - 5, hexc("ffffff"))
    img.set(c + 4, c + 3, hexc("4f90c0"))
    img.outline()
    img.save("apt_birdbath.png")


def wheelbarrow():
    rng = random.Random(305)
    img = framed(58, 32)
    o = 1
    img.line(o, o + 6, o + 20, o + 8, STEEL_DARK)
    img.line(o, o + 24, o + 20, o + 22, STEEL_DARK)
    img.rect(o + 16, o + 2, 34, 28, hexc("4a8ac4"))
    img.bevel(o + 16, o + 2, 34, 28, 0.25)
    img.rect(o + 20, o + 6, 26, 20, speckle(rng, hexc("6b4a32"), 0.12, 0.7))
    for _ in range(4):
        img.circle(o + rng.randint(24, 42), o + rng.randint(9, 22), 2.5, hexc("8a8480"))
    img.rect(o + 51, o + 10, 6, 10, hexc("2a2a30"))
    img.outline()
    img.save("apt_wheelbarrow.png")


def watering_can():
    img = framed(38, 24)
    o = 1
    g = hexc("5aa96a")
    img.line(o + 20, o + 12, o + 34, o + 4, g)
    img.line(o + 20, o + 13, o + 34, o + 5, shade(g, -0.2))
    img.rect(o + 33, o + 2, 4, 4, shade(g, 0.2))
    img.circle(o + 12, o + 12, 10, g)
    img.round_shade(o + 12, o + 12, 10, 0.3)
    img.circle(o + 12, o + 12, 4, shade(g, -0.35))
    img.line(o + 4, o + 4, o + 20, o + 4, shade(g, -0.1))
    img.outline()
    img.save("apt_watering_can.png")


FLOWER_COLOURS = ["e88aa8", "f2d14e", "f4f1ea", "d9534f", "9a8ad8", "f0a050"]


def flowers():
    rng = random.Random(307)
    img = framed(58, 42)
    img.circle(30, 22, 28, hexc("5a3e2a"), 19)
    for _ in range(18):
        x, y = rng.randint(8, 52), rng.randint(6, 38)
        if not img.get(x, y)[3]:
            continue
        img.circle(x, y, 3, LEAF_GREENS[rng.randrange(3)])
        col = hexc(rng.choice(FLOWER_COLOURS))
        for (dx, dy) in ((0, -2), (-2, 0), (2, 0), (0, 2)):
            img.set(x + dx, y + dy, col)
            img.set(x + dx + 1, y + dy + 1, shade(col, -0.25))
        img.set(x, y, hexc("f2c14e"))
    img.outline()
    img.save("apt_flowers.png")


def veggies():
    rng = random.Random(308)
    img = framed(90, 46)
    o = 1
    img.rect(o, o, 90, 46, wood_fill(rng, WOOD_DARK))
    img.bevel(o, o, 90, 46, 0.25)
    img.rect(o + 4, o + 4, 82, 38, speckle(rng, hexc("4a3222"), 0.1, 0.6))
    for row in range(3):
        y = o + 10 + row * 13
        for k in range(7):
            x = o + 10 + k * 12
            if row == 0:
                # Cabbages.
                img.circle(x, y, 5, hexc("8ac46a"))
                img.round_shade(x, y, 5, 0.3)
                img.circle(x, y, 2, hexc("b8e08a"))
            elif row == 1:
                # Carrot tops.
                for d in (-2, 0, 2):
                    img.line(x, y + 2, x + d, y - 4, LEAF_GREENS[2])
                img.rect(x - 1, y + 2, 3, 2, hexc("f08a2a"))
            else:
                # Tomatoes on a stake.
                img.rect(x, y - 5, 1, 10, WOOD)
                img.circle(x - 2, y, 2.5, hexc("d9534f"))
                img.circle(x + 2, y + 2, 2.5, hexc("e8634f"))
                img.set(x - 3, y - 1, hexc("ffffff"))
    img.outline()
    img.save("apt_veggies.png")


def scarecrow(fabric, n):
    rng = random.Random(309 + n)
    img = framed(50, 40)
    o = 1
    img.rect(o, o + 14, 50, 4, wood_fill(rng, WOOD_DARK))
    img.rect(o + 23, o + 4, 4, 36, wood_fill(rng, WOOD_DARK, False))
    img.rect(o + 12, o + 12, 26, 16, fabric)
    img.bevel(o + 12, o + 12, 26, 16, 0.2)
    for _ in range(6):
        x, y = rng.randint(o + 13, o + 36), rng.randint(o + 13, o + 26)
        img.rect(x, y, 3, 3, shade(fabric, -0.25))
    # Straw at the cuffs and a hat seen from above.
    for x in (o + 1, o + 46):
        for k in range(4):
            img.line(x, o + 15, x + (k - 2) * 2, o + 15 + (k % 2 + 1) * 3, hexc("e8c86a"))
    img.circle(o + 25, o + 8, 8, hexc("c9a24a"))
    img.circle(o + 25, o + 8, 5, shade(hexc("c9a24a"), -0.2))
    img.round_shade(o + 25, o + 8, 8, 0.25)
    img.outline()
    img.save("apt_scarecrow_%d.png" % n)


def compost():
    rng = random.Random(310)
    img = framed(48, 40)
    o = 1
    for y in range(0, 40, 8):
        img.rect(o, o + y, 48, 6, wood_fill(rng, shade(WOOD_DARK, rng.uniform(-0.1, 0.05))))
        img.bevel(o, o + y, 48, 6, 0.2)
    img.rect(o + 4, o + 4, 40, 32, speckle(rng, hexc("4a3a2a"), 0.15, 0.8))
    for _ in range(18):
        x, y = rng.randint(o + 5, o + 42), rng.randint(o + 5, o + 34)
        img.set(x, y, rng.choice([hexc("6a8a3a"), hexc("c9a24a"), hexc("8a5a3b"), hexc("d9534f")]))
        img.set(x + 1, y, shade(img.get(x, y), -0.2))
    img.outline()
    img.save("apt_compost.png")


def garden_lamp():
    img = framed(20, 20)
    c = 11
    img.rect(3, 3, 16, 16, hexc("2a3a2e"))
    img.bevel(3, 3, 16, 16, 0.3)
    img.circle(c, c, 5.5, hexc("fff3c8"))
    img.circle(c - 1, c - 1, 2.5, hexc("ffffff"))
    for (x, y) in ((3, 3), (18, 3), (3, 18), (18, 18)):
        img.set(x, y, hexc("4a5a4e"))
    img.outline()
    img.save("apt_garden_lamp.png")


# --- rooftop --------------------------------------------------------------------

def ac_unit():
    img = framed(52, 40)
    o = 1
    img.rect(o, o, 52, 40, hexc("c9ced2"))
    img.bevel(o, o, 52, 40, 0.25)
    c = (o + 19, o + 20)
    img.circle(*c, 15, hexc("5a5e62"))
    img.circle(*c, 14, hexc("7a8088"))
    for i in range(4):
        a = i * math.tau / 4 + 0.4
        img.poly([c, (c[0] + math.cos(a) * 12, c[1] + math.sin(a) * 12), (c[0] + math.cos(a + 0.6) * 12, c[1] + math.sin(a + 0.6) * 12)], hexc("a8aeb4"))
    img.circle(*c, 3, hexc("3a3e44"))
    for y in range(o + 6, o + 36, 3):
        img.rect(o + 38, y, 10, 1, hexc("8a9096"))
    img.outline()
    img.save("apt_ac_unit.png")


def vent_box():
    img = framed(28, 28)
    o = 1
    img.rect(o, o, 28, 28, hexc("9aa0a6"))
    img.bevel(o, o, 28, 28, 0.3)
    img.circle(o + 14, o + 14, 9.5, hexc("5a5e62"))
    img.circle(o + 14, o + 14, 7.5, hexc("3a3e44"))
    for i in range(6):
        a = i * math.tau / 6
        img.line(o + 14, o + 14, o + 14 + math.cos(a) * 7, o + 14 + math.sin(a) * 7, hexc("8a9096"))
    for (x, y) in ((3, 3), (24, 3), (3, 24), (24, 24)):
        img.set(o + x, o + y, hexc("e0e4e8"))
    img.outline()
    img.save("apt_vent_box.png")


def antenna():
    img = framed(40, 72)
    o = 1
    img.rect(o + 19, o, 2, 72, hexc("9aa0a6"))
    img.rect(o + 19, o, 1, 72, hexc("d0d4d8"))
    for k in range(5):
        y = o + 6 + k * 9
        w = 18 - k * 2
        img.rect(o + 20 - w, y, w * 2, 2, hexc("9aa0a6"))
        img.rect(o + 20 - w, y, w * 2, 1, hexc("d0d4d8"))
    img.rect(o + 15, o + 64, 10, 8, hexc("5a5e62"))
    img.bevel(o + 15, o + 64, 10, 8, 0.3)
    img.outline()
    img.save("apt_antenna.png")


def water_tank():
    rng = random.Random(404)
    img = framed(62, 62)
    c = 31.5
    img.circle(c, c, 30, wood_fill(rng, hexc("8a6a4a"), False))
    img.round_shade(c, c, 30, 0.25)
    for r in (29, 20, 11):
        for i in range(int(r * 6)):
            a = i * math.tau / (r * 6)
            img.set(c + math.cos(a) * r, c + math.sin(a) * r, hexc("4a4e54"))
    img.circle(c, c, 6, hexc("5a3e2a"))
    img.circle(c - 1, c - 1, 2, hexc("8a6a4a"))
    img.outline()
    img.save("apt_water_tank.png")


def solar_panel():
    img = framed(80, 48)
    o = 1
    img.rect(o, o, 80, 48, hexc("c9ced2"))
    img.rect(o + 2, o + 2, 76, 44, hexc("223060"))
    for y in range(o + 2, o + 46):
        for x in range(o + 2, o + 78):
            if (x - o - 2) % 13 == 12 or (y - o - 2) % 11 == 10:
                img.set(x, y, hexc("8a9ac4"))
            elif (x + y) % 9 == 0:
                img.set(x, y, hexc("2c3c74"))
    for i in range(14):
        img.set(o + 8 + i, o + 6 + i // 2, hexc("6a8ac4"))
    img.bevel(o, o, 80, 48, 0.2)
    img.outline()
    img.save("apt_solar_panel.png")


def chimney():
    rng = random.Random(406)
    img = framed(36, 36)
    o = 1
    brick = hexc("a8503a")
    for row in range(9):
        y = o + row * 4
        off = 0 if row % 2 else 5
        for x in range(-10, 36, 10):
            tone = shade(brick, rng.uniform(-0.12, 0.06))
            img.rect(o + max(x + off, 0), y, min(9, 36 - max(x + off, 0)), 3, tone)
        img.rect(o, y + 3, 36, 1, hexc("c8b8a0"))
    img.bevel(o, o, 36, 36, 0.25)
    img.rect(o + 9, o + 9, 18, 18, hexc("2a2a2e"))
    img.rect(o + 11, o + 11, 14, 14, hexc("141416"))
    img.outline()
    img.save("apt_chimney.png")


def skylight():
    img = framed(52, 40)
    o = 1
    img.rect(o, o, 52, 40, hexc("5a5e62"))
    img.bevel(o, o, 52, 40, 0.25)
    for (x0, x1) in ((4, 25), (27, 48)):
        img.rect(o + x0, o + 4, x1 - x0, 32, hexc("6a9cc8"))
        for i in range(8):
            img.set(o + x0 + 3 + i, o + 7 + i, hexc("c8e4f8"))
            img.set(o + x0 + 4 + i, o + 7 + i, hexc("a8d0f0"))
    img.outline()
    img.save("apt_skylight.png")


def deck_chair(fabric, n):
    rng = random.Random(408 + n)
    img = framed(28, 52)
    o = 1
    img.rect(o, o, 28, 52, wood_fill(rng, WOOD, False))
    img.bevel(o, o, 28, 52, 0.25)
    for k, y in enumerate(range(o + 3, o + 50, 6)):
        img.rect(o + 3, y, 22, 5, shade(fabric, 0.2) if k % 2 == 0 else hexc("f4f1ea"))
    img.rect(o + 3, o + 3, 22, 10, shade(fabric, 0.35))
    img.outline()
    img.save("apt_deck_chair_%d.png" % n)


def potted_tree():
    rng = random.Random(409)
    img = framed(40, 40)
    img.rect(7, 7, 28, 28, hexc("6b6e72"))
    img.bevel(7, 7, 28, 28, 0.3)
    canopy(img, rng, 21, 21, 15, lumps=6)
    img.outline()
    img.save("apt_potted_tree.png")


def clothesline():
    rng = random.Random(410)
    img = framed(144, 24)
    o = 1
    img.rect(o, o + 6, 144, 1, hexc("e8e2d0"))
    for x in (o, o + 140):
        img.rect(x, o + 4, 4, 4, STEEL_DARK)
    x = o + 10
    while x < o + 128:
        w = rng.randint(10, 18)
        col = hexc(rng.choice(FABRICS + ["f4f1ea", "f4f1ea", "6fb0e0"]))
        img.rect(x, o + 6, w, rng.randint(10, 16), col)
        img.bevel(x, o + 6, w, 12, 0.2)
        img.set(x + 2, o + 5, hexc("c9a24a"))
        img.set(x + w - 3, o + 5, hexc("c9a24a"))
        x += w + rng.randint(4, 8)
    img.outline()
    img.save("apt_clothesline.png")


# --- supermarket ------------------------------------------------------------------

PRODUCTS = ["d9534f", "f2d14e", "5aa96a", "4a8ac4", "f08a2a", "9a5ad8", "f4f1ea", "8a5a3b"]


def store_shelf():
    rng = random.Random(501)
    img = framed(120, 28)
    o = 1
    img.rect(o, o, 120, 28, hexc("e8e4dc"))
    img.bevel(o, o, 120, 28, 0.25)
    img.rect(o, o + 13, 120, 2, hexc("b8b4ac"))
    for row in (0, 1):
        x = o + 3
        y = o + 3 + row * 13
        while x < o + 116:
            w = rng.randint(4, 8)
            col = hexc(rng.choice(PRODUCTS))
            img.rect(x, y, w, 9, col)
            img.rect(x, y, w, 1, shade(col, 0.35))
            img.rect(x + w - 1, y, 1, 9, shade(col, -0.3))
            if w > 5:
                img.rect(x + 1, y + 4, w - 2, 2, hexc("ffffff"))
            x += w + 1
    img.outline()
    img.save("apt_store_shelf.png")


def price_sign():
    img = framed(32, 20)
    o = 1
    img.rect(o, o, 32, 20, hexc("f2d14e"))
    img.bevel(o, o, 32, 20, 0.25)
    img.rect(o + 3, o + 4, 14, 6, hexc("d9534f"))
    img.rect(o + 5, o + 6, 10, 2, hexc("ffffff"))
    img.rect(o + 3, o + 13, 26, 2, hexc("2a2a30"))
    img.rect(o + 20, o + 4, 8, 6, hexc("2a2a30"))
    img.outline()
    img.save("apt_price_sign.png")


def cart_row():
    img = framed(74, 26)
    o = 1
    for k in range(4):
        x = o + k * 12
        img.rect(x, o + 2, 26, 22, hexc("c8ccd2"))
        for yy in range(o + 2, o + 24, 3):
            img.rect(x + 1, yy, 24, 1, hexc("8a9096"))
        for xx in range(x + 1, x + 25, 3):
            img.rect(xx, o + 3, 1, 20, hexc("9aa0a6"))
        img.rect(x, o + 2, 26, 1, hexc("eef0f2"))
        img.rect(x + 25, o + 2, 1, 22, hexc("5a5e62"))
    img.rect(o + 62, o, 4, 26, hexc("d9534f"))
    img.rect(o + 62, o, 1, 26, hexc("f08a7a"))
    img.outline()
    img.save("apt_cart_row.png")


def fruit_stand():
    rng = random.Random(504)
    img = framed(72, 48)
    o = 1
    img.rect(o, o, 72, 48, wood_fill(rng, WOOD))
    img.bevel(o, o, 72, 48, 0.25)
    img.rect(o, o + 23, 72, 2, WOOD_DARK)
    for i, (col, r) in enumerate((("d9534f", 4), ("f08a2a", 4), ("f2d14e", 3), ("8ac46a", 4), ("9a5ad8", 2.5), ("e8634f", 4))):
        bx, by = o + 3 + (i % 3) * 23, o + 3 + (i // 3) * 23
        img.rect(bx, by, 21, 19, shade(WOOD, -0.25))
        for _ in range(9):
            x, y = bx + rng.randint(3, 17), by + rng.randint(3, 15)
            img.circle(x, y, r, hexc(col))
            img.set(x - 1, y - 1, shade(hexc(col), 0.4))
    img.outline()
    img.save("apt_fruit_stand.png")


def melon_bin():
    rng = random.Random(505)
    img = framed(48, 48)
    o = 1
    img.rect(o, o, 48, 48, wood_fill(rng, WOOD_DARK))
    img.bevel(o, o, 48, 48, 0.25)
    img.rect(o + 3, o + 3, 42, 42, shade(WOOD_DARK, -0.3))
    for (x, y) in ((14, 14), (34, 15), (15, 34), (34, 34), (24, 24)):
        img.circle(o + x, o + y, 10, hexc("3f7a34"))
        for k in range(5):
            img.line(o + x - 8 + k * 4, o + y - 8, o + x - 8 + k * 4, o + y + 8, hexc("8ac46a"))
        img.circle(o + x, o + y, 10, lambda xx, yy: img.get(xx, yy))
        img.round_shade(o + x, o + y, 10, 0.3)
    img.outline()
    img.save("apt_melon_bin.png")


def freezer_chest():
    rng = random.Random(506)
    img = framed(100, 40)
    o = 1
    img.rect(o, o, 100, 40, hexc("f4f1ea"))
    img.bevel(o, o, 100, 40, 0.25)
    img.rect(o + 4, o + 4, 92, 32, hexc("9ac8e4"))
    for _ in range(14):
        x, y = o + rng.randint(6, 88), o + rng.randint(6, 28)
        col = hexc(rng.choice(PRODUCTS))
        img.rect(x, y, 7, 5, col)
        img.rect(x, y, 7, 1, shade(col, 0.3))
    # Frost and glass glare over the goods.
    for y in range(o + 4, o + 36):
        for x in range(o + 4, o + 96):
            c = img.get(x, y)
            img.set(x, y, shade(c, 0.35))
    for i in range(18):
        img.set(o + 10 + i, o + 6 + i // 2, hexc("ffffff"))
        img.set(o + 50 + i, o + 6 + i // 2, hexc("ffffff"))
    img.rect(o + 49, o + 4, 2, 32, hexc("c9ced2"))
    img.outline()
    img.save("apt_freezer_chest.png")


def ice_block():
    img = framed(28, 28)
    o = 1
    img.rect(o, o, 28, 28, hexc("cfe8f4"))
    img.bevel(o, o, 28, 28, 0.3)
    img.line(o + 4, o + 6, o + 18, o + 4, hexc("ffffff"))
    img.line(o + 6, o + 20, o + 22, o + 16, hexc("eaf6fc"))
    img.line(o + 10, o + 10, o + 16, o + 18, hexc("a8d0e8"))
    img.outline()
    img.save("apt_ice_block.png")


# --- harbor -------------------------------------------------------------------------

def beach_umbrella():
    img = framed(62, 62)
    c = 31.5
    for k in range(8):
        a0 = math.tau * k / 8
        col = hexc("d9534f") if k % 2 == 0 else hexc("f4f1ea")
        img.poly([(c, c), (c + math.cos(a0) * 30, c + math.sin(a0) * 30), (c + math.cos(a0 + math.tau / 8) * 30, c + math.sin(a0 + math.tau / 8) * 30)], col)
    for yy in range(64):
        for xx in range(64):
            if img.get(xx, yy)[3]:
                dx, dy = (xx - c) / 30, (yy - c) / 30
                img._shade(xx, yy, -(dx + dy) * 0.15)
    for k in range(8):
        a = math.tau * k / 8
        img.line(c, c, c + math.cos(a) * 30, c + math.sin(a) * 30, hexc("b8b0a0"))
    img.circle(c, c, 3, hexc("6a4428"))
    img.outline()
    img.save("apt_beach_umbrella.png")


def towel(fabric, n):
    img = framed(28, 56)
    o = 1
    img.rect(o, o, 28, 56, shade(fabric, 0.25))
    for y in range(o + 4, o + 56, 10):
        img.rect(o, y, 28, 4, hexc("f4f1ea"))
    for x in range(o, o + 28, 2):
        img.set(x, o, hexc("f4f1ea"))
        img.set(x, o + 55, hexc("f4f1ea"))
    img.bevel(o, o, 28, 56, 0.12)
    img.outline()
    img.save("apt_towel_%d.png" % n)


def sandcastle():
    rng = random.Random(603)
    img = framed(48, 48)
    c = 24.5
    img.circle(c, c, 22, hexc("c9b07a"))
    img.round_shade(c, c, 22, 0.25)
    img.rect(c - 12, c - 12, 24, 24, hexc("d8c08a"))
    img.bevel(c - 12, c - 12, 24, 24, 0.25)
    for (x, y) in ((-12, -12), (12, -12), (-12, 12), (12, 12)):
        img.rect(c + x - 6, c + y - 6, 12, 12, hexc("e2cc94"))
        img.bevel(c + x - 6, c + y - 6, 12, 12, 0.3)
        for k in range(3):
            img.set(c + x - 4 + k * 3, c + y - 6, hexc("b89a64"))
    img.rect(c - 1, c - 10, 1, 8, hexc("6a4428"))
    img.rect(c, c - 10, 5, 3, hexc("d9534f"))
    for _ in range(30):
        x, y = rng.randint(4, 44), rng.randint(4, 44)
        img._shade(x, y, rng.choice((-0.1, 0.1)))
    img.outline()
    img.save("apt_sandcastle.png")


def lifebuoy():
    img = framed(26, 26)
    c = 13.5
    for yy in range(28):
        for xx in range(28):
            dx, dy = xx + 0.5 - c, yy + 0.5 - c
            d = (dx * dx + dy * dy) ** 0.5
            if 6 <= d <= 12.5:
                a = math.atan2(dy, dx) + math.pi / 4
                col = hexc("d9534f") if int(a / (math.pi / 2)) % 2 == 0 else hexc("f4f1ea")
                img.set(xx, yy, shade(col, -(dx + dy) / 40))
    img.outline()
    img.save("apt_lifebuoy.png")


def bollard():
    img = framed(20, 20)
    c = 10.5
    img.circle(c, c, 9, hexc("3a3a40"))
    img.round_shade(c, c, 9, 0.35)
    img.circle(c, c, 6, hexc("4a4a52"))
    img.circle(c - 2, c - 2, 2.5, hexc("7a7a82"))
    img.outline()
    img.save("apt_bollard.png")


def barrels():
    rng = random.Random(606)
    img = framed(50, 48)
    for (x, y, col) in ((13, 13, "8a5a3b"), (37, 13, "4a7a9a"), (25, 35, "8a5a3b")):
        img.circle(x, y, 12, wood_fill(rng, hexc(col), False))
        img.round_shade(x, y, 12, 0.3)
        for r in (11, 7):
            for i in range(int(r * 7)):
                a = i * math.tau / (r * 7)
                img.set(x + math.cos(a) * r, y + math.sin(a) * r, hexc("4a4e54"))
        img.circle(x + 3, y + 3, 1.5, hexc("2a2a2e"))
    img.outline()
    img.save("apt_barrels.png")


def rope_coil():
    img = framed(40, 28)
    rope = hexc("c9a26a")
    c = (14, 14)
    for r in (12, 9, 6, 3):
        for i in range(int(r * 9)):
            a = i * math.tau / (r * 9)
            x, y = c[0] + math.cos(a) * r, c[1] + math.sin(a) * r
            img.set(x, y, shade(rope, 0.15 if (i // 2) % 2 else -0.1))
            img.set(x + 1, y, shade(rope, -0.2))
    for i in range(14):
        img.set(26 + i, 14 + i * 0.4, shade(rope, 0.1 if i % 2 else -0.15))
        img.set(26 + i, 15 + i * 0.4, shade(rope, -0.25))
    img.outline()
    img.save("apt_rope_coil.png")


def fish_crate():
    rng = random.Random(608)
    img = framed(44, 32)
    o = 1
    box_crate(img, rng, o, o, 44, 32, hexc("9a7048"))
    img.rect(o + 3, o + 3, 38, 26, hexc("cfe8f4"))
    for k in range(6):
        x, y = o + 6 + k * 6, o + 8 + (k % 2) * 10
        col = hexc("9aa8b8") if k % 3 else hexc("c8a07a")
        img.circle(x + 4, y + 3, 6, col, 2.5)
        img.round_shade(x + 4, y + 3, 6, 0.3)
        img.poly([(x - 2, y + 3), (x - 6, y), (x - 6, y + 6)], shade(col, -0.2))
        img.set(x + 7, y + 2, hexc("1a1a1a"))
    img.outline()
    img.save("apt_fish_crate.png")


def fish_net():
    rng = random.Random(609)
    img = framed(64, 44)
    rope = hexc("b8a878")
    for i in range(8):
        img.line(2 + i * 8 + rng.randint(-1, 1), 2, 4 + i * 7, 42, rope)
    for i in range(7):
        img.line(2, 2 + i * 6.6, 62, 4 + i * 6.3, rope)
    for _ in range(5):
        x, y = rng.randint(6, 58), rng.randint(6, 38)
        img.circle(x, y, 2.5, hexc("e86a3a"))
    img.circle(48, 30, 4, hexc("e86a3a"))
    img.outline()
    img.save("apt_fish_net.png")


def harbor_lamp():
    lamp_head("harbor_lamp", hexc("2a3a4a"), size=18)


# --- factory --------------------------------------------------------------------------

def pallet_stack():
    rng = random.Random(701)
    img = framed(48, 48)
    o = 1
    img.rect(o, o, 48, 48, wood_fill(rng, hexc("b08a5a")))
    img.bevel(o, o, 48, 48, 0.25)
    for k in range(4):
        img.rect(o + 2, o + 3 + k * 12, 44, 3, shade(hexc("b08a5a"), -0.3))
    # A wrapped load on top.
    img.rect(o + 6, o + 6, 36, 36, hexc("c8a878"))
    img.bevel(o + 6, o + 6, 36, 36, 0.25)
    img.rect(o + 6, o + 22, 36, 3, hexc("c9a24a"))
    img.rect(o + 22, o + 6, 3, 36, hexc("c9a24a"))
    for i in range(10):
        img.set(o + 10 + i, o + 10 + i // 3, hexc("e8d8b8"))
    img.outline()
    img.save("apt_pallet_stack.png")


def machine():
    rng = random.Random(702)
    img = framed(72, 52)
    o = 1
    img.rect(o, o, 72, 52, speckle(rng, hexc("6a7a8a"), 0.04, 0.4))
    img.bevel(o, o, 72, 52, 0.25)
    img.rect(o + 6, o + 6, 30, 18, hexc("2a3a4a"))
    for y in range(o + 8, o + 22, 3):
        img.rect(o + 8, y, rng.randint(8, 24), 1, hexc("5ad16a"))
    img.circle(o + 54, o + 16, 9, hexc("c9ced2"))
    img.round_shade(o + 54, o + 16, 9, 0.3)
    img.line(o + 54, o + 16, o + 59, o + 11, hexc("d9534f"))
    for i, col in enumerate(("d9534f", "f2c14e", "5ad16a")):
        img.circle(o + 10 + i * 10, o + 38, 3.5, hexc(col))
        img.set(o + 9 + i * 10, o + 37, hexc("ffffff"))
    for y in range(o + 32, o + 48, 3):
        img.rect(o + 44, y, 22, 1, hexc("4a5868"))
    img.outline()
    img.save("apt_machine.png")


def robot_arm():
    img = framed(60, 40)
    o = 1
    y = hexc("f2c14e")
    img.circle(o + 14, o + 24, 13, STEEL_DARK)
    img.circle(o + 14, o + 24, 11, y)
    img.round_shade(o + 14, o + 24, 11, 0.3)
    for k in range(6):
        img.line(o + 14 + k, o + 22 - k * 1.6, o + 40 + k * 0.3, o + 10 + k * 0.4, y if k < 5 else shade(y, -0.3))
    img.circle(o + 41, o + 11, 5, STEEL_DARK)
    img.circle(o + 41, o + 11, 3, hexc("8a9096"))
    img.line(o + 44, o + 10, o + 56, o + 6, STEEL_DARK)
    img.line(o + 44, o + 13, o + 56, o + 16, STEEL_DARK)
    img.rect(o + 55, o + 4, 3, 4, hexc("c9ced2"))
    img.rect(o + 55, o + 15, 3, 4, hexc("c9ced2"))
    for k in range(5):
        img.set(o + 6 + k * 3, o + 33, hexc("2a2a2a") if k % 2 else y)
    img.outline()
    img.save("apt_robot_arm.png")


def control_panel():
    img = framed(52, 24)
    o = 1
    img.rect(o, o, 52, 24, hexc("3a3e44"))
    img.bevel(o, o, 52, 24, 0.3)
    for i in range(5):
        col = hexc(["5ad16a", "d9534f", "f2c14e"][i % 3])
        img.rect(o + 4 + i * 9, o + 5, 6, 5, col)
        img.set(o + 4 + i * 9, o + 5, hexc("ffffff"))
    img.circle(o + 10, o + 17, 3.5, hexc("d9534f"))
    img.circle(o + 9, o + 16, 1, hexc("ffb0a0"))
    for i in range(4):
        img.rect(o + 22 + i * 7, o + 15, 2, 6, hexc("c9ced2"))
        img.rect(o + 21 + i * 7, o + 15 + (i * 2) % 5, 4, 2, hexc("8a9096"))
    img.outline()
    img.save("apt_control_panel.png")


def gear(img, cx, cy, r, col):
    for i in range(10):
        a = i * math.tau / 10
        img.circle(cx + math.cos(a) * r, cy + math.sin(a) * r, 2.2, col)
    img.circle(cx, cy, r, col)
    img.round_shade(cx, cy, r + 2, 0.3)
    img.circle(cx, cy, r * 0.35, shade(col, -0.5))


def gear_pile():
    img = framed(38, 32)
    gear(img, 12, 12, 8, hexc("9aa0a6"))
    gear(img, 27, 15, 7, hexc("b08a5a"))
    gear(img, 17, 24, 6, hexc("8a9096"))
    img.outline()
    img.save("apt_gear_pile.png")


# --- cemetery -------------------------------------------------------------------------

GRAVE = hexc("8a8a92")


def gravestone():
    rng = random.Random(801)
    img = framed(30, 36)
    o = 1
    img.rect(o, o + 30, 30, 6, hexc("5a6a4a"))
    img.circle(o + 15, o + 13, 13, GRAVE)
    img.rect(o + 2, o + 13, 26, 18, GRAVE)
    for y in range(o, o + 32):
        for x in range(o, o + 30):
            if img.get(x, y) == GRAVE:
                img.set(x, y, shade(GRAVE, 0.12 - (x - o) * 0.012 + rng.uniform(-0.04, 0.04)))
    img.rect(o + 9, o + 12, 12, 1, shade(GRAVE, -0.35))
    img.rect(o + 8, o + 16, 14, 1, shade(GRAVE, -0.35))
    img.rect(o + 10, o + 20, 10, 1, shade(GRAVE, -0.35))
    for _ in range(6):
        img.set(o + rng.randint(3, 26), o + rng.randint(22, 30), hexc("5a8a4a"))
    img.outline()
    img.save("apt_gravestone.png")


def grave_cross():
    img = framed(28, 44)
    o = 1
    stone = hexc("9a9aa2")
    img.rect(o + 2, o + 38, 24, 6, hexc("5a6a4a"))
    img.rect(o + 10, o, 8, 40, stone)
    img.rect(o + 1, o + 9, 26, 8, stone)
    img.bevel(o + 10, o, 8, 40, 0.25)
    img.bevel(o + 1, o + 9, 26, 8, 0.25)
    img.rect(o + 11, o + 20, 6, 1, shade(stone, -0.3))
    img.outline()
    img.save("apt_grave_cross.png")


def dead_tree():
    rng = random.Random(803)
    img = framed(54, 62)
    bark = hexc("4a3a32")
    for (a, b, w) in (((27, 60), (27, 22), 4), ((27, 38), (10, 20), 2), ((27, 30), (44, 12), 2), ((14, 24), (8, 6), 1), ((40, 16), (50, 14), 1), ((27, 24), (30, 2), 2), ((36, 20), (36, 6), 1)):
        n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1]))) + 1
        for i in range(n + 1):
            t = i / n
            x = a[0] + (b[0] - a[0]) * t
            y = a[1] + (b[1] - a[1]) * t
            ww = w * (1 - t * 0.5)
            img.rect(x - ww / 2, y, max(ww, 1), 1, shade(bark, rng.uniform(-0.1, 0.1)))
            img.set(x - ww / 2, y, shade(bark, 0.2))
    img.outline()
    img.save("apt_dead_tree.png")


def grave_candle():
    img = framed(10, 16)
    o = 1
    img.rect(o + 1, o + 6, 8, 10, hexc("d9534f"))
    img.bevel(o + 1, o + 6, 8, 10, 0.3)
    img.rect(o + 2, o + 7, 6, 2, hexc("f4ecd4"))
    img.circle(o + 5, o + 3, 2.5, hexc("ff9a2a"), 3.5)
    img.set(o + 5, o + 3, hexc("fff3c8"))
    img.set(o + 5, o + 4, hexc("fff3c8"))
    img.outline()
    img.save("apt_grave_candle.png")


def crypt():
    rng = random.Random(805)
    img = framed(80, 70)
    o = 1
    stone = hexc("6a6a72")
    img.rect(o + 4, o + 24, 72, 44, speckle(rng, stone, 0.06, 0.5))
    img.bevel(o + 4, o + 24, 72, 44, 0.25)
    img.poly([(o, o + 26), (o + 40, o + 2), (o + 80, o + 26)], shade(stone, -0.15))
    img.poly([(o, o + 26), (o + 40, o + 2), (o + 40, o + 26)], shade(stone, 0.05))
    img.rect(o + 28, o + 40, 24, 28, hexc("2a2a30"))
    img.circle(o + 40, o + 40, 12, hexc("2a2a30"))
    img.rect(o + 39, o + 30, 2, 38, hexc("4a4a52"))
    img.rect(o + 36, o + 12, 8, 2, hexc("c9a24a"))
    img.rect(o + 39, o + 8, 2, 10, hexc("c9a24a"))
    for _ in range(14):
        x, y = rng.randint(6, 76), rng.randint(26, 64)
        img.set(o + x, o + y, hexc("4a6a3a"))
    img.outline()
    img.save("apt_crypt.png")


# --- station ------------------------------------------------------------------------

def ticket_machine():
    img = framed(30, 38)
    o = 1
    red = hexc("c0392b")
    img.rect(o, o, 30, 38, red)
    img.bevel(o, o, 30, 38, 0.3)
    img.rect(o + 5, o + 5, 20, 12, hexc("2a3a4a"))
    img.rect(o + 6, o + 6, 18, 10, hexc("8fd0f0"))
    for i in range(6):
        img.set(o + 7 + i, o + 7, hexc("ffffff"))
    for k in range(6):
        img.rect(o + 6 + (k % 3) * 6, o + 21 + (k // 3) * 4, 4, 3, hexc("f4f1ea"))
    img.rect(o + 8, o + 31, 14, 3, hexc("2a2a30"))
    img.outline()
    img.save("apt_ticket_machine.png")


def luggage():
    rng = random.Random(902)
    img = framed(30, 26)
    o = 1
    brown = hexc("8a5a34")
    img.rect(o + 9, o, 12, 4, hexc("2a2a2e"))
    img.rect(o, o + 4, 30, 22, brown)
    img.bevel(o, o + 4, 30, 22, 0.25)
    img.rect(o, o + 14, 30, 2, shade(brown, -0.3))
    for x in (o + 3, o + 25):
        img.rect(x, o + 4, 2, 22, hexc("c9a24a"))
    img.rect(o + 18, o + 18, 7, 5, hexc("f4f1ea"))
    img.rect(o + 6, o + 7, 6, 4, hexc(rng.choice(["5aa96a", "4a8ac4", "d9534f"])))
    img.outline()
    img.save("apt_luggage.png")


def signal():
    img = framed(18, 54)
    o = 1
    img.rect(o + 7, o + 20, 4, 34, hexc("5a5e62"))
    img.rect(o + 7, o + 20, 1, 34, hexc("9aa0a6"))
    img.rect(o, o, 18, 24, hexc("2a2a30"))
    img.bevel(o, o, 18, 24, 0.2)
    img.circle(o + 9, o + 6, 4, hexc("e24b4a"))
    img.circle(o + 8, o + 5, 1.5, hexc("ffb0a0"))
    img.circle(o + 9, o + 17, 4, hexc("2a5a3a"))
    img.outline()
    img.save("apt_signal.png")


def buffer_stop():
    img = framed(60, 22)
    o = 1
    img.rect(o, o, 60, 22, hexc("c0392b"))
    for x in range(o + 4, o + 56, 16):
        img.rect(x, o, 7, 22, hexc("f4f1ea"))
    img.bevel(o, o, 60, 22, 0.25)
    for x in (o + 10, o + 46):
        img.circle(x, o + 11, 5, hexc("4a4e54"))
        img.circle(x - 1, o + 10, 2, hexc("9aa0a6"))
    img.outline()
    img.save("apt_buffer_stop.png")


def station_lamp():
    lamp_head("station_lamp", hexc("3a4048"), size=20, square=True)


# --- island & park -----------------------------------------------------------------------

def palm():
    rng = random.Random(1001)
    img = framed(76, 76)
    c = 38.5
    for k in range(8):
        a = math.tau * k / 8 + 0.3 + rng.uniform(-0.15, 0.15)
        g = LEAF_GREENS[k % 3 + 1]
        for i in range(34):
            t = i / 34
            x = c + math.cos(a) * i + math.cos(a + math.pi / 2) * math.sin(t * 2.4) * 3
            y = c + math.sin(a) * i + math.sin(a + math.pi / 2) * math.sin(t * 2.4) * 3
            w = 4 * (1 - t) + 1
            for s in range(-int(w), int(w) + 1):
                px = x + math.cos(a + math.pi / 2) * s
                py = y + math.sin(a + math.pi / 2) * s
                img.set(px, py, shade(g, (0.15 if s < 0 else -0.12)))
            img.set(x, y, shade(g, 0.3))
    img.circle(c, c, 5, hexc("6a4428"))
    for (dx, dy) in ((-3, 2), (3, 2), (0, -3)):
        img.circle(c + dx, c + dy, 2.5, hexc("5a3a20"))
        img.set(c + dx - 1, c + dy - 1, hexc("8a6a4a"))
    img.outline()
    img.save("apt_palm.png")


def campfire():
    img = framed(30, 30)
    c = 15.5
    for k in range(7):
        a = math.tau * k / 7
        img.circle(c + math.cos(a) * 11, c + math.sin(a) * 11, 3.5, hexc("7a7470"))
        img.round_shade(c + math.cos(a) * 11, c + math.sin(a) * 11, 3.5, 0.3)
    img.line(c - 7, c - 3, c + 7, c + 3, hexc("5a3a20"))
    img.line(c - 7, c - 2, c + 7, c + 4, hexc("4a2a18"))
    img.line(c - 6, c + 4, c + 6, c - 4, hexc("5a3a20"))
    img.circle(c, c, 5, hexc("f08a2a"))
    img.circle(c, c - 1, 3, hexc("f2d14e"))
    img.set(c, c - 1, hexc("fff3c8"))
    img.outline()
    img.save("apt_campfire.png")


def rock():
    rng = random.Random(1003)
    img = framed(46, 34)
    pts = [(23 + math.cos(a) * 22 * rng.uniform(0.85, 1.0), 17 + math.sin(a) * 16 * rng.uniform(0.85, 1.0)) for a in [i * math.tau / 9 for i in range(9)]]
    img.poly(pts, hexc("8a8480"))
    for yy in range(36):
        for xx in range(48):
            if img.get(xx, yy)[3]:
                k = -((xx - 23) / 22 + (yy - 17) / 16) * 0.2
                img.set(xx, yy, shade(hexc("8a8480"), k + rng.uniform(-0.04, 0.04)))
    img.line(14, 10, 22, 16, hexc("6a6460"))
    img.line(22, 16, 30, 13, hexc("6a6460"))
    for _ in range(10):
        img.set(rng.randint(10, 36), rng.randint(20, 30), hexc("5a8a4a"))
    img.outline()
    img.save("apt_rock.png")


def wreck():
    rng = random.Random(1004)
    img = framed(90, 32)
    o = 1
    hull = hexc("6a4428")
    img.poly([(o, o + 4), (o + 70, o + 2), (o + 88, o + 16), (o + 70, o + 30), (o, o + 28)], hull)
    for y in range(o + 4, o + 29, 5):
        for x in range(o, o + 88):
            if img.get(x, y)[3]:
                img.set(x, y, shade(hull, -0.3))
    img.poly([(o + 6, o + 9), (o + 64, o + 8), (o + 76, o + 16), (o + 64, o + 24), (o + 6, o + 23)], shade(hull, -0.45))
    for x in range(o + 12, o + 64, 14):
        img.rect(x, o + 9, 3, 15, wood_fill(rng, shade(hull, 0.1), False))
    img.rect(o + 30, o + 12, 18, 8, shade(hull, 0.2))
    for _ in range(12):
        img.set(o + rng.randint(4, 80), o + rng.randint(4, 28), hexc("4f6a5a"))
    img.outline()
    img.save("apt_wreck.png")


def fountain():
    img = framed(64, 64)
    c = 32.5
    img.circle(c, c, 31, STONE)
    img.round_shade(c, c, 31, 0.25)
    img.circle(c, c, 26, shade(STONE, -0.25))
    img.circle(c, c, 25, hexc("5a9ad0"))
    img.circle(c - 4, c - 5, 15, hexc("6fb0e0"))
    for r in (18, 12):
        for i in range(int(r * 5)):
            a = i * math.tau / (r * 5)
            if i % 3:
                img.set(c + math.cos(a) * r, c + math.sin(a) * r, hexc("a8d8f8"))
    img.circle(c, c, 8, STONE)
    img.round_shade(c, c, 8, 0.3)
    img.circle(c, c, 4, hexc("8fc8f0"))
    img.set(c - 1, c - 1, hexc("ffffff"))
    img.outline()
    img.save("apt_fountain.png")


def picnic_blanket():
    rng = random.Random(1006)
    img = framed(60, 44)
    o = 1
    red = hexc("d9534f")
    for y in range(44):
        for x in range(60):
            a = (x // 8) % 2
            b = (y // 8) % 2
            c = red if a and b else hexc("f4f1ea") if not a and not b else hexc("e89a94")
            img.set(o + x, o + y, c)
    img.bevel(o, o, 60, 44, 0.12)
    # A basket and an apple.
    img.rect(o + 36, o + 6, 16, 12, wood_fill(rng, hexc("c9a26a")))
    img.bevel(o + 36, o + 6, 16, 12, 0.25)
    img.line(o + 36, o + 6, o + 51, o + 17, hexc("8a6a42"))
    img.circle(o + 14, o + 30, 3.5, hexc("5aa96a"))
    img.set(o + 13, o + 29, hexc("b8e08a"))
    img.outline()
    img.save("apt_picnic_blanket.png")


def ducks():
    img = framed(52, 22)
    for k in range(3):
        x, y = 8 + k * 17, 11 + (k % 2) * 4 - 2
        img.circle(x, y, 7, hexc("f4f1ea") if k == 1 else hexc("8a6a4a"), 4.5)
        img.round_shade(x, y, 7, 0.25)
        head = hexc("3f7a34") if k != 1 else hexc("f4f1ea")
        img.circle(x + 6, y - 2, 3, head)
        img.set(x + 9, y - 2, hexc("f2a020"))
        img.set(x + 10, y - 2, hexc("f2a020"))
        img.set(x + 6, y - 3, hexc("1a1a1a"))
    img.outline()
    img.save("apt_ducks.png")


def plain_lamps():
    lamp_head("roof_lamp", hexc("4a4e54"), size=16)
    lamp_head("shop_lamp", hexc("e8e4dc"), glass="ffffff", size=18, square=True)
    lamp_head("factory_lamp", hexc("c9a24a"), glass="fff0b0", size=18)


# --- floor clutter ----------------------------------------------------------------------

def items():
    img = framed(10, 8)
    leaf = hexc("c98a3a")
    img.poly([(1, 5), (5, 1), (10, 2), (8, 6), (3, 8)], leaf)
    img.line(2, 6, 9, 2, shade(leaf, -0.3))
    img._shade(4, 3, 0.25)
    img.outline()
    img.save("apt_item_leaf.png")

    img = framed(6, 5)
    img.circle(3.5, 3, 3, hexc("9a948a"), 2.5)
    img.round_shade(3.5, 3, 3, 0.4)
    img.outline()
    img.save("apt_item_pebble.png")

    img = framed(8, 8)
    for (dx, dy) in ((0, -2), (-2, 0), (2, 0), (0, 2)):
        img.circle(5 + dx, 5 + dy, 1.6, hexc("e88aa8"))
    img.set(5, 5, hexc("f2d14e"))
    img.set(4, 4, hexc("f2d14e"))
    img.outline()
    img.save("apt_item_flower.png")

    img = framed(6, 8)
    img.circle(4, 5.5, 2.6, hexc("a8743a"), 3)
    img.rect(1, 1, 6, 3, hexc("6a4428"))
    img.set(4, 0, hexc("4a3020"))
    img.set(2, 4, hexc("d0a060"))
    img.outline()
    img.save("apt_item_acorn.png")

    img = framed(14, 6)
    img.line(1, 4, 13, 2, hexc("6a4428"))
    img.line(7, 3, 10, 0, hexc("6a4428"))
    img.line(1, 5, 13, 3, hexc("4a3020"))
    img.outline()
    img.save("apt_item_twig.png")

    img = framed(6, 6)
    img.circle(3.5, 3.5, 3, hexc("d9534f"))
    img.circle(3.5, 3.5, 1.5, hexc("f4f1ea"))
    img.outline()
    img.save("apt_item_bottle_cap.png")

    img = framed(8, 12)
    img.rect(1, 1, 8, 12, hexc("f4f1ea"))
    for y in range(3, 11, 2):
        img.rect(2, y, 5 if y % 4 else 6, 1, hexc("9a9aa2"))
    for x in range(1, 9, 2):
        img.set(x, 12, (0, 0, 0, 0))
    img.outline()
    img.save("apt_item_receipt.png")

    img = framed(8, 8)
    for (x, y) in ((3, 3), (6, 3), (4.5, 5.5), (3, 7), (6, 7)):
        img.circle(x, y, 1.8, hexc("7a3a8a"))
    img.set(3, 2, hexc("c8a0d8"))
    img.set(5, 1, hexc("5aa96a"))
    img.outline()
    img.save("apt_item_grape.png")

    img = framed(10, 6)
    img.poly([(1, 1), (8, 1), (11, 4), (8, 7), (1, 7)], hexc("f2d14e"))
    img.set(9, 4, hexc("2a2a30"))
    img.rect(2, 3, 4, 1, hexc("d9534f"))
    img.outline()
    img.save("apt_item_price_tag.png")

    img = framed(5, 5)
    img.circle(3, 3, 2.5, hexc("e8c84a"))
    img.set(2, 2, hexc("fff3c8"))
    img.set(4, 4, hexc("a8882a"))
    img.outline()
    img.save("apt_item_coin_small.png")

    img = framed(8, 7)
    shell = hexc("f4dcc8")
    img.poly([(4.5, 1), (9, 6), (0, 6)], shell)
    img.circle(4.5, 6, 4.5, shell, 2)
    for k in range(5):
        img.line(4.5, 1, 1 + k * 2, 7, shade(shell, -0.2))
    img.outline()
    img.save("apt_item_shell.png")

    img = framed(10, 10)
    star = hexc("f08a5a")
    for k in range(5):
        a = -math.pi / 2 + k * math.tau / 5
        img.line(5.5, 5.5, 5.5 + math.cos(a) * 4.5, 5.5 + math.sin(a) * 4.5, star)
        img.line(5.5, 5.5, 5.5 + math.cos(a + 0.15) * 4, 5.5 + math.sin(a + 0.15) * 4, star)
    img.circle(5.5, 5.5, 1.8, star)
    img.set(5, 5, shade(star, 0.4))
    img.outline()
    img.save("apt_item_starfish.png")

    img = framed(14, 5)
    rope = hexc("c9a26a")
    for x in range(1, 14):
        img.set(x, 2 + (1 if x % 4 < 2 else 0), rope)
        img.set(x, 3 + (1 if x % 4 < 2 else 0), shade(rope, -0.25))
    img.outline()
    img.save("apt_item_rope_bit.png")


def main():
    os.makedirs(OUT, exist_ok=True)
    floors()
    terrain_trees()
    for fn in (tree, bush, bench, birdbath, wheelbarrow, watering_can, flowers, veggies, compost, garden_lamp,
               ac_unit, vent_box, antenna, water_tank, solar_panel, chimney, skylight, potted_tree, clothesline,
               store_shelf, price_sign, cart_row, fruit_stand, melon_bin, freezer_chest, ice_block,
               beach_umbrella, sandcastle, lifebuoy, bollard, barrels, rope_coil, fish_crate, fish_net, harbor_lamp,
               pallet_stack, machine, robot_arm, control_panel, gear_pile,
               gravestone, grave_cross, dead_tree, grave_candle, crypt,
               ticket_machine, luggage, signal, buffer_stop, station_lamp,
               palm, campfire, rock, wreck, fountain, picnic_blanket, ducks, plain_lamps, items):
        fn()
    for n, hexcode in enumerate(FABRICS):
        fabric = hexc(hexcode)
        scarecrow(fabric, n)
        deck_chair(fabric, n)
        towel(fabric, n)
    print("outdoor art written to", OUT)


if __name__ == "__main__":
    main()
