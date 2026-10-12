"""Reproducible visual-asset manifest and dimensions check for Battlemage Arena.

Generated assets are authored in Aseprite and exported by:
    Aseprite --batch --script-param root=<project> --script tools/refactor_visual_assets.lua
    Aseprite --batch --script-param root=<project> --script tools/refactor_actor_assets.lua
    Aseprite --batch --script-param root=<project> --script tools/refactor_ui_assets.lua
"""
from __future__ import annotations
import argparse
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPELLS = [
    "fireball","combustion","burning_ground","flame_lash",
    "ice_spike","frost_nova","icicle_rain","ice_barrier",
    "earth_pillar","stone_fist","stone_guard","tremor",
    "gust","vortex","wind_blade","wind_dash",
    "claw","pounce","slam","spit","hex",
]
ACTORS = ["player","pyromancer","cryomancer","battlemage","champion","golem","hound","skitter","spitter","wisp"]
PROPS = ["column","broken_column","brazier","crystal","banner_fire","banner_ice","banner_earth","banner_air"]
BUTTONS = ["normal","hover","pressed","disabled","focus","selected"]
STATUSES = ["burn","chill","freeze","stagger","airborne","barrier","guard","invulnerable"]

def entries():
    for actor in ACTORS:
        yield dict(id="actor_"+actor,category="actor",source=f"art/source/visual_refactor/actor_{actor}.aseprite",
            export=f"art/sprites/actors/{actor}.png",width=256,height=320,frame_size=[64,64],frames=20)
    for spell in SPELLS:
        yield dict(id="fx_"+spell,category="spell",source=f"art/source/visual_refactor/spell_{spell}.aseprite",
            export=f"art/sprites/spells/{spell}.png",width=192,height=48,frame_size=[48,48],frames=4)
        yield dict(id="icon_spell_"+spell,category="skill_icon",source=f"art/source/visual_refactor/icon_{spell}.aseprite",
            export=f"art/icons/spells/{spell}.png",width=48,height=48,frame_size=[48,48],frames=1)
    yield dict(id="tile_arena_floor",category="environment",source="art/source/visual_refactor/arena_floor.aseprite",
        export="art/sprites/tiles/arena_floor.png",width=512,height=64,frame_size=[64,64],frames=8)
    for prop in PROPS:
        size=(32,64) if prop.startswith("banner_") else (48,96) if "column" in prop else (48,72)
        yield dict(id="prop_"+prop,category="environment_prop",source=f"art/source/visual_refactor/prop_{prop}.aseprite",
            export=f"art/sprites/props/{prop}.png",width=size[0],height=size[1],frame_size=list(size),frames=1)
    for button in BUTTONS:
        yield dict(id="ui_button_"+button,category="ui_button",source=f"art/source/visual_refactor/ui_button_{button}.aseprite",
            export=f"art/sprites/ui/button_{button}.png",width=96,height=40,frame_size=[96,40],frames=1)
    for status in STATUSES:
        yield dict(id="icon_status_"+status,category="status_icon",source=f"art/source/visual_refactor/status_{status}.aseprite",
            export=f"art/sprites/status/{status}.png",width=24,height=24,frame_size=[24,24],frames=1)

def dimensions(path:Path):
    data=path.read_bytes()[:24]
    if data[:8]!=b"\x89PNG\r\n\x1a\n":
        raise ValueError("Not a PNG")
    return struct.unpack(">II",data[16:24])

def run(write:bool):
    manifest={"schema_version":1,"description":"Aseprite-authored visual refactor assets; reference image is not a source atlas","assets":list(entries())}
    manifest_path=ROOT/"art"/"asset_manifest.json"
    if write:
        manifest_path.write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    else:
        if not manifest_path.exists():raise ValueError("Missing manifest: "+str(manifest_path))
        saved=json.loads(manifest_path.read_text(encoding="utf-8"))
        if saved!=manifest:raise ValueError("Asset manifest drift; run --write and review changes")
    errors=[]
    for item in manifest["assets"]:
        source=ROOT/item["source"]; export=ROOT/item["export"]
        if not source.is_file():errors.append(f"{item['id']} missing Aseprite source {source}")
        if not export.is_file():errors.append(f"{item['id']} missing PNG export {export}");continue
        try:
            actual=dimensions(export)
            expected=(item["width"],item["height"])
            if actual!=expected:errors.append(f"{item['id']} dimensions {actual} != {expected}")
        except Exception as exc:
            errors.append(f"{item['id']} invalid image {exc}")
    if errors:
        print("\n".join(errors));raise SystemExit(1)
    print(f"PASS: validated {len(manifest['assets'])} source/PNG asset pairs and dimensions")

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--write",action="store_true",help="Create/update manifest before validation")
    args=parser.parse_args()
    run(args.write)
