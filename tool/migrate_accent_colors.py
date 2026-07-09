import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"
SKIP = {
    "core/theme/app_colors.dart",
    "core/theme/app_decorations.dart",
    "widgets/fitforge_logo.dart",
}


def accent_import_for(path: Path) -> str:
    rel = os.path.relpath(ROOT / "core/theme/app_accent.dart", path.parent).replace("\\", "/")
    return f"import '{rel}';"


def migrate_file(path: Path) -> bool:
    rel = path.relative_to(ROOT).as_posix()
    if rel in SKIP:
        return False

    text = path.read_text(encoding="utf-8")
    if not any(token in text for token in ("AppColors.orange", "AppColors.goldDark", "AppColors.orangeDark", "AppColors.gold")):
        return False
    if rel == "core/theme/app_theme.dart":
        return False

    original = text
    text = text.replace("AppColors.orangeDark", "context.accentDark")
    text = text.replace("AppColors.goldDark", "context.accentDark")
    text = text.replace("AppColors.orange", "context.accentColor")
    if rel not in SKIP:
        text = re.sub(r"AppColors\.gold(?!Dark)", "context.accentColor", text)

    if text == original:
        return False

    if "app_accent.dart" not in text:
        lines = text.splitlines()
        insert_at = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                insert_at = i + 1
        lines.insert(insert_at, accent_import_for(path))
        text = "\n".join(lines) + ("\n" if original.endswith("\n") else "")

    seen = set()
    deduped = []
    for line in text.splitlines():
        if "app_accent.dart" in line:
            if line in seen:
                continue
            seen.add(line)
        deduped.append(line)
    text = "\n".join(deduped) + ("\n" if original.endswith("\n") else "")

    path.write_text(text, encoding="utf-8")
    print(f"updated {rel}")
    return True


def main() -> None:
    count = 0
    for path in ROOT.rglob("*.dart"):
        if migrate_file(path):
            count += 1
    print(f"done: {count} files")


if __name__ == "__main__":
    main()
