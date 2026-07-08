#!/usr/bin/env python3
"""Repair bundled exercise media: fix file extensions and re-download mismatched GIFs."""

from __future__ import annotations

import hashlib
import json
import sys
import time
from collections import defaultdict
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / "assets" / "data" / "exercise_catalog.json"
ASSETS_DIR = ROOT / "assets" / "exercises"
HEADERS = {"User-Agent": "FitForge/1.0 (exercise media repair)"}

# ExerciseDB IDs corregidos (evita GIFs duplicados o ejercicios equivocados).
EXERCISEDB_FIXES: dict[str, str] = {
    "ff_calves_elevated_calf_raise": "6HmFgmx",
    "ff_glutes_donkey_kick": "Kpajagk",
    "ff_cardio_hiking": "IZVHb27",
    "ff_cardio_treadmill": "rjiM4L3",
    "ff_legs_pistol_squat": "nqs5HGV",
    "ff_legs_air_squat": "QChZi3x",
    "ff_back_australian_pull_up": "bZGHsAZ",
    "ff_back_pull_up": "lBDjFxJ",
    "ff_back_straight_arm_cable_pulldown": "x69MAlq",
    "ff_legs_leg_press_machine": "10Z2DXU",
    "ff_legs_v_squat_machine": "Qa55kX1",
    "ff_biceps_cable_curl": "G08RZcQ",
    "ff_biceps_high_cable_curl": "wDUqY2u",
    "ff_chest_cable_fly": "Pr9Rhf4",
    "ff_chest_high_to_low_cable_fly": "tBWXbIT",
    "ff_chest_low_to_high_cable_fly": "FVmZVhk",
    "ff_back_close_grip_lat_pulldown_machine": "ecpY0rH",
    "ff_back_lat_pulldown_machine": "LEprlgG",
    "ff_back_wide_grip_lat_pulldown_machine": "rkg41Fb",
    "ff_triceps_single_arm_cable_pushdown": "qRZ5S1N",
    "ff_triceps_straight_bar_pushdown": "gAwDzB3",
    "ff_shoulders_dumbbell_lateral_raise": "DsgkuIt",
    "ff_shoulders_single_arm_dumbbell_lateral_raise": "n5cWCsI",
    "ff_chest_dumbbell_bench_press": "SpYC0Kp",
    "ff_chest_hex_dumbbell_press": "pP8wP2P",
    "ff_chest_push_up": "7E06s6d",
    "ff_chest_ring_push_up": "IaGQCrC",
    "ff_cardio_stair_climber": "j9Q5crt",
    "ff_cardio_stepmill": "j9Q5crt",
}


def detect_format(data: bytes) -> str | None:
    if data[:3] == b"GIF":
        return "gif"
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "png"
    if data[:2] == b"\xff\xd8":
        return "jpg"
    if data[:4] == b"RIFF" and len(data) >= 12 and data[8:12] == b"WEBP":
        return "webp"
    return None


def download(url: str, dest: Path, session: requests.Session, retries: int = 3) -> bool:
    dest.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(retries):
        try:
            response = session.get(url, timeout=60)
            response.raise_for_status()
            content = response.content
            if len(content) < 512:
                raise ValueError(f"response too small ({len(content)} bytes)")
            dest.write_bytes(content)
            return True
        except (requests.RequestException, ValueError) as exc:
            if attempt + 1 >= retries:
                print(f"  FAIL {dest.name}: {exc}", file=sys.stderr)
                return False
            time.sleep(0.5 * (attempt + 1))
    return False


def fix_extensions(exercises: list[dict]) -> list[str]:
    changes: list[str] = []
    for ex in exercises:
        exercise_id = ex["id"]
        image_url = ex.get("imageUrl") or ""
        if not image_url.startswith("assets/"):
            continue

        path = ROOT / image_url
        if not path.is_file():
            continue

        data = path.read_bytes()
        fmt = detect_format(data)
        if fmt is None:
            changes.append(f"{exercise_id}: unknown format")
            continue

        current_ext = path.suffix.lower().lstrip(".")
        if current_ext == fmt or (current_ext in {"jpg", "jpeg"} and fmt == "jpg"):
            continue

        new_path = ASSETS_DIR / f"{exercise_id}.{fmt}"
        if new_path != path:
            if new_path.exists():
                new_path.unlink()
            path.rename(new_path)

        ex["imageUrl"] = f"assets/exercises/{new_path.name}"
        changes.append(f"{exercise_id}: .{current_ext} -> .{fmt}")
    return changes


def redownload(exercises: list[dict], session: requests.Session) -> tuple[list[str], list[str]]:
    by_id = {ex["id"]: ex for ex in exercises}
    ok: list[str] = []
    failed: list[str] = []

    for exercise_id, edb_id in EXERCISEDB_FIXES.items():
        ex = by_id.get(exercise_id)
        if ex is None:
            failed.append(f"{exercise_id}: not in catalog")
            continue

        dest = ASSETS_DIR / f"{exercise_id}.gif"
        urls = [
            f"https://static.exercisedb.dev/media/{edb_id}.gif",
            f"https://assets.exercisedb.dev/media/{edb_id}.gif",
        ]

        success = False
        for url in urls:
            print(f"Downloading {exercise_id} <- {edb_id} ({url})")
            if download(url, dest, session):
                success = True
                break

        if not success:
            failed.append(exercise_id)
            continue

        # Elimina assets viejos con otra extensión.
        for ext in ("png", "webp", "jpg", "jpeg"):
            stale = ASSETS_DIR / f"{exercise_id}.{ext}"
            if stale.is_file():
                stale.unlink()

        ex["imageUrl"] = f"assets/exercises/{dest.name}"
        ex["exercisedbId"] = edb_id
        ok.append(exercise_id)

    return ok, failed


def report_duplicates(exercises: list[dict]) -> None:
    by_hash: dict[str, list[str]] = defaultdict(list)
    for ex in exercises:
        url = ex.get("imageUrl") or ""
        if not url.startswith("assets/"):
            continue
        path = ROOT / url
        if not path.is_file():
            continue
        digest = hashlib.md5(path.read_bytes()).hexdigest()
        by_hash[digest].append(ex["id"])

    dupes = {digest: ids for digest, ids in by_hash.items() if len(ids) > 1}
    print(f"\nDuplicate content groups remaining: {len(dupes)}")
    for ids in sorted(dupes.values(), key=len, reverse=True):
        print(f"  {len(ids)}: {ids}")


def main() -> int:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    exercises = catalog.get("exercises", [])

    print("Fixing file extensions…")
    ext_changes = fix_extensions(exercises)
    for line in ext_changes:
        print(f"  {line}")

    session = requests.Session()
    session.headers.update(HEADERS)

    print("\nRe-downloading corrected ExerciseDB media…")
    ok, failed = redownload(exercises, session)
    print(f"  downloaded={len(ok)} failed={len(failed)}")
    for exercise_id in failed:
        print(f"  - {exercise_id}")

    catalog["exerciseCount"] = len(exercises)
    CATALOG_PATH.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    report_duplicates(exercises)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
