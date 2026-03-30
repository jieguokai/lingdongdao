#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw


PIXELS = [
    (5, 1, "claw"), (10, 1, "claw"),
    (4, 2, "claw"), (11, 2, "claw"),
    (3, 3, "claw"), (12, 3, "claw"),
    (5, 3, "shell"), (6, 3, "shell"), (7, 3, "shell"), (8, 3, "shell"), (9, 3, "shell"), (10, 3, "shell"),
    (4, 4, "shell"), (5, 4, "shell"), (6, 4, "eye"), (7, 4, "shell"), (8, 4, "shell"), (9, 4, "eye"), (10, 4, "shell"), (11, 4, "shell"),
    (4, 5, "shell"), (5, 5, "shell"), (6, 5, "shell"), (7, 5, "shell"), (8, 5, "shell"), (9, 5, "shell"), (10, 5, "shell"), (11, 5, "shell"),
    (5, 6, "belly"), (6, 6, "belly"), (7, 6, "belly"), (8, 6, "belly"), (9, 6, "belly"), (10, 6, "belly"),
    (5, 7, "belly"), (6, 7, "belly"), (9, 7, "belly"), (10, 7, "belly"),
    (4, 8, "claw"), (6, 8, "shell"), (9, 8, "shell"), (11, 8, "claw"),
    (3, 9, "claw"), (5, 9, "shell"), (10, 9, "shell"), (12, 9, "claw"),
    (5, 10, "claw"), (10, 10, "claw"),
]

COLORS = {
    "shell": (250, 115, 56, 255),
    "claw": (255, 92, 138, 255),
    "belly": (245, 245, 245, 255),
    "eye": (17, 17, 17, 255),
}


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: generate-app-icon.py <output-directory>")

    output_directory = Path(sys.argv[1])
    output_directory.mkdir(parents=True, exist_ok=True)

    for size in (16, 32, 64, 128, 256, 512, 1024):
        image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        inset = int(size * 0.04)
        radius = int(size * 0.23)

        draw.rounded_rectangle(
            (inset, inset, size - inset, size - inset),
            radius=radius,
            fill=(18, 26, 44, 255),
            outline=(255, 255, 255, 24),
            width=max(1, int(size * 0.02)),
        )

        overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        overlay_draw = ImageDraw.Draw(overlay)
        overlay_draw.rounded_rectangle(
            (inset, size * 0.36, size - inset, size - inset),
            radius=radius,
            fill=(7, 136, 140, 150),
        )
        image = Image.alpha_composite(image, overlay)
        draw = ImageDraw.Draw(image)

        pixel = size / 16.0
        padding = size * 0.06
        pixel_size = pixel * 0.86
        corner = max(1, int(pixel * 0.12))

        for x, y, role in PIXELS:
            x0 = padding + (x * pixel)
            y0 = padding + (y * pixel)
            x1 = x0 + pixel_size
            y1 = y0 + pixel_size
            draw.rounded_rectangle((x0, y0, x1, y1), radius=corner, fill=COLORS[role])

        image.save(output_directory / f"icon_{size}x{size}.png")


if __name__ == "__main__":
    main()
