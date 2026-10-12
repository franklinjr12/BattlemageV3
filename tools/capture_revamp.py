"""Capture real Godot UI screenshots and before/after evidence. Debug capture branch only."""
from pathlib import Path
import subprocess,sys,shutil
ROOT=Path(__file__).resolve().parents[1]
GODOT=Path("C:/Users/sa-su/Documents/Godot/Godot_console.exe")
OUT=ROOT/"docs"/"revamp_validation"
for kind in ("before","after"): (OUT/kind).mkdir(parents=True,exist_ok=True)
pages=sys.argv[1:] or ["title","creation","hub","shop","gear","build","encounters","level","reward","completion","settings","pause","combat","champion"]
for page in pages:
    original=OUT/"before"/f"{page}.png"
    if not original.exists():
        old=subprocess.run(["git","show",f"HEAD:docs/screenshots/{page}.png"],cwd=ROOT,capture_output=True)
        if old.returncode==0 and old.stdout:original.write_bytes(old.stdout)
    args=[str(GODOT),"--path",str(ROOT),"--","--capture",page]
    try:
        run=subprocess.run(args,cwd=ROOT,capture_output=True,timeout=40)
    except subprocess.TimeoutExpired:
        print("TIMEOUT",page,flush=True);continue
    shot=ROOT/"docs"/"screenshots"/f"{page}.png"
    if shot.exists() and run.returncode==0:
        shutil.copy2(shot,OUT/"after"/f"{page}.png")
        print("CAPTURE",page,shot.stat().st_size,flush=True)
    else:
        print("FAILED",page,run.returncode,run.stdout.decode(errors='replace')[-250:],run.stderr.decode(errors='replace')[-450:],flush=True)
