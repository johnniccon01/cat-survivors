"""Text overlays for the trailer (transparent 1920x1080 PNGs) in the game's
own hand-drawn font: warm yellow letters with a dark outline and a soft
shadow, like the in-game banners.

    python tools/media/make_cards.py OUT_DIR

Lines come from CARDS below (name -> text, size, vertical position).
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
}


def card(text: str, font_path: str, size: int, y: float, colour) -> Image.Image:
    font = ImageFont.truetype(font_path, size)
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


def main() -> None:
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "store_media/cards")
    out.mkdir(parents=True, exist_ok=True)
    for name, (text, font, size, y, colour) in CARDS.items():
        card(text, font, size, y, colour).save(out / f"{name}.png")
    print(f"{len(CARDS)} cards -> {out}")


if __name__ == "__main__":
    main()
