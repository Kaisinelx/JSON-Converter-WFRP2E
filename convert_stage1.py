import json
from pathlib import Path

# Paths
RAW_FILE = Path("raw/careers_raw.json")
OUTPUT_FILE = Path("output/careers_stage1.json")

# Schema: [
#   name, type, entry, WS, BS, S, T, Ag, Int, WP, Fel, A, W, SB, TB, M, Mag, IP, FP,
#   description, skills, talents, trappings, careerEntries, careerExits,
#   careerClass, source, page, id
# ]

FIELDS = [
    "name", "type", "entry", "WS", "BS", "S", "T", "Ag", "Int", "WP", "Fel", "A",
    "W", "SB", "TB", "M", "Mag", "IP", "FP",
    "description", "skills", "talents", "trappings",
    "careerEntries", "careerExits",
    "careerClass", "source", "page", "id"
]

def load_raw():
    with open(RAW_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def transform(raw_data):
    careers = []
    for row in raw_data:
        career = {}
        for i, field in enumerate(FIELDS):
            # Split semicolon-delimited strings into lists
            if field in ["skills", "talents", "trappings", "careerEntries", "careerExits"]:
                career[field] = row[i].split(";") if row[i] else []
            else:
                career[field] = row[i]
        careers.append(career)
    return careers

def save_output(careers):
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(careers, f, indent=2, ensure_ascii=False)

def main():
    raw_data = load_raw()
    careers = transform(raw_data)
    save_output(careers)
    print(f"✅ Converted {len(careers)} careers → {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
