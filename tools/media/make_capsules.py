"""Store capsules (Steam sizes) from a 4K gameplay still and the title board.

    python tools/media/make_capsules.py BG.png LOGO.png LOGO_PLAIN.png OUT_DIR [FX FY]

BG is a 3840x2160 still without HUD (tools/media/capture.sh), FX FY the point
(0..1) the crops centre on, usually the cat. LOGO / LOGO_PLAIN come from
tools/media/logo_shot.gd (with and without the tagline).
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

# name: (size, where the cat lands (x, y share), logo: None /
# (variant, width share, anchor x, anchor y))
CAPSULES = {
    "header_capsule": ((920, 430), (0.78, 0.55), ("plain", 0.56, 0.04, 0.5)),
    "small_capsule": ((462, 174), (0.5, 0.5), ("plain", 0.92, 0.5, 0.5)),
    "main_capsule": ((1232, 706), (0.74, 0.62), ("full", 0.52, 0.04, 0.06)),
    "vertical_capsule": ((748, 896), (0.5, 0.68), ("full", 0.9, 0.5, 0.04)),
    "library_capsule": ((600, 900), (0.5, 0.68), ("full", 0.92, 0.5, 0.04)),
    "library_hero": ((3840, 1240), (0.5, 0.5), None),
    "page_background": ((1438, 810), (0.5, 0.5), None),
}


# Closer crops where the whole 4K frame would make the cat tiny.
ZOOM = {"header_capsule": 1.3, "main_capsule": 1.15, "small_capsule": 1.2}


def crop_cover(bg: Image.Image, size: tuple, fx: float, fy: float, at: tuple, zoom: float) -> Image.Image:
    """Crop of bg with the target's aspect (zoom 1 = largest) that puts the
    point (fx, fy) of bg at the share `at` of the result where it can."""
    tw, th = size
    scale = max(tw / bg.width, th / bg.height) * zoom
    cw, ch = round(tw / scale), round(th / scale)
    x = min(max(round(bg.width * fx - cw * at[0]), 0), bg.width - cw)
    y = min(max(round(bg.height * fy - ch * at[1]), 0), bg.height - ch)
    return bg.crop((x, y, x + cw, y + ch)).resize(size, Image.LANCZOS)


def shade(img: Image.Image, box: tuple) -> Image.Image:
    """Soft dark glow behind the logo so it reads on a busy floor."""
    mask = Image.new("L", img.size, 0)
    x0, y0, x1, y1 = box
    pad = (x1 - x0) * 0.08
    ImageDraw.Draw(mask).rounded_rectangle((x0 - pad, y0 - pad, x1 + pad, y1 + pad), radius=pad, fill=150)
    mask = mask.filter(ImageFilter.GaussianBlur(pad))
    dark = Image.new("RGBA", img.size, (20, 12, 8, 255))
    return Image.composite(dark, img, mask)


def main() -> None:
    bg_path, logo_path, plain_path, out = sys.argv[1:5]
    fx, fy = (float(sys.argv[5]), float(sys.argv[6])) if len(sys.argv) > 6 else (0.5, 0.5)
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    bg = Image.open(bg_path).convert("RGBA")
    logos = {"full": Image.open(logo_path).convert("RGBA"), "plain": Image.open(plain_path).convert("RGBA")}
    logos = {k: v.crop(v.getbbox()) for k, v in logos.items()}
    for name, (size, at, logo) in CAPSULES.items():
        img = crop_cover(bg, size, fx, fy, at, ZOOM.get(name, 1.0))
        if logo:
            variant, share, ax, ay = logo
            lg = logos[variant]
            w = round(size[0] * share)
            h = round(lg.height * w / lg.width)
            if h > size[1] * 0.9:
                h = round(size[1] * 0.9)
                w = round(lg.width * h / lg.height)
            lg = lg.resize((w, h), Image.LANCZOS)
            x = round((size[0] - w) * ax) if ax != 0.5 else (size[0] - w) // 2
            y = round((size[1] - h) * ay)
            img = shade(img, (x, y, x + w, y + h))
            img.alpha_composite(lg, (x, y))
        img.convert("RGB").save(out / f"{name}.png")
    # Library logo: transparent, the title board fitted into 1280x720.
    lg = logos["plain"]
    k = min(1240 / lg.width, 680 / lg.height)
    lg = lg.resize((round(lg.width * k), round(lg.height * k)), Image.LANCZOS)
    canvas = Image.new("RGBA", (1280, 720), (0, 0, 0, 0))
    canvas.alpha_composite(lg, ((1280 - lg.width) // 2, (720 - lg.height) // 2))
    canvas.save(out / "library_logo.png")
    print(f"{len(CAPSULES) + 1} capsules -> {out}")


if __name__ == "__main__":
    main()
