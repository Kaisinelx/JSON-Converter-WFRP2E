# validate_stage1.py
import json
from pathlib import Path
import sys

try:
    import jsonschema
    from referencing import Registry, Resource
except ImportError:
    print("Install deps first:\n  (.venv) pip install jsonschema referencing")
    sys.exit(1)

ROOT = Path(__file__).parent
DATA_PATH = ROOT / "output" / "careers_stage1.json"
STAGE_SCHEMA_PATH = ROOT / "schemas" / "stage1.schema.json"
CAREER_SCHEMA_PATH = ROOT / "schemas" / "career.schema.json"

def json_path(err):
    segs = ["$"]
    for p in err.path:
        if isinstance(p, int):
            segs.append(f"[{p}]")
        else:
            segs.append("." + str(p))
    return "".join(segs)

def main():
    # Load data & schemas
    try:
        data = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"❌ Missing data file: {DATA_PATH}")
        sys.exit(1)

    try:
        stage_schema = json.loads(STAGE_SCHEMA_PATH.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"❌ Missing schema: {STAGE_SCHEMA_PATH}")
        sys.exit(1)

    try:
        career_schema = json.loads(CAREER_SCHEMA_PATH.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"❌ Missing schema: {CAREER_SCHEMA_PATH}")
        sys.exit(1)

    # Build a local registry using absolute file URIs (works on Windows too)
    career_uri = CAREER_SCHEMA_PATH.resolve().as_uri()          # e.g. file:///C:/.../career.schema.json
    stage_uri  = STAGE_SCHEMA_PATH.resolve().as_uri()

    # Ensure stage schema "items" $ref points to the absolute URI of the career schema,
    # regardless of what's currently inside the file.
    stage_schema = dict(stage_schema)  # shallow copy
    stage_schema["items"] = {"$ref": career_uri}

    registry = Registry().with_resources([
        (career_uri, Resource.from_contents(career_schema)),
        (stage_uri,  Resource.from_contents(stage_schema)),
    ])

    # Validate with Draft 2020-12 and our local registry
    validator = jsonschema.Draft202012Validator(stage_schema, registry=registry)
    errors = sorted(validator.iter_errors(data), key=lambda e: (list(e.path), e.message))

    if not errors:
        print("✅ Validation passed.")
        return

    print(f"❌ Validation failed with {len(errors)} issue(s):\n")
    for i, err in enumerate(errors, 1):
        print(f"{i}. {json_path(err)}")
        print(f"   → {err.message}\n")

if __name__ == "__main__":
    main()
