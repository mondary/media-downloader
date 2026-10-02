#!/usr/bin/env python3
"""Fetch Ko-fi's official logomark from the official Ko-fi CDN."""

from io import BytesIO
from pathlib import Path
from urllib.request import Request, urlopen

from PIL import Image

SITE = Path(__file__).resolve().parents[1]
URL = "https://storage.ko-fi.com/cdn/logomarkLogo.png"
OUTPUT = SITE / "assets/kofi-logomark.png"


def main() -> None:
    request = Request(
        URL,
        headers={
            "User-Agent": "Mozilla/5.0",
            "Referer": "https://ko-fi.com/pouark",
            "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
        },
    )
    with urlopen(request, timeout=30) as response:
        source = response.read()
    image = Image.open(BytesIO(source)).convert("RGBA")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT, "PNG", optimize=True)
    print(f"Official Ko-fi logomark: {OUTPUT} ({image.width}×{image.height})")


if __name__ == "__main__":
    main()
