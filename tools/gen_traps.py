"""Pixel art for the map traps (scripts/world/trap.gd): the trap itself in
each state; sparks, steam and water stay drawn by the game on top.
Every picture is centred on the trap's position.

    python tools/gen_traps.py

Writes assets/sprites/apt_trap_*.png. Afterwards run the Godot import.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_apartment import Img, WOOD, framed, speckle, wood_fill  # noqa: E402
from gen_sprites import OUT, hexc, shade  # noqa: E402

STEEL = hexc("9aa0a6")
DARK = hexc("3a3e44")


def centred(w, h):
    """An image `w` x `h` (even) whose middle is the trap's position."""
    img = framed(w, h)
    return img, (w + 2) / 2, (h + 2) / 2


def rake(armed):
    img, cx, cy = centred(36, 40)
    rng = random.Random(1)
    # The head with its tines, then the handle up (armed) or flat (sprung).
    img.rect(cx - 8, cy - 1, 16, 3, hexc("6a6e72"))
    img.bevel(cx - 8, cy - 1, 16, 3, 0.3)
    for x in range(-7, 9, 3):
        img.rect(cx + x, cy + 2, 1, 4, STEEL)
    tip = (cx, cy - 17) if armed else (cx - 15, cy - 4)
    for k in (0, 1):
        img.line(cx + k, cy, tip[0] + k, tip[1], wood_fill(rng, hexc("a47a50"))(0, 0))
    img.outline()
    img.save("apt_trap_rake_%s.png" % ("on" if armed else "off"))


def round_head(name, col):
    img, cx, cy = centred(12, 12)
    img.circle(cx, cy, 5, col)
    img.round_shade(cx, cy, 5, 0.35)
    img.circle(cx, cy, 2, shade(col, -0.4))
    img.set(cx - 2, cy - 2, shade(col, 0.5))
    img.outline()
    img.save("apt_trap_%s.png" % name)


def grille(name, frame, slats, size=16):
    img, cx, cy = centred(size + 2, size + 2)
    o = cx - size / 2
    img.rect(o, o, size, size, frame)
    img.bevel(o, o, size, size, 0.3)
    for k in range(3):
        img.rect(o + 3, o + 4 + k * 4, size - 6, 2, slats)
        img.rect(o + 3, o + 4 + k * 4, size - 6, 1, shade(slats, -0.3))
    for (x, y) in ((1, 1), (size - 2, 1), (1, size - 2), (size - 2, size - 2)):
        img.set(o + x, o + y, shade(frame, 0.4))
    img.outline()
    img.save("apt_trap_%s.png" % name)


def live_wire():
    img, cx, cy = centred(58, 14)
    pts = [(-26, -4), (-8, 3), (5, -3), (26, 4)]
    for i in range(len(pts) - 1):
        (x1, y1), (x2, y2) = pts[i], pts[i + 1]
        for k in (-1, 0):
            img.line(cx + x1, cy + y1 + k, cx + x2, cy + y2 + k, hexc("2a2a30") if k else hexc("4a4a52"))
    # Bare copper at the cut end, a plug at the other.
    img.circle(cx + 26, cy + 4, 2.5, hexc("d08a3a"))
    img.set(cx + 25, cy + 3, hexc("f0c070"))
    img.rect(cx - 30, cy - 7, 6, 6, hexc("f4f1ea"))
    img.rect(cx - 31, cy - 6, 2, 1, hexc("c9a24a"))
    img.rect(cx - 31, cy - 3, 2, 1, hexc("c9a24a"))
    img.outline()
    img.save("apt_trap_live_wire.png")


def broken_light():
    img, cx, cy = centred(54, 16)
    for t in range(0, 44):
        x = cx - 24 + t
        y = cy - 2 + t * 5 / 44
        img.rect(x, y - 1, 1, 3, hexc("f4f1ea"))
        img.set(x, y - 1, hexc("ffffff"))
    for (x, y) in ((-26, -3), (-24, -3)):
        img.rect(cx + x, cy + y - 1, 2, 4, STEEL)
    # Broken glass at the far end.
    for k in range(4):
        img.line(cx + 20 + k * 2, cy + 3 + k, cx + 22 + k * 2, cy + 1 + k, hexc("c9d4dc"))
    img.outline()
    img.save("apt_trap_broken_light.png")


def fish_hook():
    img, cx, cy = centred(18, 56)
    img.rect(cx, cy - 27, 1, 15, hexc("e8e8e8"))
    hook = [(0, -12), (0, 2), (-3, 6), (-7, 4), (-7, 0), (-5, -1)]
    for i in range(len(hook) - 1):
        (x1, y1), (x2, y2) = hook[i], hook[i + 1]
        img.line(cx + x1, cy + y1, cx + x2, cy + y2, hexc("c9ced2"))
        img.line(cx + x1 + 1, cy + y1, cx + x2 + 1, cy + y2, hexc("8a9096"))
    img.circle(cx, cy - 13, 1.5, hexc("c9a24a"))
    img.outline()
    img.save("apt_trap_fish_hook.png")


def tide_pool():
    rng = random.Random(9)
    img, cx, cy = centred(70, 52)
    for k in range(18):
        a = k * math.tau / 18
        img.circle(cx + math.cos(a) * 31, cy + math.sin(a) * 22, rng.uniform(4, 6.5), hexc("8a8480"))
    img.circle(cx, cy, 30, hexc("2a6a8a", 215), 21)
    img.circle(cx - 6, cy - 5, 16, hexc("3a84a8", 215), 10)
    for yy in range(int(cy - 30), int(cy + 30)):
        for xx in range(int(cx - 36), int(cx + 36)):
            c = img.get(xx, yy)
            if c[:3] == hexc("8a8480")[:3]:
                img.set(xx, yy, shade(c, -((xx - cx) + (yy - cy)) / 120.0 + rng.uniform(-0.05, 0.05)))
    for _ in range(4):
        a = rng.uniform(0, math.tau)
        x, y = cx + math.cos(a) * 16, cy + math.sin(a) * 10
        col = hexc(rng.choice(["e86a8a", "f08a5a", "9a5ad8"]))
        img.circle(x, y, 2.5, col)
        img.set(x - 1, y - 1, shade(col, 0.4))
    img.outline()
    img.save("apt_trap_tide_pool.png")


def electric_floor():
    rng = random.Random(10)
    img, cx, cy = centred(58, 42)
    o = (cx - 28, cy - 20)
    img.rect(o[0], o[1], 56, 40, speckle(rng, hexc("3a3e44"), 0.05, 0.4))
    img.bevel(o[0], o[1], 56, 40, 0.3)
    for k in range(5):
        y = o[1] + 5 + k * 7
        img.rect(o[0] + 4, y, 48, 2, hexc("6a6e72"))
        img.rect(o[0] + 4, y + 2, 48, 1, hexc("22252a"))
    # A warning sign in the corner.
    img.poly([(o[0] + 46, o[1] + 3), (o[0] + 52, o[1] + 13), (o[0] + 40, o[1] + 13)], hexc("f2d14e"))
    img.rect(o[0] + 46, o[1] + 6, 1, 4, hexc("2a2a2a"))
    img.outline()
    img.save("apt_trap_electric_floor.png")


def press_plate(armed):
    img, cx, cy = centred(22, 22)
    o = cx - 10
    col = hexc("c9a24a") if armed else hexc("6a6e72")
    img.rect(o, o, 20, 20, col)
    img.bevel(o, o, 20, 20, 0.3)
    for k in range(4):
        for i in range(20):
            x = o + i
            y = o + ((i + k * 6) % 20)
            if (i + k * 6) // 3 % 2 == 0:
                img.set(x, y, hexc("2b2b2b"))
    img.rect(o + 2, o + 2, 16, 16, lambda x, y: img.get(x, y))
    for (x, y) in ((1, 1), (18, 1), (1, 18), (18, 18)):
        img.set(o + x, o + y, hexc("e0e4e8"))
    img.outline()
    img.save("apt_trap_press_plate_%s.png" % ("on" if armed else "off"))


def rail_spark():
    rng = random.Random(12)
    img, cx, cy = centred(48, 24)
    for x in (-16, 0, 16):
        img.rect(cx + x - 3, cy - 10, 6, 20, wood_fill(rng, hexc("5a3a24"), False))
        img.bevel(cx + x - 3, cy - 10, 6, 20, 0.2)
    for y in (-6, 6):
        img.rect(cx - 22, cy + y - 2, 44, 4, hexc("6a6a72"))
        img.rect(cx - 22, cy + y - 2, 44, 1, hexc("e0e0e8"))
        img.rect(cx - 22, cy + y + 1, 44, 1, hexc("4a4a52"))
    img.outline()
    img.save("apt_trap_rail_spark.png")


def ticket_gate():
    img, cx, cy = centred(28, 22)
    for x in (-12, 6):
        img.rect(cx + x, cy - 9, 6, 18, STEEL)
        img.bevel(cx + x, cy - 9, 6, 18, 0.3)
        img.rect(cx + x + 1, cy - 7, 4, 2, hexc("3a6a9a"))
    img.circle(cx, cy, 2.5, DARK)
    img.outline()
    img.save("apt_trap_ticket_gate.png")


def coconut_palm():
    rng = random.Random(14)
    img, cx, cy = centred(76, 76)
    greens = [hexc("3f7a34", 210), hexc("4f8f3e", 210), hexc("5ea84a", 210)]
    for k in range(7):
        a = math.tau * k / 7 + 0.4 + rng.uniform(-0.1, 0.1)
        g = greens[k % 3]
        for i in range(36):
            t = i / 36
            w = 4.5 * (1 - t) + 0.8
            for s in range(-int(w), int(w) + 1):
                x = cx + math.cos(a) * i + math.cos(a + math.pi / 2) * s
                y = cy + math.sin(a) * i + math.sin(a + math.pi / 2) * s
                img.set(x, y, shade(g, 0.12 if s < 0 else -0.1))
    for (dx, dy) in ((-4, -3), (4, -2), (0, 4)):
        img.circle(cx + dx, cy + dy, 3.2, hexc("5a3a20"))
        img.set(cx + dx - 1, cy + dy - 1, hexc("8a6a4a"))
    img.outline()
    img.save("apt_trap_coconut_palm.png")


def sea_urchin(armed):
    img, cx, cy = centred(24, 24)
    col = hexc("6a3a8a") if armed else hexc("4a3a50")
    length = 10 if armed else 7
    for k in range(14):
        a = math.tau * k / 14 + 0.2
        img.line(cx, cy, cx + math.cos(a) * length, cy + math.sin(a) * length, shade(col, 0.3))
    img.circle(cx, cy, 5, col)
    img.round_shade(cx, cy, 5, 0.35)
    img.outline()
    img.save("apt_trap_sea_urchin_%s.png" % ("on" if armed else "off"))


def grave_hand(armed):
    rng = random.Random(16)
    img, cx, cy = centred(28, 26)
    img.circle(cx, cy + 3, 12, speckle(rng, hexc("4a3a30"), 0.12, 0.7), 8)
    for _ in range(6):
        img.set(cx + rng.randint(-10, 10), cy + 3 + rng.randint(-6, 6), hexc("6a5444"))
    if armed:
        for k in range(4):
            x = cx - 6 + k * 4
            top = cy - 6 - (k % 2) * 2
            img.rect(x, top, 2, cy + 4 - top, hexc("e8e2d0"))
            img.set(x + 1, top + 3, hexc("a8a290"))
        img.rect(cx - 7, cy + 2, 16, 3, hexc("d8d2c0"))
    img.outline()
    img.save("apt_trap_grave_hand_%s.png" % ("on" if armed else "off"))


def goose_nest(goose):
    rng = random.Random(17)
    img, cx, cy = centred(30, 32)
    straw = hexc("a08a5a")
    img.circle(cx, cy + 4, 12, straw, 8)
    for _ in range(40):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(6, 12)
        img.line(cx + math.cos(a) * d, cy + 4 + math.sin(a) * d * 0.66, cx + math.cos(a + 0.4) * d, cy + 4 + math.sin(a + 0.4) * d * 0.66, shade(straw, rng.uniform(-0.25, 0.2)))
    for (x, y) in ((-4, 4), (3, 3), (0, 7)):
        img.circle(cx + x, cy + y, 2.8, hexc("f4f1ea"), 2.2)
        img.set(cx + x - 1, cy + y - 1, hexc("ffffff"))
    if goose:
        img.circle(cx, cy - 6, 8, hexc("f4f1ea"), 5.5)
        img.round_shade(cx, cy - 6, 8, 0.2)
        img.circle(cx + 6, cy - 10, 3, hexc("f4f1ea"))
        img.rect(cx + 8, cy - 11, 4, 2, hexc("e8a040"))
        img.set(cx + 6, cy - 11, hexc("1a1a1a"))
    img.outline()
    img.save("apt_trap_goose_nest_%s.png" % ("goose" if goose else "eggs"))


def spark_puddle():
    img, cx, cy = centred(52, 38)
    img.circle(cx, cy, 24, hexc("4a6a8a", 170), 17)
    img.circle(cx - 5, cy - 4, 13, hexc("6a8aaa", 170), 8)
    for k in range(5):
        img.set(cx - 12 + k, cy - 8, hexc("e8f4ff", 220))
    # The frayed cable lying in it.
    img.line(cx + 26, cy - 14, cx + 8, cy - 2, hexc("2a2a30"))
    img.line(cx + 26, cy - 13, cx + 8, cy - 1, hexc("4a4a52"))
    img.circle(cx + 7, cy - 1, 1.5, hexc("d08a3a"))
    img.save("apt_trap_spark_puddle.png")


def steam_pipe():
    """The pipe end pointing right; the game turns it to the vent's way."""
    img, cx, cy = centred(24, 12)
    img.rect(cx - 12, cy - 4, 12, 8, hexc("8a9096"))
    img.rect(cx - 12, cy - 4, 12, 2, hexc("c9ced2"))
    img.rect(cx - 12, cy + 2, 12, 2, hexc("5a5e62"))
    img.rect(cx - 3, cy - 5, 4, 10, hexc("6a6e72"))
    img.circle(cx + 1, cy, 3.5, hexc("3a3e44"))
    img.outline()
    img.save("apt_trap_steam_pipe.png")


def main():
    os.makedirs(OUT, exist_ok=True)
    for armed in (True, False):
        rake(armed)
        press_plate(armed)
        sea_urchin(armed)
        grave_hand(armed)
        goose_nest(not armed)
    round_head("sprinkler", hexc("4a8a4a"))
    round_head("lawn_sprinkler", hexc("3a6ac8"))
    grille("vent", hexc("8a9096"), hexc("4a4e52"))
    grille("freezer", hexc("e8f0f4"), hexc("8ab4d0"), size=18)
    live_wire()
    broken_light()
    fish_hook()
    tide_pool()
    electric_floor()
    rail_spark()
    ticket_gate()
    coconut_palm()
    spark_puddle()
    steam_pipe()
    print("trap art written to", OUT)


if __name__ == "__main__":
    main()
