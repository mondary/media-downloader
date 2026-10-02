#!/usr/bin/env python3
"""Create the landing banner and social card from the native history capture."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SITE = Path(__file__).resolve().parents[1]
SANS = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
MONO = "/System/Library/Fonts/Supplemental/Courier New Bold.ttf"
BG = "#111114"
PAPER = "#09090b"
INK = "#f5f5f7"
MUT = "#a1a1aa"
BLUE = "#93c5fd"


def make(width: int, height: int, filename: str) -> None:
    image = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(image)
    margin = 56 if width > 1200 else 44

    draw.rounded_rectangle((margin, 40, margin + 13, 53), radius=3, fill=BLUE)
    draw.text((margin + 26, 38), "PK / MEDIADOWNLOADER / MACOS", fill=MUT, font=ImageFont.truetype(MONO, 16))

    size = 88 if width > 1200 else 74
    title = ImageFont.truetype(SANS, size)
    draw.text((margin, 105), "Télécharge. Garde.", fill=INK, font=title)
    draw.text((margin, 205), "Découpe.", fill=INK, font=title)

    draw.text((margin, height - 64), "UN LIEN  →  UN FICHIER  →  UN EXTRAIT", fill=INK, font=ImageFont.truetype(MONO, 15))

    capture = Image.open(SITE / "screenshots/01-app-history.png").convert("RGB")
    capture.thumbnail((int(width * .52), int(height * .74)), Image.Resampling.LANCZOS)
    x = width - capture.width - margin
    y = (height - capture.height) // 2
    draw.rounded_rectangle((x - 10, y - 10, x + capture.width + 10, y + capture.height + 10), radius=14, fill="#dce8ff")
    image.paste(capture, (x, y))

    path = SITE / "assets" / filename
    image.save(path, optimize=True)
    print(path)


if __name__ == "__main__":
    make(1544, 500, "banner-1544x500.png")
    make(1200, 630, "social-card.png")
