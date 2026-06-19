"""Genera copias con fondo transparente de las medallas de milestones."""

from __future__ import annotations

import sys
from pathlib import Path

from image_background_removal import process_image

ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "assets" / "images" / "milestones"
OUT_DIR = SRC_DIR / "transparent"


def main() -> None:
    if len(sys.argv) > 1:
        sources = [Path(sys.argv[1]).resolve()]
    else:
        sources = sorted(SRC_DIR.glob("tier_*.png"))
        sources = [f for f in sources if f.parent == SRC_DIR]

    if not sources:
        raise SystemExit(f"No se encontraron imágenes tier_*.png en {SRC_DIR}")

    for src in sources:
        dst = OUT_DIR / src.name
        process_image(src, dst)
        print(f"OK {src.name} -> transparent/{src.name}")


if __name__ == "__main__":
    main()
