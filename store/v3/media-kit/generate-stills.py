#!/usr/bin/env python3
"""Create the current landing's local banner and social card from a native capture."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SITE = Path(__file__).resolve().parents[1]
FONT = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
MONO = "/System/Library/Fonts/Supplemental/Courier New Bold.ttf"
PAPER = "#ecebe6"
INK = "#171918"
YELLOW = "#f2d010"


def make(width: int, height: int, filename: str) -> None:
    image = Image.new("RGB", (width, height), PAPER)
    draw = ImageDraw.Draw(image)
    padding = 55 if width > 1200 else 44
    draw.text((padding, 34), "PK / MEDIADOWNLOADER", fill=INK, font=ImageFont.truetype(MONO, 18))
    size = 93 if width > 1200 else 79
    title = ImageFont.truetype(FONT, size)
    draw.text((padding, 120), "GARDEZ CE", fill=INK, font=title)
    draw.text((padding, 215), "QUI COMPTE.", fill=INK, font=title)
    draw.ellipse((padding, height - 74, padding + 19, height - 55), fill=YELLOW)
    draw.text((padding + 36, height - 77), "UN LIEN  /  UN FICHIER  /  UN EXTRAIT", fill=INK, font=ImageFont.truetype(MONO, 16))
    capture = Image.open(SITE / "screenshots/01-app-history.png").convert("RGB")
    capture.thumbnail((int(width * .48), int(height * .73)), Image.Resampling.LANCZOS)
    x = width - capture.width - padding
    y = (height - capture.height) // 2
    draw.rectangle((x - 14, y - 14, x + capture.width + 14, y + capture.height + 14), fill=INK)
    image.paste(capture, (x, y))
    path = SITE / "assets" / filename
    image.save(path, optimize=True)
    print(path)


if __name__ == "__main__":
    make(1544, 500, "banner-1544x500.png")
    make(1200, 630, "social-card.png")
