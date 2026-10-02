#!/usr/bin/env python3
"""Fetch actual YouTube thumbnails used by the native promo-history capture."""

from io import BytesIO
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from PIL import Image

SITE = Path(__file__).resolve().parents[1]
VIDEOS = {
    "thumb-bbb.jpg": ("aqz-KE-bpKQ", "Big Buck Bunny", ("maxresdefault", "hqdefault"), 0.37),
    "thumb-sintel.jpg": ("eRsGyueVLvQ", "Sintel", ("maxresdefault", "hqdefault"), 0.52),
    "thumb-tears.jpg": ("R6MlUcmOul8", "Tears of Steel", ("maxresdefault", "hqdefault"), 0.50),
}


def fetch(video_id: str, qualities: tuple[str, ...]) -> Image.Image:
    for quality in qualities:
        url = f"https://i.ytimg.com/vi/{video_id}/{quality}.jpg"
        try:
            with urlopen(Request(url, headers={"User-Agent": "Mozilla/5.0"}), timeout=30) as response:
                data = response.read()
        except HTTPError as error:
            if error.code == 404:
                continue
            raise
        if data.startswith(b"\xff\xd8\xff"):
            return Image.open(BytesIO(data)).convert("RGB")
    raise RuntimeError(f"No real YouTube thumbnail available for {video_id}")


def remove_letterbox(image: Image.Image) -> Image.Image:
    """Trim only the solid black rows added around cinematic source frames."""
    rgb = image.convert("RGB")
    width, height = rgb.size
    pixels = rgb.load()

    def is_content_row(y: int) -> bool:
        nonblack = sum(1 for x in range(width) if max(pixels[x, y]) > 18)
        return nonblack > width * 0.04

    top = 0
    while top < height and not is_content_row(top):
        top += 1
    bottom = height
    while bottom > top and not is_content_row(bottom - 1):
        bottom -= 1
    return rgb.crop((0, top, width, bottom)) if top or bottom < height else rgb


def crop_to_history_aspect(image: Image.Image, focal_x: float) -> Image.Image:
    """Make a clean 4:3 still to match the actual thumbnail slots in history."""
    width, height = image.size
    target_width = min(width, round(height * 4 / 3))
    if target_width == width:
        target_height = min(height, round(width * 3 / 4))
        top = max(0, min(height - target_height, round(height * 0.5 - target_height * 0.5)))
        return image.crop((0, top, width, top + target_height))
    center = round(width * focal_x)
    left = max(0, min(width - target_width, center - target_width // 2))
    return image.crop((left, 0, left + target_width, height))


def main() -> None:
    for folder in (SITE / "assets", SITE / "screenshots"):
        folder.mkdir(parents=True, exist_ok=True)
        for filename, (video_id, title, qualities, focal_x) in VIDEOS.items():
            image = crop_to_history_aspect(remove_letterbox(fetch(video_id, qualities)), focal_x)
            output = folder / filename
            image.save(output, "JPEG", quality=92, optimize=True)
            print(f"{title}: {output} {image.size}")


if __name__ == "__main__":
    main()
