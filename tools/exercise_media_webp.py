"""Shared helpers for exercise media (GIF → animated WebP)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

MIN_OUTPUT_BYTES = 512


def gif_to_webp(src: Path, dest: Path, *, quality: int = 76) -> tuple[int, int]:
    """Convert an animated GIF to animated WebP. Returns (input_bytes, output_bytes)."""
    with Image.open(src) as im:
        frames: list[Image.Image] = []
        durations: list[int] = []
        try:
            while True:
                frame = im.copy().convert("RGBA")
                frames.append(frame)
                durations.append(int(im.info.get("duration", 80) or 80))
                im.seek(im.tell() + 1)
        except EOFError:
            pass

        if not frames:
            raise ValueError(f"no frames in {src.name}")

        dest.parent.mkdir(parents=True, exist_ok=True)
        frames[0].save(
            dest,
            save_all=True,
            append_images=frames[1:],
            duration=durations,
            loop=0,
            quality=quality,
            method=6,
            lossless=False,
        )

    src_size = src.stat().st_size
    dest_size = dest.stat().st_size
    if dest_size < MIN_OUTPUT_BYTES:
        dest.unlink(missing_ok=True)
        raise ValueError(f"output too small for {src.name}")
    return src_size, dest_size
