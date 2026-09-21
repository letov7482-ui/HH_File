# HH_Cheat/build/pack.py
import subprocess, shutil, json, base64, os
from pathlib import Path

PATCH_NAME = os.environ.get("PATCH_NAME", "game_patch_4.6.0.21565")

ROOT       = Path(__file__).resolve().parent.parent
OUT        = ROOT / "out"
STAGE      = OUT / "pak_stage"
ENC_DIR    = OUT / "encrypted"
KEY_FILE   = ROOT / "build" / "key.json"
LOADER_SRC = ROOT / "src" / "loader.lua"
ORIG       = ROOT / "vendor" / "SecurityCommonUtils.original.lua"

PAK_ROOT          = STAGE / "ShadowTrackerExtra/Content/Lua"
PAK_LOADER        = PAK_ROOT / "HH_loader.lua"
PAK_SECURITY_DIR  = PAK_ROOT / "GameLua/Mod/BaseMod/Common/Security"
PAK_SECURITY_ORIG = PAK_SECURITY_DIR / "SecurityCommonUtils.lua"
PAK_SECURITY_BOOT = PAK_SECURITY_DIR / "_hh_boot.lua"

def main():
    if STAGE.exists(): shutil.rmtree(STAGE)
    PAK_SECURITY_DIR.mkdir(parents=True)

    kd = json.loads(KEY_FILE.read_text())
    manifest_b64 = base64.b64encode((ENC_DIR / "manifest.json").read_bytes()).decode()

    loader_src = LOADER_SRC.read_text()
    loader_final = (loader_src
        .replace("__S4_SALT__",  kd["s4_salt"])
        .replace("__MANIFEST__", manifest_b64))

    PAK_LOADER.write_text(loader_final)

    if not ORIG.exists():
        raise SystemExit(f"[pack] нет оригинала: {ORIG}")
    PAK_SECURITY_ORIG.write_text(
        ORIG.read_text()
        + '\n-- === HH ===\n'
        + 'require("HH_loader").boot()\n'
    )

    PAK_SECURITY_BOOT.write_text('require("HH_loader").boot()\n')

    out_pak = OUT / f"{PATCH_NAME}.pak"
    # repak pack — кроссплатформенный
    subprocess.run([
        "repak", "pack", str(STAGE), str(out_pak)
    ], check=True)
    print(f"[pack] готов: {out_pak}")

if __name__ == "__main__":
    main()
