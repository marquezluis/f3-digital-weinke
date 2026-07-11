#!/usr/bin/env python3
"""
exicon_csv_to_json.py  —  Digital Weinke data pipeline
═══════════════════════════════════════════════════════
Converts an F3 Exicon CSV export into the exercises.json asset used by the
Digital Weinke Flutter app.

COLUMN CONTRACT (as exported from the F3 Exicon / Sanity CMS):
  • ID          — unique slug, e.g. "exicon-1776742880487-0-50-500"
  • Name        — exercise name (displayed in the app)
  • Description — HTML-formatted description
  • Aliases     — comma-separated, JSON array, or "[object Object]"

Additional columns are preserved in an `extra` dict and written through to
JSON, so this script degrades gracefully as the schema evolves.

USAGE (from the project root):
  python3 scripts/exicon_csv_to_json.py \\
      --input  path/to/f3-codex-export.csv \\
      --output assets/data/exercises.json \\
      [--pretty]    indent JSON (human-readable but ~4× larger)
      [--stats]     print category + intensity counts after conversion

EXAMPLE:
  python3 scripts/exicon_csv_to_json.py \\
      --input ../f3-codex-export.csv \\
      --output assets/data/exercises.json \\
      --pretty --stats

CATEGORY INFERENCE:
  The Exicon CSV has no category column. This script assigns one of four
  Digital Weinke categories from keyword scoring on name + description:

    warmup      — SSH, mosey, windmill, arm circle, imperial walker, …
    coupon      — coupon, block, sandbag, kettlebell, dumbbell, plate, …
    mary        — plank, flutter kick, LBC, crunch, sit-up, ab, …
    bodyweight  — default; merkin, squat, burpee, lunge, pull-up, …

  Equipment is set to "coupon" for coupon-category exercises, else "none".

INTENSITY INFERENCE:
  Assigns one of three intensity levels from keyword scoring:

    beginner     — "easy", "basic", "modified", "low impact", "hold", …
    intermediate — default (most exercises)
    advanced     — "ruck", "ranger", "diamond", "explosive", "pistol", …

TUNING:
  Extend any of the *_WORDS lists near the top of this file to improve
  categorisation or intensity accuracy for your region's naming conventions.

REQUIREMENTS:
  Python ≥ 3.8, standard library only (csv, json, re, argparse, collections).
"""

import argparse
import csv
import json
import re
import sys
from collections import Counter
from pathlib import Path

# ─── Category keyword lists ────────────────────────────────────────────────────

WARMUP_WORDS = [
    'warm up', 'warm-up', 'warmup', 'ssh', 'side straddle hop',
    'imperial walker', 'windmill', 'stretch', 'mosey', 'lunge walk',
    'baby arm circle', 'seal jack', 'cotton picker', 'arm circle',
    'grass grab', 'toy soldier', 'abe vigoda', 'imperial squat walker',
    'cherry picker', 'hillbilly', 'tappy tap', 'high knee',
]

COUPON_WORDS = [
    'coupon', 'block', 'sandbag', 'ruck', 'dumbbell', 'dumbell',
    'kettlebell', 'kettle bell', 'weight', 'barbell', 'plate', 'tire',
    'log', 'cinder', 'farmer carry', 'loaded carry', 'kb ', 'db ',
    'rucksack', 'ruck sack', 'thang',
]

MARY_WORDS = [
    'mary', 'ab ', 'ab-', 'core', 'plank', 'flutter kick', 'lbc',
    'hello dolly', 'crunch', 'sit-up', 'sit up', 'situp', 'leg raise',
    'bicycle kick', 'v-up', 'american hammer', 'dying cockroach',
    'crunchy frog', 'freddie mercury', 'dolly', 'rosalita', 'j-lo',
    'heels to heaven', 'box cutter', 'low slow flutter',
]

BODYWEIGHT_WORDS = [
    'merkin', 'squat', 'burpee', 'lunge', 'dip', 'pull-up', 'pullup',
    'push-up', 'pushup', 'jump', 'bear crawl', 'mountain climber',
    'step up', 'box jump', 'broad jump', 'calf raise', 'hip press',
    'bridge', 'superman', 'monkey humper', 'air squat',
]

# ─── Intensity keyword lists ───────────────────────────────────────────────────

BEGINNER_WORDS = [
    'beginner', 'easy', 'basic', 'simple', 'modified', 'low impact', 'light',
    'gentle', 'walk', 'stroll', 'slow', 'rest', 'recover', 'hold',
    'air chair', 'wall sit', 'half', 'partial',
]

ADVANCED_WORDS = [
    'advanced', 'ruck', 'ranger', 'diamond', 'clap', 'explosive',
    'plyometric', 'single leg', 'pistol', 'handstand', 'sprint',
    'full extension', 'muscle up', 'kipping', 'elevated', 'weighted',
    'tempo', 'max reps', 'partner carry', 'heavy', 'triple',
    '100 ', '200 ', '300 ',
]


# ─── Helpers ──────────────────────────────────────────────────────────────────

def html_to_text(html: str) -> str:
    """Strip HTML tags and collapse whitespace to a single space."""
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', html)).strip()


def parse_aliases(raw: str) -> list:
    raw = raw.strip()
    if not raw or raw in ('[object Object]', '[]'):
        return []
    if raw.startswith('['):
        try:
            parsed = json.loads(raw)
            if isinstance(parsed, list):
                return [str(a).strip() for a in parsed if str(a).strip()]
        except json.JSONDecodeError:
            pass
        return [a.strip().strip('"') for a in raw.strip('[]').split(',') if a.strip()]
    return [a.strip() for a in raw.split(',') if a.strip()]


def categorize(name: str, description: str) -> str:
    hay = (name + ' ' + description).lower()
    scores = {'warmup': 0, 'coupon': 0, 'mary': 0, 'bodyweight': 0}
    for w in WARMUP_WORDS:
        if w in hay: scores['warmup'] += 2
    for w in COUPON_WORDS:
        if w in hay: scores['coupon'] += 2
    for w in MARY_WORDS:
        if w in hay: scores['mary'] += 2
    for w in BODYWEIGHT_WORDS:
        if w in hay: scores['bodyweight'] += 1
    best = max(scores, key=scores.get)
    return best if scores[best] > 0 else 'bodyweight'


def infer_intensity(name: str, description: str) -> str:
    hay = (name + ' ' + description).lower()
    beg = sum(1 for w in BEGINNER_WORDS if w in hay)
    adv = sum(1 for w in ADVANCED_WORDS if w in hay)
    if adv > beg and adv >= 2:
        return 'advanced'
    if beg > adv and beg >= 2:
        return 'beginner'
    return 'intermediate'


KNOWN_COLUMNS = {'ID', 'Name', 'Description', 'Aliases', 'DemoUrl', 'VideoUrl', 'GifUrl'}


def convert(
    csv_path: Path,
    output_path: Path,
    pretty: bool,
    print_stats: bool,
) -> int:
    exercises = []

    with csv_path.open(newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = set(reader.fieldnames or [])
        extra_cols = fieldnames - KNOWN_COLUMNS

        for row in reader:
            name = row.get('Name', '').strip()
            if not name:
                continue

            raw_desc = row.get('Description', '').strip()
            demo_url = (
                row.get('GifUrl') or row.get('VideoUrl') or row.get('DemoUrl') or ''
            )
            desc_text = html_to_text(raw_desc)
            aliases = parse_aliases(row.get('Aliases', ''))
            category = categorize(name, desc_text)
            intensity = infer_intensity(name, desc_text)
            equipment = 'coupon' if category == 'coupon' else 'none'

            exercise: dict = {
                'id': row.get('ID', '').strip(),
                'name': name,
                'description': desc_text,
                'aliases': aliases,
                'category': category,
                'equipment': equipment,
                'intensity': intensity,
                'demo_url': demo_url.strip(),
            }

            if extra_cols:
                exercise['extra'] = {
                    col: row[col] for col in extra_cols
                    if col in row and row[col]
                }

            exercises.append(exercise)

    output = {
        'version':        '1.1.0',
        'source':         csv_path.name,
        'exercise_count': len(exercises),
        'exercises':      exercises,
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open('w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2 if pretty else None)

    if print_stats:
        cat_counts = Counter(e['category']  for e in exercises)
        int_counts = Counter(e['intensity'] for e in exercises)
        print(f'\nConverted {len(exercises)} exercises → {output_path}')
        print('\nCategory breakdown:')
        for cat in ('warmup', 'bodyweight', 'coupon', 'mary'):
            print(f'  {cat:<14} {cat_counts[cat]:>4}')
        print('\nIntensity breakdown:')
        for lvl in ('beginner', 'intermediate', 'advanced'):
            print(f'  {lvl:<14} {int_counts[lvl]:>4}')
        print(f'\n  {"TOTAL":<14} {len(exercises):>4}')

    return len(exercises)


# ─── CLI ──────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description='Convert F3 Exicon CSV to Digital Weinke exercises.json asset.'
    )
    parser.add_argument(
        '--input', '-i',
        type=Path,
        default=Path('f3-codex-export.csv'),
        help='Path to the Exicon CSV export (default: f3-codex-export.csv)',
    )
    parser.add_argument(
        '--output', '-o',
        type=Path,
        default=Path('assets/data/exercises.json'),
        help='Destination JSON path (default: assets/data/exercises.json)',
    )
    parser.add_argument(
        '--pretty', action='store_true',
        help='Indent JSON output (human-readable; ~4× larger)',
    )
    parser.add_argument(
        '--stats', action='store_true',
        help='Print category + intensity counts after conversion',
    )

    args = parser.parse_args()

    if not args.input.exists():
        print(f'ERROR: input file not found: {args.input}', file=sys.stderr)
        sys.exit(1)

    convert(args.input, args.output, args.pretty, args.stats)


if __name__ == '__main__':
    main()
