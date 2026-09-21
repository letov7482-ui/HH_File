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
MENU_SRC   = ROOT / "src" / "menu" / "menu.lua"
ORIG       = ROOT / "vendor" / "SecurityCommonUtils.original.lua"

# корень Lua внутри PAK
PAK_LUA_ROOT = STAGE / "ShadowTrackerExtra/Content/Lua"

# наш загрузчик
PAK_LOADER = PAK_LUA_ROOT / "HH_loader.lua"

# override SecurityCommonUtils
PAK_SECURITY_DIR  = PAK_LUA_ROOT / "GameLua/Mod/BaseMod/Common/Security"
PAK_SECURITY_ORIG = PAK_SECURITY_DIR / "SecurityCommonUtils.lua"

# override HawkEyeReportWindow (наше меню)
PAK_HAWKEYE_DIR    = PAK_LUA_ROOT / "GameLua/Mod/BaseMod/Client/Security/UI"
PAK_HAWKEYE_WINDOW = PAK_HAWKEYE_DIR / "HawkEyeReportWindow.lua"


def main():
    # чистим staging
    if STAGE.exists():
        shutil.rmtree(STAGE)
    PAK_SECURITY_DIR.mkdir(parents=True)
    PAK_HAWKEYE_DIR.mkdir(parents=True)

    # --- 1. loader с подставленными солью и манифестом ---
    kd = json.loads(KEY_FILE.read_text())
    manifest_b64 = base64.b64encode((ENC_DIR / "manifest.json").read_bytes()).decode()

    loader_final = (LOADER_SRC.read_text()
        .replace("__S4_SALT__",  kd["s4_salt"])
        .replace("__MANIFEST__", manifest_b64))
    PAK_LOADER.write_text(loader_final)
    print(f"[pack] loader -> {PAK_LOADER.relative_to(STAGE)}")

    # --- 2. override SecurityCommonUtils (оригинал + require loader) ---
    if not ORIG.exists():
        raise SystemExit(f"[pack] нет оригинала: {ORIG}")
    PAK_SECURITY_ORIG.write_text(
        ORIG.read_text()
        + '\n-- === HH boot ===\n'
        + 'require("HH_loader").boot()\n'
    )
    print(f"[pack] security -> {PAK_SECURITY_ORIG.relative_to(STAGE)}")

    # --- 3. override HawkEyeReportWindow (наше меню, не шифруется) ---
    if not MENU_SRC.exists():
        raise SystemExit(f"[pack] нет menu.lua: {MENU_SRC}")
    PAK_HAWKEYE_WINDOW.write_text(MENU_SRC.read_text())
    print(f"[pack] menu     -> {PAK_HAWKEYE_WINDOW.relative_to(STAGE)}")

    # --- 4. пакуем ---
    out_pak = OUT / f"{PATCH_NAME}.pak"
    if out_pak.exists():
        out_pak.unlink()

    subprocess.run([
        "repak", "pack", str(STAGE), str(out_pak)
    ], check=True)
    print(f"[pack] готов: {out_pak}  ({out_pak.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
