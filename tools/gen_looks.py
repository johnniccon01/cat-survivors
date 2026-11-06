"""Pixel art for the things quest steps put on the map (draw_look in
scripts/quests/chain_step.gd): items to carry, places to reach, buildings.
Every picture is centred on the thing's position; marks and effects
(paw prints, an X, the moon, fire, hints) stay drawn by the game.

    python tools/gen_looks.py

Writes assets/sprites/apt_look_*.png. Afterwards run the Godot import.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_apartment import FABRICS, framed, speckle, wood_fill  # noqa: E402
from gen_sprites import OUT, hexc, shade  # noqa: E402

WOOD = hexc("8a5a3b")
STEEL = hexc("9aa0a6")


class Look:
    """A picture whose middle is the look's position: (0, 0) maps to the
    centre, so shapes are given in the same numbers as the old drawing."""

    def __init__(self, name, w, h):
        self.name = name
        self.img = framed(w, h)
        self.cx = (w + 2) / 2
        self.cy = (h + 2) / 2

    def rect(self, x, y, w, h, c, bevel=0.0):
        self.img.rect(self.cx + x, self.cy + y, w, h, c)
        if bevel:
            self.img.bevel(self.cx + x, self.cy + y, w, h, bevel)

    def circle(self, x, y, r, c, ry=None, lit=0.0):
        self.img.circle(self.cx + x, self.cy + y, r, c, ry)
        if lit:
            self.img.round_shade(self.cx + x, self.cy + y, r, lit)

    def poly(self, pts, c):
        self.img.poly([(self.cx + x, self.cy + y) for (x, y) in pts], c)

    def line(self, x1, y1, x2, y2, c, w=1):
        for k in range(w):
            off = k - (w - 1) / 2
            if abs(x2 - x1) > abs(y2 - y1):
                self.img.line(self.cx + x1, self.cy + y1 + off, self.cx + x2, self.cy + y2 + off, c)
            else:
                self.img.line(self.cx + x1 + off, self.cy + y1, self.cx + x2 + off, self.cy + y2, c)

    def set(self, x, y, c):
        self.img.set(self.cx + x, self.cy + y, c)

    def save(self):
        self.img.outline()
        self.img.save("apt_look_%s.png" % self.name)


def small_items():
    lk = Look("key", 18, 10)
    lk.circle(-4, 0, 4, hexc("f2c14e"), lit=0.3)
    lk.circle(-4, 0, 1.5, hexc("8a6a2a"))
    lk.rect(0, -1, 8, 2, hexc("f2c14e"))
    lk.rect(5, 1, 1, 2, hexc("f2c14e"))
    lk.rect(7, 1, 1, 3, hexc("f2c14e"))
    lk.save()

    lk = Look("sock", 18, 20)
    lk.poly([(-3, -8), (3, -8), (3, 2), (8, 4), (8, 8), (-3, 8)], hexc("f4f1ea"))
    lk.rect(-3, -8, 6, 3, hexc("d9534f"))
    lk.rect(4, 5, 4, 3, hexc("d9534f"))
    lk.save()

    lk = Look("cocoon", 14, 22)
    lk.circle(0, 0, 6, hexc("eeeee6"), 10, lit=0.3)
    for k in range(4):
        lk.line(-5, -6 + k * 4, 5, -4 + k * 4, hexc("c8c8c0"))
    lk.save()

    lk = Look("gear", 26, 26)
    for k in range(8):
        a = k * math.tau / 8
        lk.circle(math.cos(a) * 9, math.sin(a) * 9, 2.6, STEEL)
    lk.circle(0, 0, 9, STEEL, lit=0.3)
    lk.circle(0, 0, 3, hexc("4a4e54"))
    lk.save()

    lk = Look("molehill", 26, 16)
    rng = random.Random(1)
    lk.circle(0, 0, 12, speckle(rng, hexc("5c4030"), 0.12, 0.7), 7, lit=0.3)
    lk.circle(0, -2, 5, hexc("33241a"), 2.5)
    lk.save()

    lk = Look("flower", 18, 22)
    lk.line(0, 2, 0, 10, hexc("4f8f3e"), 2)
    lk.circle(3, 7, 2.5, hexc("5ea84a"), 1.5)
    for k in range(5):
        a = k * math.tau / 5
        lk.circle(math.cos(a) * 4, math.sin(a) * 4 - 2, 3, hexc("e07aa0"))
    lk.circle(0, -2, 2, hexc("f2d14e"))
    lk.save()

    lk = Look("hat", 20, 14)
    lk.rect(-9, 0, 18, 3, hexc("5a4030"), 0.2)
    lk.rect(-5, -8, 10, 8, hexc("6b4a34"), 0.2)
    lk.rect(-5, -3, 10, 2, hexc("d9534f"))
    lk.save()

    lk = Look("scarf", 20, 18)
    lk.rect(-9, -4, 18, 4, hexc("d9534f"), 0.2)
    lk.rect(4, -1, 4, 9, hexc("d9534f"), 0.2)
    for x in range(-8, 9, 3):
        lk.set(x, -3, hexc("f4f1ea"))
    lk.save()

    lk = Look("pumpkin", 20, 24)
    lk.circle(0, 1, 9, hexc("ee8c33"), 7, lit=0.3)
    for x in (-4, 0, 4):
        lk.line(x, -5, x, 7, hexc("c86a20"))
    lk.rect(0, -10, 2, 5, hexc("5e9e4a"))
    lk.save()

    lk = Look("straw", 18, 18)
    for k in range(6):
        lk.line(-7 + k * 3, 6, -5 + k * 2, -7, hexc("d8b452") if k % 2 else hexc("ecc86a"))
    lk.rect(-6, 0, 12, 2, hexc("a8742a"))
    lk.save()

    lk = Look("button", 14, 14)
    lk.circle(0, 0, 5.5, hexc("4a4a58"), lit=0.35)
    for (x, y) in ((-1.5, -1.5), (1.5, -1.5), (-1.5, 1.5), (1.5, 1.5)):
        lk.set(x, y, hexc("1a1a22"))
    lk.save()

    lk = Look("fish", 26, 12)
    lk.circle(0, 0, 7, hexc("aab4be"), 3.5, lit=0.3)
    lk.poly([(6, 0), (11, -4), (11, 4)], hexc("8c96a0"))
    lk.set(-4, -1, hexc("1a1a1a"))
    lk.save()

    lk = Look("milk", 12, 18)
    lk.rect(-5, -6, 10, 14, hexc("f4f4f0"), 0.2)
    lk.poly([(-5, -6), (0, -9), (5, -6)], hexc("e0e0dc"))
    lk.rect(-5, -2, 10, 4, hexc("5a9ae6"))
    lk.save()

    lk = Look("ham", 20, 14)
    lk.circle(0, 0, 8, hexc("e08088"), 6, lit=0.3)
    lk.circle(5, 3, 2.5, hexc("f4f1ea"))
    lk.save()

    lk = Look("cheese", 18, 12)
    lk.poly([(-8, 5), (8, 5), (8, -2), (-8, -4)], hexc("f2c84e"))
    lk.rect(-8, 3, 16, 2, hexc("d8a83a"))
    for (x, y) in ((2, 1), (-4, 0), (5, -1)):
        lk.circle(x, y, 1.3, hexc("c8962a"))
    lk.save()

    lk = Look("sardines", 18, 12)
    lk.rect(-8, -5, 16, 10, hexc("8ca8b8"), 0.25)
    lk.rect(-6, -3, 12, 6, hexc("d9534f"))
    lk.rect(-5, -1, 10, 1, hexc("f4f1ea"))
    lk.save()

    lk = Look("bone", 22, 10)
    lk.rect(-7, -1.5, 14, 4, hexc("f4f0e4"))
    for (x, y) in ((-8, -2), (-8, 2), (8, -2), (8, 2)):
        lk.circle(x, y, 2.5, hexc("f4f0e4"))
    lk.save()

    lk = Look("sail", 16, 22)
    lk.poly([(-6, 8), (6, 8), (0, -10)], hexc("f4f1ea"))
    lk.line(0, -10, 0, 8, hexc("8a6a4a"))
    lk.save()

    lk = Look("wheel", 18, 18)
    for k in range(32):
        a = k * math.tau / 32
        lk.set(math.cos(a) * 7, math.sin(a) * 7, hexc("8a5a3b"))
        lk.set(math.cos(a) * 6, math.sin(a) * 6, hexc("6a4428"))
    for k in range(4):
        a = k * math.pi / 4
        lk.line(math.cos(a) * -7, math.sin(a) * -7, math.cos(a) * 7, math.sin(a) * 7, hexc("8a5a3b"))
    lk.circle(0, 0, 2, hexc("c9a24a"))
    lk.save()

    lk = Look("rope", 18, 18)
    for r in (7, 4.5, 2):
        for k in range(int(r * 8)):
            a = k * math.tau / (r * 8)
            lk.set(math.cos(a) * r, math.sin(a) * r, hexc("c9a26a") if k % 3 else hexc("a8844a"))
    lk.save()

    lk = Look("barrel", 20, 20)
    rng = random.Random(2)
    lk.circle(0, 0, 8.5, wood_fill(rng, WOOD, False), lit=0.3)
    for r in (8, 5):
        for k in range(int(r * 7)):
            a = k * math.tau / (r * 7)
            lk.set(math.cos(a) * r, math.sin(a) * r, hexc("4a4e54"))
    lk.save()

    for name, paper, mark in (("map_piece", "f0e4c0", "d9534f"), ("photo", "f4f1ea", "8ca8c0")):
        lk = Look(name, 16, 14)
        lk.rect(-7, -6, 14, 12, hexc(paper), 0.15)
        if name == "photo":
            lk.rect(-5, -4, 10, 7, hexc(mark))
            lk.circle(-1, -1, 2, hexc("f2d14e"))
        else:
            lk.line(-4, 2, 3, -3, hexc(mark))
            lk.line(-4, -3, 3, 2, hexc("8a7a5a"))
            lk.set(3, -3, hexc(mark))
        lk.save()

    lk = Look("letter", 18, 12)
    lk.rect(-8, -5, 16, 10, hexc("f4f1ea"), 0.15)
    lk.line(-8, -5, 0, 1, hexc("a8987a"))
    lk.line(0, 1, 8, -5, hexc("a8987a"))
    lk.circle(0, 1, 1.5, hexc("d9534f"))
    lk.save()

    lk = Look("ribbon", 16, 10)
    lk.poly([(-7, -3), (0, 0), (-7, 3)], hexc("e05a8a"))
    lk.poly([(7, -3), (0, 0), (7, 3)], hexc("c84a7a"))
    lk.circle(0, 0, 2, hexc("f07aa8"))
    lk.save()

    lk = Look("lantern", 12, 18)
    lk.rect(-5, -7, 10, 12, hexc("ffd86a"), 0.25)
    lk.rect(-5, -7, 10, 2, hexc("3a3a40"))
    lk.rect(-5, 4, 10, 2, hexc("3a3a40"))
    lk.rect(-1, -9, 2, 2, hexc("3a3a40"))
    lk.rect(-2, -4, 3, 5, hexc("fff6d0"))
    lk.save()

    lk = Look("bread", 20, 14)
    lk.circle(0, 0, 8.5, hexc("d8a052"), 5.5, lit=0.3)
    for x in (-4, 0, 4):
        lk.line(x - 1, -3, x + 1, 2, hexc("f0c880"))
    lk.save()

    lk = Look("candle", 10, 18)
    lk.rect(-3, -3, 6, 11, hexc("f4ecd4"), 0.25)
    lk.circle(0, -6, 2, hexc("ff9a2a"), 3)
    lk.set(0, -6, hexc("fff3c8"))
    lk.save()

    lk = Look("shovel", 28, 28)
    lk.line(-9, 9, 5, -5, hexc("8a5a34"), 2)
    lk.poly([(4, -4), (12, -12), (10, -2)], STEEL)
    lk.rect(-12, 9, 6, 2, hexc("3a3a40"))
    lk.save()

    lk = Look("bottle", 10, 18)
    lk.rect(-3, -3, 6, 10, hexc("6ab890"), 0.25)
    lk.rect(-1, -7, 2, 4, hexc("6ab890"))
    lk.rect(-1, -8, 2, 1, hexc("8a6a4a"))
    lk.rect(-2, 0, 4, 3, hexc("f4f1ea"))
    lk.save()

    lk = Look("suitcase", 20, 16)
    lk.rect(-8, -4, 16, 11, hexc("8a5a34"), 0.25)
    lk.rect(-3, -7, 6, 3, hexc("2a2a2e"))
    lk.rect(-8, 1, 16, 1, hexc("6a4428"))
    lk.rect(-6, -4, 1, 11, hexc("c9a24a"))
    lk.rect(5, -4, 1, 11, hexc("c9a24a"))
    lk.save()


def places():
    rng = random.Random(10)
    lk = Look("pantry", 54, 42)
    lk.rect(-26, -21, 52, 40, wood_fill(rng, hexc("8a5a3b")), 0.25)
    for y in (-14, -2, 10):
        lk.rect(-23, y, 46, 2, hexc("5a3a24"))
    for _ in range(14):
        x, y = rng.randint(-21, 17), rng.choice((-20, -8, 4))
        c = hexc(rng.choice(["d9534f", "f2d14e", "5aa96a", "f4f1ea", "4a8ac4"]))
        lk.rect(x, y, 4, 6, c, 0.2)
    lk.save()

    lk = Look("basket", 52, 34)
    lk.circle(0, 4, 24, hexc("c8a46a"), 15)
    for k in range(-22, 23, 4):
        lk.line(k, -8, k + 2, 16, hexc("a07a42"))
    lk.circle(0, 2, 18, hexc("5a3e22"), 9)
    lk.circle(0, 2, 16, hexc("7a5a32"), 7)
    lk.save()

    lk = Look("hole", 36, 24)
    lk.circle(0, 0, 16, hexc("6a5444"), 10)
    lk.circle(0, 1, 13, hexc("1a1210"), 8)
    for k in range(10):
        a = math.pi + k * math.pi / 10
        lk.set(math.cos(a) * 15, math.sin(a) * 9.5, hexc("8a7460"))
    lk.save()

    lk = Look("boiler", 34, 42)
    lk.rect(-16, -21, 32, 40, hexc("8a6a4a"), 0.25)
    lk.circle(0, -4, 9, hexc("c9ced2"), lit=0.3)
    lk.line(0, -4, 5, -9, hexc("d9534f"))
    lk.rect(-12, 8, 24, 8, hexc("3a2a22"))
    lk.rect(-10, 10, 20, 4, hexc("e86a2a"))
    lk.save()

    lk = Look("veggies", 52, 22)
    for k in range(3):
        x = -16 + k * 16
        lk.circle(x, 2, 7, hexc("5a3e2a"), 4)
        lk.circle(x, -2, 5, hexc("6ab04a"), lit=0.3)
        lk.circle(x, -2, 2, hexc("a8d870"))
    lk.save()

    lk = Look("beehive", 32, 42)
    for k in range(4):
        w = 14 - abs(k - 1.5) * 2
        lk.circle(0, -12 + k * 8, w, hexc("d8a64a"), 5, lit=0.25)
        lk.line(-w + 1, -8 + k * 8, w - 1, -8 + k * 8, hexc("a8742a"))
    lk.circle(0, 10, 3, hexc("2a1a10"))
    lk.save()

    lk = Look("pole", 28, 36)
    lk.rect(-1, -18, 3, 33, wood_fill(rng, hexc("6b4a34"), False))
    lk.rect(-12, -9, 25, 3, wood_fill(rng, hexc("6b4a34")))
    lk.save()

    lk = Look("chimney", 26, 26)
    lk.rect(-12, -12, 24, 24, hexc("a8503a"), 0.25)
    for y in range(-10, 12, 5):
        lk.rect(-12, y, 24, 1, hexc("c8b8a0"))
    lk.rect(-6, -6, 12, 12, hexc("1a1a1e"))
    lk.save()

    lk = Look("antenna", 32, 50)
    lk.rect(-1, -24, 2, 39, STEEL)
    for k in range(4):
        w = 12 - k * 2
        lk.rect(-w, -20 + k * 7, w * 2, 2, STEEL)
        lk.rect(-w, -20 + k * 7, w * 2, 1, hexc("d0d4d8"))
    lk.rect(-5, 12, 10, 4, hexc("4a4e54"), 0.3)
    lk.save()

    lk = Look("bin", 34, 30)
    lk.rect(-16, -10, 32, 24, hexc("4a6a54"), 0.25)
    lk.rect(-17, -13, 34, 5, hexc("3a5a44"), 0.25)
    for x in (-10, -4, 2, 8):
        lk.rect(x, -6, 2, 17, hexc("3a5a44"))
    lk.save()

    lk = Look("register", 42, 24)
    lk.rect(-20, -8, 40, 22, hexc("5a6a7a"), 0.25)
    lk.rect(-16, -11, 18, 7, hexc("2a3a4a"))
    lk.rect(-15, -10, 16, 4, hexc("8fe0a0"))
    for i in range(8):
        lk.rect(-16 + (i % 4) * 6, 0 + (i // 4) * 5, 4, 3, hexc("e8e4dc"))
    lk.rect(8, 0, 9, 10, hexc("c9a24a"), 0.3)
    lk.save()

    lk = Look("fuse", 22, 26)
    lk.rect(-10, -12, 20, 24, hexc("9aa0a6"), 0.3)
    lk.rect(-7, -9, 14, 18, hexc("3a3e44"))
    for i in range(3):
        lk.rect(-5 + i * 4, -6, 2, 8, hexc("f2c14e"))
    lk.poly([(2, 4), (-1, 8), (1, 8), (-2, 12), (4, 6), (1, 6), (3, 4)], hexc("f2d14e"))
    lk.save()

    lk = Look("doghouse", 50, 48)
    lk.rect(-21, -9, 42, 26, wood_fill(rng, hexc("c05a4a")), 0.25)
    lk.poly([(-24, -8), (0, -22), (24, -8)], hexc("6a4a3a"))
    lk.poly([(-24, -8), (0, -22), (0, -8)], hexc("8a6a5a"))
    lk.circle(0, 6, 7, hexc("2a1a14"), 9)
    lk.rect(-7, 6, 14, 11, hexc("2a1a14"))
    lk.rect(-6, -4, 12, 4, hexc("f4f1ea"))
    lk.save()

    lk = Look("boat", 72, 86)
    lk.poly([(-34, -6), (34, -6), (24, 12), (-24, 12)], hexc("8a5a3b"))
    lk.rect(-30, -6, 60, 3, hexc("d9534f"))
    lk.rect(-1, -40, 3, 34, hexc("6b4a34"))
    lk.poly([(2, -38), (26, -10), (2, -10)], hexc("f4f1ea"))
    lk.poly([(-2, -34), (-20, -10), (-2, -10)], hexc("e8e2d0"))
    lk.save()

    lk = Look("lighthouse", 30, 72)
    for y in range(-24, 21):
        t = (y + 24) / 44
        half = 7 + t * 5
        band = ((y + 24) // 8) % 2 == 1
        lk.rect(-half, y, half * 2, 1, hexc("d9534f") if band else hexc("f4f1ea"))
    lk.rect(-8, -32, 16, 8, hexc("f2d14e"), 0.3)
    lk.rect(-9, -34, 18, 2, hexc("2a2a2e"))
    lk.save()

    lk = Look("bowl", 34, 20)
    lk.circle(0, 0, 15.5, hexc("4a8ad8"), 8.5, lit=0.3)
    lk.circle(0, -1, 11, hexc("a8742a"), 5)
    for _ in range(8):
        lk.circle(rng.randint(-8, 8), rng.randint(-4, 2), 1.4, hexc("c8944a"))
    lk.save()

    lk = Look("crypt_door", 62, 50)
    lk.rect(-30, -29, 60, 47, speckle(rng, hexc("7a7a82"), 0.06, 0.5), 0.25)
    lk.rect(-14, -18, 28, 36, hexc("2a2a30"))
    lk.circle(0, -18, 14, hexc("2a2a30"))
    lk.rect(-1, -24, 2, 42, hexc("4a4a52"))
    lk.circle(5, 2, 1.5, hexc("c9a24a"))
    lk.save()

    lk = Look("grave", 40, 66)
    lk.circle(0, 6, 18, speckle(rng, hexc("5a4434"), 0.1, 0.6), 10)
    lk.rect(-9, -22, 18, 24, hexc("8a8a92"), 0.25)
    lk.circle(0, -22, 9, hexc("8a8a92"), lit=0.2)
    lk.rect(-1, -20, 2, 10, hexc("5a5a62"))
    lk.rect(-4, -17, 8, 2, hexc("5a5a62"))
    lk.save()

    lk = Look("raft", 56, 38)
    for i in range(5):
        lk.rect(-26 + i * 10.5, -18, 10, 36, wood_fill(rng, shade(WOOD, rng.uniform(-0.1, 0.05)), False), 0.2)
    for y in (-12, 10):
        lk.rect(-27, y, 54, 3, hexc("c9a26a"))
    lk.save()

    lk = Look("nest", 36, 24)
    lk.circle(0, 0, 16, hexc("a88a5a"), 10)
    for _ in range(36):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(8, 15)
        lk.line(math.cos(a) * d, math.sin(a) * d * 0.62, math.cos(a + 0.5) * d, math.sin(a + 0.5) * d * 0.62, shade(hexc("a88a5a"), rng.uniform(-0.25, 0.2)))
    for (x, y) in ((-6, -1), (0, -3), (6, -1), (-3, 3), (3, 3)):
        lk.circle(x, y, 2.6, hexc("dce8f0"), 2.1)
    lk.save()

    lk = Look("lost_found", 54, 46)
    lk.rect(-26, -14, 52, 34, wood_fill(rng, hexc("6a8aa8")), 0.25)
    lk.poly([(-28, -12), (0, -24), (28, -12)], hexc("3a4a5a"))
    lk.rect(-16, -6, 18, 12, hexc("8fd0f0"))
    lk.rect(-15, -5, 4, 4, hexc("ffffff"))
    lk.rect(8, -4, 12, 22, hexc("4a3a2a"))
    lk.rect(-22, 10, 26, 6, hexc("f2d14e"))
    lk.rect(-19, 12, 20, 2, hexc("2a2a2e"))
    lk.save()

    lk = Look("signal_light", 18, 60)
    lk.rect(-1, -6, 3, 26, STEEL)
    lk.rect(-8, -30, 16, 26, hexc("2a2a30"), 0.2)
    lk.circle(0, -24, 4, hexc("e24b4a"))
    lk.circle(0, -11, 4, hexc("2a5a3a"))
    lk.save()

    lk = Look("locomotive", 70, 34)
    lk.rect(-34, -17, 68, 31, hexc("c0392b"), 0.25)
    lk.rect(-30, -13, 60, 23, hexc("d04a3b"), 0.15)
    lk.rect(14, -12, 14, 22, hexc("2a3a4a"))
    lk.rect(16, -10, 10, 8, hexc("8fd0f0"))
    lk.rect(16, 0, 10, 8, hexc("8fd0f0"))
    lk.circle(-20, -2, 5, hexc("4a4e54"))
    lk.circle(-20, -2, 3, hexc("2a2a2e"))
    lk.rect(-34, 9, 68, 2, hexc("e8c02a"))
    lk.circle(33, 2, 2.5, hexc("fff2a0"))
    lk.save()


def main():
    os.makedirs(OUT, exist_ok=True)
    small_items()
    places()
    print("look art written to", OUT)


if __name__ == "__main__":
    main()
