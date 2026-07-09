import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"


def fix_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if "context.accent" not in text:
        return False

    lines = text.splitlines()
    changed = False
    for i, line in enumerate(lines):
        if "context.accent" not in line:
            continue
        start = max(0, i - 7)
        block = lines[start : i + 1]
        for j in range(len(block) - 1, -1, -1):
            idx = start + j
            if re.search(r"\bconst\b", lines[idx]):
                new_line = re.sub(r"\bconst\s+", "", lines[idx], count=1)
                if new_line != lines[idx]:
                    lines[idx] = new_line
                    changed = True
                break

    if not changed:
        return False

    path.write_text("\n".join(lines) + ("\n" if text.endswith("\n") else ""), encoding="utf-8")
    print(f"fixed const {path.relative_to(ROOT)}")
    return True


def main() -> None:
    count = 0
    for path in ROOT.rglob("*.dart"):
        if fix_file(path):
            count += 1
    print(f"done: {count}")


if __name__ == "__main__":
    main()
