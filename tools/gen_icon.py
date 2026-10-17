"""Draws the game icon (assets/icon.png): Mica's face as 32x32 pixel art,
scaled up to 256x256. Run: python tools/gen_icon.py"""
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "icon.png")
N, SCALE = 32, 8

C = {
    ".": (0, 0, 0, 0),
    "o": (43, 29, 20, 255),      # outline
    "f": (217, 140, 74, 255),    # fur
    "d": (168, 96, 44, 255),     # stripes
    "b": (243, 217, 184, 255),   # muzzle / belly
    "p": (243, 169, 184, 255),   # inner ear / nose
    "e": (154, 208, 74, 255),    # eyes
    "k": (26, 18, 16, 255),      # pupils
    "w": (255, 255, 255, 255),   # eye glint
    "n": (240, 138, 160, 255),   # nose
    "m": (60, 40, 100, 255),     # background disc
    "M": (90, 66, 140, 255),     # background rim
}
ART = [
    "................................",
    "...........MMMMMMMMMM...........",
    "........MMMmmmmmmmmmmMMM........",
    "......MMmmmmmmmmmmmmmmmmMM......",
    ".....Mmmmoommmmmmmmmmoommm......",
    "....Mmmmoffoommmmmmooffommm.....",
    "...Mmmmofppfoommmmoofppfommm....",
    "...Mmmmofpppfoooooofpppfommm....",
    "..Mmmmmoffpfffffffffpffoommmm...",
    "..Mmmmmofffffdfffdffffffommmm...",
    ".Mmmmmoffffffdfffdfffffffommmm..",
    ".Mmmmmofffffffffffffffffffommm..",
    ".Mmmmofffeeeffffffffeeefffommm..",
    "Mmmmmoffekkwfffffffekkwffffommm.",
    "Mmmmmoffekkefffffffekkeffffommm.",
    "Mmmmmofffeeeffffffffeeefffofmmm.",
    "Mmmmmodffffffbbbbbbbffffffdommm.",
    "Mmmmmofffffbbbbnnbbbbbffffommmm.",
    "Mmmmmoffffbbbbbbbbbbbbbfffommmm.",
    ".Mmmmofffbbbbbobbobbbbbfffommm..",
    ".Mmmmoffffbbbbboobbbbbffffommm..",
    ".Mmmmmofffffbbbbbbbbbbffffommm..",
    "..Mmmmofffffffbbbbbffffffommmm..",
    "..Mmmmmoffffffffffffffffoommm...",
    "...Mmmmmoofffffffffffffoommmm...",
    "...Mmmmmmmooffffffffffoommmm....",
    "....Mmmmmmmmoooooooooommmmm.....",
    ".....Mmmmmmmmmmmmmmmmmmmmm......",
    "......MMmmmmmmmmmmmmmmmmMM......",
    "........MMMmmmmmmmmmmMMM........",
    "...........MMMMMMMMMM...........",
    "................................",
]
assert len(ART) == N and all(len(r) == N for r in ART), [len(r) for r in ART]

raw = bytearray()
for y in range(N * SCALE):
    raw.append(0)
    row = ART[y // SCALE]
    for x in range(N * SCALE):
        raw.extend(bytes(C[row[x // SCALE]]))


def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "wb") as f:
    f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N * SCALE, N * SCALE, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))
print("written", OUT)
