"""Pixel art for the map terrain (scripts/world/terrain.gd): roof parapets
and station walls, supermarket shelves, the tide's water and the factory's
conveyor belts. Each picture tiles along the obstacle.

    python tools/gen_terrain.py

Writes assets/sprites/apt_terrain_*.png. Afterwards run the Godot import.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_apartment import Img, speckle  # noqa: E402
from gen_outdoor import Tile  # noqa: E402
from gen_sprites import OUT, hexc, shade  # noqa: E402

THICK = 22


def turned(img):
    """The same picture turned a quarter, for walls running up and down."""
    out = Tile(img.h, img.w)
    for y in range(img.h):
        for x in range(img.w):
            out.set(img.h - 1 - y, x, img.get(x, y))
    return out


def save_pair(img, name):
    img.save("apt_terrain_%s_h.png" % name)
    turned(img).save("apt_terrain_%s_v.png" % name)


def parapet():
    """A brick parapet seen from above: a stone coping in the middle, the
    brick courses showing on both sides, light from the top left."""
    rng = random.Random(1)
    W = 72
    img = Tile(W, THICK)
    brick = hexc("a8503a")
    for row, (y0, h) in enumerate(((0, 6), (16, 6))):
        off = 0 if row else 9
        for x0 in range(-18, W, 18):
            tone = shade(brick, rng.uniform(-0.12, 0.06))
            for y in range(y0, y0 + h):
                for x in range(x0 + off, x0 + off + 17):
                    img.set(x, y, shade(tone, rng.uniform(-0.04, 0.04)))
            for y in range(y0, y0 + h):
                img.set(x0 + off + 17, y, hexc("c8b8a0"))
        for x in range(W):
            img.set(x, y0 + h - 1, shade(img.get(x, y0 + h - 1), -0.2))
    coping = hexc("c9c4bc")
    for y in range(6, 16):
        for x in range(W):
            k = 0.12 if y == 6 else -0.25 if y == 15 else rng.uniform(-0.04, 0.04)
            img.set(x, y, shade(coping, k))
    for x in range(0, W, 24):
        for y in range(6, 16):
            img.set(x, y, shade(coping, -0.3))
            img.set(x + 1, y, shade(coping, 0.1))
    for x in range(W):
        img.set(x, 0, shade(img.get(x, 0), 0.15))
        img.set(x, THICK - 1, shade(img.get(x, THICK - 1), -0.35))
    for _ in range(6):
        img.set(rng.randrange(W), rng.randint(7, 14), hexc("6a8a4a"))
    save_pair(img, "parapet")


def station_wall():
    """Station partition: cream tiles with a blue stripe and a steel cap."""
    rng = random.Random(2)
    W = 64
    img = Tile(W, THICK)
    tile = hexc("e2dccb")
    for y in range(THICK):
        for x in range(W):
            c = tile
            if 9 <= y <= 12:
                c = hexc("2f5f8f")
            if x % 16 == 0 or y in (0, 8, 13, THICK - 1):
                c = shade(c, -0.25)
            img.set(x, y, shade(c, rng.uniform(-0.03, 0.03)))
    for x in range(W):
        img.set(x, 1, shade(img.get(x, 1), 0.2))
        img.set(x, THICK - 2, shade(img.get(x, THICK - 2), -0.2))
    for x in range(4, W, 16):
        img.set(x, 4, hexc("ffffff"))
    save_pair(img, "station_wall")


PRODUCTS = ["d9534f", "f2d14e", "5aa96a", "4a8ac4", "f08a2a", "9a5ad8", "f4f1ea", "8a5a3b", "e88aa8", "3f6b8a"]


def shelves():
    """Shelf units seen from above, rows 64 apart (as terrain.gd): goods of
    every colour on a grey steel shelf, a shelf edge at the bottom of a row."""
    rng = random.Random(3)
    W, H = 240, 128
    img = Tile(W, H)
    steel = hexc("6d7480")
    img.rect(0, 0, W, H, speckle(rng, steel, 0.04, 0.4))
    for ry in range(0, H, 64):
        # Shelf front edge with price strips.
        for x in range(W):
            for y in range(ry + 50, ry + 58):
                img.set(x, y, hexc("4a505a") if y > ry + 51 else hexc("8a929e"))
            if (x // 20) % 2 == 0:
                img.set(x, ry + 53, hexc("f2d14e"))
                img.set(x, ry + 54, hexc("f2d14e"))
        for y in range(ry + 58, ry + 64):
            for x in range(W):
                img.set(x, y, shade(steel, -0.35 + (y - ry - 58) * 0.05))
        x = 2
        while x < W - 2:
            kind = rng.random()
            col = hexc(rng.choice(PRODUCTS))
            if kind < 0.12:
                x += rng.randint(6, 14)
                continue
            if kind < 0.55:
                # A row of boxes.
                w, h = rng.randint(10, 18), rng.randint(20, 40)
                y0 = ry + 50 - h
                img.rect(x, y0, w, h, col)
                for yy in range(y0, y0 + h):
                    img.set(x, yy, shade(col, 0.25))
                    img.set(x + w - 1, yy, shade(col, -0.35))
                for xx in range(x, x + w):
                    img.set(xx, y0, shade(col, 0.35))
                img.rect(x + 2, y0 + 4, w - 4, 4, hexc("f4f1ea"))
                img.rect(x + 3, y0 + 5, max(w - 8, 1), 2, shade(col, -0.2))
                x += w + 1
            else:
                # Cans or bottles, round from above, in a block.
                r = rng.choice((3, 4, 5))
                cols = rng.randint(2, 4)
                rows = rng.randint(3, 5)
                for i in range(cols):
                    for j in range(rows):
                        cx = x + r + i * (2 * r + 1)
                        cy = ry + 48 - r - j * (2 * r + 1)
                        if cy - r < ry + 2:
                            continue
                        img.circle(cx, cy, r, col)
                        img.set(cx - 1, cy - 1, shade(col, 0.45))
                        img.set(cx + r - 1, cy + 1, shade(col, -0.35))
                x += cols * (2 * r + 1) + 2
    img.save("apt_terrain_shelves.png")


def water():
    rng = random.Random(4)
    S = 96
    img = Tile(S, S)
    base = hexc("2a6aa8", 228)
    for y in range(S):
        for x in range(S):
            k = 0.05 * math.sin(x * math.tau / S * 2 + math.sin(y * math.tau / S) * 1.5) + 0.04 * math.sin(y * math.tau / S * 3)
            img.set(x, y, shade(base, k + rng.uniform(-0.015, 0.015)))
    # Light ripples: short wavy dashes.
    for _ in range(26):
        x, y = rng.randrange(S), rng.randrange(S)
        n = rng.randint(4, 10)
        for i in range(n):
            yy = y + round(math.sin(i * 0.8) * 1)
            img.set(x + i, yy, hexc("8fc8f0", 235))
            img.set(x + i, yy + 1, hexc("1f5a90", 230))
    for _ in range(14):
        img.set(rng.randrange(S), rng.randrange(S), hexc("e8f6ff", 240))
    img.save("apt_terrain_water.png")


def belt(direction, name):
    """A conveyor belt across, 72 tall (as terrain.gd): yellow rails, dark
    rubber with cross ribs and painted chevrons pointing `direction`."""
    W, H = 48, 72
    img = Tile(W, H)
    rubber = hexc("3a3d44")
    for y in range(H):
        for x in range(W):
            c = rubber
            if x % 8 == 0:
                c = shade(rubber, -0.3)
            elif x % 8 == 1:
                c = shade(rubber, 0.12)
            img.set(x, y, c)
    for y in list(range(0, 6)) + list(range(H - 6, H)):
        for x in range(W):
            stripe = ((x + y) // 6) % 2 == 0
            img.set(x, y, hexc("e0b53a") if stripe else hexc("2a2a2a"))
        if y in (0, H - 6):
            for x in range(W):
                img.set(x, y, shade(img.get(x, y), 0.25))
        if y in (5, H - 1):
            for x in range(W):
                img.set(x, y, shade(img.get(x, y), -0.35))
    mid = H // 2
    tip = 30 if direction > 0 else 18
    back = 18 if direction > 0 else 30
    for k in range(-14, 15):
        x = back + (tip - back) * (1 - abs(k) / 14.0)
        for w in range(4):
            img.set(x + w * (1 if direction > 0 else -1) - (2 if direction > 0 else -2), mid + k, hexc("b8bcc4"))
        img.set(x - (3 if direction > 0 else -3), mid + k, hexc("6a6e76"))
    img.save("apt_terrain_%s.png" % name)


def main():
    os.makedirs(OUT, exist_ok=True)
    parapet()
    station_wall()
    shelves()
    water()
    belt(1, "belt_r")
    belt(-1, "belt_l")
    print("terrain art written to", OUT)


if __name__ == "__main__":
    main()
