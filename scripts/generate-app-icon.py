#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


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
    "shell": (247, 124, 63, 255),
    "claw": (255, 87, 120, 255),
    "belly": (244, 239, 232, 255),
    "eye": (18, 20, 23, 255),
}

MIN_X = min(x for x, _, _ in PIXELS)
MAX_X = max(x for x, _, _ in PIXELS)
MIN_Y = min(y for _, y, _ in PIXELS)
MAX_Y = max(y for _, y, _ in PIXELS)


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: generate-app-icon.py <output-directory>")

    output_directory = Path(sys.argv[1])
    output_directory.mkdir(parents=True, exist_ok=True)

    for size in (16, 32, 64, 128, 256, 512, 1024):
        image = build_icon(size)
        image.save(output_directory / f"icon_{size}x{size}.png")


def build_icon(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    base = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(base)

    inset = int(size * 0.04)
    radius = int(size * 0.24)
    border_width = max(1, int(size * 0.014))

    draw.rounded_rectangle(
        (inset, inset, size - inset, size - inset),
        radius=radius,
        fill=(18, 22, 31, 255),
        outline=(255, 255, 255, 28),
        width=border_width,
    )

    add_top_sheen(base, size, inset, radius)
    add_depth_panel(base, size, inset)
    add_soft_halo(base, size)
    add_orbit_line(base, size)
    add_lobster_shadow(base, size)
    add_lobster(base, size)
    add_micro_badge(base, size)

    image = Image.alpha_composite(image, base)
    return image


def add_top_sheen(base: Image.Image, size: int, inset: int, radius: int) -> None:
    sheen = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheen)
    top_height = int(size * 0.42)
    for row in range(top_height):
        alpha = int(56 * (1 - row / max(top_height, 1)))
        draw.rectangle(
            (inset, inset + row, size - inset, inset + row + 1),
            fill=(255, 255, 255, alpha),
        )
    sheen = sheen.filter(ImageFilter.GaussianBlur(radius=size * 0.015))

    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (inset, inset, size - inset, size - inset),
        radius=radius,
        fill=255,
    )
    sheen.putalpha(ImageChops.multiply(sheen.getchannel("A"), mask))
    base.alpha_composite(sheen)


def add_depth_panel(base: Image.Image, size: int, inset: int) -> None:
    panel = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(panel)
    panel_rect = (
        inset + size * 0.10,
        inset + size * 0.12,
        size - inset - size * 0.10,
        size - inset - size * 0.12,
    )
    draw.rounded_rectangle(
        panel_rect,
        radius=int(size * 0.16),
        fill=(25, 31, 42, 160),
        outline=(255, 255, 255, 12),
        width=max(1, int(size * 0.008)),
    )
    panel = panel.filter(ImageFilter.GaussianBlur(radius=size * 0.01))
    base.alpha_composite(panel)


def add_soft_halo(base: Image.Image, size: int) -> None:
    halo = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(halo)
    cx = size * 0.50
    cy = size * 0.49
    rx = size * 0.28
    ry = size * 0.22
    draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=(43, 164, 196, 56))
    draw.ellipse((cx - rx * 0.78, cy - ry * 0.78, cx + rx * 0.78, cy + ry * 0.78), fill=(255, 113, 112, 28))
    halo = halo.filter(ImageFilter.GaussianBlur(radius=size * 0.035))
    base.alpha_composite(halo)


def add_orbit_line(base: Image.Image, size: int) -> None:
    orbit = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(orbit)
    rect = (
        size * 0.14,
        size * 0.16,
        size * 0.86,
        size * 0.84,
    )
    draw.arc(rect, start=220, end=18, fill=(255, 255, 255, 22), width=max(1, int(size * 0.008)))
    draw.arc(rect, start=35, end=118, fill=(69, 179, 197, 60), width=max(1, int(size * 0.008)))
    orbit = orbit.filter(ImageFilter.GaussianBlur(radius=size * 0.004))
    base.alpha_composite(orbit)


def add_lobster_shadow(base: Image.Image, size: int) -> None:
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    width = size * 0.28
    height = size * 0.06
    cx = size * 0.50
    cy = size * 0.71
    draw.ellipse((cx - width / 2, cy - height / 2, cx + width / 2, cy + height / 2), fill=(6, 9, 14, 160))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=size * 0.02))
    base.alpha_composite(shadow)


def add_lobster(base: Image.Image, size: int) -> None:
    draw = ImageDraw.Draw(base)
    pixel = size / 16.8
    sprite_width = (MAX_X - MIN_X + 1) * pixel
    sprite_height = (MAX_Y - MIN_Y + 1) * pixel
    anchor_x = (size - sprite_width) / 2 - (MIN_X * pixel)
    anchor_y = (size - sprite_height) / 2 - (MIN_Y * pixel) + (size * 0.01)
    pixel_size = pixel * 0.94
    corner = max(1, int(pixel * 0.16))

    for x, y, role in PIXELS:
        x0 = anchor_x + (x * pixel)
        y0 = anchor_y + (y * pixel)
        x1 = x0 + pixel_size
        y1 = y0 + pixel_size
        draw.rounded_rectangle((x0, y0, x1, y1), radius=corner, fill=COLORS[role])

    add_specular_hits(draw, size, pixel, anchor_x, anchor_y)


def add_specular_hits(draw: ImageDraw.ImageDraw, size: int, pixel: float, anchor_x: float, anchor_y: float) -> None:
    sparkle = [
        (anchor_x + 8.35 * pixel, anchor_y + 3.8 * pixel, size * 0.018, (255, 248, 227, 135)),
        (anchor_x + 5.1 * pixel, anchor_y + 2.8 * pixel, size * 0.014, (255, 255, 255, 90)),
    ]
    for cx, cy, radius, color in sparkle:
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=color)


def add_micro_badge(base: Image.Image, size: int) -> None:
    badge = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(badge)
    rect = (
        size * 0.69,
        size * 0.20,
        size * 0.83,
        size * 0.34,
    )
    draw.rounded_rectangle(
        rect,
        radius=int(size * 0.05),
        fill=(31, 39, 54, 210),
        outline=(255, 255, 255, 30),
        width=max(1, int(size * 0.006)),
    )
    cx = (rect[0] + rect[2]) / 2
    cy = (rect[1] + rect[3]) / 2
    dot_radius = size * 0.024
    draw.ellipse((cx - dot_radius, cy - dot_radius, cx + dot_radius, cy + dot_radius), fill=(70, 193, 210, 255))
    badge = badge.filter(ImageFilter.GaussianBlur(radius=size * 0.002))
    base.alpha_composite(badge)


if __name__ == "__main__":
    main()
