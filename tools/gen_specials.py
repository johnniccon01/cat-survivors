"""Pixel art for the maps' special things: the station train, the cemetery's
cracked graves, shrines, the cat-flap door, and the buildings quests leave
on a map (scripts/world/map_feature.gd). Glows, rings and beams stay drawn
by the game on top.

    python tools/gen_specials.py

Writes assets/sprites/apt_*.png. Afterwards run the Godot import.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_apartment import framed, speckle, wood_fill  # noqa: E402
from gen_sprites import OUT, hexc, shade  # noqa: E402

TRAIN_W, TRAIN_H = 112, 64


def carriage(loco):
    """A carriage seen from above, heading right: a roof with vents and a
    stripe, the locomotive with its cab at the front and a headlamp."""
    rng = random.Random(1 + loco)
    img = framed(TRAIN_W, TRAIN_H)
    o = 1
    body = hexc("c0392b") if loco else hexc("3a5a8a")
    img.rect(o, o, TRAIN_W, TRAIN_H, body)
    img.bevel(o, o, TRAIN_W, TRAIN_H, 0.25)
    # The roof: a lighter band down the middle with rivets.
    img.rect(o + 4, o + 10, TRAIN_W - 8, TRAIN_H - 20, shade(body, 0.12))
    img.bevel(o + 4, o + 10, TRAIN_W - 8, TRAIN_H - 20, 0.15)
    for x in range(o + 8, o + TRAIN_W - 6, 10):
        img.set(x, o + 12, shade(body, 0.4))
        img.set(x, o + TRAIN_H - 12, shade(body, -0.3))
    img.rect(o, o + TRAIN_H - 8, TRAIN_W, 3, hexc("e8c02a"))
    img.rect(o, o + 5, TRAIN_W, 3, hexc("e8c02a"))
    if loco:
        # Cab windows at the front, a grille, the headlamp and an exhaust.
        img.rect(o + TRAIN_W - 26, o + 12, 18, 40, hexc("2a3a4a"))
        img.rect(o + TRAIN_W - 24, o + 14, 14, 16, hexc("8fd0f0"))
        img.rect(o + TRAIN_W - 24, o + 34, 14, 16, hexc("8fd0f0"))
        for i in range(5):
            img.set(o + TRAIN_W - 22 + i, o + 16 + i, hexc("ffffff"))
        for y in range(o + 18, o + TRAIN_H - 16, 3):
            img.rect(o + 30, y, 40, 1, shade(body, -0.35))
        img.circle(o + 18, o + 32, 7, hexc("4a4e54"))
        img.circle(o + 18, o + 32, 4, hexc("2a2a2e"))
        img.circle(o + TRAIN_W - 3, o + 40, 3, hexc("fff2a0"))
    else:
        for x in range(o + 10, o + TRAIN_W - 20, 26):
            img.rect(x, o + 22, 16, 20, hexc("9aa0a6"))
            img.bevel(x, o + 22, 16, 20, 0.3)
            for k in range(3):
                img.rect(x + 3, o + 26 + k * 5, 10, 1, hexc("5a5e62"))
        for _ in range(10):
            img.set(o + rng.randint(4, TRAIN_W - 4), o + rng.randint(12, TRAIN_H - 12), shade(body, -0.15))
    img.outline()
    img.save("apt_train_%s.png" % ("loco" if loco else "car"))


def grave_mound():
    rng = random.Random(3)
    img = framed(48, 56)
    o = 1
    cx, cy = o + 24, o + 40
    img.circle(cx, cy, 22, speckle(rng, hexc("4a3a30"), 0.12, 0.7), 13)
    for _ in range(18):
        img.set(cx + rng.randint(-18, 18), cy + rng.randint(-9, 9), hexc("6a5444"))
    stone = hexc("8a8a92")
    img.circle(cx, cy - 22, 8, stone)
    img.rect(cx - 8, cy - 22, 16, 12, stone)
    for y in range(cy - 31, cy - 10):
        for x in range(cx - 9, cx + 9):
            c = img.get(x, y)
            if c == stone:
                img.set(x, y, shade(stone, 0.12 - (x - cx + 8) * 0.018 + rng.uniform(-0.04, 0.04)))
    img.rect(cx - 1, cy - 28, 2, 10, hexc("5a5a62"))
    img.rect(cx - 4, cy - 25, 8, 2, hexc("5a5a62"))
    img.outline()
    img.save("apt_grave_mound.png")


def shrine(used):
    """A stone plinth with a sitting stone cat; the game paints its gem."""
    rng = random.Random(4)
    img = framed(34, 52)
    o = 1
    cx = o + 17
    base = 38  # plinth top, in picture rows (the shrine's 0 is at row 39)
    stone = hexc("8c8478")
    img.rect(cx - 15, o + base, 30, 14, speckle(rng, stone, 0.05, 0.4))
    img.bevel(cx - 15, o + base, 30, 14, 0.25)
    body = hexc("6a6258") if used else hexc("b8b0a4")
    # Tail curled round, body, head with pointed ears.
    for i in range(20):
        a = -math.pi * 0.5 + i * (math.pi * 1.1) / 20
        img.circle(cx + 7 + math.cos(a) * 6, o + base - 4 + math.sin(a) * 6, 1.5, shade(body, -0.25))
    img.circle(cx, o + base - 9, 8.5, body, 10.5)
    img.circle(cx, o + base - 24, 6.5, body)
    for side in (-1, 1):
        img.poly([(cx + side * 1.5, o + base - 28), (cx + side * 6.5, o + base - 35), (cx + side * 7, o + base - 25)], body)
    for y in range(o + 2, o + base + 2):
        for x in range(cx - 10, cx + 14):
            c = img.get(x, y)
            if c == body:
                img.set(x, y, shade(body, -(x - cx) * 0.02 - (y - o - 20) * 0.006 + rng.uniform(-0.03, 0.03)))
    img.rect(cx - 4, o + base - 24, 3, 1, hexc("2b1d14"))
    img.rect(cx + 2, o + base - 24, 3, 1, hexc("2b1d14"))
    img.rect(cx - 3, o + base - 5, 1, 5, shade(body, -0.3))
    img.rect(cx + 3, o + base - 5, 1, 5, shade(body, -0.3))
    if used:
        for _ in range(6):
            img.set(cx + rng.randint(-8, 8), o + base - rng.randint(4, 30), hexc("4a6a3a"))
    img.outline()
    img.save("apt_shrine_%s.png" % ("used" if used else "awake"))


def cat_door():
    rng = random.Random(5)
    img = framed(44, 56)
    o = 1
    wood = hexc("8a5a3b")
    img.rect(o, o, 44, 56, wood_fill(rng, wood, False))
    img.bevel(o, o, 44, 56, 0.25)
    img.rect(o + 6, o + 4, 32, 20, wood_fill(rng, shade(wood, -0.1), False))
    img.bevel(o + 6, o + 4, 32, 20, -0.2)
    img.circle(o + 36, o + 32, 2.5, hexc("f2c14e"))
    img.set(o + 35, o + 31, hexc("fff3c8"))
    # The cat flap: a dark opening with a swinging flap, and a little sign.
    img.rect(o + 12, o + 38, 20, 16, hexc("2b1d14"))
    img.rect(o + 13, o + 39, 18, 14, hexc("3a2a22"))
    img.rect(o + 13, o + 39, 18, 3, hexc("5a4a3a"))
    img.rect(o + 13, o + 42, 18, 1, hexc("7a6a5a"))
    img.rect(o + 16, o + 28, 12, 6, hexc("f4f1ea"))
    for (x, y) in ((19, 30), (22, 29), (25, 30), (22, 32)):
        img.set(o + x, o + y, hexc("2b1d14"))
    img.outline()
    img.save("apt_cat_door.png")


def fireplace():
    """The heal spot: a little stove with a pipe; the game lights the fire."""
    rng = random.Random(6)
    img = framed(32, 52)
    o = 1
    img.rect(o + 20, o, 5, 14, hexc("6a6e72"))
    img.bevel(o + 20, o, 5, 14, 0.3)
    img.rect(o, o + 12, 32, 40, speckle(rng, hexc("4a4e54"), 0.06, 0.5))
    img.bevel(o, o + 12, 32, 40, 0.3)
    img.rect(o + 6, o + 32, 20, 12, hexc("2a1a14"))
    img.rect(o + 6, o + 32, 20, 1, hexc("6a6e72"))
    for x in range(o + 4, o + 30, 6):
        img.set(x, o + 16, hexc("8a9096"))
    img.rect(o + 2, o + 48, 4, 4, hexc("2a2a2e"))
    img.rect(o + 26, o + 48, 4, 4, hexc("2a2a2e"))
    img.outline()
    img.save("apt_feature_heal_spot.png")


def turret():
    img = framed(32, 50)
    o = 1
    cx = o + 16
    img.rect(cx - 1, o + 4, 3, 46, hexc("9aa0a6"))
    img.rect(cx - 1, o + 4, 1, 46, hexc("d0d4d8"))
    for k in range(3):
        w = 14 - k * 3
        img.rect(cx - w, o + 12 + k * 9, w * 2 + 1, 2, hexc("9aa0a6"))
        img.rect(cx - w, o + 12 + k * 9, w * 2 + 1, 1, hexc("d0d4d8"))
    img.rect(cx - 7, o + 44, 15, 6, hexc("4a4e54"))
    img.bevel(cx - 7, o + 44, 15, 6, 0.3)
    img.circle(cx, o + 4, 3, hexc("5a6a7a"))
    img.outline()
    img.save("apt_feature_turret.png")


def lighthouse():
    img = framed(28, 58)
    o = 1
    cx = o + 14
    for y in range(o + 10, o + 54):
        t = (y - o - 10) / 44
        half = 7 + t * 5
        band = ((y - o - 10) // 8) % 2 == 1
        for x in range(int(cx - half), int(cx + half) + 1):
            col = hexc("d9534f") if band else hexc("f4f1ea")
            img.set(x, y, shade(col, 0.12 - (x - cx + half) / (2 * half) * 0.3))
    img.rect(cx - 9, o + 2, 18, 9, hexc("3a3e44"))
    img.rect(cx - 7, o + 4, 14, 5, hexc("f2d14e"))
    img.rect(cx - 6, o + 4, 3, 5, hexc("fff3c8"))
    img.poly([(cx - 9, o + 2), (cx, o - 1), (cx + 9, o + 2)], hexc("2a2a2e"))
    img.rect(cx - 3, o + 44, 6, 10, hexc("6a4428"))
    img.outline()
    img.save("apt_feature_lighthouse.png")


def scarecrow_feature():
    rng = random.Random(9)
    img = framed(36, 58)
    o = 1
    cx = o + 18
    img.rect(cx - 1, o + 14, 3, 44, wood_fill(rng, hexc("6b4630"), False))
    img.rect(o, o + 24, 36, 3, wood_fill(rng, hexc("6b4630")))
    img.rect(cx - 7, o + 22, 14, 18, hexc("c9a24a"))
    img.bevel(cx - 7, o + 22, 14, 18, 0.2)
    for _ in range(5):
        img.rect(cx + rng.randint(-6, 4), o + rng.randint(24, 36), 2, 2, hexc("8a6a2a"))
    img.rect(cx - 8, o + 23, 16, 2, hexc("d9534f"))
    img.circle(cx, o + 14, 7, hexc("e8902a"))
    img.round_shade(cx, o + 14, 7, 0.3)
    img.set(cx - 3, o + 13, hexc("2b1d14"))
    img.set(cx + 2, o + 13, hexc("2b1d14"))
    img.rect(cx - 3, o + 17, 6, 1, hexc("2b1d14"))
    img.rect(cx - 9, o + 5, 18, 3, hexc("5a4234"))
    img.rect(cx - 5, o, 10, 6, hexc("5a4234"))
    for x in (o + 1, o + 34):
        for k in range(3):
            img.line(x, o + 26, x + (k - 1) * 2, o + 30, hexc("e8c86a"))
    img.outline()
    img.save("apt_feature_scarecrow.png")


def main():
    os.makedirs(OUT, exist_ok=True)
    carriage(True)
    carriage(False)
    grave_mound()
    shrine(False)
    shrine(True)
    cat_door()
    fireplace()
    turret()
    lighthouse()
    scarecrow_feature()
    print("special art written to", OUT)


if __name__ == "__main__":
    main()
