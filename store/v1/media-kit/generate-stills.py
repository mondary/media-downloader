#!/usr/bin/env python3
"""Generate still promo exports from a native offscreen capture (Pillow required)."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

STORE = Path(__file__).resolve().parents[1]
SCREENSHOT = STORE / "screenshots/01-app-history.png"
ICON = STORE / "assets/icon.png"
ASSETS = STORE / "assets"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_REGULAR = "/System/Library/Fonts/Supplemental/Arial.ttf"
BG = "#0b0d12"
WHITE = "#f1f3f7"
MUTED = "#b2bac9"
ACCENT = "#b5e64a"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD if bold else FONT_REGULAR, size)


def export(width: int, height: int, filename: str) -> None:
    image = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(image)
    margin = 68 if width > 1300 else 54
    icon = Image.open(ICON).convert("RGBA")
    icon.thumbnail((64, 64), Image.Resampling.LANCZOS)
    image.paste(icon, (margin, 48), icon)
    draw.text((margin + 80, 63), "PK / MACOS", fill=ACCENT, font=font(20, True))

    title_size = 72 if width > 1300 else 60
    draw.text((margin, 150), "Vos vidéos.", fill=WHITE, font=font(title_size, True))
    draw.text((margin, 224), "À portée de main.", fill=WHITE, font=font(title_size, True))
    draw.text((margin, 332), "Télécharger  ·  Retrouver  ·  Découper", fill=MUTED, font=font(23))
    draw.rounded_rectangle((margin, height - 76, margin + 180, height - 40), radius=18, fill=ACCENT)
    draw.text((margin + 19, height - 69), "macOS 14+", fill=BG, font=font(19, True))

    capture = Image.open(SCREENSHOT).convert("RGB")
    # Crop only the empty offscreen margins; the product view is left untouched.
    capture = capture.crop((245, 82, 1630, 818))
    target_width = 760 if width > 1300 else 610
    target_height = int(capture.height * target_width / capture.width)
    capture = capture.resize((target_width, target_height), Image.Resampling.LANCZOS)
    x = width - target_width + 30
    y = (height - target_height) // 2
    image.paste(capture, (x, y))
    image.save(ASSETS / filename, optimize=True)
    print(ASSETS / filename)


if __name__ == "__main__":
    export(1544, 500, "banner-1544x500.png")
    export(1200, 630, "card-1200x630.png")
