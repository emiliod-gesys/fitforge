#!/usr/bin/env python3
"""Convert bundled exercise GIFs to animated WebP (smaller APK)."""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

from exercise_media_webp import gif_to_webp

ROOT = Path(__file__).resolve().parents[1]
ASSETS_DIR = ROOT / "assets" / "exercises"
CATALOG_PATH = ROOT / "assets" / "data" / "exercise_catalog.json"
BUILD_CATALOG_PATH = ROOT / "tools" / "build_exercise_catalog.py"
DOWNLOAD_MEDIA_PATH = ROOT / "tools" / "download_exercise_media.py"
MIN_OUTPUT_BYTES = 512


def update_catalog_paths() -> int:
    data = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    changed = 0
    for exercise in data.get("exercises", []):
        image_url = exercise.get("imageUrl")
        if isinstance(image_url, str) and image_url.endswith(".gif"):
            webp_path = image_url[:-4] + ".webp"
            if (ROOT / webp_path).is_file():
                exercise["imageUrl"] = webp_path
                changed += 1
    if changed:
        CATALOG_PATH.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return changed


def update_python_asset_refs() -> int:
    changed = 0
    for path in (BUILD_CATALOG_PATH, DOWNLOAD_MEDIA_PATH):
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        updated = re.sub(
            r"(assets/exercises/[A-Za-z0-9_]+)\.gif",
            r"\1.webp",
            text,
        )
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            changed += 1
    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--quality",
        type=int,
        default=76,
        help="WebP quality (default: 76)",
    )
    parser.add_argument(
        "--delete-gifs",
        action="store_true",
        help="Remove source GIFs after successful conversion",
    )
    parser.add_argument(
        "--skip-catalog",
        action="store_true",
        help="Only convert files; do not update catalog references",
    )
    args = parser.parse_args()

    gifs = sorted(ASSETS_DIR.glob("*.gif"))
    if not gifs:
        print("No GIF files found.")
        if not args.skip_catalog:
            catalog_changed = update_catalog_paths()
            py_changed = update_python_asset_refs()
            print(f"Catalog entries updated: {catalog_changed}")
            print(f"Python tool files updated: {py_changed}")
        return 0

    total_in = 0
    total_out = 0
    converted = 0
    skipped = 0
    failed = 0
    started = time.time()

    for index, gif_path in enumerate(gifs, start=1):
        webp_path = gif_path.with_suffix(".webp")
        try:
            if webp_path.is_file() and webp_path.stat().st_mtime >= gif_path.stat().st_mtime:
                skipped += 1
                continue

            src_size, dest_size = gif_to_webp(gif_path, webp_path, quality=args.quality)
            total_in += src_size
            total_out += dest_size
            converted += 1
            ratio = 100 * dest_size / max(src_size, 1)
            print(
                f"[{index}/{len(gifs)}] {gif_path.name}: "
                f"{src_size // 1024}KB -> {dest_size // 1024}KB ({ratio:.0f}%)"
            )

            if args.delete_gifs:
                gif_path.unlink()
        except (OSError, ValueError) as exc:
            failed += 1
            print(f"[{index}/{len(gifs)}] FAIL {gif_path.name}: {exc}", file=sys.stderr)

    elapsed = time.time() - started
    print()
    print(
        f"Done in {elapsed:.1f}s · converted={converted} skipped={skipped} failed={failed}"
    )
    if total_in:
        saved = total_in - total_out
        print(
            f"Batch size: {total_in / 1_048_576:.1f} MB -> {total_out / 1_048_576:.1f} MB "
            f"(saved {saved / 1_048_576:.1f} MB, {100 * total_out / total_in:.0f}%)"
        )

    if not args.skip_catalog and failed == 0:
        catalog_changed = update_catalog_paths()
        py_changed = update_python_asset_refs()
        print(f"Catalog entries updated: {catalog_changed}")
        print(f"Python tool files updated: {py_changed}")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
