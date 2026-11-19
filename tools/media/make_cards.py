"""Text overlays for the trailer (transparent 1920x1080 PNGs) in the game's
own hand-drawn font: warm yellow letters with a dark outline and a soft
shadow, like the in-game banners.

    python tools/media/make_cards.py OUT_DIR

Lines come from CARDS below: a card is one line or a list of lines
(text, font, size, y centre as share of height, colour); STAT cards are a
big number with a line under it.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
HEAD = str(ROOT / "fonts" / "DeliciousHandrawn-Regular.ttf")
BODY = str(ROOT / "fonts" / "ShantellSans.ttf")
W, H = 1920, 1080
YELLOW = (255, 206, 84, 255)
CREAM = (250, 240, 214, 255)
INK = (40, 24, 16, 255)

# name: (text, font, size, y centre as share of height, colour)
CARDS = {
    "one_cat": ("One cat.", HEAD, 150, 0.80, YELLOW),
    "one_night": ("One night.", HEAD, 150, 0.80, YELLOW),
    "socks": ("Way too many socks.", HEAD, 150, 0.80, YELLOW),
    "loop": ("Auto-attack. Dodge. Grow stronger.", HEAD, 110, 0.82, YELLOW),
    "weapons": ("30 weapons & evolutions", HEAD, 120, 0.82, YELLOW),
    "cats": ("25 cats, each with its own instinct", HEAD, 110, 0.82, YELLOW),
    "districts": ("4 districts · 47 maps", HEAD, 120, 0.82, YELLOW),
    "bosses": ("Bosses with a bad attitude", HEAD, 120, 0.82, YELLOW),
    "meta": ("Quests, stories, gear… and Cat Dreams", HEAD, 110, 0.82, YELLOW),
    "wishlist": ("Wishlist now on Steam", BODY, 64, 0.84, CREAM),
    # Trailer v2: what the game has, as plain numbers from data/*.json.
    "first_night": ("And that's just the first night.", HEAD, 120, 0.82, YELLOW),
    "end_facts": [
        ("173 quests · 158 bosses · 47 maps · 25 cats", BODY, 50, 0.76, CREAM),
        ("Wishlist now on Steam", HEAD, 96, 0.87, YELLOW),
    ],
}

# name: (big number, line under it)
STATS = {
    "stat_quests": ("173 quests", "each one tells its own little story"),
    "stat_campaign": ("4 districts · 47 maps", "a story campaign, not just one arena"),
    "stat_bosses": ("158 bosses", "and every one of them wants your fish"),
    "stat_enemies": ("251 kinds of enemies", "socks, dogs, machines and worse"),
    "stat_cats": ("25 cats", "each with its own weapon and instinct"),
    "stat_gear": ("48 legendary items", "8 gear slots, 30 charms, 29 artifacts"),
    "stat_dreams": ("Then the Cat Dreams begin", "endless depth, nightmare bosses, dream gear"),
    "stat_hours": ("15+ hours", "just to win every map once"),
}


def card(text: str, font_path: str, size: int, y: float, colour, img: Image.Image = None) -> Image.Image:
    font = ImageFont.truetype(font_path, size)
    if img is None:
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    box = d.textbbox((0, 0), text, font=font)
    x = (W - (box[2] - box[0])) / 2 - box[0]
    top = H * y - (box[3] - box[1]) / 2 - box[1]
    outline = max(4, size // 14)
    # Soft drop shadow under everything.
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).text((x + outline, top + outline * 1.5), text, font=font,
                                fill=(0, 0, 0, 170), stroke_width=outline, stroke_fill=(0, 0, 0, 170))
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(outline * 1.2)))
    ImageDraw.Draw(img).text((x, top), text, font=font, fill=colour,
                             stroke_width=outline, stroke_fill=INK)
    return img


def shade_bottom(img: Image.Image, top: float = 0.55, alpha: int = 160) -> Image.Image:
    """Soft dark band from `top` down so small text reads on busy footage."""
    band = Image.new("L", (1, H), 0)
    for y in range(H):
        t = (y / H - top) / (1.0 - top)
        band.putpixel((0, y), int(alpha * max(0.0, min(1.0, t)) ** 0.8))
    dark = Image.new("RGBA", (W, H), (16, 10, 6, 255))
    dark.putalpha(band.resize((W, H)))
    return Image.alpha_composite(dark, img)


def main() -> None:
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "store_media/cards")
    out.mkdir(parents=True, exist_ok=True)
    for name, lines in CARDS.items():
        img = None
        for text, font, size, y, colour in lines if isinstance(lines, list) else [lines]:
            img = card(text, font, size, y, colour, img)
        if isinstance(lines, list):
            img = shade_bottom(img)
        img.save(out / f"{name}.png")
    for name, (big, small) in STATS.items():
        img = card(big, HEAD, 150, 0.72, YELLOW)
        shade_bottom(card(small, BODY, 50, 0.86, CREAM, img)).save(out / f"{name}.png")
    print(f"{len(CARDS) + len(STATS)} cards -> {out}")


if __name__ == "__main__":
    main()
