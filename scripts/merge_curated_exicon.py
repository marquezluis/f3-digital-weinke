#!/usr/bin/env python3
"""
merge_curated_exicon.py  —  Digital Weinke data pipeline
══════════════════════════════════════════════════════════
Merges a curated Exicon reference spreadsheet (F3 Name / Common Name /
Simple Explanation / Cadence / Reps-Sets / Modification / Safety Cue /
Category) into the bundled assets/data/exercises.json produced by
exicon_csv_to_json.py.

Unlike that script — which is a straight transform of an official F3 Exicon
CMS export — this one merges a *second*, hand-curated source on top of it:

  1. Exercises that already exist in exercises.json (matched by normalized
     name/alias) get enriched in place with callStyle/simpleExplanation/
     modification/safetyCue — their id/name/description/aliases/category
     from the official export are left untouched.
  2. Exercises in the spreadsheet with no match in exercises.json are added
     as new entries (id prefixed "exicon-curated-"), using the spreadsheet's
     Simple Explanation as their description since no official Exicon text
     exists for them.

Two spreadsheet categories are intentionally skipped — not real,
block-buildable exercises:
  - "Culture & Lexicon" (AO, PAX, Q, VQ, Credo, ...) — glossary terms.
  - "COT / Closing" (Announcements, Q Message, ...) — agenda items.

CATEGORY MAPPING (spreadsheet → app's 4 block categories):
  Warm-up, Mosey & Running, Indian Run  → warmup
  Coupon Work                           → coupon
  Mary / Finishers, Plank               → mary
  everything else (Core, Upper Body,
    Lower Body, Cardio, Animal Movement,
    Partner)                            → bodyweight

CADENCE MAPPING: IC → inCadence, OYO → onYourOwn, everything else
(Timed, N/A, "IC or OYO") → left unset — not a fixed call style.

USAGE (from the project root, needs openpyxl — pip install openpyxl):
  python3 scripts/merge_curated_exicon.py \\
      --curated  path/to/F3_Exicon_300.xlsx \\
      --exercises assets/data/exercises.json \\
      [--stats]
"""

import argparse
import json
import re
import sys
from pathlib import Path

CATEGORY_MAP = {
    "Warm-up": "warmup",
    "Mosey & Running": "warmup",
    "Indian Run": "warmup",
    "Coupon Work": "coupon",
    "Mary / Finishers": "mary",
    "Plank": "mary",
    "Core": "bodyweight",
    "Upper Body": "bodyweight",
    "Lower Body": "bodyweight",
    "Cardio": "bodyweight",
    "Animal Movement": "bodyweight",
    "Partner": "bodyweight",
}
SKIPPED_CATEGORIES = {"Culture & Lexicon", "COT / Closing"}

CADENCE_MAP = {"IC": "inCadence", "OYO": "onYourOwn"}


def norm(s):
    if not s:
        return ""
    return re.sub(r"[^a-z0-9]+", " ", str(s).lower()).strip()


def slugify(name):
    return re.sub(r"-+", "-", re.sub(r"[^a-z0-9]+", "-", name.lower())).strip("-")


def load_curated_rows(xlsx_path):
    import openpyxl

    wb = openpyxl.load_workbook(xlsx_path, data_only=True, read_only=True)
    ws = wb["F3 Exicon"]
    rows = list(ws.iter_rows(values_only=True))[1:]  # skip header
    out = []
    for r in rows:
        if not r or not r[0]:
            continue
        (name, common_name, simple_explanation, cadence, reps_sets,
         modification, safety_cue, category) = (list(r) + [None] * 8)[:8]
        out.append({
            "name": name,
            "common_name": common_name,
            "simple_explanation": simple_explanation,
            "cadence": cadence,
            "modification": modification,
            "safety_cue": safety_cue,
            "category": category,
        })
    return out


def clean(value):
    if value is None:
        return None
    value = str(value).strip()
    return value if value and value.upper() != "N/A" else None


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                  formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--curated", required=True, help="Path to the curated Exicon xlsx")
    ap.add_argument("--exercises", default="assets/data/exercises.json",
                     help="Path to exercises.json (read + overwritten in place)")
    ap.add_argument("--stats", action="store_true", help="Print merge stats")
    args = ap.parse_args()

    data = json.loads(Path(args.exercises).read_text())
    exercises = data["exercises"]

    # normalized name/alias -> index into `exercises`
    name_index = {}
    for i, ex in enumerate(exercises):
        name_index[norm(ex["name"])] = i
        for a in ex.get("aliases", []):
            name_index.setdefault(norm(a), i)

    rows = load_curated_rows(args.curated)

    enriched = 0
    added = 0
    skipped_lexicon = 0

    for row in rows:
        category = row["category"]
        if category in SKIPPED_CATEGORIES:
            skipped_lexicon += 1
            continue

        cadence = CADENCE_MAP.get(clean(row["cadence"]))
        simple_explanation = clean(row["simple_explanation"])
        modification = clean(row["modification"])
        safety_cue = clean(row["safety_cue"])

        key = norm(row["name"])
        if key in name_index:
            ex = exercises[name_index[key]]
            if cadence:
                ex["callStyle"] = cadence
            if simple_explanation:
                ex["simpleExplanation"] = simple_explanation
            if modification:
                ex["modification"] = modification
            if safety_cue:
                ex["safetyCue"] = safety_cue
            enriched += 1
            continue

        app_category = CATEGORY_MAP.get(category)
        if app_category is None:
            # Unmapped category we didn't anticipate — skip rather than guess.
            skipped_lexicon += 1
            continue

        aliases = []
        common_name = clean(row["common_name"])
        if common_name and norm(common_name) != key:
            aliases.append(common_name)

        new_ex = {
            "id": f"exicon-curated-{slugify(row['name'])}",
            "name": row["name"],
            "description": simple_explanation or row["name"],
            "aliases": aliases,
            "category": app_category,
            "equipment": "coupon" if app_category == "coupon" else "none",
            "intensity": "intermediate",
        }
        if cadence:
            new_ex["callStyle"] = cadence
        if simple_explanation:
            new_ex["simpleExplanation"] = simple_explanation
        if modification:
            new_ex["modification"] = modification
        if safety_cue:
            new_ex["safetyCue"] = safety_cue

        exercises.append(new_ex)
        name_index[key] = len(exercises) - 1
        added += 1

    data["exercise_count"] = len(exercises)
    if "curated-exicon-300" not in data["source"]:
        data["source"] = data["source"] + " + curated-exicon-300-merge"

    Path(args.exercises).write_text(json.dumps(data, ensure_ascii=False))

    if args.stats:
        print(f"Curated rows: {len(rows)}")
        print(f"Enriched existing exercises: {enriched}")
        print(f"Added new exercises: {added}")
        print(f"Skipped (lexicon/agenda/unmapped): {skipped_lexicon}")
        print(f"Total exercises now: {len(exercises)}")


if __name__ == "__main__":
    sys.exit(main())
