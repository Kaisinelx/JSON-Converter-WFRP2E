# repair_stage1.py
from __future__ import annotations
import json, re, sys
from pathlib import Path
from typing import Any, Dict, List

ROOT = Path(__file__).parent
IN_PATH = ROOT / "output" / "careers_stage1.json"
OUT_PATH = ROOT / "output" / "careers_stage1.fixed.json"
BACKUP_PATH = ROOT / "output" / "careers_stage1.json.bak"

WS_RE = re.compile(r"\s+")

ALLOWED_ROOT_KEYS = {
    "id","name","type","careerClass","description","stats",
    "skillsRaw","talentsRaw","trappingsRaw","entriesRaw","exitsRaw",
    "notes","source"
}
ALLOWED_STATS_KEYS = {"WS","BS","S","T","Ag","Int","WP","Fel","A","W","SB","TB","M","Mag","IP","FP"}

def _collapse_ws(s: str | None) -> str:
    if not isinstance(s, str):
        return ""
    return WS_RE.sub(" ", s).strip()

def _to_number(x: Any) -> float | int | None:
    if isinstance(x, (int, float)):
        return x
    if isinstance(x, str):
        s = x.strip()
        if s == "":
            return None
        try:
            if "." in s:
                return float(s)
            return int(s)
        except ValueError:
            return None
    return None

def _normalize_career(c: Dict[str, Any]) -> Dict[str, Any]:
    out: Dict[str, Any] = {}

    # keep only allowed root keys
    for k in list(c.keys()):
        if k not in ALLOWED_ROOT_KEYS:
            continue
        out[k] = c[k]

    # id → string, nonempty
    cid = out.get("id")
    if cid is None:
        cid = ""
    if not isinstance(cid, str):
        cid = str(cid)
    out["id"] = cid.strip()

    # strings
    for key in ("name","type","careerClass","description","skillsRaw",
                "talentsRaw","trappingsRaw","entriesRaw","exitsRaw",
                "notes","source"):
        if key in out:
            out[key] = _collapse_ws(out.get(key))

    # type enum
    if out.get("type") not in ("basic","advanced"):
        out["type"] = "basic"  # default fallback

    # stats cleanup
    stats_in = out.get("stats")
    stats_out: Dict[str, Any] = {}
    if isinstance(stats_in, dict):
        for k, v in stats_in.items():
            if k in ALLOWED_STATS_KEYS:
                num = _to_number(v)
                if num is not None:
                    stats_out[k] = num
    out["stats"] = stats_out

    return out

def _dedupe_ids(careers: List[Dict[str, Any]]) -> None:
    seen: dict[str, int] = {}
    for c in careers:
        base = c.get("id","").strip() or "career"
        count = seen.get(base, 0)
        if count == 0:
            # first time
            seen[base] = 1
            c["id"] = base
        else:
            seen[base] = count + 1
            c["id"] = f"{base}-{seen[base]}"

def main():
    if not IN_PATH.exists():
        print(f"❌ Input not found: {IN_PATH}")
        sys.exit(1)

    data = json.loads(IN_PATH.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        print("❌ Expected a top-level JSON array of careers.")
        sys.exit(1)

    fixed = [_normalize_career(c) for c in data if isinstance(c, dict)]
    _dedupe_ids(fixed)

    # backup original once
    try:
        if not BACKUP_PATH.exists():
            BACKUP_PATH.write_text(IN_PATH.read_text(encoding="utf-8"), encoding="utf-8")
    except Exception as e:
        print(f"⚠️ Could not create backup: {e}")

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(fixed, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"✅ Wrote fixed file → {OUT_PATH}")
    print("Next:")
    print(f"  copy \"{OUT_PATH}\" \"{IN_PATH}\"")
    print("  python validate_stage1.py")

if __name__ == "__main__":
    main()
