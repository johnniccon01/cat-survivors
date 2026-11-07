"""Pixel art for the Dog District's maps (first four: the Freight Yard, the
Shelter, the Dog Park, the Junkyard). Same style and helpers as
tools/gen_outdoor.py and tools/gen_district1.py.

    python tools/gen_district2.py

Writes assets/sprites/apt_*.png. Afterwards run the Godot import.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_apartment import framed, speckle, wood_fill  # noqa: E402
from gen_outdoor import Tile, blob, box_crate, floor_concrete_plain, sand  # noqa: E402
from gen_sprites import OUT, hexc, shade  # noqa: E402
from gen_terrain import THICK, save_pair  # noqa: E402

METAL = hexc("8a9096")


# --- floors -------------------------------------------------------------------------

def kennel_row():
    floor_concrete_plain("kennel_row", hexc("9a968e"), 301, slab=40)


def agility():
    sand("agility", hexc("d8c08a"), 302, ripples=False)


def scrap():
    rng = random.Random(303)
    S = 160
    img = Tile(S, S)
    base = hexc("6a6258")
    img.rect(0, 0, S, S, speckle(rng, base, 0.12, 0.7))
    for _ in range(8):
        blob(img, rng, rng.randrange(S), rng.randrange(S), rng.randint(8, 20), rng.choice((-0.1, 0.06)))
    # Bits of metal, glass and rust everywhere.
    for _ in range(260):
        x, y = rng.randrange(S), rng.randrange(S)
        col = hexc(rng.choice(["9aa0a6", "8a5a3a", "3a5a7a", "c9a24a", "4a4e54", "a8d0e8"]))
        img.set(x, y, col)
        if rng.random() < 0.5:
            img.set(x + 1, y, shade(col, -0.3))
    for _ in range(5):
        cx, cy = rng.randrange(S), rng.randrange(S)
        for k in range(3):
            blob(img, rng, cx, cy, 9 - k * 3, -0.12)
    img.save("apt_floor_scrap.png")


# --- furniture -----------------------------------------------------------------------

def kennel():
    rng = random.Random(310)
    img = framed(40, 34)
    o = 1
    img.rect(o, o + 6, 40, 28, wood_fill(rng, hexc("b8503a")))
    img.poly([(o - 1, o + 8), (o + 20, o - 1), (o + 41, o + 8)], hexc("6a3a2a"))
    img.poly([(o - 1, o + 8), (o + 20, o - 1), (o + 20, o + 8)], hexc("8a4a32"))
    img.circle(o + 20, o + 22, 8, hexc("1a1210"), 9)
    img.rect(o + 12, o + 22, 16, 12, hexc("1a1210"))
    img.rect(o + 14, o + 10, 12, 4, hexc("f4f1ea"))
    img.outline()
    img.save("apt_kennel.png")


def dog_bed():
    img = framed(34, 26)
    c = (18, 14)
    img.circle(*c, 16, hexc("4a6a9a"), 12)
    img.round_shade(*c, 15, 0.25)
    img.circle(*c, 11, hexc("e8d8b8"), 8)
    img.circle(c[0] + 3, c[1] + 2, 3, hexc("c8b898"))
    img.outline()
    img.save("apt_dog_bed.png")


def water_bowl():
    img = framed(18, 14)
    img.circle(9.5, 7.5, 8, METAL, 6)
    img.round_shade(9.5, 7.5, 8, 0.3)
    img.circle(9.5, 7, 5.5, hexc("6fb0e0"), 4)
    img.set(7, 5, hexc("ffffff"))
    img.outline()
    img.save("apt_water_bowl.png")


def agility_hoop():
    img = framed(36, 30)
    for k in range(60):
        a = k * math.tau / 60
        x, y = 18 + math.cos(a) * 12, 13 + math.sin(a) * 12
        img.set(x, y, hexc("e04646") if (k // 6) % 2 else hexc("f4f1ea"))
        img.set(x + 1, y, hexc("e04646") if (k // 6) % 2 else hexc("f4f1ea"))
    img.rect(5, 13, 2, 16, METAL)
    img.rect(29, 13, 2, 16, METAL)
    img.outline()
    img.save("apt_agility_hoop.png")


def tire_stack():
    img = framed(30, 30)
    c = 15.5
    for r in (14, 10):
        img.circle(c, c, r, hexc("2a2a2e"))
        img.circle(c, c, r - 3, hexc("3a3a40"))
    img.circle(c, c, 5, hexc("1a1a1e"))
    img.round_shade(c, c, 14, 0.25)
    for k in range(16):
        a = k * math.tau / 16
        img.set(c + math.cos(a) * 12.5, c + math.sin(a) * 12.5, hexc("4a4a52"))
    img.outline()
    img.save("apt_tire_stack.png")


def car_wreck():
    rng = random.Random(316)
    img = framed(70, 38)
    o = 1
    body = hexc(rng.choice(["3a5a7a", "8a3a2a", "5a6a3a"]))
    img.rect(o + 2, o + 4, 66, 30, body)
    img.bevel(o + 2, o + 4, 66, 30, 0.25)
    img.rect(o + 18, o + 9, 30, 20, shade(body, -0.25))
    img.rect(o + 20, o + 11, 10, 16, hexc("4a6a7a"))
    img.rect(o + 36, o + 11, 10, 16, hexc("4a6a7a"))
    for _ in range(40):
        img.set(o + rng.randint(3, 66), o + rng.randint(5, 32), hexc("8a5a3a"))
    for (x, y) in ((8, 2), (54, 2), (8, 32), (54, 32)):
        img.rect(o + x, o + y, 8, 4, hexc("1a1a1e"))
    img.outline()
    img.save("apt_car_wreck.png")
    return img


def scrap_pile():
    rng = random.Random(317)
    img = framed(46, 34)
    img.circle(23, 18, 22, hexc("6a6058"), 15)
    for _ in range(70):
        x, y = rng.randint(4, 42), rng.randint(4, 30)
        if img.get(x, y)[3]:
            col = hexc(rng.choice(["9aa0a6", "8a5a3a", "3a5a7a", "c9a24a", "4a4e54", "c0392b"]))
            img.rect(x, y, rng.randint(2, 4), rng.randint(1, 3), col)
    img.round_shade(23, 18, 22, 0.25)
    img.outline()
    img.save("apt_scrap_pile.png")


def fridge():
    img = framed(22, 30)
    o = 1
    img.rect(o, o, 22, 30, hexc("e8ecef"))
    img.bevel(o, o, 22, 30, 0.25)
    img.rect(o, o + 11, 22, 1, hexc("9aa0a6"))
    img.rect(o + 17, o + 4, 2, 5, hexc("9aa0a6"))
    img.rect(o + 17, o + 15, 2, 8, hexc("9aa0a6"))
    img.rect(o + 3, o + 20, 6, 4, hexc("8a5a3a"))
    img.outline()
    img.save("apt_fridge.png")


def dog_crate():
    rng = random.Random(319)
    img = framed(36, 30)
    box_crate(img, rng, 1, 1, 36, 30, hexc("9a7048"))
    for x in range(6, 32, 5):
        img.rect(x, 8, 1, 16, hexc("2a2a2e"))
    img.rect(5, 8, 27, 1, hexc("2a2a2e"))
    img.rect(5, 23, 27, 1, hexc("2a2a2e"))
    img.outline()
    img.save("apt_dog_crate.png")


# --- terrain and crane loads ------------------------------------------------------------

def chainlink():
    """A chain-link fence on posts, seen from above (Shelter walls)."""
    W = 64
    img = Tile(W, THICK)
    for y in range(THICK):
        for x in range(W):
            on = (x + y) % 6 == 0 or (x - y) % 6 == 0
            img.set(x, y, hexc("b8bcc4", 255) if on else hexc("3a3e44", 90))
    for x in range(0, W, 32):
        for y in range(THICK):
            img.set(x, y, hexc("6a6e72"))
            img.set(x + 1, y, hexc("9aa0a6"))
            img.set(x + 2, y, hexc("4a4e54"))
    for x in range(W):
        img.set(x, 1, hexc("9aa0a6"))
        img.set(x, THICK - 2, hexc("6a6e72"))
    save_pair(img, "chainlink")


def scrapwall():
    rng = random.Random(330)
    W = 72
    img = Tile(W, THICK)
    img.rect(0, 0, W, THICK, speckle(rng, hexc("5a5248"), 0.1, 0.7))
    x = 0
    while x < W:
        w = rng.randint(6, 14)
        col = hexc(rng.choice(["3a5a7a", "8a3a2a", "9aa0a6", "c9a24a", "4a4e54", "5a6a3a"]))
        h = rng.randint(6, THICK - 4)
        y = rng.randint(2, THICK - h - 2)
        img.rect(x, y, w, h, col)
        img.bevel(x, y, w, h, 0.25)
        x += w + rng.randint(0, 2)
    for x in range(W):
        img.set(x, 0, shade(img.get(x, 0), 0.15))
        img.set(x, THICK - 1, shade(img.get(x, THICK - 1), -0.35))
    save_pair(img, "scrapwall")


def crane_car():
    img = car_wreck()
    img.save("apt_crane_load_car.png")


def main():
    os.makedirs(OUT, exist_ok=True)
    for fn in (kennel_row, agility, scrap, kennel, dog_bed, water_bowl, agility_hoop, tire_stack, scrap_pile,
               fridge, dog_crate, chainlink, scrapwall, crane_car):
        fn()
    print("district 2 art written to", OUT)


# --- maps 5-8: the Grooming Salon, the Biscuit Bakery, the Racetrack, the Fire Station ---

def salon_tiles():
    from gen_outdoor import tiles_floor
    tiles_floor("salon", hexc("f8e0ec"), hexc("f4f1ea"), 340, t=32, grout="c8a8b8").save("apt_floor_salon.png")


def bakery_tiles():
    from gen_outdoor import tiles_floor
    img = tiles_floor("bakery", hexc("f0dcb0"), hexc("e8c890"), 341, t=32, grout="b8986a")
    rng = random.Random(341)
    for _ in range(200):
        img.set(rng.randrange(128), rng.randrange(128), hexc("fffaf0"))
    img.save("apt_floor_bakery.png")


def fire_floor():
    floor_concrete_plain("fire_bay", hexc("a8423a"), 342, slab=80, stripes=True)


def dryer_chair():
    img = framed(30, 34)
    img.rect(3, 14, 26, 20, hexc("e88aa8"))
    img.bevel(3, 14, 26, 20, 0.25)
    img.circle(16, 9, 10, hexc("c9ced2"), 8)
    img.round_shade(16, 9, 10, 0.3)
    img.circle(16, 9, 6, hexc("4a4e54"), 4)
    img.outline()
    img.save("apt_dryer_chair.png")


def bath_tub():
    img = framed(52, 30)
    img.rect(1, 1, 52, 30, hexc("f4f4f0"))
    img.bevel(1, 1, 52, 30, 0.25)
    img.rect(5, 5, 44, 22, hexc("8fd3ff"))
    for k in range(9):
        img.circle(10 + k * 4.5, 10 + (k % 3) * 5, 2.5, hexc("ffffff"))
    img.outline()
    img.save("apt_bath_tub.png")


def oven():
    img = framed(40, 36)
    img.rect(1, 1, 40, 36, hexc("6a6e72"))
    img.bevel(1, 1, 40, 36, 0.3)
    img.rect(6, 12, 30, 18, hexc("2a1a14"))
    img.rect(8, 16, 26, 10, hexc("f08a2a"))
    for x in range(10, 34, 6):
        img.rect(x, 18, 4, 3, hexc("c88a4a"))
    img.circle(10, 6, 2, hexc("e04646"))
    img.circle(18, 6, 2, hexc("f2d14e"))
    img.outline()
    img.save("apt_oven.png")


def flour_sacks():
    rng = random.Random(350)
    img = framed(40, 28)
    for (x, y) in ((2, 2), (20, 2), (11, 13)):
        img.rect(x, y, 18, 13, shade(hexc("f4ecd8"), rng.uniform(-0.05, 0.02)))
        img.bevel(x, y, 18, 13, 0.25)
        img.rect(x + 5, y + 4, 8, 4, hexc("c88a4a"))
    img.outline()
    img.save("apt_flour_sacks.png")


def hurdle():
    img = framed(44, 14)
    img.rect(2, 4, 40, 4, hexc("f4f1ea"))
    for x in range(2, 42, 8):
        img.rect(x, 4, 4, 4, hexc("c0392b"))
    img.rect(2, 2, 2, 12, METAL)
    img.rect(40, 2, 2, 12, METAL)
    img.outline()
    img.save("apt_hurdle.png")


def start_gate():
    img = framed(70, 24)
    for i in range(6):
        x = 1 + i * 11
        img.rect(x, 1, 10, 22, hexc("3a6ac8") if i % 2 else hexc("c0392b"))
        img.bevel(x, 1, 10, 22, 0.3)
        img.rect(x + 3, 4, 4, 2, hexc("f4f1ea"))
    img.outline()
    img.save("apt_start_gate.png")


def fire_truck():
    img = framed(96, 40)
    img.rect(1, 2, 96, 36, hexc("c0392b"))
    img.bevel(1, 2, 96, 36, 0.25)
    img.rect(70, 6, 22, 28, hexc("a02a20"))
    img.rect(74, 9, 14, 10, hexc("8fd3ff"))
    for y in range(8, 34, 6):
        img.rect(8, y, 56, 2, hexc("c9ced2"))
    img.rect(80, 1, 10, 3, hexc("4a8ae8"))
    img.outline()
    img.save("apt_fire_truck.png")


def hose_reel():
    img = framed(30, 30)
    c = 15.5
    img.circle(c, c, 14, hexc("c0392b"))
    img.round_shade(c, c, 14, 0.3)
    for r in (11, 8, 5):
        for k in range(int(r * 8)):
            a = k * math.tau / (r * 8)
            img.set(c + math.cos(a) * r, c + math.sin(a) * r, hexc("e8c02a"))
    img.circle(c, c, 2.5, hexc("4a4e54"))
    img.outline()
    img.save("apt_hose_reel.png")


def main58():
    for fn in (salon_tiles, bakery_tiles, fire_floor, dryer_chair, bath_tub, oven, flour_sacks, hurdle, start_gate, fire_truck, hose_reel):
        fn()



# --- maps 9-12: snow and ice for the Snowy Hill ---

def snow():
    sand("snow", hexc("eef4f8"), 360, ripples=False)


def ice():
    rng = random.Random(361)
    S = 128
    img = Tile(S, S)
    img.rect(0, 0, S, S, speckle(rng, hexc("b8d8ec"), 0.04, 0.5))
    for _ in range(12):
        x, y = rng.randrange(S), rng.randrange(S)
        for i in range(rng.randint(8, 24)):
            img.set(x + i, y + i // 3, hexc("e8f4ff"))
    img.save("apt_floor_ice.png")


def main912():
    snow()
    ice()


if __name__ == "__main__":
    main()
    main58()
    main912()
