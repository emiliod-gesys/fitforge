#!/usr/bin/env python3
"""Quita fondo negro o verde (chroma) de emblemas de nivel y los guarda en assets."""

from __future__ import annotations

import argparse
import statistics
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
LEVELS_DIR = ROOT / "assets" / "images" / "player_levels"
TRANSPARENT_DIR = LEVELS_DIR / "transparent"

BADGE_OUTPUTS = {
    "bronze": "level_1_9.png",
    "silver": "level_10_24.png",
    "gold": "level_25_49.png",
    "platinum": "level_50_74.png",
    "diamond": "level_75_99.png",
    "master": "level_100_149.png",
    "grandmaster": "level_150_199.png",
    "legend": "level_200_299.png",
    "mythic": "level_300_499.png",
    "immortal": "level_500_plus.png",
}


def remove_black_background(
    image: Image.Image,
    *,
    threshold: int = 35,
    feather: int = 25,
) -> Image.Image:
    result = image.convert("RGBA")
    pixels = result.load()
    width, height = result.size

    for y in range(height):
        for x in range(width):
            red, green, blue, _alpha = pixels[x, y]
            peak = max(red, green, blue)
            if peak <= threshold:
                pixels[x, y] = (red, green, blue, 0)
            elif peak < threshold + feather:
                alpha = int(255 * (peak - threshold) / feather)
                pixels[x, y] = (red, green, blue, max(0, min(255, alpha)))
            else:
                pixels[x, y] = (red, green, blue, 255)

    return result


def sample_border_color(image: Image.Image) -> tuple[int, int, int]:
    rgb = image.convert("RGB")
    width, height = rgb.size
    samples: list[tuple[int, int, int]] = []

    for x in range(width):
        samples.append(rgb.getpixel((x, 0)))
        samples.append(rgb.getpixel((x, height - 1)))
    for y in range(height):
        samples.append(rgb.getpixel((0, y)))
        samples.append(rgb.getpixel((width - 1, y)))

    return tuple(int(statistics.median(channel)) for channel in zip(*samples, strict=True))


def remove_chroma_green_background(
    image: Image.Image,
    *,
    tolerance: int = 42,
    feather: int = 28,
    dominance: int = 35,
    min_green: int = 70,
) -> Image.Image:
    key_color = sample_border_color(image)
    result = image.convert("RGBA")
    pixels = result.load()
    width, height = result.size
    cutoff = tolerance + feather
    key_red, key_green, key_blue = key_color
    use_distance_key = key_green < min_green

    for y in range(height):
        for x in range(width):
            red, green, blue, _alpha = pixels[x, y]
            if use_distance_key:
                distance = (
                    (red - key_red) ** 2
                    + (green - key_green) ** 2
                    + (blue - key_blue) ** 2
                ) ** 0.5
                if distance <= tolerance:
                    pixels[x, y] = (red, green, blue, 0)
                elif distance <= cutoff:
                    alpha = int(255 * (distance - tolerance) / feather)
                    pixels[x, y] = (red, green, blue, max(0, min(255, alpha)))
                else:
                    pixels[x, y] = (red, green, blue, 255)
                continue

            green_lead = green - max(red, blue)
            dominance_cutoff = dominance + feather
            if green >= min_green and green_lead >= dominance_cutoff:
                pixels[x, y] = (red, green, blue, 0)
            elif green >= min_green and green_lead >= dominance:
                alpha = int(255 * (dominance_cutoff - green_lead) / feather)
                pixels[x, y] = (red, green, blue, max(0, min(255, alpha)))
            else:
                pixels[x, y] = (red, green, blue, 255)

    return result


def trim_alpha(image: Image.Image, *, padding: int = 12) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        return image

    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(image.size[0], right + padding)
    bottom = min(image.size[1], bottom + padding)
    return image.crop((left, top, right, bottom))


def resize_max(image: Image.Image, max_dim: int) -> Image.Image:
    width, height = image.size
    scale = max_dim / max(width, height)
    if scale >= 1:
        return image
    return image.resize(
        (int(width * scale), int(height * scale)),
        Image.Resampling.LANCZOS,
    )


def process_badge(
    source: Path,
    tier: str,
    *,
    background: str = "black",
    max_dim: int = 512,
    threshold: int = 35,
    feather: int = 25,
    chroma_dominance: int = 35,
    chroma_min_green: int = 70,
    chroma_tolerance: int = 42,
    chroma_feather: int = 28,
) -> tuple[Path, Path]:
    if tier not in BADGE_OUTPUTS:
        known = ", ".join(sorted(BADGE_OUTPUTS))
        raise SystemExit(f"Tier desconocido '{tier}'. Usa uno de: {known}")

    filename = BADGE_OUTPUTS[tier]
    transparent_path = TRANSPARENT_DIR / filename
    opaque_path = LEVELS_DIR / filename

    image = Image.open(source)
    if background == "green":
        image = remove_chroma_green_background(
            image,
            tolerance=chroma_tolerance,
            feather=chroma_feather,
            dominance=chroma_dominance,
            min_green=chroma_min_green,
        )
    else:
        image = remove_black_background(image, threshold=threshold, feather=feather)
    image = trim_alpha(image)
    image = resize_max(image, max_dim)

    TRANSPARENT_DIR.mkdir(parents=True, exist_ok=True)
    LEVELS_DIR.mkdir(parents=True, exist_ok=True)

    image.save(transparent_path, optimize=True)
    image.save(opaque_path, optimize=True)

    return transparent_path, opaque_path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "source",
        type=Path,
        help="PNG/JPG del emblema con fondo negro o verde",
    )
    parser.add_argument(
        "tier",
        choices=sorted(BADGE_OUTPUTS.keys()),
        help="Rango del emblema",
    )
    parser.add_argument(
        "--background",
        choices=("black", "green"),
        default="black",
        help="Tipo de fondo a eliminar (default: black)",
    )
    parser.add_argument("--max-dim", type=int, default=512)
    parser.add_argument("--threshold", type=int, default=35)
    parser.add_argument("--feather", type=int, default=25)
    parser.add_argument("--chroma-dominance", type=int, default=35)
    parser.add_argument("--chroma-min-green", type=int, default=70)
    parser.add_argument("--chroma-tolerance", type=int, default=42)
    parser.add_argument("--chroma-feather", type=int, default=28)
    args = parser.parse_args()

    transparent, opaque = process_badge(
        args.source,
        args.tier,
        background=args.background,
        max_dim=args.max_dim,
        threshold=args.threshold,
        feather=args.feather,
        chroma_dominance=args.chroma_dominance,
        chroma_min_green=args.chroma_min_green,
        chroma_tolerance=args.chroma_tolerance,
        chroma_feather=args.chroma_feather,
    )
    print(f"OK transparent -> {transparent}")
    print(f"OK opaque      -> {opaque}")


if __name__ == "__main__":
    main()
