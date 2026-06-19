"""Genera copias con fondo transparente de las medallitas de nivel."""

from __future__ import annotations

from pathlib import Path

from image_background_removal import process_image

ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "assets" / "images" / "player_levels"
OUT_DIR = SRC_DIR / "transparent"


def main() -> None:
    files = sorted(SRC_DIR.glob("level_*.png"))
    files = [f for f in files if f.parent == SRC_DIR]

    if not files:
        raise SystemExit(f"No se encontraron imágenes en {SRC_DIR}")

    for src in files:
        dst = OUT_DIR / src.name
        process_image(src, dst)
        print(f"OK {src.name} -> transparent/{src.name}")


if __name__ == "__main__":
    main()
