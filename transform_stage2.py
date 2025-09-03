# transform_stage2.py
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).parent
IN_PATH = ROOT / "output" / "careers_stage1.json"
OUT_PATH = ROOT / "output" / "careers_stage2.json"

SPLIT_RE = re.compile(r"[;,]")  # split on commas/semicolons
OR_RE = re.compile(r"\bor\b", re.IGNORECASE)

def _split_items(raw: str | None) -> list[str]:
    """
    Split a comma/semicolon separated string into trimmed items.
    """
    if not raw:
        return []
    return [p.strip() for p in SPLIT_RE.split(raw) if p.strip()]

def _parse_or_groups(raw: str | None) -> list[list[str]]:
    """
    Parse a skills/talents string into a list of OR-groups.
    Example: "Charm, Heal or Intimidate" →
             [["Charm"], ["Heal", "Intimidate"]]
    """
    if not raw:
        return []

    groups: list[list[str]] = []
    parts = SPLIT_RE.split(raw)
    for part in parts:
        if not part.strip():
            continue
        # split "A or B" inside each part
        or_split = [p.strip() for p in OR_RE.split(part) if p.strip()]
        groups.append(or_split)
    return groups

def transform_career(c: dict) -> dict:
    out = {
        "id": c["id"],
        "name": c["name"],
        "type": c["type"],
        "careerClass": c.get("careerClass", ""),
        "description": c.get("description", ""),
        "stats": c.get("stats", {}),
        "skills": _parse_or_groups(c.get("skillsRaw")),
        "talents": _split_items(c.get("talentsRaw")),
        "trappings": _split_items(c.get("trappingsRaw")),
        "entries": _split_items(c.get("entriesRaw")),
        "exits": _split_items(c.get("exitsRaw"))
    }
    return out

def main():
    if not IN_PATH.exists():
        print(f"❌ Input not found: {IN_PATH}")
        sys.exit(1)

    data = json.loads(IN_PATH.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        print("❌ Expected top-level JSON array.")
        sys.exit(1)

    careers2 = [transform_career(c) for c in data]

    OUT_PATH.write_text(json.dumps(careers2, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"✅ Wrote Stage-2 careers → {OUT_PATH}")

if __name__ == "__main__":
    main()
