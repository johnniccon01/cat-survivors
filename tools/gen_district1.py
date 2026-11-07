"""Pixel art for the last four maps of the first district: the Sewer, the
Forest, the Construction site and the Railyard. Same style and helpers as
tools/gen_outdoor.py (one pixel = one world unit, light from the top left).

    python tools/gen_district1.py

Writes assets/sprites/apt_*.png: floors, furniture, clutter, the terrain
(fences, parked wagons, sewer canals and the flood wave), the crane's loads
and a freight wagon. Afterwards run the Godot import.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_apartment import framed, speckle, wood_fill  # noqa: E402
from gen_outdoor import (LEAF_GREENS, STEEL_DARK, Tile, blob, box_crate, canopy, floor_concrete_plain,  # noqa: E402
                         grass, gravel, lamp_head, planks_floor, tiles_floor)
from gen_sprites import OUT, hexc, shade  # noqa: E402
from gen_terrain import THICK, save_pair  # noqa: E402

BRICK = hexc("6a4a3a")
MOSS = hexc("4a6a3a")
RUST = hexc("9a5a3a")


# --- floors ----------------------------------------------------------------------

def sewer_bricks():
    rng = random.Random(1)
    W, H = 96, 64
    img = Tile(W, H)
    base = hexc("5a5048")
    for row in range(H // 8):
        off = 0 if row % 2 else 8
        for x0 in range(-16, W, 16):
            tone = shade(base, rng.uniform(-0.12, 0.06))
            for y in range(row * 8, row * 8 + 7):
                for x in range(x0 + off, x0 + off + 15):
                    img.set(x, y, shade(tone, rng.uniform(-0.04, 0.04)))
            for y in range(row * 8, row * 8 + 8):
                img.set(x0 + off + 15, y, hexc("2e2824"))
        for x in range(W):
            img.set(x, row * 8 + 7, hexc("2e2824"))
            img.set(x, row * 8, shade(img.get(x, row * 8), 0.1))
    for _ in range(5):
        blob(img, rng, rng.randrange(W), rng.randrange(H), rng.randint(5, 10), -0.12)
    for _ in range(30):
        img.set(rng.randrange(W), rng.randrange(H), MOSS)
    img.save("apt_floor_tunnel.png")


def sewer_grating():
    img = Tile(32, 32)
    for y in range(32):
        for x in range(32):
            if x % 8 in (0, 1) or y % 8 in (0, 1):
                c = hexc("6a6e72") if (x % 8 == 0 or y % 8 == 0) else hexc("4a4e52")
            else:
                c = hexc("1a1c1e") if (x + y) % 5 else hexc("2a3a2a")
            img.set(x, y, c)
    for x in range(32):
        img.set(x, 0, hexc("8a9096"))
    img.save("apt_floor_walkway.png")


def sewer_sludge():
    rng = random.Random(3)
    S = 128
    img = Tile(S, S)
    base = hexc("4a4a3a")
    img.rect(0, 0, S, S, speckle(rng, base, 0.08, 0.6))
    for _ in range(10):
        blob(img, rng, rng.randrange(S), rng.randrange(S), rng.randint(8, 18), rng.choice((-0.1, 0.08)))
    for _ in range(4):
        cx, cy, r = rng.randrange(S), rng.randrange(S), rng.randint(8, 14)
        for yy in range(cy - r, cy + r):
            for xx in range(cx - r, cx + r):
                if (xx - cx) ** 2 + ((yy - cy) * 1.5) ** 2 < r * r:
                    img.set(xx, yy, shade(hexc("4a5a3a"), rng.uniform(-0.05, 0.05)))
        img.set(cx - r // 3, cy - 2, hexc("c8d8a8"))
    for _ in range(160):
        img.set(rng.randrange(S), rng.randrange(S), shade(MOSS, rng.uniform(-0.1, 0.15)))
    img.save("apt_floor_sludge.png")


def forest_floor():
    rng = random.Random(4)
    S = 160
    img = Tile(S, S)
    base = hexc("5a4a32")
    img.rect(0, 0, S, S, speckle(rng, base, 0.1, 0.7))
    # Needles and fallen leaves.
    for _ in range(S * S // 14):
        x, y = rng.randrange(S), rng.randrange(S)
        k = rng.choice((-0.2, 0.15, 0.25))
        dx = rng.choice((1, -1))
        img.set(x, y, shade(hexc("7a5a32"), k))
        img.set(x + dx, y + 1, shade(hexc("6a4a2a"), k))
    for _ in range(60):
        x, y = rng.randrange(S), rng.randrange(S)
        col = hexc(rng.choice(["c98a3a", "a8642a", "d8a84a"]))
        img.set(x, y, col)
        img.set(x + 1, y, shade(col, -0.2))
    for _ in range(20):
        img.set(rng.randrange(S), rng.randrange(S), hexc("4f8f3e"))
    img.save("apt_floor_forest_floor.png")


def forest_moss():
    grass("moss", hexc("4a7a3a"), 5, flowers=((hexc("e8e2c8"), 12),), dry=-0.08)


def forest_clearing():
    grass("clearing", hexc("6aa850"), 6, flowers=((hexc("f4f1ea"), 30), (hexc("e88aa8"), 16), (hexc("9a8ad8"), 14), (hexc("f2d14e"), 18)))


def site_dirt():
    rng = random.Random(7)
    S = 160
    img = Tile(S, S)
    base = hexc("8a6a48")
    img.rect(0, 0, S, S, speckle(rng, base, 0.1, 0.7))
    for _ in range(10):
        blob(img, rng, rng.randrange(S), rng.randrange(S), rng.randint(10, 22), rng.choice((-0.08, 0.06)))
    # Tyre tracks.
    for y0 in (40, 110):
        for x in range(S):
            for dy in (0, 1, 12, 13):
                yy = y0 + dy + int(math.sin(x * 0.04) * 3)
                img.set(x, yy, shade(img.get(x, yy), -0.18 if x % 4 else -0.28))
    for _ in range(S * 2):
        img.set(rng.randrange(S), rng.randrange(S), shade(hexc("a8a09a"), rng.uniform(-0.2, 0.1)))
    img.save("apt_floor_site_dirt.png")


def site_slab():
    floor_concrete_plain("site_slab", hexc("a09c94"), 8, slab=80)


def site_yard():
    gravel("site_yard", hexc("a89a80"), 9, stones=False)


def yard_ballast():
    gravel("yard_ballast", hexc("7a7268"), 10, stones=False)


def yard_rails():
    """Several sidings side by side, rails every 64 px down the picture."""
    rng = random.Random(11)
    W, H = 96, 64
    img = Tile(W, H)
    ballast = hexc("6e665c")
    img.rect(0, 0, W, H, speckle(rng, ballast, 0.12, 0.7))
    for x0 in range(0, W, 16):
        tone = shade(hexc("4a3020"), rng.uniform(-0.1, 0.05))
        img.rect(x0, 10, 7, 44, wood_fill(rng, tone, horizontal=False))
        img.bevel(x0, 10, 7, 44, 0.2)
    for ry in (20, 42):
        for x in range(W):
            img.set(x, ry - 1, hexc("3a3a40"))
            img.set(x, ry, shade(hexc("b8a888"), 0.1))
            img.set(x, ry + 1, hexc("8a6a4a"))
            img.set(x, ry + 2, hexc("5a4a3a"))
    img.save("apt_floor_yard_rails.png")


def yard_dock():
    img = tiles_floor("yard_dock", hexc("9a968e"), hexc("8e8a82"), 12, t=40, grout="6a665e", n=4, glint=False)
    rng = random.Random(13)
    for _ in range(6):
        blob(img, rng, rng.randrange(160), rng.randrange(160), rng.randint(6, 14), -0.08)
    for x in range(160):
        for y in range(4):
            img.set(x, 76 + y, hexc("e8c02a") if (x // 8) % 2 == 0 else hexc("2a2a2a"))
    img.save("apt_floor_yard_dock.png")


# --- furniture --------------------------------------------------------------------------

def valve():
    img = framed(24, 24)
    c = 12.5
    img.circle(c, c, 4, hexc("6a6e72"))
    for k in range(40):
        a = k * math.tau / 40
        img.set(c + math.cos(a) * 10, c + math.sin(a) * 10, hexc("c0392b"))
        img.set(c + math.cos(a) * 9, c + math.sin(a) * 9, hexc("a02a20"))
    for k in range(4):
        a = k * math.pi / 2 + 0.3
        img.line(c, c, c + math.cos(a) * 9, c + math.sin(a) * 9, hexc("c0392b"))
    img.set(c - 1, c - 1, hexc("c9ced2"))
    img.outline()
    img.save("apt_valve.png")


def sewer_grate():
    img = framed(30, 30)
    c = 15.5
    img.circle(c, c, 14, hexc("4a4e52"))
    img.round_shade(c, c, 14, 0.3)
    for x in range(4, 28, 4):
        img.rect(x, 5, 2, 22, hexc("1a1c1e"))
    img.circle(c, c, 14, lambda x, y: img.get(x, y))
    img.outline()
    img.save("apt_sewer_grate.png")


def rubber_duck():
    img = framed(14, 12)
    img.circle(6, 7, 5.5, hexc("f2d14e"), 4.5)
    img.circle(10, 4, 3.2, hexc("f2d14e"))
    img.round_shade(6, 7, 5.5, 0.3)
    img.rect(13, 4, 2, 2, hexc("f08a2a"))
    img.set(10, 3, hexc("1a1a1a"))
    img.outline()
    img.save("apt_rubber_duck.png")


def sewer_ladder():
    img = framed(20, 46)
    for x in (2, 16):
        img.rect(x, 1, 3, 45, hexc("8a9096"))
        img.rect(x, 1, 1, 45, hexc("c9ced2"))
    for y in range(4, 46, 7):
        img.rect(4, y, 12, 2, hexc("8a9096"))
        img.rect(4, y, 12, 1, hexc("c9ced2"))
    img.outline()
    img.save("apt_sewer_ladder.png")


def mushrooms_glow():
    rng = random.Random(20)
    img = framed(30, 24)
    for _ in range(5):
        x, y = rng.randint(6, 24), rng.randint(8, 18)
        img.rect(x, y, 2, 5, hexc("d8d8c0"))
        img.circle(x + 1, y, 4, hexc("7ae0c0"), 2.5)
        img.set(x, y - 1, hexc("d8fff0"))
    img.outline()
    img.save("apt_mushrooms_glow.png")


def pine():
    rng = random.Random(21)
    img = framed(64, 64)
    greens = [hexc("1f4a2a"), hexc("2a5e34"), hexc("357040"), hexc("4a8a4a")]
    c = 33
    # Layers of needle tufts, a star seen from above.
    for layer, r in enumerate((30, 22, 14, 7)):
        for k in range(10):
            a = k * math.tau / 10 + layer * 0.3
            img.poly([(c, c), (c + math.cos(a - 0.22) * r * 0.7, c + math.sin(a - 0.22) * r * 0.7),
                      (c + math.cos(a) * r, c + math.sin(a) * r), (c + math.cos(a + 0.22) * r * 0.7, c + math.sin(a + 0.22) * r * 0.7)],
                     greens[min(layer, 3)])
    for yy in range(66):
        for xx in range(66):
            col = img.get(xx, yy)
            if col[3]:
                img.set(xx, yy, shade(col, -((xx - c) + (yy - c)) / 140.0 + rng.uniform(-0.04, 0.04)))
    img.circle(c, c, 2, hexc("5a3a20"))
    img.outline()
    img.save("apt_pine.png")


def stump():
    img = framed(28, 26)
    c = (14.5, 13.5)
    img.circle(*c, 12, hexc("6a4a2a"), 11)
    img.circle(*c, 9.5, hexc("c8a070"), 8.5)
    for r in (7, 4.5, 2):
        for k in range(int(r * 8)):
            a = k * math.tau / (r * 8)
            img.set(c[0] + math.cos(a) * r, c[1] + math.sin(a) * r * 0.9, hexc("a8804a"))
    img.line(c[0], c[1], c[0] + 6, c[1] - 5, hexc("8a6a3a"))
    img.outline()
    img.save("apt_stump.png")


def fern():
    rng = random.Random(23)
    img = framed(40, 34)
    c = (20.5, 17.5)
    for k in range(7):
        a = k * math.tau / 7 + rng.uniform(-0.2, 0.2)
        for i in range(16):
            x = c[0] + math.cos(a) * i
            y = c[1] + math.sin(a) * i * 0.8
            g = LEAF_GREENS[1 + (i % 3 == 0)]
            img.set(x, y, g)
            side = (math.cos(a + math.pi / 2), math.sin(a + math.pi / 2))
            ln = 3.5 * (1 - i / 16) + 0.6
            img.line(x, y, x + side[0] * ln, y + side[1] * ln, LEAF_GREENS[2])
            img.line(x, y, x - side[0] * ln, y - side[1] * ln, LEAF_GREENS[1])
    img.outline()
    img.save("apt_fern.png")


def log():
    rng = random.Random(24)
    img = framed(70, 18)
    bark = hexc("5a3a22")
    img.rect(5, 2, 60, 14, wood_fill(rng, bark))
    img.bevel(5, 2, 60, 14, 0.25)
    for _ in range(14):
        x = rng.randint(7, 62)
        img.line(x, 3, x + rng.randint(2, 6), 3, shade(bark, -0.3))
    img.circle(5, 9, 6.5, hexc("c8a070"), 7)
    img.circle(5, 9, 4, hexc("a8804a"), 4.5)
    for _ in range(6):
        img.set(rng.randint(10, 60), rng.randint(3, 6), MOSS)
    img.outline()
    img.save("apt_log.png")


def mushrooms():
    rng = random.Random(25)
    img = framed(26, 20)
    for _ in range(4):
        x, y = rng.randint(5, 21), rng.randint(8, 15)
        img.rect(x, y, 2, 4, hexc("f0e8d8"))
        img.circle(x + 1, y, 4, hexc("d9534f"), 3)
        img.set(x - 1, y - 1, hexc("ffffff"))
        img.set(x + 2, y, hexc("ffffff"))
    img.outline()
    img.save("apt_mushrooms.png")


def anthill():
    rng = random.Random(26)
    img = framed(32, 24)
    img.circle(16, 12, 15, speckle(rng, hexc("7a5a3a"), 0.15, 0.8), 11)
    img.round_shade(16, 12, 14, 0.25)
    img.circle(16, 10, 2.5, hexc("2a1a10"))
    for _ in range(8):
        img.set(rng.randint(4, 28), rng.randint(3, 21), hexc("1a1210"))
    img.outline()
    img.save("apt_anthill.png")


def tent():
    img = framed(54, 44)
    o = 1
    canvas = hexc("3f7a8a")
    img.poly([(o, o + 42), (o + 27, o), (o + 54, o + 42)], canvas)
    img.poly([(o, o + 42), (o + 27, o), (o + 27, o + 42)], shade(canvas, 0.15))
    img.poly([(o + 20, o + 42), (o + 27, o + 20), (o + 34, o + 42)], hexc("1a2a2e"))
    img.line(o + 27, o, o + 27, o + 42, shade(canvas, -0.3))
    img.outline()
    img.save("apt_tent.png")


def traffic_cone():
    img = framed(16, 16)
    c = 8.5
    img.rect(1, 1, 16, 16, hexc("2a2a2e"))
    img.circle(c, c, 7, hexc("f08a2a"))
    img.circle(c, c, 4.5, hexc("f4f1ea"))
    img.circle(c, c, 2.5, hexc("f08a2a"))
    img.set(c - 1, c - 1, hexc("ffd0a0"))
    img.outline()
    img.save("apt_traffic_cone.png")


def brick_pallet():
    rng = random.Random(30)
    img = framed(40, 34)
    img.rect(1, 1, 40, 34, wood_fill(rng, hexc("b08a5a")))
    for row in range(5):
        off = 0 if row % 2 else 4
        for x0 in range(2 + off, 38, 9):
            img.rect(x0, 3 + row * 6, 8, 5, shade(hexc("b8503a"), rng.uniform(-0.1, 0.06)))
            img.bevel(x0, 3 + row * 6, 8, 5, 0.25)
    img.outline()
    img.save("apt_brick_pallet.png")


def sand_pile():
    rng = random.Random(31)
    img = framed(48, 36)
    img.circle(24, 18, 23, hexc("d8c08a"), 17)
    for yy in range(38):
        for xx in range(50):
            col = img.get(xx, yy)
            if col[3]:
                d = math.hypot((xx - 20) / 23, (yy - 14) / 17)
                img.set(xx, yy, shade(col, 0.15 - d * 0.3 + rng.uniform(-0.04, 0.04)))
    img.line(30, 8, 40, 2, hexc("6a4428"))
    img.poly([(39, 0), (45, 2), (42, 6)], hexc("8a9096"))
    img.outline()
    img.save("apt_sand_pile.png")


def cement_bags():
    rng = random.Random(32)
    img = framed(44, 30)
    for (x, y) in ((2, 2), (22, 2), (12, 14)):
        img.rect(x, y, 18, 13, shade(hexc("d8d0c0"), rng.uniform(-0.06, 0.03)))
        img.bevel(x, y, 18, 13, 0.25)
        img.rect(x + 4, y + 4, 10, 4, hexc("4a6a9a"))
    img.outline()
    img.save("apt_cement_bags.png")


def rebar():
    img = framed(56, 22)
    for k in range(6):
        y = 3 + k * 3
        for x in range(2, 54):
            img.set(x, y + (1 if (x // 3) % 2 else 0) * 0, RUST if x % 3 else shade(RUST, -0.25))
    for x in (8, 46):
        img.rect(x, 2, 2, 18, hexc("4a4a52"))
    img.outline()
    img.save("apt_rebar.png")


def toolbox():
    img = framed(26, 16)
    img.rect(1, 3, 26, 13, hexc("c0392b"))
    img.bevel(1, 3, 26, 13, 0.3)
    img.rect(9, 0, 10, 3, hexc("3a3a40"))
    img.rect(1, 8, 26, 1, hexc("8a2a20"))
    img.rect(12, 7, 4, 3, hexc("c9ced2"))
    img.outline()
    img.save("apt_toolbox.png")


def portable_toilet():
    img = framed(28, 32)
    img.rect(1, 1, 28, 32, hexc("3a7ac8"))
    img.bevel(1, 1, 28, 32, 0.25)
    img.rect(5, 5, 20, 24, hexc("2a6ab8"))
    img.circle(15, 15, 4, hexc("e8f0f4"))
    img.rect(13, 22, 4, 2, hexc("2a2a2e"))
    img.outline()
    img.save("apt_portable_toilet.png")


def pipe_stack():
    img = framed(60, 32)
    for row, n in ((0, 5), (1, 4)):
        for i in range(n):
            cx = 7 + i * 12 + row * 6
            cy = 24 - row * 11
            img.circle(cx, cy, 6, hexc("8a9096"))
            img.round_shade(cx, cy, 6, 0.35)
            img.circle(cx, cy, 3.5, hexc("2a2a2e"))
    img.outline()
    img.save("apt_pipe_stack.png")


def cement_mixer():
    img = framed(42, 36)
    img.rect(3, 26, 36, 8, hexc("4a4e54"))
    img.bevel(3, 26, 36, 8, 0.3)
    for x in (8, 34):
        img.circle(x, 34, 3, hexc("1a1a1e"))
    img.circle(21, 15, 13, hexc("f08a2a"), 12)
    img.round_shade(21, 15, 13, 0.3)
    for k in range(5):
        img.line(12 + k * 4, 5, 10 + k * 4, 25, shade(hexc("f08a2a"), -0.25))
    img.circle(25, 9, 4, hexc("3a3a40"))
    img.outline()
    img.save("apt_cement_mixer.png")


def cable_drum():
    rng = random.Random(36)
    img = framed(32, 32)
    c = 16.5
    img.circle(c, c, 15, wood_fill(rng, hexc("b08a5a"), False))
    img.round_shade(c, c, 15, 0.25)
    for r in (11, 8):
        for k in range(int(r * 8)):
            a = k * math.tau / (r * 8)
            img.set(c + math.cos(a) * r, c + math.sin(a) * r, hexc("2a2a2e"))
    img.circle(c, c, 4, hexc("6a4428"))
    img.outline()
    img.save("apt_cable_drum.png")


def coal_pile():
    rng = random.Random(40)
    img = framed(46, 32)
    img.circle(23, 17, 22, hexc("2a2a2e"), 15)
    for _ in range(80):
        x, y = rng.randint(4, 44), rng.randint(4, 30)
        if img.get(x, y)[3]:
            img.circle(x, y, rng.uniform(1.5, 3), shade(hexc("3a3a40"), rng.uniform(-0.2, 0.25)))
            img.set(x - 1, y - 1, hexc("6a6a74"))
    img.outline()
    img.save("apt_coal_pile.png")


def switch_lever():
    img = framed(22, 26)
    img.rect(3, 16, 16, 9, hexc("4a4e54"))
    img.bevel(3, 16, 16, 9, 0.3)
    img.line(11, 18, 16, 3, hexc("8a9096"))
    img.line(12, 18, 17, 3, hexc("c9ced2"))
    img.circle(17, 3, 2.5, hexc("c0392b"))
    img.rect(2, 22, 18, 2, hexc("e8c02a"))
    img.outline()
    img.save("apt_switch_lever.png")


def container():
    rng = random.Random(42)
    img = framed(110, 44)
    col = hexc(rng.choice(["c0392b", "2f6f9a", "2f8a5a"]))
    img.rect(1, 1, 110, 44, col)
    for x in range(3, 108, 4):
        img.rect(x, 3, 2, 40, shade(col, -0.2))
        img.rect(x + 2, 3, 1, 40, shade(col, 0.15))
    img.bevel(1, 1, 110, 44, 0.25)
    for (x, y) in ((2, 2), (106, 2), (2, 40), (106, 40)):
        img.rect(x, y, 4, 4, hexc("3a3a40"))
    img.rect(40, 18, 30, 8, hexc("f4f1ea"))
    img.rect(43, 20, 24, 4, shade(col, -0.1))
    img.outline()
    img.save("apt_container.png")


def lamps():
    lamp_head("sewer_lamp", hexc("3a4a3a"), glass="d8f0a0", size=16, square=True)
    lamp_head("site_lamp", hexc("e8c02a"), glass="ffffff", size=18, square=True)
    lamp_head("yard_lamp", hexc("4a4e54"), glass="fff0c0", size=18)


def items():
    img = framed(8, 10)
    img.circle(5, 6, 3.5, hexc("8a5a34"), 4.5)
    for y in range(2, 11, 2):
        img.line(2, y, 8, y + 1, hexc("6a4428"))
    img.outline()
    img.save("apt_item_pinecone.png")

    img = framed(8, 8)
    img.rect(4, 4, 2, 4, hexc("f0e8d8"))
    img.circle(5, 4, 3.5, hexc("c88a4a"), 2.5)
    img.set(4, 3, hexc("f0d0a0"))
    img.outline()
    img.save("apt_item_mushroom_small.png")

    img = framed(12, 4)
    img.rect(1, 2, 10, 1, hexc("9aa0a6"))
    img.rect(1, 1, 2, 3, hexc("c9ced2"))
    img.outline()
    img.save("apt_item_nail.png")

    img = framed(10, 6)
    img.rect(1, 1, 9, 5, hexc("b8503a"))
    img.bevel(1, 1, 9, 5, 0.3)
    img.outline()
    img.save("apt_item_brick_bit.png")

    img = framed(6, 6)
    img.circle(3.5, 3.5, 3, hexc("2a2a2e"))
    img.set(2, 2, hexc("6a6a74"))
    img.outline()
    img.save("apt_item_coal_bit.png")


# --- terrain, crane, freight --------------------------------------------------------------

def fence():
    """A board fence with a scaffold rail on top, seen from above."""
    rng = random.Random(50)
    W = 64
    img = Tile(W, THICK)
    wood = hexc("b08a5a")
    for x0 in range(0, W, 8):
        tone = shade(wood, rng.uniform(-0.12, 0.05))
        for y in range(THICK):
            for x in range(x0, x0 + 7):
                img.set(x, y, shade(tone, rng.uniform(-0.04, 0.04)))
        for y in range(THICK):
            img.set(x0 + 7, y, hexc("4a3020"))
    for y in (7, 14):
        for x in range(W):
            img.set(x, y, hexc("8a9096"))
            img.set(x, y + 1, hexc("5a5e62"))
    for x in range(0, W, 32):
        for y in range(THICK):
            img.set(x, y, hexc("e8c02a") if (y // 3) % 2 else hexc("2a2a2a"))
            img.set(x + 1, y, hexc("e8c02a") if (y // 3) % 2 else hexc("2a2a2a"))
    for x in range(W):
        img.set(x, 0, shade(img.get(x, 0), 0.15))
        img.set(x, THICK - 1, shade(img.get(x, THICK - 1), -0.35))
    save_pair(img, "fence")


def wagons():
    """Parked freight wagons from above, in rows 64 apart (as the shelves)."""
    rng = random.Random(51)
    W, H = 256, 128
    img = Tile(W, H)
    img.rect(0, 0, W, H, speckle(rng, hexc("6e665c"), 0.12, 0.7))
    for ry in range(0, H, 64):
        x = 0
        while x < W:
            w = rng.choice((56, 72, 88))
            col = hexc(rng.choice(["8a3a2a", "3a5a7a", "5a6a3a", "7a6a4a", "4a4a52"]))
            y0 = ry + 6
            img.rect(x + 2, y0, w - 4, 50, col)
            for xx in range(x + 4, x + w - 4, 5):
                img.rect(xx, y0 + 2, 1, 46, shade(col, -0.2))
            img.bevel(x + 2, y0, w - 4, 50, 0.25)
            if rng.random() < 0.4:
                # An open hopper with coal.
                img.rect(x + 8, y0 + 8, w - 16, 34, hexc("2a2a2e"))
                for _ in range(30):
                    img.set(rng.randint(x + 9, x + w - 10), rng.randint(y0 + 9, y0 + 40), hexc("5a5a64"))
            img.rect(x, y0 + 22, 2, 6, hexc("2a2a2e"))
            x += w
    img.save("apt_terrain_wagons.png")


def canal(direction, name):
    """A sewer canal 72 high (as the belts): murky water between stone kerbs,
    ripples drifting the way the current runs."""
    rng = random.Random(52 + direction)
    W, H = 48, 72
    img = Tile(W, H)
    water = hexc("3a5a4a")
    for y in range(H):
        for x in range(W):
            img.set(x, y, shade(water, 0.04 * math.sin((x + y * 0.5) * 0.4) + rng.uniform(-0.02, 0.02)))
    for y in list(range(0, 6)) + list(range(H - 6, H)):
        for x in range(W):
            img.set(x, y, shade(hexc("7a746a"), (0.12 if y in (0, H - 6) else -0.3 if y in (5, H - 1) else rng.uniform(-0.05, 0.05))))
    for k in range(4):
        y = 14 + k * 14
        for i in range(10):
            x = (8 + k * 11 + i * direction) % W
            img.set(x, y + (1 if i % 3 == 0 else 0), hexc("8aa898"))
        img.set((8 + k * 11 + 10 * direction) % W, y, hexc("c8d8c8"))
    img.save("apt_terrain_%s.png" % name)


def sewage():
    rng = random.Random(55)
    S = 64
    img = Tile(S, S)
    base = hexc("5a5a3a")
    for y in range(S):
        for x in range(S):
            img.set(x, y, shade(base, 0.06 * math.sin(x * 0.3 + y * 0.2) + rng.uniform(-0.03, 0.03)))
    for _ in range(14):
        x, y = rng.randrange(S), rng.randrange(S)
        for i in range(6):
            img.set(x + i, y, hexc("a8a878"))
    img.save("apt_terrain_sewage.png")


def crane_loads():
    rng = random.Random(56)
    img = framed(44, 34)
    for row in range(4):
        off = 0 if row % 2 else 5
        for x0 in range(2 + off, 42, 10):
            img.rect(x0, 2 + row * 8, 9, 7, shade(hexc("b8503a"), rng.uniform(-0.1, 0.06)))
            img.bevel(x0, 2 + row * 8, 9, 7, 0.25)
    img.outline()
    img.save("apt_crane_load_bricks.png")

    img = framed(50, 30)
    for i in range(4):
        y = 4 + i * 7
        img.rect(2, y, 46, 6, hexc("8a9096"))
        img.rect(2, y, 46, 1, hexc("c9ced2"))
        img.circle(3, y + 3, 3, hexc("2a2a2e"))
    img.rect(14, 1, 3, 29, hexc("e8c02a"))
    img.rect(34, 1, 3, 29, hexc("e8c02a"))
    img.outline()
    img.save("apt_crane_load_pipes.png")

    img = framed(36, 36)
    box_crate(img, rng, 1, 1, 36, 36, hexc("9a7048"))
    img.outline()
    img.save("apt_crane_load_crate.png")


def freight():
    rng = random.Random(57)
    W, H = 112, 64
    img = framed(W, H)
    col = hexc("6a4a3a")
    img.rect(1, 1, W, H, col)
    for x in range(4, W - 2, 6):
        img.rect(x, 3, 2, H - 4, shade(col, -0.22))
        img.rect(x + 2, 3, 1, H - 4, shade(col, 0.12))
    img.bevel(1, 1, W, H, 0.25)
    img.rect(20, 10, W - 40, H - 18, hexc("2a2a2e"))
    for _ in range(60):
        img.circle(rng.randint(22, W - 22), rng.randint(12, H - 10), rng.uniform(1.5, 3), shade(hexc("3a3a40"), rng.uniform(-0.2, 0.3)))
    for (x, y) in ((2, 2), (W - 3, 2), (2, H - 3), (W - 3, H - 3)):
        img.rect(x, y, 3, 3, hexc("e8c02a"))
    img.outline()
    img.save("apt_train_freight.png")


def main():
    os.makedirs(OUT, exist_ok=True)
    for fn in (sewer_bricks, sewer_grating, sewer_sludge, forest_floor, forest_moss, forest_clearing,
               site_dirt, site_slab, site_yard, yard_ballast, yard_rails, yard_dock,
               valve, sewer_grate, rubber_duck, sewer_ladder, mushrooms_glow, pine, stump, fern, log, mushrooms,
               anthill, tent, traffic_cone, brick_pallet, sand_pile, cement_bags, rebar, toolbox, portable_toilet,
               pipe_stack, cement_mixer, cable_drum, coal_pile, switch_lever, container, lamps, items,
               fence, wagons, sewage, crane_loads, freight):
        fn()
    canal(1, "canal_r")
    canal(-1, "canal_l")
    print("district 1 art written to", OUT)


if __name__ == "__main__":
    main()
