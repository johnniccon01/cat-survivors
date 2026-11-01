"""Pixel art for the basement (map Pivnica), in the style of the apartment
(tools/gen_apartment.py): one pixel = one world unit, light from the top
left, a dark outline.

    python tools/gen_basement.py

Writes assets/sprites/apt_*.png (the floor loader's prefix; the names don't
clash with the apartment's). Afterwards run the Godot import.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_apartment import FABRICS, Img, framed, speckle, wood_fill  # noqa: E402
from gen_sprites import OUT, OUTLINE, hexc, shade  # noqa: E402

METAL = hexc("8a9096")
RUST = hexc("9a5a3a")
WOOD_OLD = hexc("7a6048")


# --- floors ------------------------------------------------------------------

def floor_concrete():
    rng = random.Random(41)
    img = Img(128, 128)
    base = hexc("6e6a66")
    img.rect(0, 0, 128, 128, speckle(rng, base, 0.07, 0.6))
    # Big poured slabs with a seam, a few cracks and old stains.
    for i in range(128):
        img.set(i, 0, shade(base, -0.25))
        img.set(0, i, shade(base, -0.25))
        img.set(i, 1, shade(base, 0.1))
    for _ in range(3):
        x, y = rng.randint(10, 118), rng.randint(10, 118)
        for _ in range(rng.randint(10, 24)):
            img.set(x % 128, y % 128, shade(base, -0.35))
            x += rng.choice((-1, 0, 1, 1))
            y += rng.choice((0, 1, 1))
    for _ in range(2):
        cx, cy, r = rng.randint(20, 108), rng.randint(20, 108), rng.randint(6, 12)
        for yy in range(cy - r, cy + r):
            for xx in range(cx - r, cx + r):
                if (xx - cx) ** 2 + (yy - cy) ** 2 * 1.4 < r * r and rng.random() < 0.8:
                    img.set(xx % 128, yy % 128, shade(img.get(xx % 128, yy % 128), -0.12))
    img.save("apt_floor_concrete.png")


def floor_laundry():
    rng = random.Random(42)
    img = Img(48, 48)
    for ty in range(3):
        for tx in range(3):
            base = hexc("d6dadc") if (tx + ty) % 2 == 0 else hexc("c4cacd")
            x0, y0 = tx * 16, ty * 16
            img.rect(x0, y0, 16, 16, speckle(rng, base, 0.04, 0.3))
            img.bevel(x0 + 1, y0 + 1, 14, 14, 0.1)
            for i in range(16):
                img.set(x0 + i, y0, hexc("8a9396"))
                img.set(x0, y0 + i, hexc("8a9396"))
    img.save("apt_floor_laundry.png")


def floor_boards():
    rng = random.Random(43)
    img = Img(160, 60)
    for row in range(3):
        y0 = row * 20
        offset = [0, 60, 30][row]
        for k in range(-1, 3):
            x0 = offset + k * 80
            tone = shade(WOOD_OLD, rng.uniform(-0.14, 0.04))
            for y in range(y0, y0 + 20):
                for x in range(x0, x0 + 80):
                    c = shade(tone, rng.uniform(-0.05, 0.05) + (0.04 if (x * 3 + y * 7) % 19 == 0 else 0))
                    img.set(x % 160, y, c)
            for y in range(y0, y0 + 20):
                img.set(x0 % 160, y, shade(tone, -0.5))
            for x in range(x0, x0 + 80):
                img.set(x % 160, y0, shade(tone, 0.1))
                img.set(x % 160, y0 + 19, shade(tone, -0.45))
            # Nails at the ends and a dusty patch.
            for nx in (x0 + 3, x0 + 76):
                img.set(nx % 160, y0 + 5, hexc("3a3a3a"))
                img.set(nx % 160, y0 + 14, hexc("3a3a3a"))
            if rng.random() < 0.5:
                dx = x0 + rng.randint(10, 60)
                for i in range(14):
                    img.set((dx + i) % 160, y0 + rng.randint(4, 15), shade(tone, 0.18))
    img.save("apt_floor_boards.png")


# --- furniture ---------------------------------------------------------------

def boiler():
    rng = random.Random(44)
    img = framed(60, 76)
    o = 1
    img.rect(o, o, 60, 60, speckle(rng, METAL, 0.05, 0.4))
    img.bevel(o, o, 60, 60, 0.2)
    img.circle(o + 30, o + 30, 22, hexc("b0b5ba"))
    img.round_shade(o + 30, o + 30, 22, 0.3)
    for i in range(24):
        a = i * math.tau / 24
        img.set(o + 30 + math.cos(a) * 19, o + 30 + math.sin(a) * 19, hexc("8a9096"))
    # Gauge with a red needle, rivets, a pipe going down.
    img.circle(o + 40, o + 20, 6, hexc("e8e2d0"))
    img.line(o + 40, o + 20, o + 43, o + 17, hexc("e04646"))
    for (rx, ry) in ((4, 4), (55, 4), (4, 55), (55, 55)):
        img.set(o + rx, o + ry, shade(METAL, 0.4))
        img.set(o + rx + 1, o + ry + 1, shade(METAL, -0.4))
    img.rect(o + 26, o + 60, 8, 16, RUST)
    img.bevel(o + 26, o + 60, 8, 16, 0.2)
    img.rect(o + 24, o + 62, 12, 3, shade(RUST, -0.2))
    img.outline()
    img.save("apt_boiler.png")


def pipes():
    img = framed(180, 18)
    o = 1
    for k, base in enumerate((RUST, METAL)):
        y = o + 1 + k * 9
        img.rect(o, y, 180, 6, base)
        img.rect(o, y, 180, 1, shade(base, 0.35))
        img.rect(o, y + 5, 180, 1, shade(base, -0.35))
        for x in (30, 90, 150):
            img.rect(o + x - 3, y - 1, 6, 8, hexc("5a5e62"))
            img.rect(o + x - 3, y - 1, 6, 1, hexc("8a8f94"))
    # A drip of rust.
    img.rect(o + 60, o + 7, 1, 3, shade(RUST, -0.3))
    img.outline()
    img.save("apt_pipes.png")


def bike(fabric, n):
    img = framed(64, 30)
    o = 1
    tyre, rim = hexc("2a2a2e"), hexc("c9ced2")
    for wx in (o + 14, o + 50):
        img.circle(wx, o + 18, 11, tyre)
        img.circle(wx, o + 18, 9, CLEAR_OF(img))
        for i in range(16):
            a = i * math.tau / 16
            img.set(wx + math.cos(a) * 9, o + 18 + math.sin(a) * 9, rim)
        for i in range(6):
            a = i * math.tau / 6
            img.line(wx, o + 18, wx + math.cos(a) * 8, o + 18 + math.sin(a) * 8, shade(rim, -0.2))
    for (a, b) in (((14, 18), (28, 8)), ((28, 8), (44, 8)), ((44, 8), (50, 18)), ((28, 8), (32, 18)), ((32, 18), (14, 18))):
        img.line(o + a[0], o + a[1], o + b[0], o + b[1], fabric)
        img.line(o + a[0], o + a[1] + 1, o + b[0], o + b[1] + 1, shade(fabric, -0.25))
    img.rect(o + 24, o + 4, 8, 3, hexc("3a3a3a"))
    img.line(o + 44, o + 8, o + 46, o + 2, OUTLINE)
    img.rect(o + 42, o + 1, 8, 2, hexc("3a3a3a"))
    img.outline()
    img.save("apt_bike_%d.png" % n)


def CLEAR_OF(img):
    return (0, 0, 0, 0)


def shelf():
    rng = random.Random(45)
    img = framed(120, 28)
    o = 1
    img.rect(o, o, 120, 28, wood_fill(rng, WOOD_OLD))
    img.bevel(o, o, 120, 28, 0.2)
    img.rect(o + 2, o + 2, 116, 24, shade(WOOD_OLD, -0.4))
    x = o + 5
    while x < o + 112:
        roll = rng.random()
        if roll < 0.55:
            # A jar of preserves with a checked lid.
            c = hexc(rng.choice(["c0392b", "e08a2a", "7a3a8a", "5a8a3a", "d9b84a"]))
            img.circle(x + 4, o + 14, 4.5, c)
            img.round_shade(x + 4, o + 14, 4.5, 0.35)
            img.set(x + 3, o + 12, hexc("ffffff"))
            img.rect(x + 1, o + 8, 7, 2, hexc("e8e2d0"))
            img.set(x + 2, o + 8, hexc("c0392b"))
            img.set(x + 5, o + 8, hexc("c0392b"))
            x += 10
        elif roll < 0.8:
            # A paint can from above.
            img.circle(x + 5, o + 14, 5, hexc("c9ced2"))
            img.circle(x + 5, o + 14, 3, hexc(rng.choice(FABRICS)))
            x += 12
        else:
            # A toolbox.
            img.rect(x, o + 8, 14, 12, hexc("c0392b"))
            img.bevel(x, o + 8, 14, 12, 0.2)
            img.rect(x + 4, o + 6, 6, 2, hexc("3a3a3a"))
            x += 17
    img.outline()
    img.save("apt_shelf.png")


def crates():
    rng = random.Random(46)
    img = framed(68, 62)
    o = 1
    for (bx, by) in ((0, 0), (34, 0), (17, 32)):
        x0, y0 = o + bx, o + by
        img.rect(x0, y0, 32, 28, wood_fill(rng, hexc("9a7a4a")))
        img.bevel(x0, y0, 32, 28, 0.2)
        for k in range(1, 4):
            img.rect(x0, y0 + k * 7, 32, 1, shade(hexc("9a7a4a"), -0.35))
        img.line(x0 + 1, y0 + 1, x0 + 30, y0 + 26, shade(hexc("9a7a4a"), -0.3))
        # A stencilled mark.
        img.rect(x0 + 11, y0 + 10, 10, 1, hexc("3a2a1a"))
        img.rect(x0 + 15, y0 + 8, 2, 6, hexc("3a2a1a"))
    img.outline()
    img.save("apt_crates.png")


def covered_sofa():
    rng = random.Random(47)
    img = framed(116, 50)
    o = 1
    sheet = hexc("dcd6c8")
    img.poly([(o + 2, o + 4), (o + 114, o + 2), (o + 116, o + 48), (o, o + 50)], speckle(rng, sheet, 0.04, 0.4))
    img.bevel(o, o + 2, 116, 48, 0.15)
    # Folds of the dust sheet and the hint of cushions under it.
    for k, x in enumerate((24, 50, 78, 98)):
        img.line(o + x, o + 4, o + x + 6 + k, o + 47, shade(sheet, -0.16))
        img.line(o + x + 1, o + 4, o + x + 7 + k, o + 47, shade(sheet, 0.1))
    img.rect(o + 4, o + 12, 108, 1, shade(sheet, -0.12))
    for _ in range(30):
        img._shade(o + rng.randint(2, 112), o + rng.randint(3, 46), -0.1)
    img.outline()
    img.save("apt_covered_sofa.png")


def washer():
    img = framed(46, 46)
    o = 1
    body = hexc("eef1f3")
    img.rect(o, o, 46, 46, body)
    img.bevel(o, o, 46, 46, 0.2)
    img.rect(o, o, 46, 9, shade(body, -0.08))
    img.rect(o + 4, o + 3, 10, 3, hexc("5aa9e6"))
    img.circle(o + 36, o + 4, 2.5, hexc("8a9096"))
    img.circle(o + 23, o + 27, 15, hexc("9aa2a8"))
    img.circle(o + 23, o + 27, 12, hexc("6f8a9a"))
    img.round_shade(o + 23, o + 27, 12, 0.35)
    # Clothes tumbling behind the glass and a glint.
    img.circle(o + 19, o + 30, 4, hexc(FABRICS[0]))
    img.circle(o + 27, o + 25, 3, hexc(FABRICS[2]))
    img.line(o + 16, o + 20, o + 20, o + 18, hexc("ffffff"))
    img.outline()
    img.save("apt_washer.png")


def drying_rack():
    rng = random.Random(48)
    img = framed(82, 34)
    o = 1
    frame = hexc("c9ced2")
    img.rect(o, o, 82, 2, frame)
    img.rect(o, o + 31, 82, 2, frame)
    for y in range(o + 6, o + 30, 6):
        img.rect(o, y, 82, 1, shade(frame, -0.1))
    img.rect(o, o, 2, 33, frame)
    img.rect(o + 80, o, 2, 33, frame)
    # Hanging clothes: a shirt, socks, a towel.
    x = o + 6
    for i in range(5):
        c = hexc(FABRICS[(i * 2) % len(FABRICS)])
        w, h = rng.randint(8, 16), rng.randint(8, 20)
        y = o + 4 + rng.randint(0, 8)
        img.rect(x, y, w, h, shade(c, 0.2))
        img.bevel(x, y, w, h, 0.15)
        img.rect(x, y, w, 1, shade(c, 0.45))
        x += w + rng.randint(2, 5)
        if x > o + 70:
            break
    img.outline()
    img.save("apt_drying_rack.png")


def laundry_pile():
    rng = random.Random(49)
    img = framed(44, 28)
    o = 1
    for k in range(7):
        c = hexc(FABRICS[k % len(FABRICS)])
        cx, cy = o + 8 + rng.randint(0, 28), o + 7 + rng.randint(0, 14)
        img.circle(cx, cy, rng.randint(5, 9), shade(c, 0.2), rng.randint(4, 6))
        img.round_shade(cx, cy, 6, 0.25)
    img.rect(o + 14, o + 12, 10, 2, hexc("efe6d0"))
    img.outline()
    img.save("apt_laundry_pile.png")


def paint_cans():
    rng = random.Random(50)
    img = framed(34, 30)
    o = 1
    for (cx, cy) in ((9, 10), (24, 8), (16, 22)):
        c = hexc(rng.choice(FABRICS))
        img.circle(o + cx, o + cy, 7, hexc("c9ced2"))
        img.round_shade(o + cx, o + cy, 7, 0.3)
        img.circle(o + cx, o + cy, 4.5, c)
        img.set(o + cx - 2, o + cy - 2, shade(c, 0.4))
        # A drip down the side.
        img.rect(o + cx + 5, o + cy, 1, 3, c)
    img.outline()
    img.save("apt_paint_cans.png")


# --- floor clutter ------------------------------------------------------------

def item_bolt():
    img = framed(8, 8)
    o = 1
    img.poly([(o + 2, o), (o + 6, o), (o + 8, o + 4), (o + 6, o + 8), (o + 2, o + 8), (o, o + 4)], hexc("8a9096"))
    img.circle(o + 4, o + 4, 1.5, hexc("4a4e52"))
    img.set(o + 2, o + 1, hexc("d0d4d8"))
    img.outline()
    img.save("apt_item_bolt.png")


def item_jar():
    img = framed(10, 12)
    o = 1
    img.rect(o + 1, o + 3, 8, 9, hexc("a8c8a8"))
    img.round_shade(o + 5, o + 7, 4, 0.3)
    img.rect(o, o, 10, 3, hexc("c9a24a"))
    img.set(o + 2, o + 5, hexc("ffffff"))
    img.outline()
    img.save("apt_item_jar.png")


def item_rag(fabric, n):
    rng = random.Random(51 + n)
    img = framed(16, 12)
    o = 1
    img.poly([(o, o + 3), (o + 10, o), (o + 16, o + 6), (o + 8, o + 12), (o + 1, o + 9)], shade(fabric, -0.1))
    for _ in range(8):
        img._shade(o + rng.randint(1, 14), o + rng.randint(2, 10), -0.2)
    img.line(o + 3, o + 4, o + 12, o + 8, shade(fabric, 0.2))
    img.outline()
    img.save("apt_item_rag_%d.png" % n)


def main():
    os.makedirs(OUT, exist_ok=True)
    floor_concrete()
    floor_laundry()
    floor_boards()
    boiler()
    pipes()
    shelf()
    crates()
    covered_sofa()
    washer()
    drying_rack()
    laundry_pile()
    paint_cans()
    item_bolt()
    item_jar()
    for n, hexcode in enumerate(FABRICS):
        bike(hexc(hexcode), n)
        item_rag(hexc(hexcode), n)
    print("basement art written to", OUT)


if __name__ == "__main__":
    main()
