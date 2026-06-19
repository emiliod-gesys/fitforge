"""Utilidades compartidas para quitar fondo negro de assets PNG."""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


def is_background(r: int, g: int, b: int, threshold: int) -> bool:
    return r <= threshold and g <= threshold and b <= threshold


def flood_background_mask(rgb: np.ndarray, threshold: int) -> np.ndarray:
    h, w, _ = rgb.shape
    bg = np.zeros((h, w), dtype=bool)
    queue: deque[tuple[int, int]] = deque()

    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))

    while queue:
        x, y = queue.popleft()
        if x < 0 or x >= w or y < 0 or y >= h or bg[y, x]:
            continue
        pixel = rgb[y, x]
        if not is_background(int(pixel[0]), int(pixel[1]), int(pixel[2]), threshold):
            continue
        bg[y, x] = True
        queue.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])

    return bg


def soft_alpha(rgb: np.ndarray, bg_mask: np.ndarray, threshold: int, feather: int) -> np.ndarray:
    brightness = np.max(rgb, axis=2).astype(np.float32)
    alpha = np.full(rgb.shape[:2], 255, dtype=np.float32)
    alpha[bg_mask] = 0

    edge_band = (~bg_mask) & (brightness <= threshold + feather)
    alpha[edge_band] = ((brightness[edge_band] - threshold) / feather * 255).clip(0, 255)

    return alpha.astype(np.uint8)


def process_image(src: Path, dst: Path, threshold: int = 28, feather: int = 18) -> None:
    img = Image.open(src).convert("RGBA")
    rgb = np.array(img)[..., :3]
    bg_mask = flood_background_mask(rgb, threshold)
    alpha = soft_alpha(rgb, bg_mask, threshold, feather)

    out = np.dstack([rgb, alpha])
    dst.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(out, mode="RGBA").save(dst, optimize=True)
