"""One-time idempotent migration from legacy SVG skill icons to Aseprite PNG icons.

The generated icon PNGs must exist before this script runs.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
changed = 0
for spell_resource in sorted((ROOT / "resources" / "spells").glob("*.tres")):
    old = f'path="res://art/{spell_resource.stem}.svg"'
    new = f'path="res://art/icons/spells/{spell_resource.stem}.png"'
    text = spell_resource.read_text(encoding="utf-8")
    if new in text:
        continue
    if old not in text:
        continue  # Enemy-only spells may have no standalone UI icon.
    export = ROOT / "art" / "icons" / "spells" / (spell_resource.stem + ".png")
    if not export.is_file():
        raise SystemExit(f"Missing required PNG before migration: {export}")
    spell_resource.write_text(text.replace(old, new), encoding="utf-8", newline="\n")
    changed += 1
print(f"Skill icon migration complete: {changed} Resource paths changed")
