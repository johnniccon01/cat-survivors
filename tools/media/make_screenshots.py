"""Store screenshots from the picked 4K stills (tools/media/capture.sh).

    python tools/media/make_screenshots.py MEDIA_DIR

Reads MEDIA_DIR/raw/stills/<still>.png or MEDIA_DIR/extra/<still>.png for
every line of PICKS and writes MEDIA_DIR/screenshots/NN_<name>.png in
1920x1080 (store upload) and MEDIA_DIR/screenshots/4k/NN_<name>.png.
"""
import sys
from pathlib import Path

from PIL import Image

# (output name, still) in store order: the strongest picture first.
PICKS = [
    ("horde", "horde_living_room_hud_8"),
    ("cemetery_ring", "night_cemetery_6"),
    ("power", "power_basement_10"),
    ("dog_park", "dogs_park_6"),
    ("boss", "boss_robovacuum_12"),
    ("level_up", "levelup"),
    ("snow_hill", "dogs_snow_hill_8"),
    ("sock_king", "horde_wide_24"),
    ("kraken", "boss_kraken_10"),
    ("burnt_clearing", "wild_burnt_clearing_6"),
    ("district_map", "select_map"),
]


def main() -> None:
    media = Path(sys.argv[1] if len(sys.argv) > 1 else "store_media")
    out = media / "screenshots"
    (out / "4k").mkdir(parents=True, exist_ok=True)
    for i, (name, still) in enumerate(PICKS, 1):
        src = media / "raw" / "stills" / f"{still}.png"
        if not src.exists():
            src = media / "extra" / f"{still}.png"
        img = Image.open(src).convert("RGB")
        img.save(out / "4k" / f"{i:02d}_{name}.png")
        img.resize((1920, 1080), Image.LANCZOS).save(out / f"{i:02d}_{name}.png")
    print(f"{len(PICKS)} screenshots -> {out}")


if __name__ == "__main__":
    main()
