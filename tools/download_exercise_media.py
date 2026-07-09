#!/usr/bin/env python3
"""Bundle exercise GIFs locally and point the catalog to assets/exercises/."""

from __future__ import annotations

import json
import sys
import time
import unicodedata
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import requests
from rapidfuzz import fuzz, process

from exercise_media_webp import gif_to_webp

ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / "assets" / "data" / "exercise_catalog.json"
ASSETS_DIR = ROOT / "assets" / "exercises"
EXERCISEDB_RAW_PATH = ROOT / "tools" / "exercise_match_output" / "exercisedb_raw.json"
GYM_GIFS_INDEX = (
    "https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/api/en/exercises.json"
)
GYM_GIFS_BASE = "https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0"
MIN_MATCH_SCORE = 78
MIN_CATALOG_MATCH_SCORE = 86
HEADERS = {"User-Agent": "FitForge/1.0 (exercise media bundler)"}

# Catálogo apunta a otro asset con el mismo visual.
CATALOG_ASSET_ALIASES: dict[str, str] = {
    "ff_legs_front_squat": "assets/exercises/ff_legs_barbell_front_squat.jpg",
    "ff_back_romanian_deadlift": "assets/exercises/ff_back_barbell_romanian_deadlift.webp",
}

# Sin match fiable en ExerciseDB; GIF del índice GymGifs por nombre exacto.
MANUAL_GYM_GIF_OVERRIDES: dict[str, str] = {
    "ff_cardio_swimming": "Swimmer Kicks v2 Male",
    "ff_shoulders_wall_walk": "Handstand",
}


def normalize_name(value: str) -> str:
    value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    value = value.lower()
    value = re.sub(r"[^a-z0-9]+", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def local_asset_path(exercise_id: str, ext: str) -> str:
    return f"assets/exercises/{exercise_id}.{ext}"


def resolve_existing_asset(exercise_id: str, image_url: str | None) -> Path | None:
    candidates: list[Path] = []
    if image_url and image_url.startswith("assets/"):
        candidates.append(ROOT / image_url)
    for ext in ("png", "gif", "webp"):
        candidates.append(ASSETS_DIR / f"{exercise_id}.{ext}")

    for path in candidates:
        if path.is_file() and path.stat().st_size > 512:
            return path
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
            if content[:15].lower().startswith(b"<!doctype") or content[:5].lower() == b"<html":
                raise ValueError("received HTML instead of media")
            dest.write_bytes(content)
            return True
        except (requests.RequestException, ValueError) as exc:
            if attempt + 1 >= retries:
                print(f"  FAIL {dest.name}: {exc}", file=sys.stderr)
                return False
            time.sleep(0.6 * (attempt + 1))
    return False


def remote_candidates(exercise: dict) -> list[str]:
    urls: list[str] = []
    image_url = (exercise.get("imageUrl") or "").strip()
    exercisedb_id = exercise.get("exercisedbId")

    if image_url.startswith("http"):
        urls.append(image_url)

    if exercisedb_id:
        urls.extend(
            [
                f"https://static.exercisedb.dev/media/{exercisedb_id}.gif",
                f"https://assets.exercisedb.dev/media/{exercisedb_id}.gif",
            ]
        )

    deduped: list[str] = []
    seen: set[str] = set()
    for url in urls:
        if url not in seen:
            seen.add(url)
            deduped.append(url)
    return deduped


def load_gym_gif_index(session: requests.Session) -> tuple[list[str], dict[str, dict]]:
    print("Loading ExerciseGymGifsDB index…", flush=True)
    response = session.get(GYM_GIFS_INDEX, timeout=120)
    response.raise_for_status()
    exercises = response.json()["exercises"]
    names = [ex["name"] for ex in exercises]
    by_name = {ex["name"]: ex for ex in exercises}
    print(f"  {len(exercises)} remote GIF entries", flush=True)
    return names, by_name


def load_exercisedb_names() -> dict[str, str]:
    if not EXERCISEDB_RAW_PATH.is_file():
        return {}
    raw = json.loads(EXERCISEDB_RAW_PATH.read_text(encoding="utf-8"))
    return {
        item["exerciseId"]: item["name"]
        for item in raw
        if item.get("exerciseId") and item.get("name")
    }


def match_gym_gif(
    *,
    english_name: str,
    exercisedb_name: str | None,
    names: list[str],
    by_name: dict[str, dict],
) -> dict | None:
    candidates: list[tuple[str, int]] = []

    for label, cutoff in (
        (exercisedb_name, MIN_MATCH_SCORE),
        (english_name, MIN_CATALOG_MATCH_SCORE),
    ):
        if not label:
            continue

        direct = by_name.get(label.title()) or by_name.get(label)
        if direct is not None:
            return direct

        normalized_names = {normalize_name(name): name for name in names}
        direct_norm = normalized_names.get(normalize_name(label))
        if direct_norm:
            return by_name[direct_norm]

        match = process.extractOne(
            label,
            names,
            scorer=fuzz.token_sort_ratio,
            score_cutoff=cutoff,
        )
        if match is not None:
            candidates.append(match)

    if not candidates:
        return None

    best = max(candidates, key=lambda item: item[1])
    return by_name[best[0]]


def gym_gif_url(entry: dict) -> str:
    if entry.get("gifUrl"):
        return entry["gifUrl"]
    file_path = entry.get("file")
    if file_path:
        return f"{GYM_GIFS_BASE}/{file_path}"
    return f"{GYM_GIFS_BASE}/{entry['muscle']}/{entry['slug']}.gif"


def main() -> int:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    exercises = catalog.get("exercises", [])
    session = requests.Session()
    session.headers.update(HEADERS)

    gym_names, gym_by_name = load_gym_gif_index(session)
    exercisedb_names = load_exercisedb_names()

    downloaded = 0
    linked = 0
    skipped = 0
    failed: list[str] = []

    for ex in exercises:
        exercise_id = ex["id"]
        alias = CATALOG_ASSET_ALIASES.get(exercise_id)
        if alias is not None:
            alias_path = ROOT / alias
            if alias_path.is_file():
                ex["imageUrl"] = alias
                linked += 1
                continue
            failed.append(f"{exercise_id}: missing alias asset {alias}")
            continue

        existing = resolve_existing_asset(exercise_id, ex.get("imageUrl"))
        if existing is not None:
            ex["imageUrl"] = f"assets/exercises/{existing.name}"
            skipped += 1
            continue

        english_name = (ex.get("names") or {}).get("en", "").strip()
        exercisedb_name = exercisedb_names.get(ex.get("exercisedbId") or "")

        manual_name = MANUAL_GYM_GIF_OVERRIDES.get(exercise_id)
        gym_entry = gym_by_name.get(manual_name) if manual_name else None
        if gym_entry is None:
            gym_entry = match_gym_gif(
                english_name=english_name,
                exercisedb_name=exercisedb_name,
                names=gym_names,
                by_name=gym_by_name,
            )

        dest = ASSETS_DIR / f"{exercise_id}.gif"
        success = False

        if gym_entry is not None:
            url = gym_gif_url(gym_entry)
            print(f"Downloading {exercise_id} <- {gym_entry['name']}")
            success = download(url, dest, session)

        if not success:
            for url in remote_candidates(ex):
                print(f"Downloading {exercise_id} <- {url}")
                if download(url, dest, session):
                    success = True
                    break

        if success:
            webp_dest = ASSETS_DIR / f"{exercise_id}.webp"
            try:
                gif_to_webp(dest, webp_dest)
                dest.unlink(missing_ok=True)
                ex["imageUrl"] = local_asset_path(exercise_id, "webp")
            except (OSError, ValueError) as exc:
                print(f"  WARN webp convert failed for {exercise_id}: {exc}", file=sys.stderr)
                ex["imageUrl"] = local_asset_path(exercise_id, "gif")
            downloaded += 1
        else:
            failed.append(f"{exercise_id}: {english_name or 'no english name'}")

    catalog["exerciseCount"] = len(exercises)
    CATALOG_PATH.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(
        f"\nDone. downloaded={downloaded} linked_aliases={linked} "
        f"already_local={skipped} failed={len(failed)}",
        flush=True,
    )
    if failed:
        print("Failures:", flush=True)
        for line in failed:
            print(f"  - {line}", flush=True)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
