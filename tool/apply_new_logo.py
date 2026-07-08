"""Procesa el nuevo logo FitForge: versión transparente recortada + icono de app."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

from image_background_removal import flood_background_mask, soft_alpha

ROOT = Path(__file__).resolve().parents[1]
IMAGES = ROOT / "assets" / "images"
SRC = Path(
    r"C:\Users\xemil\.cursor\projects\c-Users-xemil-fitforge\assets"
    r"\c__Users_xemil_AppData_Roaming_Cursor_User_workspaceStorage_d5fb3935aeb44a17d23315451bd9143c"
    r"_images_360a81cd-bcc2-4236-b8a0-0a4df4358f84-4672f089-6ad4-4a6c-92d8-9520269eb7d9.png"
)

THRESHOLD = 40
FEATHER = 22


def transparent_logo(src: Path) -> Image.Image:
    img = Image.open(src).convert("RGBA")
    rgb = np.array(img)[..., :3]
    bg_mask = flood_background_mask(rgb, THRESHOLD)
    alpha = soft_alpha(rgb, bg_mask, THRESHOLD, FEATHER)
    out = np.dstack([rgb, alpha])
    return Image.fromarray(out, mode="RGBA")


def autocrop(img: Image.Image, pad_ratio: float = 0.06) -> Image.Image:
    alpha = np.array(img)[..., 3]
    rows = np.any(alpha > 8, axis=1)
    cols = np.any(alpha > 8, axis=0)
    if not rows.any() or not cols.any():
        return img
    y0, y1 = np.where(rows)[0][[0, -1]]
    x0, x1 = np.where(cols)[0][[0, -1]]
    cropped = img.crop((x0, y0, x1 + 1, y1 + 1))

    w, h = cropped.size
    side = max(w, h)
    pad = int(side * pad_ratio)
    canvas = Image.new("RGBA", (side + 2 * pad, side + 2 * pad), (0, 0, 0, 0))
    canvas.paste(cropped, ((side - w) // 2 + pad, (side - h) // 2 + pad), cropped)
    return canvas


def main() -> None:
    logo = transparent_logo(SRC)
    square = autocrop(logo)

    # Isotipo transparente (spinner + widget de logo).
    icon = square.resize((640, 640), Image.LANCZOS)
    icon.save(IMAGES / "logo_icon.png", optimize=True)
    icon.save(IMAGES / "logo_mark.png", optimize=True)

    # Logo full transparente 1024.
    full = square.resize((1024, 1024), Image.LANCZOS)
    full.save(IMAGES / "logo_full.png", optimize=True)

    # Icono de app: logo sobre fondo negro puro, con margen para el launcher.
    base = Image.new("RGBA", (1024, 1024), (0, 0, 0, 255))
    padded = square.resize((820, 820), Image.LANCZOS)
    base.alpha_composite(padded, ((1024 - 820) // 2, (1024 - 820) // 2))
    base.convert("RGB").save(IMAGES / "app_icon.png", optimize=True)

    print("Saved logo_icon.png, logo_mark.png, logo_full.png, app_icon.png")


if __name__ == "__main__":
    main()
